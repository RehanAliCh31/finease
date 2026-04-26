import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../models/transaction.dart';
import '../chatbot/chatbot_page.dart';
import '../loans/loan_simulator_page.dart';
import '../welfare/welfare_programs_page.dart';
import '../forum/community_forum_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final String _profileImageUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuBPLeW6cibJTqudsCzS2Ql69cVkmZpts5-djYjsJ2pmGffAh8kSWY0QTpHIUiTj-1yim0D9OqG_lQFpvcLx-Ob4XpAOsBrv24TSvAVUz8LAiW6f4IdM2L8xG3dNn9Dy-DQshp-mJrd2TjnobaPHzNKqR7jQ5S05IFcP2bDC51dtw6ne35dpjAjiclWqrJGU7dpKOX8d__S86OE5LwJupNraYqI3NPI19BqwM-hePGywFAC51DrH6DVN0wKKN7qSq-jMeMzJPcr7-AbO";

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = authService.firestoreService;
    final theme = Theme.of(context);
    
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
            _buildTopBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildBalanceCard(context, primaryColor, secondaryColor),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Recent Transactions', () {}),
                  const SizedBox(height: 16),
                  if (firestoreService != null)
                    StreamBuilder<List<FinancialTransaction>>(
                      stream: firestoreService.getTransactions(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ));
                        }
                        
                        final transactions = snapshot.data ?? [];
                        if (transactions.isEmpty) {
                          return _buildEmptyState();
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionItem(transactions[index], theme);
                          },
                        );
                      },
                    )
                  else
                    const Center(child: Text('Login to see transactions')),
                  const SizedBox(height: 120), // Bottom padding for nav bar
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          onPressed: () => _showAddTransactionDialog(context, firestoreService),
          backgroundColor: primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
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
                    child: Image.network(_profileImageUrl, fit: BoxFit.cover),
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
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Alex Morgan',
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, Color primaryColor, Color secondaryColor) {
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
            color: primaryColor.withOpacity(0.3),
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
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$48,250.00',
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
                    _buildBalanceStat('Income', '+\$4,250.00', const Color(0xFF10B981)),
                    Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
                    _buildBalanceStat('Expenses', '-\$1,120.00', Colors.orangeAccent),
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
            color: Colors.white.withOpacity(0.6),
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

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.auto_awesome, 'FinEase AI', const Color(0xFFEEF2FF), const Color(0xFF4F46E5), () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotPage()));
        }),
        _buildActionItem(Icons.calculate_rounded, 'Loans', const Color(0xFFECFDF5), const Color(0xFF059669), () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoanSimulatorPage()));
        }),
        _buildActionItem(Icons.volunteer_activism_rounded, 'Welfare', const Color(0xFFFFF7ED), const Color(0xFFD97706), () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const WelfareProgramsPage()));
        }),
        _buildActionItem(Icons.forum_rounded, 'Forum', const Color(0xFFF1F5F9), const Color(0xFF475569), () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityForumPage()));
        }),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap) {
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
                )
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

  Widget _buildTransactionItem(FinancialTransaction t, ThemeData theme) {
    final isIncome = t.type == 'income';
    final amountColor = isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48);
    final bgColor = isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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
              isIncome ? Icons.keyboard_double_arrow_down_rounded : Icons.keyboard_double_arrow_up_rounded,
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
                  DateFormat('MMM dd, yyyy').format(t.date),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Color(0xFF64748B),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, dynamic firestoreService) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'New Transaction',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'What for?',
                  labelStyle: GoogleFonts.inter(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'How much?',
                  prefixText: '\$ ',
                  labelStyle: GoogleFonts.inter(color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) => Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'Income',
                        type == 'income',
                        const Color(0xFF059669),
                        () => setModalState(() => type = 'income'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTypeButton(
                        'Expense',
                        type == 'expense',
                        const Color(0xFFE11D48),
                        () => setModalState(() => type = 'expense'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (firestoreService != null) {
                      await firestoreService.addTransaction(FinancialTransaction(
                        id: '',
                        title: titleController.text,
                        amount: double.tryParse(amountController.text) ?? 0,
                        date: DateTime.now(),
                        category: 'General',
                        type: type,
                      ));
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3192),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Transaction',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, bool isSelected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
