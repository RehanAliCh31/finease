import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../app_constants.dart';
import '../models/budget_plan.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../utils/currency_utils.dart';

class AIConfigurationException implements Exception {
  AIConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AIService {
  AIService({String? apiKey, String? modelName})
    : _apiKey = apiKey?.trim().isNotEmpty == true
          ? apiKey!.trim()
          : dotenv.env['GEMINI_API_KEY']?.trim() ?? '',
      _modelName = modelName?.trim().isNotEmpty == true
          ? modelName!.trim()
          : dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
          ? dotenv.env['GEMINI_MODEL']!.trim()
          : AppConstants.geminiModel {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(model: _modelName, apiKey: _apiKey);
    }
  }

  final String _apiKey;
  final String _modelName;
  GenerativeModel? _model;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<void> validateConfiguration() async {
    _ensureConfigured();
    try {
      final response = await _model!.generateContent([
        Content.text('Reply with exactly: OK'),
      ]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw AIConfigurationException(
          'The chatbot API key was accepted but returned an empty response.',
        );
      }
    } catch (error) {
      if (error is AIConfigurationException) rethrow;
      throw AIConfigurationException(
        'Invalid or inactive chatbot API key. Update GEMINI_API_KEY in .env and restart FinEase.',
      );
    }
  }

  void _ensureConfigured() {
    if (!isConfigured || _model == null) {
      throw AIConfigurationException(
        'AI is not configured. Add a valid GEMINI_API_KEY in .env and restart FinEase.',
      );
    }
  }

  Future<String> getBudgetAdvice(
    List<FinancialTransaction> transactions,
  ) async {
    if (transactions.isEmpty) {
      return 'Add this month\'s income and expenses first so the AI Budget Advisor can analyze real financial activity.';
    }

    final prompt =
        '''
You are FinEase AI Budget Advisor for users in Pakistan.
Return exactly 3 concise bullet points using PKR amounts.
Analyze only the real current-month transactions below.
Focus on savings, unusual spending, and one specific action for this month.
Transactions:
${transactions.take(60).map((t) => '${t.title} | ${t.type} | ${t.category} | ${CurrencyUtils.format(t.amount)} | ${t.date.toIso8601String()}').join('\n')}
''';

    return _generate(prompt);
  }

  Future<List<Map<String, dynamic>>> detectUnusualSpending(
    List<FinancialTransaction> transactions,
  ) async {
    final categorySpending = <String, List<double>>{};
    for (final transaction in transactions.where((t) => t.type == 'expense')) {
      categorySpending
          .putIfAbsent(transaction.category, () => [])
          .add(transaction.amount);
    }

    final anomalies = <Map<String, dynamic>>[];
    for (final entry in categorySpending.entries) {
      if (entry.value.length < 2) continue;
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
    if (goals.isEmpty) {
      return 'Create at least one savings goal first so the AI Finance Coach can generate personalized guidance.';
    }

    final prompt =
        '''
You are FinEase AI Finance Coach.
Return exactly 2 concrete bullet points using PKR amounts.
Base advice only on these real savings goals:
${goals.map((goal) => '${goal.title}: ${CurrencyUtils.format(goal.currentAmount)} / ${CurrencyUtils.format(goal.targetAmount)} due ${goal.targetDate.toIso8601String()}').join('\n')}
''';

    return _generate(prompt);
  }

  Future<String> getInvestmentSuggestions(
    List<SavingGoal> goals,
    double totalSaved,
  ) async {
    final prompt =
        '''
Act as a conservative personal finance coach in Pakistan.
Return exactly 3 beginner-friendly investment or savings suggestions.
Mention risk briefly. Do not recommend individual stocks.
Total saved: ${CurrencyUtils.format(totalSaved)}
Goals: ${goals.map((goal) => goal.title).join(', ')}
''';

    return _generate(prompt);
  }

  Future<String> getGoalImprovementTips(SavingGoal goal) async {
    final remaining = goal.remaining;
    final daysLeft = goal.daysLeft <= 0 ? 1 : goal.daysLeft;
    final prompt =
        '''
Give one practical sentence under 28 words to improve this savings goal.
Use PKR and this exact data:
Goal: ${goal.title}
Progress: ${(goal.progress * 100).round()}%
Remaining: ${CurrencyUtils.format(remaining)}
Days left: $daysLeft
''';

    return _generate(prompt);
  }

  Future<String> getBudgetPlanRecommendations(
    List<BudgetPlan> budgets,
    List<FinancialTransaction> transactions,
  ) async {
    if (budgets.isEmpty) {
      return 'Create category budgets first, then FinEase AI can compare planned amounts against your real spending.';
    }

    final budgetLines = budgets
        .map(
          (budget) =>
              '${budget.title} | ${budget.category} | allocated ${CurrencyUtils.format(budget.allocatedAmount)}',
        )
        .join('\n');
    final transactionLines = transactions
        .take(50)
        .map(
          (tx) =>
              '${tx.category} | ${tx.type} | ${CurrencyUtils.format(tx.amount)}',
        )
        .join('\n');

    final prompt =
        '''
You are the FinEase AI Budget Advisor.
Return exactly 3 bullet points.
Each bullet must mention one practical action tied to the user's current-month budget plans.
Use PKR and do not invent missing data.
Budgets:
$budgetLines

Transactions:
$transactionLines
''';

    return _generate(prompt);
  }

  Future<String> generalFinancialAnswer(String question) {
    final prompt =
        '''
You are FinEase AI Chatbot, a general financial Q&A assistant for Pakistan.
Answer the user's question clearly with practical PKR examples where relevant.
Do not pretend to know the user's personal balances unless supplied.
Question: $question
''';
    return _generate(prompt);
  }

  Future<String> personalizedCoachAnswer({
    required String question,
    required List<FinancialTransaction> transactions,
    required List<BudgetPlan> budgets,
    required List<SavingGoal> goals,
  }) {
    final prompt =
        '''
You are FinEase AI Finance Coach.
Give personalized budgeting, savings, spending analysis, and recommendations using only the user's real data below.
If data is missing, say exactly what is needed.
Question: $question

Budgets:
${budgets.map((b) => '${b.category}: ${CurrencyUtils.format(b.allocatedAmount)}').join('\n')}

Savings goals:
${goals.map((g) => '${g.title}: ${CurrencyUtils.format(g.currentAmount)} of ${CurrencyUtils.format(g.targetAmount)}').join('\n')}

Transactions:
${transactions.take(80).map((t) => '${t.type} | ${t.category} | ${CurrencyUtils.format(t.amount)} | ${t.title}').join('\n')}
''';
    return _generate(prompt);
  }

  Future<String> _generate(String prompt) async {
    _ensureConfigured();
    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw AIConfigurationException(
          'AI returned an empty response. Verify the $_modelName model and API key.',
        );
      }
      return text.replaceAll('â€¢', '-');
    } on AIConfigurationException {
      rethrow;
    } catch (error) {
      throw AIConfigurationException(
        'AI request failed. Check GEMINI_API_KEY, GEMINI_MODEL, billing/API access, and network. Details: $error',
      );
    }
  }
}
