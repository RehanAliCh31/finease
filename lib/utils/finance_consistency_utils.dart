class FinanceConsistencyUtils {
  const FinanceConsistencyUtils._();

  static double scaledMonthlyIncome(double monthlyIncome, String periodType) {
    switch (periodType) {
      case 'daily':
        return monthlyIncome / 30;
      case 'weekly':
        return monthlyIncome / 4.345;
      case 'yearly':
        return monthlyIncome * 12;
      case 'monthly':
      default:
        return monthlyIncome;
    }
  }

  static double resolvePeriodIncome({
    required double profileMonthlyIncome,
    required double transactionIncome,
    required String periodType,
  }) {
    if (transactionIncome > 0) return transactionIncome;
    return scaledMonthlyIncome(profileMonthlyIncome, periodType);
  }

  static double resolveMonthlyIncome({
    required double profileMonthlyIncome,
    required double transactionIncome,
    double summaryIncome = 0,
  }) {
    if (summaryIncome > 0) return summaryIncome;
    if (transactionIncome > 0) return transactionIncome;
    return profileMonthlyIncome;
  }
}
