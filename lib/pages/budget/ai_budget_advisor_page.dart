import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/budget_plan.dart';
import '../../models/saving_goal.dart';
import '../../models/transaction.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';

class AIBudgetAdvisorPage extends StatefulWidget {
  const AIBudgetAdvisorPage({super.key});

  @override
  State<AIBudgetAdvisorPage> createState() => _AIBudgetAdvisorPageState();
}

class _AIBudgetAdvisorPageState extends State<AIBudgetAdvisorPage> {
  final AIService _aiService = AIService();

  String get _monthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;

    if (firestoreService == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, transactionSnapshot) {
          final transactions =
              transactionSnapshot.data ?? const <FinancialTransaction>[];
          final monthlyTransactions = transactions
              .where((txn) => _sameMonth(txn.date, DateTime.now()))
              .toList();

          return StreamBuilder<List<SavingGoal>>(
            stream: firestoreService.getSavingGoals(),
            builder: (context, goalsSnapshot) {
              final goals = goalsSnapshot.data ?? const <SavingGoal>[];

              return StreamBuilder<List<BudgetPlan>>(
                stream: firestoreService.getBudgetPlans(monthKey: _monthKey),
                builder: (context, budgetSnapshot) {
                  final budgets = budgetSnapshot.data ?? const <BudgetPlan>[];
                  final analytics = _BudgetAnalytics.from(
                    budgets,
                    monthlyTransactions,
                    goals,
                  );

                  return SafeArea(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Budget Advisor',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your own budgets, track actual spending, and get AI recommendations in PKR.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _SummaryCard(analytics: analytics),
                              const SizedBox(height: 24),
                              _SectionTitle(
                                title: 'This Month\'s Budget Plans',
                                action: TextButton.icon(
                                  onPressed: () => _showBudgetEditor(
                                    context,
                                    firestoreService,
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Budget'),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (budgets.isEmpty)
                                _EmptyBudgetState(
                                  onCreate: () => _showBudgetEditor(
                                    context,
                                    firestoreService,
                                  ),
                                )
                              else
                                ...budgets.map(
                                  (budget) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _BudgetPlanCard(
                                      budget: budget,
                                      spent: analytics.spentForCategory(
                                        budget.category,
                                      ),
                                      onEdit: () => _showBudgetEditor(
                                        context,
                                        firestoreService,
                                        budget: budget,
                                      ),
                                      onDelete: () => firestoreService
                                          .deleteBudgetPlan(budget.id),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              const _SectionTitle(title: 'AI Recommendations'),
                              const SizedBox(height: 14),
                              FutureBuilder<String>(
                                future: _aiService.getBudgetPlanRecommendations(
                                  budgets,
                                  monthlyTransactions,
                                ),
                                builder: (context, snapshot) {
                                  return _InsightCard(
                                    title: 'Budget Plan Coach',
                                    body:
                                        snapshot.data ??
                                        'Generating budget plan recommendations...',
                                    icon: Icons.auto_awesome_rounded,
                                    color: const Color(0xFF22D3EE),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              FutureBuilder<String>(
                                future: _aiService.getBudgetAdvice(
                                  monthlyTransactions,
                                ),
                                builder: (context, snapshot) {
                                  return _InsightCard(
                                    title: 'Spending Pattern Insights',
                                    body:
                                        snapshot.data ??
                                        'Analyzing your transaction patterns...',
                                    icon: Icons.insights_rounded,
                                    color: const Color(0xFF818CF8),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              const _SectionTitle(title: 'Budget Health'),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _MetricCard(
                                    title: 'Budgeted',
                                    value: CurrencyUtils.format(
                                      analytics.totalBudgeted,
                                    ),
                                    subtitle: 'Current month allocation',
                                    color: const Color(0xFF22C55E),
                                  ),
                                  _MetricCard(
                                    title: 'Spent',
                                    value: CurrencyUtils.format(
                                      analytics.totalSpent,
                                    ),
                                    subtitle: 'Current month expenses',
                                    color: const Color(0xFFF97316),
                                  ),
                                  _MetricCard(
                                    title: 'Remaining',
                                    value: CurrencyUtils.format(
                                      analytics.remainingBudget,
                                    ),
                                    subtitle: 'Still available',
                                    color: const Color(0xFF38BDF8),
                                  ),
                                  _MetricCard(
                                    title: 'Savings Rate',
                                    value:
                                        '${analytics.savingsRate.toStringAsFixed(0)}%',
                                    subtitle: 'Based on monthly income',
                                    color: const Color(0xFFFACC15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const _SectionTitle(title: 'Category Breakdown'),
                              const SizedBox(height: 14),
                              _DistributionCard(analytics: analytics),
                              const SizedBox(height: 24),
                              const _SectionTitle(title: 'Goal Alignment'),
                              const SizedBox(height: 14),
                              ...goals
                                  .take(3)
                                  .map(
                                    (goal) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _GoalTile(goal: goal),
                                    ),
                                  ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _sameMonth(DateTime first, DateTime second) {
    return first.year == second.year && first.month == second.month;
  }

  void _showBudgetEditor(
    BuildContext context,
    FirestoreService firestoreService, {
    BudgetPlan? budget,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetEditorSheet(
        firestoreService: firestoreService,
        budget: budget,
        monthKey: _monthKey,
      ),
    );
  }
}

class _BudgetAnalytics {
  _BudgetAnalytics({
    required this.budgets,
    required this.transactions,
    required this.goals,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalIncome,
    required this.categorySpend,
  });

  final List<BudgetPlan> budgets;
  final List<FinancialTransaction> transactions;
  final List<SavingGoal> goals;
  final double totalBudgeted;
  final double totalSpent;
  final double totalIncome;
  final Map<String, double> categorySpend;

  factory _BudgetAnalytics.from(
    List<BudgetPlan> budgets,
    List<FinancialTransaction> transactions,
    List<SavingGoal> goals,
  ) {
    final totalBudgeted = budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.allocatedAmount,
    );
    final totalSpent = transactions
        .where((txn) => txn.type == 'expense')
        .fold<double>(0, (sum, txn) => sum + txn.amount);
    final totalIncome = transactions
        .where((txn) => txn.type == 'income')
        .fold<double>(0, (sum, txn) => sum + txn.amount);
    final categorySpend = <String, double>{};
    for (final txn in transactions.where((txn) => txn.type == 'expense')) {
      categorySpend[txn.category] =
          (categorySpend[txn.category] ?? 0) + txn.amount;
    }

    return _BudgetAnalytics(
      budgets: budgets,
      transactions: transactions,
      goals: goals,
      totalBudgeted: totalBudgeted,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      categorySpend: categorySpend,
    );
  }

  double get remainingBudget => totalBudgeted - totalSpent;
  double get spendingRatio =>
      totalBudgeted == 0 ? 0 : (totalSpent / totalBudgeted).clamp(0.0, 2.0);
  double get savingsRate {
    if (totalIncome <= 0) {
      return 0;
    }
    final saved = totalIncome - totalSpent;
    return ((saved > 0 ? saved : 0) / totalIncome) * 100;
  }

  double spentForCategory(String category) => categorySpend[category] ?? 0;

  List<MapEntry<String, double>> get topCategories {
    final entries = categorySpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.analytics});

  final _BudgetAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available to allocate',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtils.format(analytics.remainingBudget),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: analytics.spendingRatio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryStat(
                label: 'Budgeted',
                value: CurrencyUtils.format(
                  analytics.totalBudgeted,
                  compact: true,
                ),
              ),
              _SummaryStat(
                label: 'Spent',
                value: CurrencyUtils.format(
                  analytics.totalSpent,
                  compact: true,
                ),
              ),
              _SummaryStat(
                label: 'Income',
                value: CurrencyUtils.format(
                  analytics.totalIncome,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _BudgetPlanCard extends StatelessWidget {
  const _BudgetPlanCard({
    required this.budget,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetPlan budget;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final remaining = budget.allocatedAmount - spent;
    final progress = budget.allocatedAmount == 0
        ? 0.0
        : (spent / budget.allocatedAmount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget.category,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (budget.notes.isNotEmpty)
            Text(
              budget.notes,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              color: remaining < 0 ? Colors.redAccent : const Color(0xFF22D3EE),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _BudgetFigure(
                  label: 'Allocated',
                  value: CurrencyUtils.format(budget.allocatedAmount),
                ),
              ),
              Expanded(
                child: _BudgetFigure(
                  label: 'Spent',
                  value: CurrencyUtils.format(spent),
                ),
              ),
              Expanded(
                child: _BudgetFigure(
                  label: 'Remaining',
                  value: CurrencyUtils.format(remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetFigure extends StatelessWidget {
  const _BudgetFigure({required this.label, required this.value});

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
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.76),
                    height: 1.55,
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

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({required this.analytics});

  final _BudgetAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final categories = analytics.topCategories;
    final colors = [
      const Color(0xFF38BDF8),
      const Color(0xFF818CF8),
      const Color(0xFF34D399),
      const Color(0xFFF59E0B),
      const Color(0xFFFB7185),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: categories.isEmpty
          ? Text(
              'Add transactions to see your category breakdown.',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 56,
                      sectionsSpace: 3,
                      sections: List.generate(categories.length, (index) {
                        final value = categories[index].value;
                        return PieChartSectionData(
                          value: value,
                          color: colors[index % colors.length],
                          radius: 18,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(categories.length, (index) {
                  final entry = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                        Text(
                          CurrencyUtils.format(entry.value),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.64),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.56),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal});

  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(goal.progress * 100).round()}%',
                style: GoogleFonts.inter(
                  color: const Color(0xFF22D3EE),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: const Color(0xFF22D3EE),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${CurrencyUtils.format(goal.currentAmount)} of ${CurrencyUtils.format(goal.targetAmount)} saved, ${goal.daysLeft} days left.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

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
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            'Create monthly budgets for categories like food, transport, housing, and savings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('Create First Budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetEditorSheet extends StatefulWidget {
  const _BudgetEditorSheet({
    required this.firestoreService,
    required this.monthKey,
    this.budget,
  });

  final FirestoreService firestoreService;
  final BudgetPlan? budget;
  final String monthKey;

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late String _category;
  bool _saving = false;

  final _categories = const [
    'Housing',
    'Food',
    'Transport',
    'Utilities',
    'Shopping',
    'Health',
    'Savings',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.budget?.title ?? '');
    _amountController = TextEditingController(
      text: widget.budget?.allocatedAmount.toStringAsFixed(0) ?? '',
    );
    _notesController = TextEditingController(text: widget.budget?.notes ?? '');
    _category = widget.budget?.category ?? 'Food';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.budget == null ? 'Create Budget Plan' : 'Edit Budget Plan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Budget title'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Allocated amount in PKR',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'What should this budget cover?',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save Budget Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title and valid budget amount.')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'title': title,
      'category': _category,
      'allocatedAmount': amount,
      'notes': _notesController.text.trim(),
      'monthKey': widget.monthKey,
    };

    if (widget.budget == null) {
      await widget.firestoreService.addBudgetPlan(
        BudgetPlan(
          id: '',
          title: title,
          category: _category,
          allocatedAmount: amount,
          notes: _notesController.text.trim(),
          monthKey: widget.monthKey,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      await widget.firestoreService.updateBudgetPlan(widget.budget!.id, data);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
