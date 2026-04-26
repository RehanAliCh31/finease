import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction.dart';

class AIService {
  final String apiKey;
  late final GenerativeModel _model;

  AIService({required this.apiKey}) {
    _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
  }

  Future<String> getBudgetAdvice(List<FinancialTransaction> transactions) async {
    if (apiKey.isEmpty || apiKey == 'AIzaSyAov6ZcsAyI0MtqJ81a1_xEZ2ELRgPyVm4') {
      return "AI Advisor is currently in mock mode. Please provide a Gemini API key for personalized insights.\n\n"
          "Tip: You spent a bit more on dining this week compared to last week. Consider setting a weekly limit.";
    }

    final prompt = "As a financial advisor, analyze these transactions and provide 2-3 concise, actionable pieces of advice to save money or optimize the budget. "
        "Transactions: ${transactions.map((t) => '${t.title}: \$${t.amount} (${t.category})').join(', ')}";

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to generate advice at this time.";
    } catch (e) {
      return "Error connecting to AI advisor: $e";
    }
  }
}
