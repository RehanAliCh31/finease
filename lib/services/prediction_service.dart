import '../models/transaction.dart';
import '../models/prediction_models.dart';

/// Mathematical forecasting service for FinEase predictive spending features.
class PredictionService {
  // ─────────────────────────────────────────────────────────────────────────
  // 1. PREDICT NEXT MONTH EXPENSES
  //    Weighted moving average: 50% most recent, 30% second, 20% third month.
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns a [ForecastResult] containing predicted per-category spending
  /// and total for the upcoming month based on the last 3 months of data.
  ///
  /// Weights: month-1 = 50%, month-2 = 30%, month-3 = 20%
  ForecastResult predictNextMonthExpenses(
      List<FinancialTransaction> last3Months) {
    final now = DateTime.now();

    // Build per-month category totals for months -1, -2, -3
    final weights = [0.50, 0.30, 0.20];
    final monthOffsets = [1, 2, 3]; // 1 = last month, 2 = two months ago, etc.

    final Map<String, double> weighted = {};

    for (int i = 0; i < 3; i++) {
      final targetMonth = _monthOffset(now, -monthOffsets[i]);
      final monthTotals = _categoryTotalsForMonth(
        last3Months,
        targetMonth.year,
        targetMonth.month,
      );

      for (final entry in monthTotals.entries) {
        weighted[entry.key] =
            (weighted[entry.key] ?? 0.0) + entry.value * weights[i];
      }
    }

    final totalPredicted =
        weighted.values.fold(0.0, (sum, v) => sum + v);

    return ForecastResult(
      categoryPredictions: weighted,
      totalPredicted: totalPredicted,
      predictedSavings: 0, // filled in by forecastSavings
      savingsPercentage: 0,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. FORECAST SAVINGS
  // ─────────────────────────────────────────────────────────────────────────

  /// Given a monthly income and predicted expense map, returns predicted
  /// savings amount and savings-rate percentage.
  ForecastResult forecastSavings(
    double monthlyIncome,
    Map<String, double> predictedExpenses,
  ) {
    final totalExpenses =
        predictedExpenses.values.fold(0.0, (sum, v) => sum + v);
    final predictedSavings = monthlyIncome - totalExpenses;
    final savingsPercentage =
        monthlyIncome > 0 ? (predictedSavings / monthlyIncome) * 100 : 0.0;

    return ForecastResult(
      categoryPredictions: predictedExpenses,
      totalPredicted: totalExpenses,
      predictedSavings: predictedSavings,
      savingsPercentage: savingsPercentage.clamp(-100.0, 100.0),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. BUDGET WARNINGS — daily burn rate → project to month end
  // ─────────────────────────────────────────────────────────────────────────

  /// Analyses current-month transactions against budget limits.
  /// For each category, calculates a daily burn rate, projects to month-end
  /// and warns if spend will exceed the budget.
  ///
  /// Returns a list of [BudgetWarning] sorted by most urgent first.
  List<BudgetWarning> getBudgetWarnings(
    List<FinancialTransaction> currentMonthTransactions,
    Map<String, double> budgets,
  ) {
    final now = DateTime.now();
    final daysInMonth = _daysInMonth(now.year, now.month);
    final daysPassed = now.day; // number of days elapsed (incl. today)
    final daysRemaining = daysInMonth - daysPassed;

    // Sum current-month spending per category
    final Map<String, double> spentSoFar = {};
    for (final t in currentMonthTransactions) {
      if (t.type != 'expense') continue;
      spentSoFar[t.category] =
          (spentSoFar[t.category] ?? 0.0) + t.amount;
    }

    final List<BudgetWarning> warnings = [];

    for (final entry in budgets.entries) {
      final category = entry.key;
      final budget = entry.value;
      final spent = spentSoFar[category] ?? 0.0;

      if (budget <= 0) continue;

      // Daily burn rate based on days elapsed (avoid div-by-zero on day 0)
      final safeDaysPassed = daysPassed > 0 ? daysPassed : 1;
      final dailyBurnRate = spent / safeDaysPassed;

      // Project total spend to end of month
      final projectedTotal = spent + dailyBurnRate * daysRemaining;

      if (projectedTotal > budget) {
        final overspend = projectedTotal - budget;

        // Days until budget is hit: (budget - spent) / dailyBurnRate
        int daysUntilExceed;
        if (dailyBurnRate <= 0) {
          daysUntilExceed = daysRemaining; // no burn, never exceeds
        } else if (spent >= budget) {
          daysUntilExceed = 0; // already exceeded
        } else {
          daysUntilExceed =
              ((budget - spent) / dailyBurnRate).floor();
        }

        warnings.add(BudgetWarning(
          category: category,
          daysUntilExceed: daysUntilExceed,
          projectedOverspend: overspend,
          currentSpend: spent,
          budget: budget,
          projectedTotal: projectedTotal,
        ));
      }
    }

    // Sort: already exceeded first (daysUntilExceed == 0), then by soonest
    warnings.sort((a, b) => a.daysUntilExceed.compareTo(b.daysUntilExceed));
    return warnings;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Monthly totals per category
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns {category → total expense} for the given year/month.
  Map<String, double> _categoryTotalsForMonth(
    List<FinancialTransaction> txns,
    int year,
    int month,
  ) {
    final Map<String, double> totals = {};
    for (final t in txns) {
      if (t.type != 'expense') continue;
      if (t.date.year != year || t.date.month != month) continue;
      totals[t.category] = (totals[t.category] ?? 0.0) + t.amount;
    }
    return totals;
  }

  /// Returns the monthly totals map for a specific month+year (public).
  Map<String, double> getCategoryTotalsForMonth(
    List<FinancialTransaction> txns,
    int year,
    int month,
  ) =>
      _categoryTotalsForMonth(txns, year, month);

  /// Returns the total expense for a given month/year.
  double getTotalForMonth(
    List<FinancialTransaction> txns,
    int year,
    int month,
  ) =>
      _categoryTotalsForMonth(txns, year, month)
          .values
          .fold(0.0, (s, v) => s + v);

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────────────────────

  /// Offsets [base] by [months] calendar months.
  DateTime _monthOffset(DateTime base, int months) {
    int m = base.month + months;
    int y = base.year;
    while (m <= 0) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    final maxDay = _daysInMonth(y, m);
    return DateTime(y, m, base.day.clamp(1, maxDay));
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Format number with thousand separators.
  static String fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}
