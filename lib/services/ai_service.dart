import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../app_constants.dart';
import '../models/budget_plan.dart';
import '../models/parsed_expense.dart';
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
  AIService({
    String? apiKey,
    String? githubModelsToken,
    String? modelName,
    String? proxyUrl,
    http.Client? httpClient,
  }) : _githubModelsToken = _firstNonEmpty([
         githubModelsToken,
         apiKey,
         _defineGitHubModelsToken,
         _defineModelsApiToken,
         dotenv.env['GITHUB_MODELS_TOKEN'],
         dotenv.env['MODELS_API_TOKEN'],
       ]),
       _modelName = _firstNonEmpty([
         modelName,
         _defineGitHubModelsModel,
         dotenv.env['GITHUB_MODELS_MODEL'],
         AppConstants.githubModelsModel,
       ]),
       _proxyUrl = _firstNonEmpty([
         proxyUrl,
         _defineAiProxyUrl,
         dotenv.env['AI_PROXY_URL'],
       ]),
       _client = httpClient ?? http.Client();

  static const String _githubModelsEndpoint =
      'https://models.github.ai/inference/chat/completions';
  static const String _defineGitHubModelsToken = String.fromEnvironment(
    'GITHUB_MODELS_TOKEN',
  );
  static const String _defineModelsApiToken = String.fromEnvironment(
    'MODELS_API_TOKEN',
  );
  static const String _defineGitHubModelsModel = String.fromEnvironment(
    'GITHUB_MODELS_MODEL',
  );
  static const String _defineAiProxyUrl = String.fromEnvironment(
    'AI_PROXY_URL',
  );

  final String _githubModelsToken;
  final String _modelName;
  final String _proxyUrl;
  final http.Client _client;

  bool get isConfigured =>
      _proxyUrl.trim().isNotEmpty || _githubModelsToken.trim().isNotEmpty;

  Future<void> validateConfiguration() async {
    final text = await _generate('Reply with exactly: OK');
    if (text.trim().isEmpty) {
      throw AIConfigurationException(
        'The chatbot key was accepted but returned an empty response.',
      );
    }
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw AIConfigurationException(
        'AI is not configured. Set MODELS_API_TOKEN or GITHUB_MODELS_TOKEN as a dart define, or set AI_PROXY_URL for a server proxy.',
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

  /// Parse natural language expense input and extract structured data
  /// Example: "I spent 500 rupees on lunch today"
  /// Returns ParsedExpense with amount, category, and description
  Future<ParsedExpense> parseExpenseFromNaturalLanguage(
    String userInput, {
    List<String> availableCategories = const [
      'Groceries',
      'Transport',
      'Education',
      'Electricity',
      'Healthcare',
      'Entertainment',
      'Savings',
      'Others',
    ],
  }) async {
    if (userInput.trim().isEmpty) {
      return ParsedExpense(isExpense: false, error: 'Input cannot be empty');
    }

    final localFallback = _parseExpenseLocally(userInput, availableCategories);
    if (localFallback.isValid) {
      return localFallback;
    }

    final prompt =
        '''You are an AI that extracts expense information from natural language text.
Parse the user input and respond ONLY with a JSON object. Do not add any explanation.

Available categories: ${availableCategories.join(', ')}

User input: "$userInput"

Respond with JSON in this exact format:
{
  "is_expense": true/false,
  "amount": <number or null>,
  "category": "<category name or null>",
  "description": "<brief description or null>",
  "confidence": "high/medium/low",
  "raw_input": "$userInput"
}

Rules:
1. Set is_expense to true only if the user is describing spending money
2. Extract the amount as a number (not text)
3. Match category to available categories. Be flexible: "lunch" -> Groceries, "taxi" -> Transport, "doctor" -> Healthcare
4. If confidence is low or amount is missing, still return valid JSON
5. Return ONLY the JSON object, no other text''';

    try {
      final response = await _generate(prompt);

      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{[^{}]*\}').firstMatch(response);
      if (jsonMatch != null) {
        try {
          final decoded = jsonDecode(jsonMatch.group(0)!);
          final parsed = ParsedExpense.fromJson(decoded);
          return parsed.isValid ? parsed : localFallback;
        } catch (e) {
          // JSON parsing failed, return error
          return localFallback.isValid
              ? localFallback
              : ParsedExpense(
                  isExpense: false,
                  error: 'Failed to parse AI response: $e',
                  rawInput: userInput,
                );
        }
      }

      return localFallback.isValid
          ? localFallback
          : ParsedExpense(
              isExpense: false,
              error: 'Could not extract JSON from response',
              rawInput: userInput,
            );
    } catch (error) {
      return localFallback.isValid
          ? localFallback
          : ParsedExpense(
              isExpense: false,
              error: 'AI parsing failed: $error',
              rawInput: userInput,
            );
    }
  }

  ParsedExpense _parseExpenseLocally(
    String userInput,
    List<String> availableCategories,
  ) {
    final input = userInput.trim();
    final lower = input.toLowerCase();
    final expenseVerb = RegExp(
      r'\b(spent|paid|bought|purchased|used|expense|charged|cost)\b',
    );
    if (!expenseVerb.hasMatch(lower)) {
      return ParsedExpense(isExpense: false, rawInput: userInput);
    }

    final amountMatch = RegExp(
      r'(?:pkr|rs\.?|rupees?)\s*([0-9][0-9,]*(?:\.\d+)?)|([0-9][0-9,]*(?:\.\d+)?)\s*(?:pkr|rs\.?|rupees?)?',
      caseSensitive: false,
    ).firstMatch(input);
    final amountText = amountMatch?.group(1) ?? amountMatch?.group(2);
    final amount = double.tryParse(amountText?.replaceAll(',', '') ?? '');
    if (amount == null || amount <= 0) {
      return ParsedExpense(isExpense: true, rawInput: userInput);
    }

    final category = _categoryFromText(lower, availableCategories);
    return ParsedExpense(
      isExpense: true,
      amount: amount,
      category: category,
      description: _descriptionFromInput(input),
      rawInput: userInput,
      confidence: category == 'Others' ? 'medium' : 'high',
    );
  }

  String _categoryFromText(String lower, List<String> availableCategories) {
    final keywordMap = <String, List<String>>{
      'Groceries': [
        'food',
        'grocery',
        'groceries',
        'lunch',
        'dinner',
        'breakfast',
        'restaurant',
        'meal',
        'snack',
        'milk',
        'vegetable',
      ],
      'Transport': [
        'taxi',
        'uber',
        'careem',
        'bus',
        'fuel',
        'petrol',
        'rickshaw',
        'transport',
        'fare',
      ],
      'Education': [
        'school',
        'college',
        'university',
        'tuition',
        'book',
        'course',
        'fees',
      ],
      'Electricity': [
        'electricity',
        'utility',
        'utilities',
        'bill',
        'wapda',
        'k-electric',
      ],
      'Healthcare': [
        'doctor',
        'hospital',
        'medicine',
        'medical',
        'clinic',
        'pharmacy',
        'health',
      ],
      'Entertainment': [
        'movie',
        'cinema',
        'netflix',
        'game',
        'outing',
        'entertainment',
        'subscription',
      ],
      'Savings': ['saving', 'savings', 'deposit'],
    };

    for (final entry in keywordMap.entries) {
      if (entry.value.any(lower.contains)) {
        return availableCategories.contains(entry.key) ? entry.key : 'Others';
      }
    }
    if (availableCategories.contains('Others')) return 'Others';
    return availableCategories.isEmpty ? 'Others' : availableCategories.first;
  }

  String _descriptionFromInput(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'\b(i|have|just)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? 'Voice expense' : cleaned;
  }

  Future<String> _generate(String prompt) async {
    _ensureConfigured();

    final useProxy = _proxyUrl.isNotEmpty;
    final uri = Uri.parse(useProxy ? _proxyUrl : _githubModelsEndpoint);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (!useProxy) {
      headers['Authorization'] = 'Bearer $_githubModelsToken';
      headers['X-GitHub-Api-Version'] = '2022-11-28';
    }

    final body = jsonEncode({
      'model': _modelName,
      'temperature': 0.35,
      'max_tokens': 500,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are FinEase, a practical financial resilience assistant for users in Pakistan. Be concise, specific, and action-focused.',
        },
        {'role': 'user', 'content': prompt},
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AIConfigurationException(
          'GitHub Models rejected the token. Check MODELS_API_TOKEN or GITHUB_MODELS_TOKEN, and confirm the token has Models access.',
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AIConfigurationException(
          'AI request failed with status ${response.statusCode}. Check GITHUB_MODELS_MODEL, token access, and network.',
        );
      }

      final decoded = jsonDecode(response.body);
      final text = _extractText(decoded);
      if (text.isEmpty) {
        throw AIConfigurationException(
          'AI returned an empty response. Verify the $_modelName model and token access.',
        );
      }

      return text.replaceAll('\u2022', '-').trim();
    } on AIConfigurationException {
      rethrow;
    } on TimeoutException {
      throw AIConfigurationException(
        'AI request timed out. Check the network and try again.',
      );
    } catch (error) {
      throw AIConfigurationException(
        'AI request failed. Check MODELS_API_TOKEN, GITHUB_MODELS_MODEL, AI_PROXY_URL, and network. Details: $error',
      );
    }
  }

  static String _extractText(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) return '';

    final choices = decoded['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String) return content.trim();
          if (content is List) {
            return content
                .map((part) {
                  if (part is String) return part;
                  if (part is Map<String, dynamic>) {
                    return part['text']?.toString() ?? '';
                  }
                  return '';
                })
                .join()
                .trim();
          }
        }

        final text = first['text'];
        if (text is String) return text.trim();
      }
    }

    for (final key in const ['text', 'content', 'answer', 'message']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  static String _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }
}
