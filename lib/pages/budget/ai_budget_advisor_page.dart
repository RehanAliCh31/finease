import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_constants.dart';
import '../../models/budget_plan.dart';
import '../../models/saving_goal.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/finance_consistency_utils.dart';

enum _PeriodMode { monthly, weekly, daily, yearly }

class AIBudgetAdvisorPage extends StatefulWidget {
  const AIBudgetAdvisorPage({super.key});

  @override
  State<AIBudgetAdvisorPage> createState() => _AIBudgetAdvisorPageState();
}

class _AIBudgetAdvisorPageState extends State<AIBudgetAdvisorPage> {
  _PeriodMode _periodMode = _PeriodMode.monthly;
  DateTime _anchorDate = DateTime.now();
  final Set<String> _carryForwardChecks = {};

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;

    if (firestoreService == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final period = _BudgetPeriod.from(_periodMode, _anchorDate);
    _scheduleCarryForward(context, firestoreService, period);

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        child: StreamBuilder<List<FinancialTransaction>>(
          stream: firestoreService.getTransactions(),
          builder: (context, transactionSnapshot) {
            final transactions =
                transactionSnapshot.data ?? const <FinancialTransaction>[];
            final periodTransactions = transactions
                .where((transaction) => period.contains(transaction.date))
                .toList();

            return StreamBuilder<Map<String, dynamic>>(
              stream: firestoreService.getUserProfile(),
              builder: (context, profileSnapshot) {
                final profile = profileSnapshot.data ?? const {};

                return StreamBuilder<List<BudgetPlan>>(
                  stream: firestoreService.getBudgetPlans(monthKey: period.key),
                  builder: (context, budgetSnapshot) {
                    final budgets = budgetSnapshot.data ?? const <BudgetPlan>[];

                    return StreamBuilder<List<SavingGoal>>(
                      stream: firestoreService.getSavingGoals(),
                      builder: (context, goalSnapshot) {
                        final goals = goalSnapshot.data ?? const <SavingGoal>[];
                        final analytics = _BudgetAnalytics.from(
                          budgets: budgets,
                          periodTransactions: periodTransactions,
                          allTransactions: transactions,
                          goals: goals,
                          profile: profile,
                          period: period,
                        );

                        if (budgetSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !budgetSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                          children: [
                            _BudgetHeader(
                              period: period,
                              mode: _periodMode,
                              onPrevious: () => setState(
                                () =>
                                    _anchorDate = period.shift(_periodMode, -1),
                              ),
                              onNext: () => setState(
                                () =>
                                    _anchorDate = period.shift(_periodMode, 1),
                              ),
                              onModeChanged: (mode) => setState(() {
                                _periodMode = mode;
                                _anchorDate = DateTime.now();
                              }),
                            ),
                            const SizedBox(height: 16),
                            _BudgetStatusCard(
                              analytics: analytics,
                              onEdit: () => _showBudgetEditor(
                                context,
                                firestoreService,
                                analytics: analytics,
                                budgets: budgets,
                              ),
                              onAutoBudget: () => _showAutoBudgetPreview(
                                context,
                                firestoreService,
                                analytics: analytics,
                                budgets: budgets,
                              ),
                              onUseSavings: analytics.isOverBudget
                                  ? () => _confirmSavingsPull(
                                      context,
                                      firestoreService,
                                      analytics,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _BudgetSnapshotRow(analytics: analytics),
                            if (analytics.warning != null) ...[
                              const SizedBox(height: 12),
                              _NoticeBanner(message: analytics.warning!),
                            ],
                            const SizedBox(height: 16),
                            _BudgetActions(
                              onEdit: () => _showBudgetEditor(
                                context,
                                firestoreService,
                                analytics: analytics,
                                budgets: budgets,
                              ),
                              onAutoBudget: () => _showAutoBudgetPreview(
                                context,
                                firestoreService,
                                analytics: analytics,
                                budgets: budgets,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _SectionTitle(
                              title: 'Categories',
                              trailing: '${budgets.length} planned',
                            ),
                            const SizedBox(height: 12),
                            if (budgets.isEmpty)
                              _EmptyBudgetState(
                                onCreate: () => _showBudgetEditor(
                                  context,
                                  firestoreService,
                                  analytics: analytics,
                                  budgets: budgets,
                                ),
                                onAutoBudget: () => _showAutoBudgetPreview(
                                  context,
                                  firestoreService,
                                  analytics: analytics,
                                  budgets: budgets,
                                ),
                              )
                            else
                              ..._sortBudgets(budgets, analytics).map(
                                (budget) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _BudgetCategoryCard(
                                    budget: budget,
                                    analytics: analytics,
                                    onEdit: () => _showBudgetEditor(
                                      context,
                                      firestoreService,
                                      analytics: analytics,
                                      budgets: budgets,
                                    ),
                                    onUseSavings:
                                        analytics.isCategoryOverBudget(
                                          budget.category,
                                        )
                                        ? () => _confirmSavingsPull(
                                            context,
                                            firestoreService,
                                            analytics,
                                            category: budget.category,
                                          )
                                        : null,
                                    onDelete: () => _confirmDeleteBudget(
                                      context,
                                      firestoreService,
                                      budget,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 22),
                            _SectionTitle(
                              title: 'This period',
                              trailing: '${periodTransactions.length} txns',
                            ),
                            const SizedBox(height: 12),
                            _PeriodDetailsCard(analytics: analytics),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ElevatedButton.icon(
          onPressed: () async {
            final budgets = await firestoreService
                .getBudgetPlans(monthKey: period.key)
                .first;
            final transactions = await firestoreService.getTransactions().first;
            final profile = await firestoreService.getUserProfile().first;
            final goals = await firestoreService.getSavingGoals().first;
            final analytics = _BudgetAnalytics.from(
              budgets: budgets,
              periodTransactions: transactions
                  .where((transaction) => period.contains(transaction.date))
                  .toList(),
              allTransactions: transactions,
              goals: goals,
              profile: profile,
              period: period,
            );
            if (!context.mounted) return;
            _showBudgetEditor(
              context,
              firestoreService,
              analytics: analytics,
              budgets: budgets,
            );
          },
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Edit budget'),
        ),
      ),
    );
  }

  void _scheduleCarryForward(
    BuildContext context,
    FirestoreService firestoreService,
    _BudgetPeriod period,
  ) {
    if (!period.isClosed || _carryForwardChecks.contains(period.key)) return;
    _carryForwardChecks.add(period.key);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final leftover = await firestoreService.previewBudgetLeftover(
        periodType: period.modeName,
        periodKey: period.key,
      );
      if (!context.mounted || leftover <= 0) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Move leftover to savings?'),
          content: Text(
            '${CurrencyUtils.format(leftover)} is left from ${period.label}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Move'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      await firestoreService.carryForwardBudgetLeftover(
        periodType: period.modeName,
        periodKey: period.key,
        periodEnd: period.end,
      );
    });
  }

  Future<void> _confirmSavingsPull(
    BuildContext context,
    FirestoreService firestoreService,
    _BudgetAnalytics analytics, {
    String? category,
  }) async {
    final amount = category == null
        ? analytics.overBudgetAmount
        : analytics.categoryOverage(category);
    if (amount <= 0) return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use savings?'),
        content: Text(
          'Move ${CurrencyUtils.format(amount)} from savings to cover this budget pressure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use savings'),
          ),
        ],
      ),
    );

    if (approved != true) return;
    try {
      await firestoreService.pullSavingsForBudgetOverage(
        amount: amount,
        periodType: analytics.period.modeName,
        periodKey: analytics.period.key,
        reason: category == null
            ? 'Budget support for ${analytics.period.label}'
            : '$category support for ${analytics.period.label}',
      );
      if (!context.mounted) return;
      _showSnack(context, 'Savings support recorded');
    } on FinanceValidationException catch (error) {
      if (!context.mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }

  Future<void> _confirmDeleteBudget(
    BuildContext context,
    FirestoreService firestoreService,
    BudgetPlan budget,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Remove the ${budget.category} budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await firestoreService.deleteBudgetPlan(budget.id);
    if (!context.mounted) return;
    _showSnack(context, '${budget.category} budget deleted');
  }

  void _showBudgetEditor(
    BuildContext context,
    FirestoreService firestoreService, {
    required _BudgetAnalytics analytics,
    required List<BudgetPlan> budgets,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetEditorSheet(
        firestoreService: firestoreService,
        budgets: budgets,
        analytics: analytics,
      ),
    );
  }

  void _showAutoBudgetPreview(
    BuildContext context,
    FirestoreService firestoreService, {
    required _BudgetAnalytics analytics,
    required List<BudgetPlan> budgets,
  }) {
    final suggestions = _AutoBudgetGenerator.generate(analytics);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AutoBudgetSheet(
        suggestions: suggestions,
        analytics: analytics,
        onApply: () async {
          try {
            await _applySuggestedBudgets(
              firestoreService,
              analytics,
              budgets,
              suggestions,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
            _showSnack(context, 'Suggested budget applied');
          } on FinanceValidationException catch (error) {
            if (!context.mounted) return;
            _showSnack(context, error.message, isError: true);
          } catch (_) {
            if (!context.mounted) return;
            _showSnack(context, 'Could not apply budget', isError: true);
          }
        },
      ),
    );
  }

  Future<void> _applySuggestedBudgets(
    FirestoreService firestoreService,
    _BudgetAnalytics analytics,
    List<BudgetPlan> budgets,
    List<_BudgetSuggestion> suggestions,
  ) async {
    final total = suggestions.fold<double>(
      0,
      (total, suggestion) => total + suggestion.amount,
    );
    if (analytics.projectedIncome > 0 && total > analytics.projectedIncome) {
      throw FinanceValidationException(
        'Budget total cannot exceed projected income.',
      );
    }

    final existingByCategory = {
      for (final budget in budgets) budget.category: budget,
    };
    final suggestedCategories = {
      for (final suggestion in suggestions) suggestion.category,
    };

    for (final existing in budgets.where(
      (budget) => !suggestedCategories.contains(budget.category),
    )) {
      await firestoreService.deleteBudgetPlan(existing.id);
    }

    final ordered = [...suggestions]
      ..sort((a, b) {
        final oldA = existingByCategory[a.category]?.allocatedAmount ?? 0;
        final oldB = existingByCategory[b.category]?.allocatedAmount ?? 0;
        return (a.amount - oldA).compareTo(b.amount - oldB);
      });

    for (final suggestion in ordered) {
      final existing = existingByCategory[suggestion.category];
      final budget = BudgetPlan(
        id: existing?.id ?? '',
        title: suggestion.category,
        category: suggestion.category,
        allocatedAmount: suggestion.amount,
        notes: suggestion.reason,
        monthKey: analytics.period.key,
        periodKey: analytics.period.key,
        periodType: analytics.period.modeName,
        createdAt: DateTime.now(),
        allocationMode: 'auto',
        isDebtPayment: existing?.isDebtPayment ?? false,
        reminderDate: existing?.reminderDate,
      );
      if (existing == null) {
        await firestoreService.addBudgetPlan(budget);
      } else {
        await firestoreService.updateBudgetPlan(existing.id, budget.toMap());
      }
    }
  }
}

class _BudgetPeriod {
  const _BudgetPeriod({
    required this.mode,
    required this.key,
    required this.label,
    required this.start,
    required this.end,
  });

  final _PeriodMode mode;
  final String key;
  final String label;
  final DateTime start;
  final DateTime end;

  factory _BudgetPeriod.from(_PeriodMode mode, DateTime anchor) {
    switch (mode) {
      case _PeriodMode.daily:
        final start = DateTime(anchor.year, anchor.month, anchor.day);
        return _BudgetPeriod(
          mode: mode,
          key:
              '${anchor.year}-${anchor.month.toString().padLeft(2, '0')}-${anchor.day.toString().padLeft(2, '0')}',
          label: DateFormat('MMM dd, yyyy').format(anchor),
          start: start,
          end: start.add(const Duration(days: 1)),
        );
      case _PeriodMode.weekly:
        final start = DateTime(
          anchor.year,
          anchor.month,
          anchor.day,
        ).subtract(Duration(days: anchor.weekday - DateTime.monday));
        final firstDay = DateTime(anchor.year, 1, 1);
        final offset = firstDay.weekday - DateTime.monday;
        final firstMonday = firstDay.subtract(
          Duration(days: offset < 0 ? 6 : offset),
        );
        final week = (start.difference(firstMonday).inDays ~/ 7) + 1;
        return _BudgetPeriod(
          mode: mode,
          key: '${anchor.year}-W${week.toString().padLeft(2, '0')}',
          label:
              '${DateFormat('MMM dd').format(start)} - ${DateFormat('MMM dd').format(start.add(const Duration(days: 6)))}',
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case _PeriodMode.yearly:
        final start = DateTime(anchor.year);
        return _BudgetPeriod(
          mode: mode,
          key: '${anchor.year}',
          label: '${anchor.year}',
          start: start,
          end: DateTime(anchor.year + 1),
        );
      case _PeriodMode.monthly:
        final start = DateTime(anchor.year, anchor.month);
        return _BudgetPeriod(
          mode: mode,
          key: '${anchor.year}-${anchor.month.toString().padLeft(2, '0')}',
          label: DateFormat('MMMM yyyy').format(anchor),
          start: start,
          end: DateTime(anchor.year, anchor.month + 1),
        );
    }
  }

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  bool get isClosed => end.isBefore(DateTime.now());

  String get modeName => switch (mode) {
    _PeriodMode.daily => 'daily',
    _PeriodMode.weekly => 'weekly',
    _PeriodMode.monthly => 'monthly',
    _PeriodMode.yearly => 'yearly',
  };

  String get modeLabel => switch (mode) {
    _PeriodMode.daily => 'Daily',
    _PeriodMode.weekly => 'Weekly',
    _PeriodMode.monthly => 'Monthly',
    _PeriodMode.yearly => 'Yearly',
  };

  DateTime shift(_PeriodMode mode, int step) {
    switch (mode) {
      case _PeriodMode.daily:
        return start.add(Duration(days: step));
      case _PeriodMode.weekly:
        return start.add(Duration(days: step * 7));
      case _PeriodMode.monthly:
        return DateTime(start.year, start.month + step);
      case _PeriodMode.yearly:
        return DateTime(start.year + step);
    }
  }
}

class _BudgetAnalytics {
  const _BudgetAnalytics({
    required this.budgets,
    required this.periodTransactions,
    required this.allTransactions,
    required this.goals,
    required this.period,
    required this.projectedIncome,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.categorySpend,
    required this.profileSavings,
  });

  final List<BudgetPlan> budgets;
  final List<FinancialTransaction> periodTransactions;
  final List<FinancialTransaction> allTransactions;
  final List<SavingGoal> goals;
  final _BudgetPeriod period;
  final double projectedIncome;
  final double totalBudgeted;
  final double totalSpent;
  final Map<String, double> categorySpend;
  final double profileSavings;

  factory _BudgetAnalytics.from({
    required List<BudgetPlan> budgets,
    required List<FinancialTransaction> periodTransactions,
    required List<FinancialTransaction> allTransactions,
    required List<SavingGoal> goals,
    required Map<String, dynamic> profile,
    required _BudgetPeriod period,
  }) {
    final periodIncome = periodTransactions
        .where((transaction) => transaction.type == 'income')
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final profileIncome = ((profile['monthlyIncome'] ?? 0) as num).toDouble();
    final projectedIncome = FinanceConsistencyUtils.resolvePeriodIncome(
      profileMonthlyIncome: profileIncome,
      transactionIncome: periodIncome,
      periodType: period.modeName,
    );
    final totalBudgeted = budgets.fold<double>(
      0,
      (total, budget) => total + budget.allocatedAmount,
    );
    final totalSpent = periodTransactions
        .where((transaction) => transaction.type == 'expense')
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final categorySpend = <String, double>{};
    for (final transaction in periodTransactions.where(
      (transaction) => transaction.type == 'expense',
    )) {
      final category = transaction.linkedBudgetCategory?.isNotEmpty == true
          ? transaction.linkedBudgetCategory!
          : transaction.category;
      categorySpend[category] =
          (categorySpend[category] ?? 0) + transaction.amount;
    }
    final profileSavings =
        ((profile['savingsBalance'] ?? 0) as num).toDouble() +
        ((profile['extraSavingsBalance'] ?? 0) as num).toDouble();

    return _BudgetAnalytics(
      budgets: budgets,
      periodTransactions: periodTransactions,
      allTransactions: allTransactions,
      goals: goals,
      period: period,
      projectedIncome: projectedIncome,
      totalBudgeted: totalBudgeted,
      totalSpent: totalSpent,
      categorySpend: categorySpend,
      profileSavings: profileSavings,
    );
  }

  double get remainingBudget =>
      (totalBudgeted - totalSpent).clamp(0, double.infinity).toDouble();
  double get overBudgetAmount =>
      (totalSpent - totalBudgeted).clamp(0, double.infinity).toDouble();
  double get availableToPlan =>
      (projectedIncome - totalBudgeted).clamp(0, double.infinity).toDouble();
  double get unplannedSpending => categorySpend.entries
      .where((entry) => allocatedForCategory(entry.key) <= 0)
      .fold<double>(0, (total, entry) => total + entry.value);
  double get spendingRatio =>
      totalBudgeted <= 0 ? 0 : (totalSpent / totalBudgeted).clamp(0.0, 2.0);
  double get planRatio => projectedIncome <= 0
      ? 0
      : (totalBudgeted / projectedIncome).clamp(0.0, 2.0);
  bool get isOverBudget => overBudgetAmount > 0;
  bool get isOverPlanned =>
      projectedIncome > 0 && totalBudgeted > projectedIncome + 0.01;
  int get overCategoryCount =>
      budgets.where((budget) => isCategoryOverBudget(budget.category)).length;
  int get activeGoalCount => goals.where((goal) => goal.remaining > 0).length;

  double spentForCategory(String category) => categorySpend[category] ?? 0;

  double allocatedForCategory(String category) => budgets
      .where((budget) => budget.category == category)
      .fold<double>(0, (total, budget) => total + budget.allocatedAmount);

  double categoryOverage(String category) =>
      (spentForCategory(category) - allocatedForCategory(category))
          .clamp(0, double.infinity)
          .toDouble();

  bool isCategoryOverBudget(String category) => categoryOverage(category) > 0;

  double get goalPressure {
    if (goals.isEmpty) return 0;
    return goals.where((goal) => goal.remaining > 0).fold<double>(0, (
      total,
      goal,
    ) {
      final dailyNeed = goal.remaining / math.max(goal.daysLeft, 1);
      return total +
          switch (period.mode) {
            _PeriodMode.daily => dailyNeed,
            _PeriodMode.weekly => dailyNeed * 7,
            _PeriodMode.monthly => dailyNeed * 30,
            _PeriodMode.yearly => dailyNeed * 365,
          };
    });
  }

  String get statusLabel {
    if (totalBudgeted <= 0) return 'Setup needed';
    if (isOverBudget) return 'Over budget';
    if (spendingRatio >= 0.85) return 'Close to limit';
    return 'On track';
  }

  String get decisionTitle {
    if (projectedIncome <= 0) return 'Add income first';
    if (totalBudgeted <= 0) return 'Create a spending plan';
    if (isOverBudget) return 'Budget pressure detected';
    if (isOverPlanned) return 'Plan exceeds income';
    if (overCategoryCount > 0) return 'Category limit crossed';
    if (unplannedSpending > 0) return 'Unplanned spending found';
    if (availableToPlan > 0) return 'Assign remaining income';
    if (spendingRatio >= 0.85) return 'Close to your limit';
    return 'Budget is working';
  }

  String get primaryActionLabel {
    if (projectedIncome <= 0) return 'Review setup';
    if (totalBudgeted <= 0) return 'Auto-budget';
    if (isOverBudget && profileSavings > 0) return 'Use savings support';
    if (isOverBudget || isOverPlanned || overCategoryCount > 0) {
      return 'Adjust budget';
    }
    if (unplannedSpending > 0) return 'Add missing category';
    if (availableToPlan > 0) return 'Plan remaining';
    return 'Review categories';
  }

  Color statusColor(BuildContext context) {
    if (isOverBudget || isOverPlanned) return AppTheme.error;
    if (spendingRatio >= 0.85 || totalBudgeted <= 0) return AppTheme.warning;
    return AppTheme.success;
  }

  String get nextAction {
    if (projectedIncome <= 0) return 'Add income so budgets can be validated.';
    if (totalBudgeted <= 0) {
      return 'Create a starter budget or use Auto-budget.';
    }
    if (isOverBudget) {
      return 'Reduce spending or use savings support deliberately.';
    }
    if (overCategoryCount > 0) {
      return 'Adjust categories that crossed their limit.';
    }
    if (availableToPlan > 0) {
      return 'You still have ${CurrencyUtils.format(availableToPlan)} unplanned.';
    }
    return 'Keep recording expenses against these categories.';
  }

  String? get warning {
    if (isOverPlanned) {
      return 'Budget total is higher than projected income. Reduce allocations.';
    }
    if (unplannedSpending > 0) {
      return '${CurrencyUtils.format(unplannedSpending)} was spent without a planned category.';
    }
    if (profileSavings <= 0 && isOverBudget) {
      return 'Savings support is unavailable because no savings balance is recorded.';
    }
    return null;
  }
}

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader({
    required this.period,
    required this.mode,
    required this.onPrevious,
    required this.onNext,
    required this.onModeChanged,
  });

  final _BudgetPeriod period;
  final _PeriodMode mode;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<_PeriodMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimaryFor(context),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Plan income, control spending, protect savings',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            IconButton.outlined(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Previous period',
            ),
            Expanded(
              child: Center(
                child: Text(
                  period.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton.outlined(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Next period',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PeriodChips(mode: mode, onChanged: onModeChanged),
      ],
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.mode, required this.onChanged});

  final _PeriodMode mode;
  final ValueChanged<_PeriodMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _PeriodMode.values.map((item) {
          final selected = item == mode;
          final label = switch (item) {
            _PeriodMode.monthly => 'Month',
            _PeriodMode.weekly => 'Week',
            _PeriodMode.daily => 'Day',
            _PeriodMode.yearly => 'Year',
          };
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onChanged(item),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BudgetStatusCard extends StatelessWidget {
  const _BudgetStatusCard({
    required this.analytics,
    required this.onEdit,
    required this.onAutoBudget,
    required this.onUseSavings,
  });

  final _BudgetAnalytics analytics;
  final VoidCallback onEdit;
  final VoidCallback onAutoBudget;
  final VoidCallback? onUseSavings;

  @override
  Widget build(BuildContext context) {
    final color = analytics.statusColor(context);

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
          _StatusPill(label: analytics.statusLabel, color: color),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _AmountBlock(
                  label: analytics.isOverBudget ? 'Over by' : 'Left to spend',
                  value: CurrencyUtils.format(
                    analytics.isOverBudget
                        ? analytics.overBudgetAmount
                        : analytics.remainingBudget,
                  ),
                ),
              ),
              Text(
                '${(analytics.spendingRatio * 100).clamp(0, 200).toStringAsFixed(0)}%',
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: analytics.spendingRatio.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: AppTheme.isDark(context) ? 0.18 : 0.08,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analytics.decisionTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  analytics.nextAction,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _primaryAction(),
                    icon: Icon(_primaryIcon(), size: 18),
                    label: Text(analytics.primaryActionLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (onUseSavings != null &&
                    analytics.primaryActionLabel != 'Use savings support') ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onUseSavings,
                      icon: const Icon(Icons.savings_rounded),
                      label: const Text('Use savings support'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback _primaryAction() {
    if (analytics.projectedIncome <= 0) return onEdit;
    if (analytics.totalBudgeted <= 0) return onAutoBudget;
    if (analytics.isOverBudget && analytics.profileSavings > 0) {
      return onUseSavings ?? onEdit;
    }
    return onEdit;
  }

  IconData _primaryIcon() {
    if (analytics.projectedIncome <= 0) return Icons.tune_rounded;
    if (analytics.totalBudgeted <= 0) return Icons.auto_awesome_rounded;
    if (analytics.isOverBudget && analytics.profileSavings > 0) {
      return Icons.savings_rounded;
    }
    return Icons.tune_rounded;
  }
}

class _BudgetSnapshotRow extends StatelessWidget {
  const _BudgetSnapshotRow({required this.analytics});

  final _BudgetAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BudgetMiniStat(
            label: 'Income',
            value: CurrencyUtils.format(analytics.projectedIncome),
            icon: Icons.payments_rounded,
            color: AppTheme.primaryFor(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BudgetMiniStat(
            label: 'Planned',
            value: CurrencyUtils.format(analytics.totalBudgeted),
            icon: Icons.account_balance_wallet_rounded,
            color: analytics.isOverPlanned ? AppTheme.error : AppTheme.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BudgetMiniStat(
            label: 'Spent',
            value: CurrencyUtils.format(analytics.totalSpent),
            icon: Icons.receipt_long_rounded,
            color: analytics.isOverBudget ? AppTheme.error : AppTheme.warning,
          ),
        ),
      ],
    );
  }
}

class _BudgetMiniStat extends StatelessWidget {
  const _BudgetMiniStat({
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimaryFor(context),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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
    );
  }
}

class _BudgetActions extends StatelessWidget {
  const _BudgetActions({required this.onEdit, required this.onAutoBudget});

  final VoidCallback onEdit;
  final VoidCallback onAutoBudget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.tune_rounded,
            label: 'Edit',
            onTap: onEdit,
            color: AppTheme.primaryFor(context),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.auto_awesome_rounded,
            label: 'Auto-budget',
            onTap: onAutoBudget,
            color: AppTheme.success,
          ),
        ),
      ],
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.budget,
    required this.analytics,
    required this.onEdit,
    required this.onUseSavings,
    required this.onDelete,
  });

  final BudgetPlan budget;
  final _BudgetAnalytics analytics;
  final VoidCallback onEdit;
  final VoidCallback? onUseSavings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final spent = analytics.spentForCategory(budget.category);
    final remaining = (budget.allocatedAmount - spent)
        .clamp(0, double.infinity)
        .toDouble();
    final over = analytics.categoryOverage(budget.category);
    final progress = budget.allocatedAmount <= 0
        ? 0.0
        : (spent / budget.allocatedAmount).clamp(0.0, 1.0);
    final isOver = over > 0;
    final color = isOver
        ? AppTheme.error
        : progress >= 0.85
        ? AppTheme.warning
        : AppTheme.primaryFor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_categoryIcon(budget.category), color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (budget.isDebtPayment)
                      Text(
                        'Debt payment',
                        style: GoogleFonts.inter(
                          color: AppTheme.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit budgets')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CurrencyUtils.format(spent)} of ${CurrencyUtils.format(budget.allocatedAmount)}',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                isOver
                    ? '${CurrencyUtils.format(over)} over'
                    : '${CurrencyUtils.format(remaining)} left',
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (budget.reminderDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reminder ${DateFormat('MMM dd').format(budget.reminderDate!)}',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (onUseSavings != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUseSavings,
                icon: const Icon(Icons.savings_rounded),
                label: const Text('Cover from savings'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodDetailsCard extends StatelessWidget {
  const _PeriodDetailsCard({required this.analytics});

  final _BudgetAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Projected income',
            value: CurrencyUtils.format(analytics.projectedIncome),
          ),
          _DetailRow(
            label: 'Budgeted',
            value: CurrencyUtils.format(analytics.totalBudgeted),
          ),
          _DetailRow(
            label: 'Spent',
            value: CurrencyUtils.format(analytics.totalSpent),
          ),
          _DetailRow(
            label: 'Unplanned spend',
            value: CurrencyUtils.format(analytics.unplannedSpending),
          ),
          _DetailRow(
            label: 'Savings pool',
            value: CurrencyUtils.format(analytics.profileSavings),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _BudgetEditorSheet extends StatefulWidget {
  const _BudgetEditorSheet({
    required this.firestoreService,
    required this.budgets,
    required this.analytics,
  });

  final FirestoreService firestoreService;
  final List<BudgetPlan> budgets;
  final _BudgetAnalytics analytics;

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  final _inputs = <String, _BudgetInput>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final category in AppConstants.budgetCategories) {
      final existing = widget.budgets
          .where((budget) => budget.category == category)
          .cast<BudgetPlan?>()
          .firstWhere((budget) => budget != null, orElse: () => null);
      _inputs[category] = _BudgetInput(existing);
    }
  }

  @override
  void dispose() {
    for (final input in _inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  double get _total =>
      _inputs.values.fold<double>(0, (total, input) => total + input.amount);

  @override
  Widget build(BuildContext context) {
    final exceedsIncome =
        widget.analytics.projectedIncome > 0 &&
        _total > widget.analytics.projectedIncome;

    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          Text(
            'Edit budget',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _SheetTotals(
            income: widget.analytics.projectedIncome,
            total: _total,
            remaining: (widget.analytics.projectedIncome - _total)
                .clamp(0, double.infinity)
                .toDouble(),
          ),
          if (exceedsIncome) ...[
            const SizedBox(height: 12),
            const _NoticeBanner(
              message: 'Budget total is higher than projected income.',
            ),
          ],
          const SizedBox(height: 14),
          ...AppConstants.budgetCategories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BudgetInputRow(
                category: category,
                input: _inputs[category]!,
                onChanged: () => setState(() {}),
                onPickReminder: () => _pickReminder(category),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving || exceedsIncome ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_saving ? 'Saving...' : 'Save budget'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickReminder(String category) async {
    final input = _inputs[category]!;
    final picked = await showDatePicker(
      context: context,
      initialDate: input.reminderDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => input.reminderDate = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final existingByCategory = {
        for (final budget in widget.budgets) budget.category: budget,
      };
      final changes = <_BudgetSaveChange>[];

      for (final category in AppConstants.budgetCategories) {
        final input = _inputs[category]!;
        final existing = existingByCategory[category];
        if (input.amount <= 0) {
          if (existing != null) changes.add(_BudgetSaveChange.delete(existing));
          continue;
        }
        final budget = BudgetPlan(
          id: existing?.id ?? '',
          title: category,
          category: category,
          allocatedAmount: input.amount,
          notes: input.isDebtPayment
              ? 'Debt payment budget'
              : '${widget.analytics.period.modeLabel} budget',
          monthKey: widget.analytics.period.key,
          periodKey: widget.analytics.period.key,
          periodType: widget.analytics.period.modeName,
          createdAt: DateTime.now(),
          allocationMode: 'manual',
          isDebtPayment: input.isDebtPayment,
          reminderDate: input.reminderDate,
        );
        changes.add(_BudgetSaveChange.upsert(existing, budget));
      }

      changes.sort((a, b) => a.delta.compareTo(b.delta));
      for (final change in changes) {
        if (change.deleteExisting) {
          await widget.firestoreService.deleteBudgetPlan(change.existing!.id);
        } else if (change.existing == null) {
          await widget.firestoreService.addBudgetPlan(change.next!);
        } else {
          await widget.firestoreService.updateBudgetPlan(
            change.existing!.id,
            change.next!.toMap(),
          );
        }
      }
      if (!mounted) return;
      Navigator.pop(context);
    } on FinanceValidationException catch (error) {
      if (!mounted) return;
      _showSnack(context, error.message, isError: true);
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      _showSnack(context, 'Could not save budget', isError: true);
      setState(() => _saving = false);
    }
  }
}

class _BudgetInput {
  _BudgetInput(BudgetPlan? budget)
    : controller = TextEditingController(
        text: budget == null || budget.allocatedAmount == 0
            ? ''
            : budget.allocatedAmount.toStringAsFixed(0),
      ),
      isDebtPayment = budget?.isDebtPayment ?? false,
      reminderDate = budget?.reminderDate;

  final TextEditingController controller;
  bool isDebtPayment;
  DateTime? reminderDate;

  double get amount {
    final value = double.tryParse(controller.text.trim()) ?? 0;
    return value.isFinite && value > 0 ? value : 0;
  }

  void dispose() => controller.dispose();
}

class _BudgetInputRow extends StatelessWidget {
  const _BudgetInputRow({
    required this.category,
    required this.input,
    required this.onChanged,
    required this.onPickReminder,
  });

  final String category;
  final _BudgetInput input;
  final VoidCallback onChanged;
  final VoidCallback onPickReminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _categoryIcon(category),
                color: AppTheme.primaryFor(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(
                value: input.isDebtPayment,
                activeThumbColor: AppTheme.primaryFor(context),
                onChanged: (value) {
                  input.isDebtPayment = value;
                  onChanged();
                },
              ),
            ],
          ),
          TextField(
            controller: input.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: 'PKR ',
            ),
          ),
          if (input.isDebtPayment) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: onPickReminder,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceFor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderFor(context)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        input.reminderDate == null
                            ? 'Add reminder'
                            : 'Reminder ${DateFormat('MMM dd').format(input.reminderDate!)}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoBudgetGenerator {
  static List<_BudgetSuggestion> generate(_BudgetAnalytics analytics) {
    final income = analytics.projectedIncome;
    if (income <= 0) return const [];
    final savingsAmount = math
        .max(income * 0.12, analytics.goalPressure)
        .clamp(0, income * 0.25)
        .toDouble();
    final remaining = (income - savingsAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final categories = AppConstants.budgetCategories
        .where((category) => category != 'Savings')
        .toList();
    final history = <String, double>{};
    for (final transaction in analytics.allTransactions.where(
      (transaction) => transaction.type == 'expense',
    )) {
      final category =
          AppConstants.budgetCategories.contains(transaction.category)
          ? transaction.category
          : 'Others';
      history[category] = (history[category] ?? 0) + transaction.amount;
    }
    final historyTotal = history.values.fold<double>(
      0,
      (total, value) => total + value,
    );
    final suggestions = <_BudgetSuggestion>[];

    for (final category in categories) {
      final share = historyTotal > 0
          ? (history[category] ?? 0) / historyTotal
          : 1 / categories.length;
      final amount = remaining * share;
      if (amount > 0) {
        suggestions.add(
          _BudgetSuggestion(
            category: category,
            amount: amount,
            reason: historyTotal > 0
                ? 'Based on past spending'
                : 'Balanced starter amount',
          ),
        );
      }
    }

    if (savingsAmount > 0) {
      suggestions.add(
        _BudgetSuggestion(
          category: 'Savings',
          amount: savingsAmount,
          reason: analytics.activeGoalCount > 0
              ? 'Protects active saving goals'
              : 'Builds a savings buffer',
        ),
      );
    }
    return suggestions;
  }
}

class _AutoBudgetSheet extends StatelessWidget {
  const _AutoBudgetSheet({
    required this.suggestions,
    required this.analytics,
    required this.onApply,
  });

  final List<_BudgetSuggestion> suggestions;
  final _BudgetAnalytics analytics;
  final Future<void> Function() onApply;

  @override
  Widget build(BuildContext context) {
    final total = suggestions.fold<double>(
      0,
      (total, suggestion) => total + suggestion.amount,
    );
    final valid =
        suggestions.isNotEmpty &&
        (analytics.projectedIncome <= 0 || total <= analytics.projectedIncome);

    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          Text(
            'Auto-budget',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A starter plan from income, spending history, and savings goals.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _SheetTotals(
            income: analytics.projectedIncome,
            total: total,
            remaining: (analytics.projectedIncome - total)
                .clamp(0, double.infinity)
                .toDouble(),
          ),
          const SizedBox(height: 14),
          if (suggestions.isEmpty)
            const _NoticeBanner(message: 'Add income first to generate a plan.')
          else
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(
                      _categoryIcon(suggestion.category),
                      color: AppTheme.primaryFor(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.category,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimaryFor(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            suggestion.reason,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondaryFor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyUtils.format(suggestion.amount),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: valid ? onApply : null,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Apply plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSuggestion {
  const _BudgetSuggestion({
    required this.category,
    required this.amount,
    required this.reason,
  });

  final String category;
  final double amount;
  final String reason;
}

class _BudgetSaveChange {
  const _BudgetSaveChange._({
    required this.existing,
    required this.next,
    required this.deleteExisting,
  });

  factory _BudgetSaveChange.delete(BudgetPlan existing) {
    return _BudgetSaveChange._(
      existing: existing,
      next: null,
      deleteExisting: true,
    );
  }

  factory _BudgetSaveChange.upsert(BudgetPlan? existing, BudgetPlan next) {
    return _BudgetSaveChange._(
      existing: existing,
      next: next,
      deleteExisting: false,
    );
  }

  final BudgetPlan? existing;
  final BudgetPlan? next;
  final bool deleteExisting;

  double get delta {
    if (deleteExisting) return -(existing?.allocatedAmount ?? 0);
    return (next?.allocatedAmount ?? 0) - (existing?.allocatedAmount ?? 0);
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            fontSize: 12,
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
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimaryFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
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

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningFillFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: AppTheme.textPrimaryFor(context),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({required this.onCreate, required this.onAutoBudget});

  final VoidCallback onCreate;
  final VoidCallback onAutoBudget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: AppTheme.primaryFor(context),
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            'No budget yet',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start with Auto-budget or enter your own category limits.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCreate,
                  child: const Text('Manual'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAutoBudget,
                  child: const Text('Auto'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppTheme.borderFor(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(top: false, child: SingleChildScrollView(child: child)),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppTheme.borderFor(context),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetTotals extends StatelessWidget {
  const _SheetTotals({
    required this.income,
    required this.total,
    required this.remaining,
  });

  final double income;
  final double total;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Income', value: CurrencyUtils.format(income)),
          _DetailRow(label: 'Budget total', value: CurrencyUtils.format(total)),
          _DetailRow(
            label: 'Left unplanned',
            value: CurrencyUtils.format(remaining),
            last: true,
          ),
        ],
      ),
    );
  }
}

List<BudgetPlan> _sortBudgets(
  List<BudgetPlan> budgets,
  _BudgetAnalytics analytics,
) {
  return [...budgets]..sort((a, b) {
    final overCompare = analytics
        .categoryOverage(b.category)
        .compareTo(analytics.categoryOverage(a.category));
    if (overCompare != 0) return overCompare;
    return analytics
        .spentForCategory(b.category)
        .compareTo(analytics.spentForCategory(a.category));
  });
}

IconData _categoryIcon(String category) {
  final key = category.toLowerCase();
  if (key.contains('electricity')) return Icons.bolt_rounded;
  if (key.contains('grocery')) return Icons.shopping_basket_rounded;
  if (key.contains('education')) return Icons.school_rounded;
  if (key.contains('transport')) return Icons.directions_bus_rounded;
  if (key.contains('entertainment')) return Icons.movie_rounded;
  if (key.contains('health')) return Icons.local_hospital_rounded;
  if (key.contains('saving')) return Icons.savings_rounded;
  return Icons.category_rounded;
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ),
  );
}
