import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/budget_plan.dart';
import '../../models/saving_goal.dart';
import '../../models/spending_analytics.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/spending_analytics_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;

    if (firestoreService == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundFor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final monthKey = _monthKey(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        child: StreamBuilder<List<FinancialTransaction>>(
          stream: firestoreService.getTransactions(),
          builder: (context, transactionSnapshot) {
            return StreamBuilder<List<BudgetPlan>>(
              stream: firestoreService.getBudgetPlans(monthKey: monthKey),
              builder: (context, budgetSnapshot) {
                return StreamBuilder<List<SavingGoal>>(
                  stream: firestoreService.getSavingGoals(),
                  builder: (context, goalSnapshot) {
                    return StreamBuilder<Map<String, dynamic>>(
                      stream: firestoreService.getUserProfile(),
                      builder: (context, profileSnapshot) {
                        final isLoading =
                            transactionSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !transactionSnapshot.hasData;
                        if (isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final transactions =
                            transactionSnapshot.data ??
                            const <FinancialTransaction>[];
                        final budgets =
                            budgetSnapshot.data ?? const <BudgetPlan>[];
                        final goals = goalSnapshot.data ?? const <SavingGoal>[];
                        final profile =
                            profileSnapshot.data ?? const <String, dynamic>{};
                        final insight = _AnalysisInsight.from(
                          transactions: transactions,
                          budgets: budgets,
                          goals: goals,
                          profile: profile,
                        );

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                          children: [
                            _AnalysisHeader(
                              onBack: () => Navigator.maybePop(context),
                            ),
                            const SizedBox(height: 16),
                            if (!insight.hasAnyData)
                              const _EmptyAnalysisState()
                            else ...[
                              _DecisionCard(insight: insight),
                              const SizedBox(height: 12),
                              _ActionPlanCard(insight: insight),
                              const SizedBox(height: 14),
                              _SummaryGrid(insight: insight),
                              const SizedBox(height: 22),
                              _SectionTitle(
                                title: 'Budget safety',
                                trailing: insight.budgetStatusLabel,
                              ),
                              const SizedBox(height: 12),
                              _BudgetVsActualCard(insight: insight),
                              const SizedBox(height: 22),
                              _SectionTitle(
                                title: 'Savings pressure',
                                trailing: '${insight.activeGoals} active',
                              ),
                              const SizedBox(height: 12),
                              _SavingsPressureCard(insight: insight),
                              const SizedBox(height: 22),
                              _SectionTitle(
                                title: 'Top spending',
                                trailing: DateFormat(
                                  'MMM yyyy',
                                ).format(DateTime.now()),
                              ),
                              const SizedBox(height: 12),
                              _TopCategoriesCard(insight: insight),
                              const SizedBox(height: 22),
                              _SectionTitle(
                                title: 'Needs attention',
                                trailing: insight.alertCount == 0
                                    ? 'Clear'
                                    : '${insight.alertCount} items',
                              ),
                              const SizedBox(height: 12),
                              _AttentionList(insight: insight),
                              const SizedBox(height: 22),
                              _SectionTitle(
                                title: 'Weekly trend',
                                trailing:
                                    '${insight.weeklyTotals.length} weeks',
                              ),
                              const SizedBox(height: 12),
                              _WeeklyTrendCard(insight: insight),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AnalysisInsight {
  const _AnalysisInsight({
    required this.currentIncome,
    required this.currentExpense,
    required this.previousExpense,
    required this.totalBudget,
    required this.savingsBalance,
    required this.savingsTarget,
    required this.savingsCurrent,
    required this.savingsMonthlyNeed,
    required this.activeGoals,
    required this.categorySpending,
    required this.categoryBudgets,
    required this.weeklyTotals,
    required this.anomalies,
    required this.recurring,
  });

  final double currentIncome;
  final double currentExpense;
  final double previousExpense;
  final double totalBudget;
  final double savingsBalance;
  final double savingsTarget;
  final double savingsCurrent;
  final double savingsMonthlyNeed;
  final int activeGoals;
  final Map<String, double> categorySpending;
  final Map<String, double> categoryBudgets;
  final Map<String, double> weeklyTotals;
  final List<SpendingAnomaly> anomalies;
  final List<RecurringExpense> recurring;

  factory _AnalysisInsight.from({
    required List<FinancialTransaction> transactions,
    required List<BudgetPlan> budgets,
    required List<SavingGoal> goals,
    required Map<String, dynamic> profile,
  }) {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    final service = SpendingAnalyticsService();
    final currentMonth = transactions.where(
      (txn) => txn.date.year == now.year && txn.date.month == now.month,
    );
    final previousMonth = transactions.where(
      (txn) =>
          txn.date.year == previous.year && txn.date.month == previous.month,
    );
    final categorySpending = <String, double>{};
    for (final txn in currentMonth.where((txn) => txn.type == 'expense')) {
      categorySpending[txn.category] =
          (categorySpending[txn.category] ?? 0) + txn.amount;
    }
    final categoryBudgets = <String, double>{};
    for (final budget in budgets) {
      categoryBudgets[budget.category] =
          (categoryBudgets[budget.category] ?? 0) + budget.allocatedAmount;
    }
    final activeGoals = goals.where((goal) => goal.remaining > 0).toList();

    return _AnalysisInsight(
      currentIncome: currentMonth
          .where((txn) => txn.type == 'income')
          .fold(0, (total, txn) => total + txn.amount),
      currentExpense: currentMonth
          .where((txn) => txn.type == 'expense')
          .fold(0, (total, txn) => total + txn.amount),
      previousExpense: previousMonth
          .where((txn) => txn.type == 'expense')
          .fold(0, (total, txn) => total + txn.amount),
      totalBudget: budgets.fold(
        0,
        (total, budget) => total + budget.allocatedAmount,
      ),
      savingsBalance:
          ((profile['savingsBalance'] ?? 0) as num).toDouble() +
          ((profile['extraSavingsBalance'] ?? 0) as num).toDouble(),
      savingsTarget: activeGoals.fold(
        0,
        (total, goal) => total + goal.targetAmount,
      ),
      savingsCurrent: activeGoals.fold(
        0,
        (total, goal) => total + goal.currentAmount,
      ),
      savingsMonthlyNeed: activeGoals.fold(
        0,
        (total, goal) => total + goal.monthlyTarget,
      ),
      activeGoals: activeGoals.length,
      categorySpending: categorySpending,
      categoryBudgets: categoryBudgets,
      weeklyTotals: service.getWeeklyTrends(transactions, weeksBack: 5),
      anomalies: service.detectAnomalies(transactions),
      recurring: service.detectRecurringExpenses(transactions),
    );
  }

  double get net => currentIncome - currentExpense;
  double get budgetRemaining => totalBudget - currentExpense;
  double get budgetUsage =>
      totalBudget <= 0 ? 0 : (currentExpense / totalBudget).clamp(0.0, 2.0);
  double get savingsProgress =>
      savingsTarget <= 0 ? 0 : (savingsCurrent / savingsTarget).clamp(0.0, 1.0);
  double get availableAfterSavings => net - savingsMonthlyNeed;
  double get savingsRate =>
      currentIncome <= 0 ? 0 : (net / currentIncome).clamp(-1.0, 1.0);
  double get expenseChange => currentExpense - previousExpense;
  int get alertCount =>
      anomalies.length + recurring.length + overBudgetCategories.length;
  bool get hasAnyData =>
      currentIncome > 0 ||
      currentExpense > 0 ||
      totalBudget > 0 ||
      activeGoals > 0 ||
      savingsBalance > 0;
  bool get isHealthy =>
      net >= 0 &&
      budgetUsage <= 0.9 &&
      availableAfterSavings >= 0 &&
      anomalies.isEmpty;
  String get budgetStatusLabel {
    if (totalBudget <= 0) return 'No budget';
    if (budgetRemaining < 0) return 'Over';
    if (budgetUsage >= 0.85) return 'Tight';
    return 'Safe';
  }

  List<MapEntry<String, double>> get topCategories {
    final entries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  List<_BudgetCategoryStatus> get budgetCategoryStatuses {
    final categories = {...categoryBudgets.keys, ...categorySpending.keys};
    final statuses = categories.map((category) {
      final budget = categoryBudgets[category] ?? 0;
      final spent = categorySpending[category] ?? 0;
      return _BudgetCategoryStatus(
        category: category,
        budget: budget,
        spent: spent,
      );
    }).toList()..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return statuses;
  }

  List<_BudgetCategoryStatus> get overBudgetCategories =>
      budgetCategoryStatuses.where((item) => item.isOverBudget).toList();

  List<String> get priorityActions {
    final actions = <String>[];
    if (net < 0) {
      actions.add(
        'Stop new discretionary spending until income covers this month.',
      );
    }
    if (overBudgetCategories.isNotEmpty) {
      final item = overBudgetCategories.first;
      actions.add(
        'Reduce ${item.category} by ${CurrencyUtils.format(item.overAmount)} to return to budget.',
      );
    }
    if (savingsMonthlyNeed > 0 && availableAfterSavings < 0) {
      actions.add(
        'Lower goal pressure by ${CurrencyUtils.format(availableAfterSavings.abs())} this month.',
      );
    }
    if (anomalies.isNotEmpty) {
      actions.add('Review the ${anomalies.first.category} spike this week.');
    }
    if (actions.isEmpty) {
      actions.add('Keep logging transactions; your plan is currently steady.');
      if (budgetRemaining > 0) {
        actions.add(
          'Move up to ${CurrencyUtils.format(budgetRemaining)} into savings if the month closes cleanly.',
        );
      }
    }
    return actions.take(3).toList();
  }

  String get headline {
    if (currentIncome <= 0 && currentExpense <= 0) {
      if (totalBudget > 0 || activeGoals > 0) {
        return 'Plan is ready; transactions will unlock live insight.';
      }
      return 'Add this month\'s transactions first.';
    }
    if (net < 0) {
      return 'Spending is above income this month.';
    }
    if (budgetRemaining < 0) {
      return 'Budget is over plan even though cash flow is positive.';
    }
    if (savingsMonthlyNeed > 0 && availableAfterSavings < 0) {
      return 'Savings goals need more room this month.';
    }
    if (anomalies.isNotEmpty) {
      return '${anomalies.first.category} needs a quick check.';
    }
    if (savingsRate >= 0.2) {
      return 'This month is in good shape.';
    }
    return 'Cash flow is positive, but savings are thin.';
  }

  String get action {
    if (net < 0) {
      return 'Cut or delay one non-essential expense before adding new commitments.';
    }
    if (budgetRemaining < 0) {
      return 'Fix the highest over-budget category before moving money to goals.';
    }
    if (savingsMonthlyNeed > 0 && availableAfterSavings < 0) {
      return 'Reduce spending or adjust goal timing so savings targets stay realistic.';
    }
    if (anomalies.isNotEmpty) {
      return 'Review the flagged category and set a smaller weekly limit.';
    }
    if (topCategories.isNotEmpty) {
      return 'Watch ${topCategories.first.key}; it is your biggest category this month.';
    }
    return 'Keep recording transactions so patterns become useful.';
  }
}

class _BudgetCategoryStatus {
  const _BudgetCategoryStatus({
    required this.category,
    required this.budget,
    required this.spent,
  });

  final String category;
  final double budget;
  final double spent;

  double get remaining => budget - spent;
  double get overAmount => (spent - budget).clamp(0, double.infinity);
  double get usage => budget <= 0 ? (spent > 0 ? 2 : 0) : spent / budget;
  double get riskScore => budget <= 0 && spent > 0 ? 3 : usage;
  bool get isOverBudget => budget > 0 && spent > budget;
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Simple signals from your money flow',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = insight.net < 0
        ? AppTheme.error
        : insight.anomalies.isNotEmpty
        ? AppTheme.warning
        : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            label: insight.isHealthy ? 'Healthy' : 'Check',
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            insight.headline,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.action,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPlanCard extends StatelessWidget {
  const _ActionPlanCard({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    return _PlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What to do next',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...insight.priorityActions.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == insight.priorityActions.length - 1
                    ? 0
                    : 10,
              ),
              child: _ActionRow(number: entry.key + 1, text: entry.value),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _MetricTile(
          label: 'Income',
          value: CurrencyUtils.format(insight.currentIncome),
          icon: Icons.south_west_rounded,
          color: AppTheme.success,
        ),
        _MetricTile(
          label: 'Expense',
          value: CurrencyUtils.format(insight.currentExpense),
          icon: Icons.north_east_rounded,
          color: AppTheme.error,
        ),
        _MetricTile(
          label: 'Net cash',
          value: CurrencyUtils.format(insight.net),
          icon: insight.net >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: insight.net >= 0
              ? AppTheme.primaryFor(context)
              : AppTheme.error,
        ),
        _MetricTile(
          label: 'Budget left',
          value: CurrencyUtils.format(insight.budgetRemaining),
          icon: Icons.savings_rounded,
          color: insight.budgetRemaining >= 0
              ? AppTheme.warning
              : AppTheme.error,
        ),
      ],
    );
  }
}

class _BudgetVsActualCard extends StatelessWidget {
  const _BudgetVsActualCard({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    if (insight.totalBudget <= 0) {
      return const _PlainCard(
        child: Text(
          'Create a monthly budget to compare planned vs actual spending.',
        ),
      );
    }

    final statuses = insight.budgetCategoryStatuses.take(4).toList();
    return _PlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactStat(
                  label: 'Planned',
                  value: CurrencyUtils.format(insight.totalBudget),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactStat(
                  label: 'Used',
                  value: '${(insight.budgetUsage * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: insight.budgetUsage.clamp(0.0, 1.0),
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                insight.budgetRemaining < 0
                    ? AppTheme.error
                    : insight.budgetUsage >= 0.85
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
            ),
          ),
          if (statuses.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...statuses.map((item) => _BudgetStatusRow(status: item)),
          ],
        ],
      ),
    );
  }
}

class _SavingsPressureCard extends StatelessWidget {
  const _SavingsPressureCard({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    if (insight.activeGoals == 0) {
      return const _PlainCard(
        child: Text(
          'Create a savings goal to see how much monthly pressure it adds.',
        ),
      );
    }

    final isTight = insight.availableAfterSavings < 0;
    return _PlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactStat(
                  label: 'Goal progress',
                  value:
                      '${(insight.savingsProgress * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactStat(
                  label: 'Monthly need',
                  value: CurrencyUtils.format(insight.savingsMonthlyNeed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: insight.savingsProgress,
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                isTight ? AppTheme.warning : AppTheme.success,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isTight
                ? '${CurrencyUtils.format(insight.availableAfterSavings.abs())} more is needed to fund current goals after spending.'
                : '${CurrencyUtils.format(insight.availableAfterSavings)} remains after this month\'s goal pace.',
            style: GoogleFonts.inter(
              color: isTight
                  ? AppTheme.warning
                  : AppTheme.textSecondaryFor(context),
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    if (insight.topCategories.isEmpty) {
      return const _PlainCard(
        child: Text('No expense categories recorded this month.'),
      );
    }

    final maxValue = insight.topCategories.first.value;
    return _PlainCard(
      child: Column(
        children: insight.topCategories.map((entry) {
          return _CategoryBar(
            label: entry.key,
            amount: entry.value,
            percent: maxValue <= 0 ? 0 : entry.value / maxValue,
          );
        }).toList(),
      ),
    );
  }
}

class _WeeklyTrendCard extends StatelessWidget {
  const _WeeklyTrendCard({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    final maxValue = insight.weeklyTotals.values.fold<double>(
      0,
      (max, value) => math.max(max, value),
    );

    return _PlainCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: insight.weeklyTotals.entries.map((entry) {
          final height = maxValue <= 0
              ? 16.0
              : 16 + (86 * entry.value / maxValue);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFor(context),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key.replaceFirst('Week of ', ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({required this.insight});

  final _AnalysisInsight insight;

  @override
  Widget build(BuildContext context) {
    if (insight.anomalies.isEmpty && insight.recurring.isEmpty) {
      return const _PlainCard(
        child: Text('No unusual spikes or recurring expenses detected yet.'),
      );
    }

    return Column(
      children: [
        ...insight.overBudgetCategories
            .take(2)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AttentionTile(
                  icon: Icons.account_balance_wallet_rounded,
                  title: '${item.category} is over budget',
                  subtitle:
                      'Reduce by ${CurrencyUtils.format(item.overAmount)} or adjust the plan.',
                  color: AppTheme.error,
                ),
              ),
            ),
        ...insight.anomalies
            .take(3)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AttentionTile(
                  icon: Icons.warning_amber_rounded,
                  title: item.category,
                  subtitle: item.message,
                  color: AppTheme.warning,
                ),
              ),
            ),
        ...insight.recurring
            .take(3)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AttentionTile(
                  icon: Icons.repeat_rounded,
                  title: item.name,
                  subtitle:
                      '${CurrencyUtils.format(item.estimatedMonthlyAmount)} monthly estimate',
                  color: AppTheme.primaryFor(context),
                ),
              ),
            ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryFor(context).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$number',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.primaryFor(context),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetStatusRow extends StatelessWidget {
  const _BudgetStatusRow({required this.status});

  final _BudgetCategoryStatus status;

  @override
  Widget build(BuildContext context) {
    final isOver = status.isOverBudget;
    final color = isOver
        ? AppTheme.error
        : status.usage >= 0.85
        ? AppTheme.warning
        : AppTheme.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status.budget <= 0
                      ? 'No budget set'
                      : '${CurrencyUtils.format(status.spent)} of ${CurrencyUtils.format(status.budget)}',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(
            label: isOver
                ? 'Over'
                : status.usage >= 0.85
                ? 'Tight'
                : 'Safe',
            color: color,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.amount,
    required this.percent,
  });

  final String label;
  final double amount;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                CurrencyUtils.format(amount),
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: percent.clamp(0.0, 1.0),
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _PlainCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: child,
    );
  }
}

class _EmptyAnalysisState extends StatelessWidget {
  const _EmptyAnalysisState();

  @override
  Widget build(BuildContext context) {
    return _PlainCard(
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.mutedFillFor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.query_stats_rounded,
              color: AppTheme.primaryFor(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No analysis yet',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add income and expense transactions to see useful patterns.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
