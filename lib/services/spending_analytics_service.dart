import '../models/transaction.dart';
import '../models/spending_analytics.dart';

class SpendingAnalyticsService {
  // ─────────────────────────────────────────────
  // 1. WEEKLY TRENDS
  // ─────────────────────────────────────────────

  /// Returns a map of {weekLabel → totalExpense} for the last [weeksBack] weeks.
  /// Week labels are formatted as "Week of MMM d" (e.g. "Week of Apr 28").
  Map<String, double> getWeeklyTrends(
    List<FinancialTransaction> transactions, {
    int weeksBack = 8,
  }) {
    final now = DateTime.now();
    // Start of current week (Monday)
    final startOfCurrentWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
        startOfCurrentWeek.year, startOfCurrentWeek.month, startOfCurrentWeek.day);

    final Map<String, double> result = {};

    for (int i = weeksBack - 1; i >= 0; i--) {
      final wStart = weekStart.subtract(Duration(days: i * 7));
      final wEnd = wStart.add(const Duration(days: 7));

      final label =
          'Week of ${_monthAbbr(wStart.month)} ${wStart.day}';

      final total = transactions
          .where((t) =>
              t.type == 'expense' &&
              !t.date.isBefore(wStart) &&
              t.date.isBefore(wEnd))
          .fold<double>(0.0, (sum, t) => sum + t.amount);

      result[label] = total;
    }
    return result;
  }

  // ─────────────────────────────────────────────
  // 2. MONTHLY CATEGORY BREAKDOWN
  // ─────────────────────────────────────────────

  /// Returns {category → totalExpense} for the given month/year.
  Map<String, double> getMonthlyCategoryBreakdown(
    List<FinancialTransaction> transactions, {
    required int month,
    required int year,
  }) {
    final filtered = transactions.where((t) =>
        t.type == 'expense' &&
        t.date.month == month &&
        t.date.year == year);

    final Map<String, double> breakdown = {};
    for (final t in filtered) {
      breakdown[t.category] =
          (breakdown[t.category] ?? 0.0) + t.amount;
    }
    return breakdown;
  }

  // ─────────────────────────────────────────────
  // 3. ANOMALY DETECTION
  // ─────────────────────────────────────────────

  /// Compares current week spending per category vs the 4-week rolling average.
  /// Flags categories where current spending exceeds the average by > 30%.
  List<SpendingAnomaly> detectAnomalies(
      List<FinancialTransaction> transactions) {
    final now = DateTime.now();
    final startOfCurrentWeek =
        now.subtract(Duration(days: now.weekday - 1));
    final currentWeekStart = DateTime(startOfCurrentWeek.year,
        startOfCurrentWeek.month, startOfCurrentWeek.day);
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));

    // Current week per-category totals
    final Map<String, double> currentWeek = {};
    for (final t in transactions.where((t) =>
        t.type == 'expense' &&
        !t.date.isBefore(currentWeekStart) &&
        t.date.isBefore(currentWeekEnd))) {
      currentWeek[t.category] =
          (currentWeek[t.category] ?? 0.0) + t.amount;
    }

    // 4-week average per-category totals (weeks 1-4 before current)
    final Map<String, List<double>> previousWeeklyTotals = {};
    for (int i = 1; i <= 4; i++) {
      final wStart =
          currentWeekStart.subtract(Duration(days: i * 7));
      final wEnd = wStart.add(const Duration(days: 7));

      final Map<String, double> weekMap = {};
      for (final t in transactions.where((t) =>
          t.type == 'expense' &&
          !t.date.isBefore(wStart) &&
          t.date.isBefore(wEnd))) {
        weekMap[t.category] =
            (weekMap[t.category] ?? 0.0) + t.amount;
      }
      for (final entry in weekMap.entries) {
        previousWeeklyTotals
            .putIfAbsent(entry.key, () => [])
            .add(entry.value);
      }
    }

    final Map<String, double> fourWeekAvg = {};
    for (final entry in previousWeeklyTotals.entries) {
      fourWeekAvg[entry.key] =
          entry.value.fold(0.0, (a, b) => a + b) / 4;
    }

    final List<SpendingAnomaly> anomalies = [];

    for (final entry in currentWeek.entries) {
      final category = entry.key;
      final current = entry.value;
      final avg = fourWeekAvg[category] ?? 0.0;

      if (avg == 0) continue; // no baseline — skip

      final pct = ((current - avg) / avg) * 100;
      if (pct > 30) {
        anomalies.add(SpendingAnomaly(
          category: category,
          currentAmount: current,
          averageAmount: avg,
          percentageIncrease: pct,
          message:
              'You spent ${pct.toStringAsFixed(0)}% more on $category '
              'this week (PKR ${_fmt(current)} vs avg PKR ${_fmt(avg)})',
        ));
      }
    }

    // Sort by highest overshoot first
    anomalies.sort(
        (a, b) => b.percentageIncrease.compareTo(a.percentageIncrease));
    return anomalies;
  }

  // ─────────────────────────────────────────────
  // 4. RECURRING EXPENSE DETECTION
  // ─────────────────────────────────────────────

  /// Detects expenses with similar descriptions that appear across at least 2
  /// different calendar months — treating them as recurring subscriptions/bills.
  List<RecurringExpense> detectRecurringExpenses(
      List<FinancialTransaction> transactions) {
    final expenses =
        transactions.where((t) => t.type == 'expense').toList();

    // Group by normalised description key
    final Map<String, List<FinancialTransaction>> grouped = {};
    for (final t in expenses) {
      final key = _normalise(t.title);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final List<RecurringExpense> recurring = [];

    for (final entry in grouped.entries) {
      final txns = entry.value;

      // Collect distinct year-month occurrences
      final months = txns
          .map((t) => '${t.date.year}-${t.date.month}')
          .toSet();

      if (months.length < 2) continue; // must span ≥ 2 months

      // Estimated monthly amount: average of per-month totals
      final Map<String, double> monthlyTotals = {};
      for (final t in txns) {
        final mk = '${t.date.year}-${t.date.month}';
        monthlyTotals[mk] = (monthlyTotals[mk] ?? 0.0) + t.amount;
      }
      final estimated =
          monthlyTotals.values.fold(0.0, (a, b) => a + b) /
              monthlyTotals.length;

      final latest =
          txns.map((t) => t.date).reduce((a, b) => a.isAfter(b) ? a : b);

      recurring.add(RecurringExpense(
        name: _titleCase(txns.first.title),
        estimatedMonthlyAmount: estimated,
        lastDetectedDate: latest,
        category: txns.first.category,
      ));
    }

    recurring.sort((a, b) =>
        b.estimatedMonthlyAmount.compareTo(a.estimatedMonthlyAmount));
    return recurring;
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  /// Strips punctuation, lowercases, and trims to build a match key.
  String _normalise(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  String _titleCase(String s) => s
      .split(' ')
      .map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  String _monthAbbr(int month) {
    const abbrs = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return abbrs[month - 1];
  }

  /// Format a number with comma-separated thousands.
  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final result = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(s[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }
}
