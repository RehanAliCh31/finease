// Models used by SpendingAnalyticsService

class SpendingAnomaly {
  final String category;
  final double currentAmount;
  final double averageAmount;
  final double percentageIncrease;
  final String message;

  const SpendingAnomaly({
    required this.category,
    required this.currentAmount,
    required this.averageAmount,
    required this.percentageIncrease,
    required this.message,
  });
}

class RecurringExpense {
  final String name;
  final double estimatedMonthlyAmount;
  final DateTime lastDetectedDate;
  final String category;

  const RecurringExpense({
    required this.name,
    required this.estimatedMonthlyAmount,
    required this.lastDetectedDate,
    required this.category,
  });
}
