import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/saving_goal.dart';
import '../../models/transaction.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';

class AIBudgetAdvisorPage extends StatelessWidget {
  const AIBudgetAdvisorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;
    const primaryColor = Color(0xFF2E3192);
    const accentColor = Color(0xFF1BFFFF);
    const darkBgColor = Color(0xFF0F0F1E);

    if (firestoreService == null) {
      return const Scaffold(
        backgroundColor: darkBgColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: darkBgColor,
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactions(),
        builder: (context, transactionSnapshot) {
          final transactions =
              transactionSnapshot.data ?? const <FinancialTransaction>[];
          return StreamBuilder<List<SavingGoal>>(
            stream: firestoreService.getSavingGoals(),
            builder: (context, goalSnapshot) {
              final goals = goalSnapshot.data ?? const <SavingGoal>[];
              final analytics = _BudgetAnalytics.from(transactions, goals);
              final aiService = AIService();

              return SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Budget Advisor',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Live stats, unusual spending, goal progress, and AI recommendations.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildSummaryCard(
                            analytics,
                            primaryColor,
                            accentColor,
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(title: 'AI Recommendations'),
                          const SizedBox(height: 14),
                          FutureBuilder<String>(
                            future: aiService.getBudgetAdvice(transactions),
                            builder: (context, snapshot) => _InsightCard(
                              title: 'Personalized Guidance',
                              body:
                                  snapshot.data ??
                                  'Generating recommendations...',
                              icon: Icons.auto_awesome_rounded,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: aiService.detectUnusualSpending(
                              transactions,
                            ),
                            builder: (context, snapshot) {
                              final anomalies = snapshot.data ?? const [];
                              return _AnomalyCard(anomalies: anomalies);
                            },
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(title: 'Spending Distribution'),
                          const SizedBox(height: 14),
                          _DistributionCard(analytics: analytics),
                          const SizedBox(height: 24),
                          _SectionTitle(title: 'Budget Health'),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              _MetricCard(
                                title: 'Income',
                                value: analytics.totalIncomeLabel,
                                subtitle: 'Tracked this month',
                                color: const Color(0xFF10B981),
                              ),
                              _MetricCard(
                                title: 'Expenses',
                                value: analytics.totalExpenseLabel,
                                subtitle: 'Tracked this month',
                                color: const Color(0xFFFF6B6B),
                              ),
                              _MetricCard(
                                title: 'Savings Rate',
                                value: '${analytics.savingsRate.round()}%',
                                subtitle: 'Goal: 20%+',
                                color: accentColor,
                              ),
                              _MetricCard(
                                title: 'Avg Daily Spend',
                                value: analytics.averageDailySpendLabel,
                                subtitle: 'Current month',
                                color: const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(title: 'Goal Progress'),
                          const SizedBox(height: 14),
                          ...goals.map(
                            (goal) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _GoalProgressTile(goal: goal),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(title: 'AI Insights'),
                          const SizedBox(height: 14),
                          _InsightCard(
                            title: 'Monthly Trend',
                            body: analytics.monthlyInsight,
                            icon: Icons.insights_rounded,
                            color: primaryColor,
                          ),
                          const SizedBox(height: 16),
                          _InsightCard(
                            title: 'Cash-Flow Signal',
                            body: analytics.cashFlowInsight,
                            icon: Icons.monitor_heart_rounded,
                            color: const Color(0xFF00B09B),
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
      ),
    );
  }

  Widget _buildSummaryCard(
    _BudgetAnalytics analytics,
    Color primaryColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [primaryColor, accentColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available to allocate',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            analytics.remainingBudgetLabel,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: analytics.spendingRatio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SummaryStat(label: 'Budget', value: analytics.totalIncomeLabel),
              _SummaryStat(label: 'Spent', value: analytics.totalExpenseLabel),
              _SummaryStat(label: 'Saved', value: analytics.savingsAmountLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetAnalytics {
  _BudgetAnalytics({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSavedInGoals,
    required this.categoryTotals,
    required this.averageDailySpend,
    required this.goalProgressAverage,
  });

  final double totalIncome;
  final double totalExpense;
  final double totalSavedInGoals;
  final Map<String, double> categoryTotals;
  final double averageDailySpend;
  final double goalProgressAverage;

  factory _BudgetAnalytics.from(
    List<FinancialTransaction> transactions,
    List<SavingGoal> goals,
  ) {
    final income = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (sum, item) => sum + item.amount);
    final categoryTotals = <String, double>{};
    for (final transaction in transactions.where((t) => t.type == 'expense')) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    final saved = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );
    final averageProgress = goals.isEmpty
        ? 0.0
        : goals.fold<double>(0, (sum, goal) => sum + goal.progress) /
              goals.length;
    final now = DateTime.now();
    final daysElapsed = now.day.toDouble().clamp(1, 31);

    return _BudgetAnalytics(
      totalIncome: income,
      totalExpense: expense,
      totalSavedInGoals: saved,
      categoryTotals: categoryTotals,
      averageDailySpend: expense / daysElapsed,
      goalProgressAverage: averageProgress,
    );
  }

  double get remainingBudget => totalIncome - totalExpense;
  double get spendingRatio => totalIncome == 0 ? 0 : totalExpense / totalIncome;
  double get savingsAmount =>
      totalIncome - totalExpense > 0 ? totalIncome - totalExpense : 0;
  double get savingsRate =>
      totalIncome == 0 ? 0 : (savingsAmount / totalIncome) * 100;

  String get totalIncomeLabel => _currency(totalIncome);
  String get totalExpenseLabel => _currency(totalExpense);
  String get remainingBudgetLabel => _currency(remainingBudget);
  String get savingsAmountLabel => _currency(savingsAmount);
  String get averageDailySpendLabel => _currency(averageDailySpend);

  List<MapEntry<String, double>> get topCategories {
    final entries = categoryTotals.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(4).toList();
  }

  String get monthlyInsight {
    if (spendingRatio > 0.85) {
      return 'You have used ${(spendingRatio * 100).round()}% of income. Focus on variable categories before fixed obligations crowd out savings.';
    }
    if (spendingRatio > 0.65) {
      return 'Cash flow is stable, but variable spending still has room to tighten. A small dining or shopping cut would lift savings quickly.';
    }
    return 'You are holding spending well below income. This is a strong window to accelerate debt payoff or increase automated savings.';
  }

  String get cashFlowInsight {
    final topCategory = topCategories.isEmpty
        ? 'General'
        : topCategories.first.key;
    return 'Top expense pressure is $topCategory. Average daily spend is $averageDailySpendLabel, and savings goals are ${(goalProgressAverage * 100).round()}% funded on average.';
  }

  static String _currency(double value) => '\$${value.toStringAsFixed(0)}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
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
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.5,
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
      const Color(0xFF2E3192),
      const Color(0xFF1BFFFF),
      const Color(0xFFF59E0B),
      const Color(0xFFFF6B6B),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
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
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  Text(
                    '\$${entry.value.toStringAsFixed(0)}',
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

class _AnomalyCard extends StatelessWidget {
  const _AnomalyCard({required this.anomalies});

  final List<Map<String, dynamic>> anomalies;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unusual Spending',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (anomalies.isEmpty)
            Text(
              'No major anomalies detected from your current transaction history.',
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.72),
              ),
            )
          else
            ...anomalies.map(
              (anomaly) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${anomaly['category']}: \$${(anomaly['amount'] as double).toStringAsFixed(0)} vs average \$${(anomaly['average'] as double).toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.62),
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
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressTile extends StatelessWidget {
  const _GoalProgressTile({required this.goal});

  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
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
                  color: const Color(0xFF1BFFFF),
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
              color: const Color(0xFF1BFFFF),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$${goal.currentAmount.toStringAsFixed(0)} of \$${goal.targetAmount.toStringAsFixed(0)} saved, ${goal.daysLeft} days left.',
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
