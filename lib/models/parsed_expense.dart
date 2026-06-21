class ParsedExpense {
  final bool isExpense;
  final double? amount;
  final String? category;
  final String? description;
  final String? rawInput;
  final String? confidence; // 'high', 'medium', 'low'
  final String? error;

  const ParsedExpense({
    required this.isExpense,
    this.amount,
    this.category,
    this.description,
    this.rawInput,
    this.confidence,
    this.error,
  });

  bool get isValid =>
      isExpense &&
      amount != null &&
      amount! > 0 &&
      _cleanText(category) != null;

  factory ParsedExpense.fromJson(Map<String, dynamic> json) {
    return ParsedExpense(
      isExpense: json['is_expense'] == true,
      amount: _parseDouble(json['amount']),
      category: _cleanText(json['category']),
      description: _cleanText(json['description']),
      rawInput: _cleanText(json['raw_input']),
      confidence: _cleanText(json['confidence']),
      error: _cleanText(json['error']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '').trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  static String? _cleanText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}
