import '../models/transaction.dart';

/// Represents an instant tip from the financial coach
class InstantTip {
  final String message;
  final String icon;
  final bool isWarning;
  final DateTime timestamp;

  InstantTip({
    required this.message,
    required this.icon,
    required this.isWarning,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service that provides financial coach tips and instant alerts
class FinancialCoachService {
  /// Generate instant tips based on financial data
  List<InstantTip> getInstantTips({
    required List<FinancialTransaction> transactions,
    required Map<String, double> budgets,
    required double monthlyIncome,
  }) {
    final tips = <InstantTip>[];

    if (transactions.isEmpty) {
      return tips;
    }

    // Analyze spending by category
    final spending = _analyzeSpending(transactions);

    // Check budget overruns
    for (final entry in spending.entries) {
      final category = entry.key;
      final amount = entry.value;
      final budget = budgets[category] ?? 0;

      if (budget > 0 && amount > budget) {
        final overrun = amount - budget;
        tips.add(
          InstantTip(
            message:
                'Your $category spending (₹${amount.toStringAsFixed(0)}) exceeded budget (₹${budget.toStringAsFixed(0)}) by ₹${overrun.toStringAsFixed(0)}',
            icon: '⚠️',
            isWarning: true,
          ),
        );
      }
    }

    // Check if spending is unusually high
    final totalExpenses =
        transactions.where((t) => t.type == 'expense').fold<double>(
              0,
              (sum, t) => sum + t.amount,
            );

    if (monthlyIncome > 0) {
      final spendingRatio = totalExpenses / monthlyIncome;
      if (spendingRatio > 0.85) {
        tips.add(
          InstantTip(
            message:
                'High spending alert: You\'ve used ${(spendingRatio * 100).toStringAsFixed(0)}% of your monthly income',
            icon: '🚨',
            isWarning: true,
          ),
        );
      } else if (spendingRatio < 0.5) {
        tips.add(
          InstantTip(
            message:
                'Great savings! You\'ve only spent ${(spendingRatio * 100).toStringAsFixed(0)}% of your monthly income',
            icon: '✨',
            isWarning: false,
          ),
        );
      }
    }

    // Check for unusual transactions
    final largeTransactions = transactions
        .where((t) => t.type == 'expense' && t.amount > monthlyIncome * 0.2)
        .toList();

    if (largeTransactions.isNotEmpty) {
      final largest = largeTransactions.first;
      tips.add(
        InstantTip(
          message:
              'Large transaction detected: ${largest.title} (₹${largest.amount.toStringAsFixed(0)})',
          icon: '💰',
          isWarning: largest.amount > monthlyIncome * 0.5,
        ),
      );
    }

    // Suggest saving if no savings found
    final savings = transactions
        .where((t) => t.type == 'income' || t.category == 'Savings')
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (savings == 0 && transactions.isNotEmpty) {
      tips.add(
        InstantTip(
          message: 'Consider setting up automatic savings transfers',
          icon: '🏦',
          isWarning: false,
        ),
      );
    }

    return tips;
  }

  /// Analyze spending by category
  Map<String, double> _analyzeSpending(List<FinancialTransaction> transactions) {
    final spending = <String, double>{};

    for (final transaction in transactions.where((t) => t.type == 'expense')) {
      spending[transaction.category] =
          (spending[transaction.category] ?? 0) + transaction.amount;
    }

    return spending;
  }

  /// Get budget summary
  Map<String, dynamic> getBudgetSummary({
    required List<FinancialTransaction> transactions,
    required Map<String, double> budgets,
    required double monthlyIncome,
  }) {
    final totalExpenses =
        transactions.where((t) => t.type == 'expense').fold<double>(
              0,
              (sum, t) => sum + t.amount,
            );
    final totalBudget = budgets.values.fold<double>(0, (sum, b) => sum + b);

    return {
      'totalExpenses': totalExpenses,
      'totalBudget': totalBudget,
      'remaining': totalBudget - totalExpenses,
      'percentageUsed': totalBudget > 0 ? (totalExpenses / totalBudget * 100) : 0,
      'monthlyIncome': monthlyIncome,
      'netSavings': monthlyIncome - totalExpenses,
      'savingsRate':
          monthlyIncome > 0 ? ((monthlyIncome - totalExpenses) / monthlyIncome * 100) : 0,
    };
  }

  /// Get personalized recommendations
  List<String> getRecommendations({
    required List<FinancialTransaction> transactions,
    required Map<String, double> budgets,
    required double monthlyIncome,
  }) {
    final recommendations = <String>[];
    final spending = _analyzeSpending(transactions);
    final summary = getBudgetSummary(
      transactions: transactions,
      budgets: budgets,
      monthlyIncome: monthlyIncome,
    );

    // Check savings rate
    if (summary['savingsRate'] < 10) {
      recommendations.add('Try to increase your savings rate to at least 10% of income');
    }

    // Check for overspending categories
    for (final entry in spending.entries) {
      final category = entry.key;
      final amount = entry.value;
      final budget = budgets[category] ?? 0;

      if (budget > 0 && amount > budget * 1.2) {
        recommendations.add('Reduce $category spending to stay within budget');
      }
    }

    // Emergency fund check
    if (summary['netSavings'] > 0) {
      recommendations.add('Build an emergency fund with 3-6 months of expenses');
    }

    return recommendations;
  }
}
