import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/transaction.dart';
import '../../models/spending_analytics.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/spending_analytics_service.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final fs = FirestoreService(uid: auth.user!.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: fs.getTransactions(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E3192)),
            );
          }
          final transactions = snap.data ?? [];
          final svc = SpendingAnalyticsService();
          final weeklyTrends = svc.getWeeklyTrends(transactions);
          final anomalies = svc.detectAnomalies(transactions);
          final recurring = svc.detectRecurringExpenses(transactions);

          return CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    _SectionHeader(
                      icon: Icons.bar_chart_rounded,
                      title: 'Weekly Spending Trends',
                      subtitle: 'Last 8 weeks',
                    ),
                    const SizedBox(height: 12),
                    _WeeklyBarChart(trends: weeklyTrends),
                    const SizedBox(height: 24),
                    if (anomalies.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.warning_amber_rounded,
                        title: 'Spending Alerts',
                        subtitle: '${anomalies.length} categor${anomalies.length == 1 ? 'y' : 'ies'} flagged',
                        iconColor: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 12),
                      ...anomalies.map((a) => _AnomalyCard(anomaly: a)),
                    ],
                    const SizedBox(height: 24),
                    _SectionHeader(
                      icon: Icons.calendar_month_rounded,
                      title: 'Recurring Expenses',
                      subtitle: recurring.isEmpty
                          ? 'None detected yet'
                          : '${recurring.length} detected',
                    ),
                    const SizedBox(height: 12),
                    if (recurring.isEmpty)
                      _EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'No recurring expenses detected yet.\nAdd more transactions to see patterns.',
                      )
                    else
                      ...recurring.map((r) => _RecurringCard(expense: r)),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2E3192),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
        title: const Text(
          'Spending Analytics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E3192), Color(0xFF4B5BD6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = const Color(0xFF2E3192),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Plus Jakarta Sans',
                )),
            Text(subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontFamily: 'Plus Jakarta Sans',
                )),
          ],
        ),
      ],
    );
  }
}

// ─── Weekly Bar Chart ──────────────────────────────────────────────────────

class _WeeklyBarChart extends StatefulWidget {
  final Map<String, double> trends;
  const _WeeklyBarChart({required this.trends});

  @override
  State<_WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<_WeeklyBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.trends.entries.toList();
    final maxVal = entries.isEmpty
        ? 100.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E3192).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxVal * 1.25,
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              setState(() {
                _touchedIndex =
                    response?.spot?.touchedBarGroupIndex;
              });
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF2E3192),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'PKR ${_fmt(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) => Text(
                  _fmtK(value),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  // Show only "Apr 28" part
                  final label = entries[idx].key.replaceFirst('Week of ', '');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF64748B),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: const Color(0xFFE2E8F0),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (i) {
            final isTouched = _touchedIndex == i;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value,
                  width: isTouched ? 18 : 14,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                  gradient: LinearGradient(
                    colors: isTouched
                        ? [const Color(0xFF4B5BD6), const Color(0xFF2E3192)]
                        : [
                            const Color(0xFF818CF8),
                            const Color(0xFF4B5BD6),
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  String _fmtK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }
}

// ─── Anomaly Card ──────────────────────────────────────────────────────────

class _AnomalyCard extends StatelessWidget {
  final SpendingAnomaly anomaly;
  const _AnomalyCard({required this.anomaly});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      anomaly.category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${anomaly.percentageIncrease.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  anomaly.message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78350F),
                    height: 1.5,
                    fontFamily: 'Plus Jakarta Sans',
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

// ─── Recurring Expense Card ────────────────────────────────────────────────

class _RecurringCard extends StatelessWidget {
  final RecurringExpense expense;
  const _RecurringCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = expense.lastDetectedDate;
    final dateStr = '${d.day} ${months[d.month - 1]} ${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E3192).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3192).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Color(0xFF2E3192), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.label_outline_rounded,
                        size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      expense.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      'Last: $dateStr',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${_fmt(expense.estimatedMonthlyAmount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E3192),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const Text(
                '/month',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

// ─── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.6,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}
