import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../models/transaction.dart';
import '../../theme/app_theme.dart';
import '../chatbot/chatbot_page.dart';
import '../loans/loan_simulator_page.dart';
import '../welfare/welfare_programs_page.dart';
import '../forum/community_forum_page.dart';
import '../notifications/notifications_page.dart';
import '../transactions/add_transaction_page.dart';
import '../transactions/all_transactions_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = authService.firestoreService;
    final user = authService.user;
    final displayName = user?.displayName?.split(' ').first ?? 
        user?.email?.split('@').first ?? 'User';
    final photoUrl = user?.photoURL;

    const Color primaryColor = Color(0xFF2E3192);
    const Color secondaryColor = Color(0xFF1BFFFF);
    const Color surfaceColor = Color(0xFFF8F9FF);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Top Bar ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildTopBar(context, displayName, photoUrl),
            ),
            // ── Balance Card ─────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: firestoreService != null
                    ? StreamBuilder<List<FinancialTransaction>>(
                        stream: firestoreService.getTransactions(),
                        builder: (ctx, snap) {
                          final txns = snap.data ?? [];
                          final income = txns
                              .where((t) => t.type == 'income')
                              .fold(0.0, (s, t) => s + t.amount);
                          final expense = txns
                              .where((t) => t.type == 'expense')
                              .fold(0.0, (s, t) => s + t.amount);
                          return _buildBalanceCard(
                            context,
                            primaryColor,
                            secondaryColor,
                            balance: income - expense,
                            income: income,
                            expense: expense,
                          );
                        },
                      )
                    : _buildBalanceCard(
                        context,
                        primaryColor,
                        secondaryColor,
                        balance: 0,
                        income: 0,
                        expense: 0,
                      ),
              ),
            ),
            // ── Quick Actions ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildQuickActions(context),
              ),
            ),
            // ── Recent Transactions Header ───────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Recent Transactions',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllTransactionsPage(),
                    ),
                  ),
                ),
              ),
            ),
            // ── Recent Transactions List ────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: firestoreService != null
                  ? StreamBuilder<List<FinancialTransaction>>(
                      stream: firestoreService.getTransactions(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SliverToBoxAdapter(
                            child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final txns = (snap.data ?? []).take(5).toList();
                        if (txns.isEmpty) {
                          return SliverToBoxAdapter(
                            child: _buildEmptyState(),
                          );
                        }
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildTransactionItem(
                              txns[i],
                              Theme.of(ctx),
                            ),
                            childCount: txns.length,
                          ),
                        );
                      },
                    )
                  : const SliverToBoxAdapter(
                      child: Center(
                        child: Text('Login to see transactions'),
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionPage()),
          ),
          backgroundColor: primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child:
              const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar(
    BuildContext context,
    String displayName,
    String? photoUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Icon(Icons.person_rounded,
                                color: Colors.white),
                          ),
                        )
                      : const CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Icon(Icons.person_rounded,
                              color: Colors.white, size: 22),
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
                      fontSize: 16,
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF0F172A),
                      size: 24,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Balance Card ───────────────────────────────────────────────────────
  Widget _buildBalanceCard(
    BuildContext context,
    Color primaryColor,
    Color secondaryColor, {
    required double balance,
    required double income,
    required double expense,
  }) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withBlue(200)],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      fmt.format(balance),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBalanceStat(
                      'Income',
                      '+${fmt.format(income)}',
                      const Color(0xFF10B981),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    _buildBalanceStat(
                      'Expenses',
                      '-${fmt.format(expense)}',
                      Colors.orangeAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceStat(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          Icons.auto_awesome,
          'FinEase AI',
          const Color(0xFFEEF2FF),
          const Color(0xFF4F46E5),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotPage()),
          ),
        ),
        _buildActionItem(
          Icons.calculate_rounded,
          'Loans',
          const Color(0xFFECFDF5),
          const Color(0xFF059669),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoanSimulatorPage()),
          ),
        ),
        _buildActionItem(
          Icons.volunteer_activism_rounded,
          'Welfare',
          const Color(0xFFFFF7ED),
          const Color(0xFFD97706),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WelfareProgramsPage()),
          ),
        ),
        _buildActionItem(
          Icons.forum_rounded,
          'Forum',
          const Color(0xFFF1F5F9),
          const Color(0xFF475569),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityForumPage()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: Text(
            'See All',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4F46E5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Transaction Item ───────────────────────────────────────────────────
  Widget _buildTransactionItem(FinancialTransaction t, ThemeData theme) {
    final isIncome = t.type == 'income';
    final amountColor =
        isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48);
    final bgColor =
        isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isIncome
                  ? Icons.keyboard_double_arrow_down_rounded
                  : Icons.keyboard_double_arrow_up_rounded,
              color: amountColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.category} · ${DateFormat('MMM dd, yyyy').format(t.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              color: amountColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
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
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first one',
            style: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
