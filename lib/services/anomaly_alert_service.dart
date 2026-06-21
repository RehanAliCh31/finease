import '../models/transaction.dart';
import '../utils/currency_utils.dart';

class AnomalyAlert {
  final String category;
  final double amount;
  final double average;
  final double overspent;
  final double percentageOver;
  final String message;
  final String suggestion;

  AnomalyAlert({
    required this.category,
    required this.amount,
    required this.average,
    required this.overspent,
    required this.percentageOver,
    required this.message,
    required this.suggestion,
  });

  factory AnomalyAlert.fromAnomalyData(Map<String, dynamic> data) {
    final category = _text(data['category']) ?? 'Others';
    final amount = _number(data['amount']);
    final average = _number(data['average']);
    final overspent = _number(
      data['overspent'],
      fallback: amount - average,
    ).clamp(0, double.infinity).toDouble();
    final percentageOver = average <= 0
        ? 0.0
        : ((amount - average) / average * 100)
              .clamp(0, double.infinity)
              .roundToDouble();

    return AnomalyAlert(
      category: category,
      amount: amount,
      average: average,
      overspent: overspent,
      percentageOver: percentageOver,
      message:
          '$category spending is ${percentageOver.toStringAsFixed(0)}% above your average (${CurrencyUtils.format(average)})',
      suggestion: _generateSuggestion(category, average, amount),
    );
  }

  static String _generateSuggestion(
    String category,
    double average,
    double amount,
  ) {
    final saved = amount - average;
    final suggestions = <String, String>{
      'Groceries':
          'Try buying in bulk or visiting discount stores to reduce spending by ${CurrencyUtils.format(saved)}.',
      'Transport':
          'Consider carpooling or using public transport to save ${CurrencyUtils.format(saved)} next time.',
      'Entertainment':
          'Scale back premium subscriptions or outings. Potential savings: ${CurrencyUtils.format(saved)}.',
      'Electricity':
          'Check for power leaks. Turn off devices when not in use to reduce by ${CurrencyUtils.format(saved)}.',
      'Healthcare':
          'Stock up on generic medicines or visit clinics during off-peak hours.',
      'Others': 'Review this category and identify cost-saving opportunities.',
    };

    return suggestions[category] ??
        'Look for ways to reduce spending in $category by ${CurrencyUtils.format(saved)}.';
  }

  static double _number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
    }
    return fallback;
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}

class AnomalyAlertService {
  /// Detect anomalies from AI analysis results
  static List<AnomalyAlert> processAnomalies(
    List<Map<String, dynamic>> anomalyData,
  ) {
    return anomalyData
        .map((data) => AnomalyAlert.fromAnomalyData(data))
        .toList();
  }

  /// Simple threshold-based anomaly detection (fallback if AI not available)
  static List<AnomalyAlert> detectAnomaliesLocally(
    List<FinancialTransaction> transactions, {
    double threshold = 1.45, // 45% above average
  }) {
    final categorySpending = <String, List<double>>{};
    for (final transaction in transactions.where((t) => t.type == 'expense')) {
      categorySpending
          .putIfAbsent(transaction.category, () => [])
          .add(transaction.amount);
    }

    final anomalies = <AnomalyAlert>[];
    for (final entry in categorySpending.entries) {
      if (entry.value.length < 2) continue;
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (average <= 0) continue;
      final highest = entry.value.reduce((a, b) => a > b ? a : b);
      if (highest >= average * threshold) {
        anomalies.add(
          AnomalyAlert(
            category: entry.key,
            amount: highest,
            average: average,
            overspent: highest - average,
            percentageOver: ((highest - average) / average * 100)
                .roundToDouble(),
            message:
                '${entry.key} spending is ${(((highest - average) / average * 100).roundToDouble()).toStringAsFixed(0)}% above your average',
            suggestion: AnomalyAlert._generateSuggestion(
              entry.key,
              average,
              highest,
            ),
          ),
        );
      }
    }

    anomalies.sort((a, b) => b.overspent.compareTo(a.overspent));
    return anomalies;
  }
}
