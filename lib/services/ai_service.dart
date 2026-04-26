import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction.dart';
import '../models/saving_goal.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAov6ZcsAyI0MtqJ81a1_xEZ2ELRgPyVm4';
  late final GenerativeModel _model;
  bool _useRealAI = false;

  AIService({String? apiKey}) {
    final key = (apiKey?.isNotEmpty == true) ? apiKey! : _apiKey;
    _useRealAI = key.isNotEmpty && key != 'YOUR_API_KEY';
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: key);
  }

  // --------------- Budget Advisor ---------------

  Future<String> getBudgetAdvice(List<FinancialTransaction> transactions) async {
    if (!_useRealAI || transactions.isEmpty) {
      return _mockBudgetAdvice(transactions);
    }
    final prompt = '''You are a professional financial advisor AI. Analyze these recent transactions and provide exactly 3 concise, actionable insights in bullet points. Focus on savings opportunities and unusual patterns.

Transactions: ${transactions.take(20).map((t) => '${t.title}(\$${t.amount.toStringAsFixed(0)}, ${t.category}, ${t.type})').join('; ')}

Format: Start each point with • and keep each under 25 words. Be specific.''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _mockBudgetAdvice(transactions);
    } catch (e) {
      return _mockBudgetAdvice(transactions);
    }
  }

  String _mockBudgetAdvice(List<FinancialTransaction> transactions) {
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final topCategory = _getTopCategory(transactions);

    return '''• Your top spending category is **$topCategory** — consider setting a monthly cap to avoid overspending.\n\n• You've spent \$${totalExpense.toStringAsFixed(0)} this month. The 50/30/20 rule suggests allocating 20% (\$${(totalExpense * 0.2).toStringAsFixed(0)}) to savings.\n\n• Automate savings transfers on payday to build wealth consistently without relying on willpower.''';
  }

  // --------------- Unusual Spending ---------------

  Future<List<Map<String, dynamic>>> detectUnusualSpending(List<FinancialTransaction> transactions) async {
    // Group by category and find anomalies
    final Map<String, List<double>> categorySpending = {};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      categorySpending.putIfAbsent(t.category, () => []).add(t.amount);
    }

    final List<Map<String, dynamic>> anomalies = [];
    for (final entry in categorySpending.entries) {
      if (entry.value.length >= 2) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final max = entry.value.reduce((a, b) => a > b ? a : b);
        if (max > avg * 1.5) {
          anomalies.add({
            'category': entry.key,
            'amount': max,
            'average': avg,
            'overspent': max - avg,
          });
        }
      }
    }
    return anomalies;
  }

  // --------------- Savings AI ---------------

  Future<String> getSavingsInsight(List<SavingGoal> goals) async {
    if (goals.isEmpty) {
      return 'Start by creating your first savings goal! Even saving \$50/month adds up to \$600/year — the foundation of financial freedom.';
    }

    if (!_useRealAI) {
      return _mockSavingsInsight(goals);
    }

    final prompt = '''You are a savings advisor. Analyze these goals and provide 2 tips to accelerate savings:
Goals: ${goals.map((g) => '${g.title}: \$${g.currentAmount.toStringAsFixed(0)}/\$${g.targetAmount.toStringAsFixed(0)} (${(g.progress * 100).toStringAsFixed(0)}%)').join('; ')}
Keep each tip under 20 words, start with •.''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _mockSavingsInsight(goals);
    } catch (e) {
      return _mockSavingsInsight(goals);
    }
  }

  String _mockSavingsInsight(List<SavingGoal> goals) {
    final nearestGoal = goals.reduce((a, b) =>
        (a.targetDate.difference(DateTime.now()).inDays) < (b.targetDate.difference(DateTime.now()).inDays) ? a : b);
    final needed = nearestGoal.targetAmount - nearestGoal.currentAmount;
    final days = nearestGoal.targetDate.difference(DateTime.now()).inDays;
    final perDay = days > 0 ? needed / days : needed;

    return '''• Save \$${perDay.toStringAsFixed(2)}/day to reach "${nearestGoal.title}" on time — try a daily coffee-brew habit instead of café visits.\n\n• Round-up micro-savings: every purchase rounded to the next dollar, automatically saved. Small amounts build big momentum.''';
  }

  // --------------- Investment Suggestions ---------------

  Future<String> getInvestmentSuggestions(List<SavingGoal> goals, double totalSaved) async {
    if (!_useRealAI) {
      return _mockInvestmentSuggestions(totalSaved);
    }

    final prompt = '''As a financial advisor, suggest 3 investment opportunities for someone with \$${totalSaved.toStringAsFixed(0)} in savings and goals: ${goals.map((g) => g.title).join(', ')}. Be specific and practical. Format as • bullet points under 20 words each.''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? _mockInvestmentSuggestions(totalSaved);
    } catch (e) {
      return _mockInvestmentSuggestions(totalSaved);
    }
  }

  String _mockInvestmentSuggestions(double saved) {
    if (saved < 500) {
      return '''• Start a high-yield savings account (4–5% APY) — better than a standard bank account.\n\n• Try fractional share investing: buy partial stocks in companies you believe in for as little as \$1.\n\n• Look into micro-investment apps that round up purchases and invest the spare change automatically.''';
    } else if (saved < 5000) {
      return '''• Index funds (S&P 500 ETFs) offer broad market exposure with low fees — ideal for beginners.\n\n• Consider a Roth IRA: tax-free growth with \$7,000 annual contribution limit for 2024.\n\n• Treasury I-Bonds provide inflation-protected government-backed returns with zero risk.''';
    } else {
      return '''• Diversify into REITs for real estate exposure without buying property — average 8–12% returns.\n\n• Explore a 3-fund portfolio: US stocks, international stocks, and bonds for balanced growth.\n\n• With \$${saved.toStringAsFixed(0)} saved, consider consulting a fee-only financial advisor for a personalized wealth plan.''';
    }
  }

  // --------------- Helpers ---------------

  String _getTopCategory(List<FinancialTransaction> transactions) {
    final Map<String, double> totals = {};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }
    if (totals.isEmpty) return 'General';
    return totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Future<String> getGoalImprovementTips(SavingGoal goal) async {
    final progress = (goal.progress * 100).toStringAsFixed(0);
    final remaining = goal.targetAmount - goal.currentAmount;
    final days = goal.targetDate.difference(DateTime.now()).inDays;

    if (!_useRealAI) {
      return 'You\'re $progress% toward "${goal.title}". To hit your target, save \$${(remaining / (days > 0 ? days : 1)).toStringAsFixed(2)}/day. Consider automating transfers on payday.';
    }

    final prompt = 'Give one actionable tip (under 30 words) to help reach this savings goal: ${goal.title}, ${progress}% complete, \$${remaining.toStringAsFixed(0)} remaining, $days days left.';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Keep going! Consistency is the key to reaching your goal.';
    } catch (e) {
      return 'Keep going! You\'re $progress% there. Consistent small contributions beat sporadic large ones.';
    }
  }
}
