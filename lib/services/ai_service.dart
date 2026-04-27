import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/saving_goal.dart';
import '../models/transaction.dart';

class AIService {
  AIService({String? apiKey})
    : _apiKey = apiKey?.trim().isNotEmpty == true
          ? apiKey!.trim()
          : dotenv.env['GEMINI_API_KEY']?.trim() ?? '' {
    _useRealAI = _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY';
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
  }

  final String _apiKey;
  late final GenerativeModel _model;
  late final bool _useRealAI;

  Future<String> getBudgetAdvice(
    List<FinancialTransaction> transactions,
  ) async {
    if (transactions.isEmpty || !_useRealAI) {
      return _mockBudgetAdvice(transactions);
    }

    final prompt =
        '''
You are a financial coach. Return exactly 3 bullet points.
Focus on savings, unusual spending, and one specific action for this month.
Keep each bullet under 24 words.
Transactions:
${transactions.take(30).map((t) => '${t.title} | ${t.type} | ${t.category} | \$${t.amount.toStringAsFixed(0)}').join('\n')}
''';

    return _generateOrFallback(prompt, _mockBudgetAdvice(transactions));
  }

  Future<List<Map<String, dynamic>>> detectUnusualSpending(
    List<FinancialTransaction> transactions,
  ) async {
    final Map<String, List<double>> categorySpending = {};
    for (final transaction in transactions.where((t) => t.type == 'expense')) {
      categorySpending
          .putIfAbsent(transaction.category, () => [])
          .add(transaction.amount);
    }

    final anomalies = <Map<String, dynamic>>[];
    for (final entry in categorySpending.entries) {
      if (entry.value.length < 2) {
        continue;
      }

      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      final highest = entry.value.reduce((a, b) => a > b ? a : b);
      if (highest >= average * 1.45) {
        anomalies.add({
          'category': entry.key,
          'amount': highest,
          'average': average,
          'overspent': highest - average,
        });
      }
    }

    anomalies.sort(
      (a, b) => (b['overspent'] as double).compareTo(a['overspent'] as double),
    );
    return anomalies.take(4).toList();
  }

  Future<String> getSavingsInsight(List<SavingGoal> goals) async {
    if (goals.isEmpty || !_useRealAI) {
      return _mockSavingsInsight(goals);
    }

    final prompt =
        '''
You are a savings coach. Return exactly 2 bullet points with concrete tactics.
Keep each bullet below 22 words.
Goals:
${goals.map((goal) => '${goal.title}: \$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)} due ${goal.targetDate.toIso8601String()}').join('\n')}
''';

    return _generateOrFallback(prompt, _mockSavingsInsight(goals));
  }

  Future<String> getInvestmentSuggestions(
    List<SavingGoal> goals,
    double totalSaved,
  ) async {
    final fallback = _mockInvestmentSuggestions(totalSaved);
    if (!_useRealAI) {
      return fallback;
    }

    final prompt =
        '''
Act as a conservative personal finance coach.
Return exactly 3 bullet points with beginner-friendly investment or savings opportunities.
Mention risk briefly and keep each bullet below 24 words.
Total saved: \$${totalSaved.toStringAsFixed(0)}
Goals: ${goals.map((goal) => goal.title).join(', ')}
''';

    return _generateOrFallback(prompt, fallback);
  }

  Future<String> getGoalImprovementTips(SavingGoal goal) async {
    final remaining = goal.remaining;
    final daysLeft = goal.daysLeft <= 0 ? 1 : goal.daysLeft;
    final fallback =
        'Save about \$${(remaining / daysLeft).toStringAsFixed(2)} per day for ${goal.title}, and automate the transfer right after payday.';

    if (!_useRealAI) {
      return fallback;
    }

    final prompt =
        '''
Give one practical sentence under 28 words to improve this savings goal.
Goal: ${goal.title}
Progress: ${(goal.progress * 100).round()}%
Remaining: \$${remaining.toStringAsFixed(0)}
Days left: $daysLeft
''';

    return _generateOrFallback(prompt, fallback);
  }

  Future<String> _generateOrFallback(String prompt, String fallback) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return fallback;
      }
      return text.replaceAll('•', '-');
    } catch (_) {
      return fallback;
    }
  }

  String _mockBudgetAdvice(List<FinancialTransaction> transactions) {
    if (transactions.isEmpty) {
      return '- Add a few transactions first so FinEase can build personalized budget advice.\n- Start by tracking fixed bills, food, and transport.\n- Set a weekly spending check-in to catch drift early.';
    }

    final expenses = transactions.where((t) => t.type == 'expense').toList();
    final totalExpense = expenses.fold<double>(0, (sum, t) => sum + t.amount);
    final averageExpense = expenses.isEmpty
        ? 0.0
        : totalExpense / expenses.length;
    final topCategory = _topExpenseCategory(transactions);

    return '- $topCategory is your largest expense category. Cap it before month-end.\n- Average expense size is \$${averageExpense.toStringAsFixed(0)}. Watch frequent small purchases.\n- Move 10% of every income transaction into savings automatically.';
  }

  String _mockSavingsInsight(List<SavingGoal> goals) {
    if (goals.isEmpty) {
      return '- Create one short-term emergency fund goal first.\n- Start with an automatic weekly contribution, even if it is small.';
    }

    final mostUrgent = goals.reduce((a, b) => a.daysLeft < b.daysLeft ? a : b);
    final weeklyNeeded = mostUrgent.daysLeft <= 0
        ? mostUrgent.remaining
        : mostUrgent.remaining / (mostUrgent.daysLeft / 7);

    return '- ${mostUrgent.title} needs about \$${weeklyNeeded.toStringAsFixed(0)} per week to stay on schedule.\n- Redirect one non-essential category into your top-priority goal this month.';
  }

  String _mockInvestmentSuggestions(double saved) {
    if (saved < 1000) {
      return '- Keep emergency cash in a high-yield savings account before taking risk.\n- Use round-up savings or recurring transfers to build your first \$1,000 buffer.\n- Learn index funds now, but prioritize liquidity first.';
    }
    if (saved < 5000) {
      return '- Consider a broad-market index fund for long-term growth if your emergency fund is stable.\n- Compare Roth IRA eligibility for tax-advantaged investing.\n- Keep near-term goals in cash, not volatile assets.';
    }
    return '- Split long-term money between a broad-market index fund and high-yield cash reserves.\n- Consider Treasury bills for low-risk short-term yields.\n- Match investments to each goal timeline before chasing returns.';
  }

  String _topExpenseCategory(List<FinancialTransaction> transactions) {
    final totals = <String, double>{};
    for (final transaction in transactions.where((t) => t.type == 'expense')) {
      totals[transaction.category] =
          (totals[transaction.category] ?? 0) + transaction.amount;
    }
    if (totals.isEmpty) {
      return 'General';
    }
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
