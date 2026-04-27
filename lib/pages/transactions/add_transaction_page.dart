import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/transaction.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _type = 'expense';
  String _category = 'Food';
  bool _saving = false;

  late final AnimationController _anim;
  late final Animation<double> _fadeAnim;

  final List<_Cat> _categories = const [
    _Cat('Food',       Icons.restaurant_rounded,         Color(0xFFFF6B35)),
    _Cat('Transport',  Icons.directions_car_rounded,      Color(0xFF2E3192)),
    _Cat('Shopping',   Icons.shopping_bag_rounded,        Color(0xFF8B5CF6)),
    _Cat('Health',     Icons.health_and_safety_rounded,   Color(0xFF06C270)),
    _Cat('Education',  Icons.school_rounded,              Color(0xFF0099CC)),
    _Cat('Bills',      Icons.receipt_long_rounded,        Color(0xFFFF4B5C)),
    _Cat('Salary',     Icons.work_rounded,                Color(0xFF06C270)),
    _Cat('General',    Icons.category_rounded,            Color(0xFF6B7A99)),
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'New Transaction',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Type Toggle ──────────────────────────────────────────
                _TypeToggle(
                  value: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 24),

                // ── Amount ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: _type == 'income'
                            ? [const Color(0xFF059669), const Color(0xFF047857)]
                            : [const Color(0xFF2E3192), const Color(0xFF3D44B0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount',
                          style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('\$',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                hintText: '0.00',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter amount';
                                if (double.tryParse(v) == null) return 'Invalid number';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ────────────────────────────────────────────────
                _FieldLabel('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Grocery shopping',
                    prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.textSecondary),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter a description' : null,
                ),
                const SizedBox(height: 20),

                // ── Category ─────────────────────────────────────────────
                _FieldLabel('Category'),
                const SizedBox(height: 10),
                _CategoryGrid(
                  categories: _categories,
                  selected: _category,
                  onSelect: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: 20),

                // ── Note ─────────────────────────────────────────────────
                _FieldLabel('Note (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes_rounded, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Submit ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _type == 'income'
                          ? AppTheme.success
                          : AppTheme.primary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _type == 'income'
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  'Save ${_type == 'income' ? 'Income' : 'Expense'}',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final fs = authService.firestoreService;
    if (fs != null) {
      await fs.addTransaction(FinancialTransaction(
        id: '',
        title: _titleCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        date: DateTime.now(),
        category: _category,
        type: _type,
      ));
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction saved ✓'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

class _Cat {
  final String name;
  final IconData icon;
  final Color color;
  const _Cat(this.name, this.icon, this.color);
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      );
}

class _TypeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _ToggleBtn(
              label: 'Expense',
              icon: Icons.arrow_upward_rounded,
              selected: value == 'expense',
              color: AppTheme.error,
              onTap: () => onChanged('expense')),
          _ToggleBtn(
              label: 'Income',
              icon: Icons.arrow_downward_rounded,
              selected: value == 'income',
              color: AppTheme.success,
              onTap: () => onChanged('income')),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<_Cat> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryGrid(
      {required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories
          .map((cat) => GestureDetector(
                onTap: () => onSelect(cat.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == cat.name
                        ? cat.color.withValues(alpha: 0.15)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected == cat.name ? cat.color : AppTheme.border,
                      width: selected == cat.name ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon,
                          color: selected == cat.name
                              ? cat.color
                              : AppTheme.textSecondary,
                          size: 16),
                      const SizedBox(width: 6),
                      Text(
                        cat.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected == cat.name
                              ? cat.color
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
