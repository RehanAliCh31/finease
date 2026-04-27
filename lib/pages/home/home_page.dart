import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/demo_finance_data.dart';
import '../../models/saving_goal.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../forum/community_forum_page.dart';
import '../literacy/literacy_hub_page.dart';
import '../notifications/notifications_page.dart';
import '../rewards/rewards_screen.dart';
import '../savings/savings_tracker_page.dart';
import '../transactions/add_transaction_page.dart';
import '../transactions/all_transactions_page.dart';
import '../welfare/welfare_programs_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = authService.firestoreService;
    final user = authService.user;
    final displayName =
        user?.displayName?.split(' ').first ??
        user?.email?.split('@').first ??
        'User';
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: _TopBar(displayName: displayName, photoUrl: photoUrl),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: firestoreService == null
                    ? const SizedBox.shrink()
                    : StreamBuilder<List<FinancialTransaction>>(
                        stream: firestoreService.getTransactions(),
                        builder: (context, snapshot) {
                          final txns = snapshot.data ?? const [];
                          final income = txns
                              .where((t) => t.type == 'income')
                              .fold<double>(0, (sum, t) => sum + t.amount);
                          final expense = txns
                              .where((t) => t.type == 'expense')
                              .fold<double>(0, (sum, t) => sum + t.amount);
                          final balance = income - expense;
                          return _BalanceCard(
                            balance: balance,
                            income: income,
                            expense: expense,
                          );
                        },
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Explore FinEase',
                  actionLabel: 'See rewards',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RewardsScreen(),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _FeatureGrid(
                  items: [
                    _FeatureItem(
                      label: 'Savings',
                      icon: Icons.savings_rounded,
                      color: const Color(0xFF0EA5A4),
                      background: const Color(0xFFECFEFF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavingsTrackerPage(),
                        ),
                      ),
                    ),
                    _FeatureItem(
                      label: 'Literacy Hub',
                      icon: Icons.school_rounded,
                      color: const Color(0xFF4F46E5),
                      background: const Color(0xFFEEF2FF),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LiteracyHubPage(),
                        ),
                      ),
                    ),
                    _FeatureItem(
                      label: 'Welfare',
                      icon: Icons.volunteer_activism_rounded,
                      color: const Color(0xFFD97706),
                      background: const Color(0xFFFFF7ED),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WelfareProgramsPage(),
                        ),
                      ),
                    ),
                    _FeatureItem(
                      label: 'Forum',
                      icon: Icons.forum_rounded,
                      color: const Color(0xFF475569),
                      background: const Color(0xFFF1F5F9),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunityForumPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Your Progress',
                  actionLabel: 'All activity',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTransactionsPage(),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: firestoreService == null
                    ? const SizedBox.shrink()
                    : StreamBuilder<List<SavingGoal>>(
                        stream: firestoreService.getSavingGoals(),
                        builder: (context, goalSnapshot) {
                          return StreamBuilder<List<FinancialTransaction>>(
                            stream: firestoreService.getTransactions(),
                            builder: (context, txnSnapshot) {
                              final goals = goalSnapshot.data ?? const [];
                              final txns = txnSnapshot.data ?? const [];
                              final saved = goals.fold<double>(
                                0,
                                (sum, goal) => sum + goal.currentAmount,
                              );
                              return FutureBuilder<List<int>>(
                                future: Future.wait(
                                  DemoFinanceData.courses.map((course) async {
                                    final progress = await firestoreService
                                        .getCourseProgress(course.id)
                                        .first;
                                    final completed = List<String>.from(
                                      progress['completedLessonIds'] ??
                                          const [],
                                    );
                                    return completed.length;
                                  }),
                                ),
                                builder: (context, lessonSnapshot) {
                                  final completedLessons =
                                      (lessonSnapshot.data ?? const <int>[])
                                          .fold<int>(
                                            0,
                                            (sum, value) => sum + value,
                                          );
                                  return _ProgressPanel(
                                    totalSaved: saved,
                                    goalCount: goals.length,
                                    transactionCount: txns.length,
                                    completedLessons: completedLessons,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recent Transactions',
                  actionLabel: 'See all',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllTransactionsPage(),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: firestoreService == null
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : StreamBuilder<List<FinancialTransaction>>(
                      stream: firestoreService.getTransactions(),
                      builder: (context, snapshot) {
                        final txns = (snapshot.data ?? const [])
                            .take(5)
                            .toList();
                        if (txns.isEmpty) {
                          return const SliverToBoxAdapter(child: _EmptyState());
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _TransactionTile(txn: txns[index]),
                            childCount: txns.length,
                          ),
                        );
                      },
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          ),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Add Transaction',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.displayName, required this.photoUrl});

  final String displayName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: AppTheme.softShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                              ),
                            ),
                      )
                    : const CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.person_rounded, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsPage()),
          ),
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });

  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: AppTheme.primaryGradient,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtils.format(balance),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  label: 'Income',
                  value: CurrencyUtils.format(income, compact: true),
                ),
              ),
              Expanded(
                child: _BalanceStat(
                  label: 'Expenses',
                  value: CurrencyUtils.format(expense, compact: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({required this.label, required this.value});

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
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items});

  final List<_FeatureItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: item.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                const Spacer(),
                Text(
                  item.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.totalSaved,
    required this.goalCount,
    required this.transactionCount,
    required this.completedLessons,
  });

  final double totalSaved;
  final int goalCount;
  final int transactionCount;
  final int completedLessons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your progress is syncing across savings, learning, and activity.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ProgressMetric(
                  label: 'Saved',
                  value: CurrencyUtils.format(totalSaved, compact: true),
                ),
              ),
              Expanded(
                child: _ProgressMetric(
                  label: 'Goals',
                  value: '$goalCount active',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ProgressMetric(
                  label: 'Lessons',
                  value: '$completedLessons done',
                ),
              ),
              Expanded(
                child: _ProgressMetric(
                  label: 'Transactions',
                  value: '$transactionCount logged',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.txn});

  final FinancialTransaction txn;

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == 'income';
    final color = isIncome ? AppTheme.success : const Color(0xFFE11D48);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  txn.category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.format(txn.amount),
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
