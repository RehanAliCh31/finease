// Models used by PredictionService

class BudgetWarning {
  final String category;
  final int daysUntilExceed;
  final double projectedOverspend;
  final double currentSpend;
  final double budget;
  final double projectedTotal;

  const BudgetWarning({
    required this.category,
    required this.daysUntilExceed,
    required this.projectedOverspend,
    required this.currentSpend,
    required this.budget,
    required this.projectedTotal,
  });

  String get message {
    if (daysUntilExceed <= 0) {
      return 'You have already exceeded your $category budget by PKR ${_fmt(projectedOverspend)}.';
    }
    return 'At current rate, you will exceed your $category budget in $daysUntilExceed day${daysUntilExceed == 1 ? '' : 's'}.';
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

class ForecastResult {
  /// Predicted spending per category for next month.
  final Map<String, double> categoryPredictions;

  /// Sum of all predicted category expenses.
  final double totalPredicted;

  /// Predicted savings amount.
  final double predictedSavings;

  /// Predicted savings as a percentage of income (0–100).
  final double savingsPercentage;

  const ForecastResult({
    required this.categoryPredictions,
    required this.totalPredicted,
    required this.predictedSavings,
    required this.savingsPercentage,
  });
}
