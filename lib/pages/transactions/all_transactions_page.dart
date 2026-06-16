import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/budget_plan.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import 'add_transaction_page.dart';

enum _PeriodMode { daily, weekly, monthly, yearly }

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _categoryFilter = 'all';
  _PeriodMode _periodMode = _PeriodMode.monthly;
  DateTime _anchorDate = DateTime.now();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        bottom: false,
        child: firestoreService == null
            ? const Center(child: Text('Please log in'))
            : StreamBuilder<List<FinancialTransaction>>(
                stream: firestoreService.getTransactions(),
                builder: (context, transactionSnapshot) {
                  if (transactionSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allTransactions =
                      transactionSnapshot.data ??
                      const <FinancialTransaction>[];
                  return StreamBuilder<List<BudgetPlan>>(
                    stream: firestoreService.getBudgetPlans(
                      monthKey: _monthKey(_anchorDate),
                    ),
                    initialData: const [],
                    builder: (context, budgetSnapshot) {
                      final budgets = budgetSnapshot.data ?? const [];
                      final periodTransactions = allTransactions
                          .where((item) => _isInPeriod(item.date))
                          .toList();
                      final analytics = _TransactionSummary.from(
                        periodTransactions,
                        budgets,
                      );
                      final categories = {
                        for (final txn in periodTransactions) txn.category,
                      }.where((item) => item.isNotEmpty).toList()..sort();
                      final visibleTransactions = _applyFilters(
                        periodTransactions,
                      );

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Header(onAdd: _openAddTransaction),
                                  const SizedBox(height: 18),
                                  _PeriodCard(
                                    mode: _periodMode,
                                    label: _periodLabel(),
                                    onPrevious: () => setState(
                                      () => _anchorDate = _shiftPeriod(-1),
                                    ),
                                    onNext: () => setState(
                                      () => _anchorDate = _shiftPeriod(1),
                                    ),
                                    onModeChanged: (mode) => setState(() {
                                      _periodMode = mode;
                                      _anchorDate = DateTime.now();
                                    }),
                                  ),
                                  const SizedBox(height: 14),
                                  _SummaryCard(summary: analytics),
                                  const SizedBox(height: 14),
                                  _SearchAndFilter(
                                    controller: _searchController,
                                    activeFilterCount: _activeFilterCount,
                                    onChanged: (value) => setState(
                                      () => _searchQuery = value.toLowerCase(),
                                    ),
                                    onClear: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                    onFilterTap: () =>
                                        _openFilterSheet(categories),
                                  ),
                                  const SizedBox(height: 18),
                                  _SectionTitle(
                                    title: 'History',
                                    subtitle:
                                        '${visibleTransactions.length} shown',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (visibleTransactions.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(
                                onAdd: _openAddTransaction,
                                onClear: _activeFilterCount > 0
                                    ? _clearFilters
                                    : null,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                12,
                                20,
                                116,
                              ),
                              sliver: SliverList.separated(
                                itemCount: visibleTransactions.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final transaction =
                                      visibleTransactions[index];
                                  return _TransactionTile(
                                    transaction: transaction,
                                    overBudget: analytics.overspentCategory(
                                      transaction.linkedBudgetCategory ??
                                          transaction.category,
                                    ),
                                    onTap: () => _openTransactionSheet(
                                      transaction,
                                      onRepeat: () =>
                                          _openAddTransaction(transaction),
                                      onDelete: transaction.type == 'transfer'
                                          ? null
                                          : () => _deleteTransaction(
                                              firestoreService,
                                              transaction,
                                            ),
                                    ),
                                    onDelete: transaction.type == 'transfer'
                                        ? null
                                        : () => _deleteTransaction(
                                            firestoreService,
                                            transaction,
                                          ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        backgroundColor: AppTheme.primaryFor(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  int get _activeFilterCount =>
      (_typeFilter != 'all' ? 1 : 0) +
      (_categoryFilter != 'all' ? 1 : 0) +
      (_searchQuery.isNotEmpty ? 1 : 0);

  List<FinancialTransaction> _applyFilters(List<FinancialTransaction> txns) {
    var filtered = txns;
    if (_typeFilter != 'all') {
      filtered = filtered.where((txn) => txn.type == _typeFilter).toList();
    }
    if (_categoryFilter != 'all') {
      filtered = filtered
          .where((txn) => txn.category == _categoryFilter)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (txn) =>
                txn.title.toLowerCase().contains(_searchQuery) ||
                txn.category.toLowerCase().contains(_searchQuery) ||
                txn.note.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }
    return filtered;
  }

  bool _isInPeriod(DateTime date) {
    switch (_periodMode) {
      case _PeriodMode.daily:
        return DateUtils.isSameDay(date, _anchorDate);
      case _PeriodMode.weekly:
        final range = _weekRange(_anchorDate);
        return !date.isBefore(range.$1) && date.isBefore(range.$2);
      case _PeriodMode.monthly:
        return date.year == _anchorDate.year && date.month == _anchorDate.month;
      case _PeriodMode.yearly:
        return date.year == _anchorDate.year;
    }
  }

  DateTime _shiftPeriod(int step) {
    switch (_periodMode) {
      case _PeriodMode.daily:
        return _anchorDate.add(Duration(days: step));
      case _PeriodMode.weekly:
        return _anchorDate.add(Duration(days: 7 * step));
      case _PeriodMode.monthly:
        return DateTime(_anchorDate.year, _anchorDate.month + step);
      case _PeriodMode.yearly:
        return DateTime(_anchorDate.year + step);
    }
  }

  String _periodLabel() {
    switch (_periodMode) {
      case _PeriodMode.daily:
        return DateFormat('MMM d, yyyy').format(_anchorDate);
      case _PeriodMode.weekly:
        final range = _weekRange(_anchorDate);
        final end = range.$2.subtract(const Duration(days: 1));
        return '${DateFormat('MMM d').format(range.$1)} - ${DateFormat('MMM d').format(end)}';
      case _PeriodMode.monthly:
        return DateFormat('MMMM yyyy').format(_anchorDate);
      case _PeriodMode.yearly:
        return '${_anchorDate.year}';
    }
  }

  (DateTime, DateTime) _weekRange(DateTime date) {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
    return (start, start.add(const Duration(days: 7)));
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  void _openAddTransaction([FinancialTransaction? prefill]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTransactionPage(prefill: prefill)),
    );
  }

  void _openTransactionSheet(
    FinancialTransaction transaction, {
    required VoidCallback onRepeat,
    required VoidCallback? onDelete,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransactionDetailSheet(
        transaction: transaction,
        onRepeat: onRepeat,
        onDelete: onDelete,
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _typeFilter = 'all';
      _categoryFilter = 'all';
    });
  }

  void _openFilterSheet(List<String> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        typeFilter: _typeFilter,
        categoryFilter: _categoryFilter,
        categories: categories,
        onTypeChanged: (value) => setState(() => _typeFilter = value),
        onCategoryChanged: (value) => setState(() => _categoryFilter = value),
        onClear: _clearFilters,
      ),
    );
  }

  Future<void> _deleteTransaction(
    FirestoreService firestoreService,
    FinancialTransaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('This removes "${transaction.title}" from your totals.'),
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
    if (confirmed != true || !mounted) return;

    try {
      await firestoreService.deleteTransaction(transaction.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('"${transaction.title}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } on FinanceValidationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _TransactionSummary {
  const _TransactionSummary({
    required this.income,
    required this.expenses,
    required this.transfers,
    required this.budgeted,
    required this.categorySpend,
    required this.categoryBudgets,
  });

  final double income;
  final double expenses;
  final double transfers;
  final double budgeted;
  final Map<String, double> categorySpend;
  final Map<String, double> categoryBudgets;

  factory _TransactionSummary.from(
    List<FinancialTransaction> transactions,
    List<BudgetPlan> budgets,
  ) {
    final categorySpend = <String, double>{};
    for (final txn in transactions.where((txn) => txn.type == 'expense')) {
      final category = txn.linkedBudgetCategory?.isNotEmpty == true
          ? txn.linkedBudgetCategory!
          : txn.category;
      categorySpend[category] = (categorySpend[category] ?? 0) + txn.amount;
    }
    final categoryBudgets = <String, double>{};
    for (final budget in budgets) {
      categoryBudgets[budget.category] =
          (categoryBudgets[budget.category] ?? 0) + budget.allocatedAmount;
    }
    return _TransactionSummary(
      income: transactions
          .where((txn) => txn.type == 'income')
          .fold<double>(0, (sum, txn) => sum + txn.amount),
      expenses: transactions
          .where((txn) => txn.type == 'expense')
          .fold<double>(0, (sum, txn) => sum + txn.amount),
      transfers: transactions
          .where((txn) => txn.type == 'transfer')
          .fold<double>(0, (sum, txn) => sum + txn.amount),
      budgeted: budgets.fold<double>(
        0,
        (sum, budget) => sum + budget.allocatedAmount,
      ),
      categorySpend: categorySpend,
      categoryBudgets: categoryBudgets,
    );
  }

  double get balance => income - expenses;
  double get remainingBudget => (budgeted - expenses).clamp(0, double.infinity);

  bool overspentCategory(String category) {
    if (category.isEmpty) return false;
    final categoryBudget = categoryBudgets[category] ?? 0;
    return categoryBudget > 0 &&
        (categorySpend[category] ?? 0) > categoryBudget;
  }

  MapEntry<String, double>? get topExpenseCategory {
    if (categorySpend.isEmpty) return null;
    final entries = categorySpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  double budgetForCategory(String category) => categoryBudgets[category] ?? 0;
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppTheme.textPrimaryFor(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Transactions',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          color: Colors.white,
          tooltip: 'Add transaction',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryFor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.mode,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onModeChanged,
  });

  final _PeriodMode mode;
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<_PeriodMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: _PeriodMode.values.map((item) {
              final selected = mode == item;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => onModeChanged(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryFor(context)
                            : AppTheme.mutedFillFor(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.name[0].toUpperCase() + item.name.substring(1),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondaryFor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final _TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Income',
                  value: CurrencyUtils.format(summary.income),
                  color: AppTheme.success,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Spent',
                  value: CurrencyUtils.format(summary.expenses),
                  color: AppTheme.error,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Left',
                  value: CurrencyUtils.format(summary.balance),
                  color: summary.balance >= 0
                      ? AppTheme.primary
                      : AppTheme.error,
                ),
              ),
            ],
          ),
          if (summary.budgeted > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Budget left',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  CurrencyUtils.format(summary.remainingBudget),
                  style: GoogleFonts.plusJakartaSans(
                    color: summary.remainingBudget > 0
                        ? AppTheme.success
                        : AppTheme.error,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
          if (summary.topExpenseCategory != null) ...[
            const SizedBox(height: 14),
            _TopCategoryInsight(summary: summary),
          ],
        ],
      ),
    );
  }
}

class _TopCategoryInsight extends StatelessWidget {
  const _TopCategoryInsight({required this.summary});

  final _TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    final entry = summary.topExpenseCategory!;
    final budget = summary.budgetForCategory(entry.key);
    final over = budget > 0 && entry.value > budget;
    final color = over ? AppTheme.warning : AppTheme.primaryFor(context);
    final message = budget > 0
        ? '${CurrencyUtils.format(entry.value)} of ${CurrencyUtils.format(budget)} planned'
        : '${CurrencyUtils.format(entry.value)} spent without a category budget';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.isDark(context) ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            over ? Icons.warning_amber_rounded : Icons.query_stats_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most spent: ${entry.key}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.controller,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search title, category, note',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Clear search',
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune_rounded),
              color: AppTheme.primaryFor(context),
              tooltip: 'Filters',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceFor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppTheme.borderFor(context)),
                ),
              ),
            ),
            if (activeFilterCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: AppTheme.primaryFor(context),
                  child: Text(
                    '$activeFilterCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.typeFilter,
    required this.categoryFilter,
    required this.categories,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onClear,
  });

  final String typeFilter;
  final String categoryFilter;
  final List<String> categories;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderFor(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: 'Filters', subtitle: ''),
          const SizedBox(height: 14),
          _FilterGroup(
            title: 'Type',
            values: const ['all', 'income', 'expense', 'transfer'],
            selected: typeFilter,
            labelFor: _typeLabel,
            onChanged: onTypeChanged,
          ),
          const SizedBox(height: 16),
          _FilterGroup(
            title: 'Category',
            values: ['all', ...categories],
            selected: categoryFilter,
            labelFor: (value) => value == 'all' ? 'All categories' : value,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    onClear();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Show results'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.onChanged,
  });

  final String title;
  final List<String> values;
  final String selected;
  final String Function(String value) labelFor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimaryFor(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => ActionChip(
                  onPressed: () => onChanged(value),
                  label: Text(labelFor(value)),
                  avatar: selected == value
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 17,
                        )
                      : null,
                  backgroundColor: selected == value
                      ? AppTheme.primaryFor(context)
                      : AppTheme.mutedFillFor(context),
                  labelStyle: GoogleFonts.inter(
                    color: selected == value
                        ? Colors.white
                        : AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.overBudget,
    required this.onTap,
    required this.onDelete,
  });

  final FinancialTransaction transaction;
  final bool overBudget;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(transaction.type);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: _SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_typeIcon(transaction.type), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimaryFor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${transaction.category} - ${DateFormat('MMM d').format(transaction.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (overBudget && transaction.type == 'expense') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Budget pressure',
                      style: GoogleFonts.inter(
                        color: AppTheme.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${transaction.type == 'income' ? '+' : '-'}${CurrencyUtils.format(transaction.amount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppTheme.textHintFor(context),
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({
    required this.transaction,
    required this.onRepeat,
    required this.onDelete,
  });

  final FinancialTransaction transaction;
  final VoidCallback onRepeat;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(transaction.type);
    final amountPrefix = transaction.type == 'income' ? '+' : '-';
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon(transaction.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_typeLabel(transaction.type)} - ${DateFormat('MMM d, yyyy').format(transaction.date)}',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$amountPrefix${CurrencyUtils.format(transaction.amount)}',
                style: GoogleFonts.plusJakartaSans(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailLine(label: 'Category', value: transaction.category),
          if ((transaction.linkedBudgetCategory ?? '').isNotEmpty &&
              transaction.linkedBudgetCategory != transaction.category)
            _DetailLine(
              label: 'Budget category',
              value: transaction.linkedBudgetCategory!,
            ),
          if (transaction.deadline != null)
            _DetailLine(
              label: 'Reminder',
              value: DateFormat('MMM d, yyyy').format(transaction.deadline!),
            ),
          if (transaction.note.trim().isNotEmpty)
            _DetailLine(label: 'Note', value: transaction.note.trim()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onRepeat();
                  },
                  icon: const Icon(Icons.repeat_rounded),
                  label: const Text('Repeat'),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete!();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd, required this.onClear});

  final VoidCallback onAdd;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              color: AppTheme.textHintFor(context),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No transactions found',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w900,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              onClear == null
                  ? 'Add your first income or expense.'
                  : 'Try clearing filters or changing the period.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            if (onClear != null)
              TextButton(onPressed: onClear, child: const Text('Clear filters'))
            else
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add transaction'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderFor(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}

String _typeLabel(String value) {
  return switch (value) {
    'income' => 'Income',
    'expense' => 'Expense',
    'transfer' => 'Transfer',
    _ => 'All types',
  };
}

IconData _typeIcon(String type) {
  return switch (type) {
    'income' => Icons.south_west_rounded,
    'transfer' => Icons.swap_horiz_rounded,
    _ => Icons.north_east_rounded,
  };
}

Color _typeColor(String type) {
  return switch (type) {
    'income' => AppTheme.success,
    'transfer' => AppTheme.primary,
    _ => AppTheme.error,
  };
}
