import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/transaction.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  String _filter = 'all';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final fs = authService.firestoreService;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'All Transactions',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                _buildChip('All', 'all'),
                const SizedBox(width: 8),
                _buildChip('Income', 'income'),
                const SizedBox(width: 8),
                _buildChip('Expense', 'expense'),
              ],
            ),
          ),
          Expanded(
            child: fs != null
                ? StreamBuilder<List<FinancialTransaction>>(
                    stream: fs.getTransactions(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var txns = snap.data ?? [];
                      if (_filter != 'all') {
                        txns = txns.where((t) => t.type == _filter).toList();
                      }
                      if (_searchQuery.isNotEmpty) {
                        txns = txns
                            .where(
                              (t) =>
                                  t.title.toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  t.category.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                            )
                            .toList();
                      }
                      if (txns.isEmpty) {
                        return Center(
                          child: Text(
                            'No transactions found',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: txns.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final t = txns[i];
                          final isIncome = t.type == 'income';
                          final color = isIncome
                              ? AppTheme.success
                              : AppTheme.error;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isIncome
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${t.category} · ${DateFormat('MMM dd, yyyy').format(t.date)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  )
                : const Center(child: Text('Please log in')),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
