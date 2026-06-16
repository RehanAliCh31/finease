import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key, this.prefill});

  final FinancialTransaction? prefill;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _type = 'expense';
  String _category = 'Groceries';
  DateTime _date = DateTime.now();
  DateTime? _deadline;
  bool _saving = false;
  Timer? _impactDebounce;
  TransactionImpactPreview? _impact;
  String? _impactError;

  static const List<_CategoryOption> _categories = [
    _CategoryOption(
      'Groceries',
      Icons.local_grocery_store_rounded,
      Color(0xFFFF6B35),
    ),
    _CategoryOption(
      'Transport',
      Icons.directions_car_rounded,
      AppTheme.primary,
    ),
    _CategoryOption('Education', Icons.school_rounded, Color(0xFF0099CC)),
    _CategoryOption('Electricity', Icons.bolt_rounded, Color(0xFFFF4B5C)),
    _CategoryOption(
      'Healthcare',
      Icons.health_and_safety_rounded,
      AppTheme.success,
    ),
    _CategoryOption('Entertainment', Icons.movie_rounded, Color(0xFF8B5CF6)),
    _CategoryOption('Savings', Icons.savings_rounded, AppTheme.success),
    _CategoryOption('Salary', Icons.work_rounded, AppTheme.success),
    _CategoryOption('Others', Icons.category_rounded, Color(0xFF6B7280)),
  ];

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;
    if (prefill != null) {
      _type = prefill.type == 'income' ? 'income' : 'expense';
      _category = prefill.category;
      _date = DateTime.now();
      _titleController.text = prefill.title;
      _amountController.text = CurrencyUtils.exact(prefill.amount);
      _noteController.text = prefill.note;
      if (!_availableCategories.any((item) => item.name == _category)) {
        _category = _availableCategories.first.name;
      }
    }
    _titleController.addListener(_scheduleImpactPreview);
    _amountController.addListener(_scheduleImpactPreview);
    if (prefill != null) {
      _scheduleImpactPreview();
    }
  }

  @override
  void dispose() {
    _impactDebounce?.cancel();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _Header(onBack: () => Navigator.pop(context)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 116),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _TypeSegmented(
                      value: _type,
                      onChanged: (value) {
                        setState(() {
                          _type = value;
                          if (!_availableCategories.any(
                            (item) => item.name == _category,
                          )) {
                            _category = _availableCategories.first.name;
                          }
                        });
                        _scheduleImpactPreview();
                      },
                    ),
                    const SizedBox(height: 16),
                    _AmountField(controller: _amountController, type: _type),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Description',
                      child: TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Grocery shopping',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter a description'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DescriptionChips(
                      type: _type,
                      onSelected: (value) {
                        _titleController.text = value;
                        _titleController.selection = TextSelection.collapsed(
                          offset: value.length,
                        );
                        _scheduleImpactPreview();
                      },
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Category',
                      child: _CategoryButton(
                        category: _selectedCategory,
                        onTap: _openCategorySheet,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerButton(
                            label: DateFormat('MMM d, yyyy').format(_date),
                            icon: Icons.calendar_month_rounded,
                            onTap: () => _pickDate(isDeadline: false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerButton(
                            label: _deadline == null
                                ? 'No reminder'
                                : DateFormat('MMM d').format(_deadline!),
                            icon: Icons.notifications_active_rounded,
                            onTap: () => _pickDate(isDeadline: true),
                            onClear: _deadline == null
                                ? null
                                : () {
                                    setState(() => _deadline = null);
                                    _scheduleImpactPreview();
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ImpactPreview(
                      impact: _impact,
                      error: _impactError,
                      type: _type,
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Note',
                      optional: true,
                      child: TextField(
                        controller: _noteController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Add context if needed',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 38),
                            child: Icon(Icons.notes_rounded),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SaveBar(
        type: _type,
        saving: _saving,
        onSave: _saving ? null : _submit,
      ),
    );
  }

  _CategoryOption get _selectedCategory {
    return _availableCategories.firstWhere(
      (item) => item.name == _category,
      orElse: () => _availableCategories.first,
    );
  }

  List<_CategoryOption> get _availableCategories {
    if (_type == 'income') {
      return _categories
          .where((item) => item.name == 'Salary' || item.name == 'Others')
          .toList();
    }
    return _categories.where((item) => item.name != 'Salary').toList();
  }

  void _openCategorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategorySheet(
        categories: _availableCategories,
        selected: _category,
        onSelected: (value) {
          setState(() => _category = value);
          _scheduleImpactPreview();
        },
      ),
    );
  }

  Future<void> _pickDate({required bool isDeadline}) async {
    final initial = isDeadline ? (_deadline ?? _date) : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isDeadline) {
        _deadline = picked;
      } else {
        _date = picked;
      }
    });
    _scheduleImpactPreview();
  }

  void _scheduleImpactPreview() {
    _impactDebounce?.cancel();
    _impactDebounce = Timer(const Duration(milliseconds: 350), _loadImpact);
  }

  Future<void> _loadImpact() async {
    final firestoreService = context.read<AuthService>().firestoreService;
    final amount = double.tryParse(_amountController.text.trim());
    if (firestoreService == null ||
        amount == null ||
        amount <= 0 ||
        _titleController.text.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _impact = null;
        _impactError = null;
      });
      return;
    }

    try {
      final impact = await firestoreService.previewTransactionImpact(
        _draft(amount),
      );
      if (!mounted) return;
      setState(() {
        _impact = impact;
        _impactError = null;
      });
    } on FinanceValidationException catch (error) {
      if (!mounted) return;
      setState(() {
        _impact = null;
        _impactError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _impact = null;
        _impactError = 'Live finance check is unavailable.';
      });
    }
  }

  FinancialTransaction _draft(double amount) {
    return FinancialTransaction(
      id: '',
      title: _titleController.text.trim(),
      amount: amount,
      date: _date,
      category: _category,
      type: _type,
      note: _noteController.text.trim(),
      deadline: _deadline,
      linkedBudgetCategory: _category,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0 || !amount.isFinite) {
      _showError('Amount must be greater than zero.');
      return;
    }

    final firestoreService = context.read<AuthService>().firestoreService;
    if (firestoreService == null) {
      _showError('Please log in before adding a transaction.');
      return;
    }

    setState(() => _saving = true);
    final transaction = _draft(amount);

    try {
      await firestoreService.addTransaction(transaction);
    } on SavingsUsageRequiredException catch (error) {
      if (!mounted) return;
      final approved = await _confirmSavingsUse(error.requiredAmount);
      if (approved != true) {
        setState(() => _saving = false);
        return;
      }
      try {
        await firestoreService.addTransaction(
          transaction,
          allowSavingsWithdrawal: true,
        );
      } on FinanceValidationException catch (secondError) {
        if (mounted) _showError(secondError.message);
        if (mounted) setState(() => _saving = false);
        return;
      }
    } on FinanceValidationException catch (error) {
      if (mounted) _showError(error.message);
      if (mounted) setState(() => _saving = false);
      return;
    } catch (_) {
      if (mounted) _showError('Could not save this transaction.');
      if (mounted) setState(() => _saving = false);
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _deadline == null
              ? 'Transaction saved'
              : 'Transaction saved with reminder',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<bool?> _confirmSavingsUse(double amount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Use savings?'),
        content: Text(
          'This needs ${CurrencyUtils.format(amount)} from Savings. Continue?',
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
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppTheme.textPrimaryFor(context),
          tooltip: 'Back',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Add transaction',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeSegmented extends StatelessWidget {
  const _TypeSegmented({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.mutedFillFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _TypeOption(
            label: 'Expense',
            icon: Icons.north_east_rounded,
            selected: value == 'expense',
            color: AppTheme.error,
            onTap: () => onChanged('expense'),
          ),
          _TypeOption(
            label: 'Income',
            icon: Icons.south_west_rounded,
            selected: value == 'income',
            color: AppTheme.success,
            onTap: () => onChanged('income'),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : AppTheme.textSecondaryFor(context),
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected
                      ? Colors.white
                      : AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.type});

  final TextEditingController controller;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = type == 'income'
        ? AppTheme.success
        : AppTheme.primaryFor(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'PKR',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.optional = false,
  });

  final String label;
  final Widget child;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimaryFor(context),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Text(
                'optional',
                style: GoogleFonts.inter(
                  color: AppTheme.textHintFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DescriptionChips extends StatelessWidget {
  const _DescriptionChips({required this.type, required this.onSelected});

  final String type;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = type == 'income'
        ? const ['Salary', 'Freelance payment', 'Family support']
        : const ['Groceries', 'Transport', 'Electricity bill', 'School fees'];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return ActionChip(
            label: Text(option),
            avatar: const Icon(Icons.flash_on_rounded, size: 15),
            onPressed: () => onSelected(option),
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.category, required this.onTap});

  final _CategoryOption category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderFor(context)),
        ),
        child: Row(
          children: [
            _IconBadge(category: category),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textSecondaryFor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryFor(context), size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimaryFor(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.textHintFor(context),
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImpactPreview extends StatelessWidget {
  const _ImpactPreview({
    required this.impact,
    required this.error,
    required this.type,
  });

  final TransactionImpactPreview? impact;
  final String? error;
  final String type;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return _InlineNotice(
        icon: Icons.error_outline_rounded,
        color: AppTheme.error,
        title: 'Check failed',
        body: error!,
      );
    }

    final currentImpact = impact;
    if (currentImpact == null) {
      return _InlineNotice(
        icon: Icons.auto_graph_rounded,
        color: AppTheme.primaryFor(context),
        title: 'Live check',
        body:
            'Enter amount and description to preview budget and savings impact.',
      );
    }

    if (type == 'income') {
      return _InlineNotice(
        icon: Icons.check_circle_outline_rounded,
        color: AppTheme.success,
        title: 'Income update',
        body:
            'Monthly income becomes ${CurrencyUtils.format(currentImpact.periodIncome)}.',
      );
    }

    if (currentImpact.needsSavings) {
      return _InlineNotice(
        icon: Icons.savings_outlined,
        color: AppTheme.error,
        title: 'Savings needed',
        body:
            'This may use ${CurrencyUtils.format(currentImpact.requiredSavings)} from Savings.',
      );
    }

    if (currentImpact.warnings.isNotEmpty) {
      return _InlineNotice(
        icon: Icons.warning_amber_rounded,
        color: AppTheme.warning,
        title: 'Budget warning',
        body: currentImpact.warnings.first,
      );
    }

    return _InlineNotice(
      icon: Icons.check_circle_outline_rounded,
      color: AppTheme.success,
      title: 'Looks okay',
      body:
          'Projected expenses: ${CurrencyUtils.format(currentImpact.projectedExpenses)}.',
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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

class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<_CategoryOption> categories;
  final String selected;
  final ValueChanged<String> onSelected;

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
          Text(
            'Category',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selected == category.name;
              return InkWell(
                onTap: () {
                  onSelected(category.name);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withValues(alpha: 0.12)
                        : AppTheme.mutedFillFor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? category.color
                          : AppTheme.borderFor(context),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IconBadge(category: category),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimaryFor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.category});

  final _CategoryOption category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(category.icon, color: category.color, size: 20),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.type,
    required this.saving,
    required this.onSave,
  });

  final String type;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          border: Border(top: BorderSide(color: AppTheme.borderFor(context))),
          boxShadow: AppTheme.softShadow,
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    type == 'income'
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                  ),
            label: Text(
              saving
                  ? 'Saving...'
                  : 'Save ${type == 'income' ? 'income' : 'expense'}',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'income'
                  ? AppTheme.success
                  : AppTheme.primaryFor(context),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}
