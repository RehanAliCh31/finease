import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/budget_plan.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';

class LoanSimulatorPage extends StatefulWidget {
  const LoanSimulatorPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LoanSimulatorPage> createState() => _LoanSimulatorPageState();
}

class _LoanSimulatorPageState extends State<LoanSimulatorPage> {
  final _amountController = TextEditingController(text: '1500000');
  final _rateController = TextEditingController(text: '16.5');
  final _tenureController = TextEditingController(text: '36');
  final _incomeController = TextEditingController();
  final AIService _aiService = AIService();

  double _amount = 1500000;
  double _rate = 16.5;
  int _tenure = 36;
  double _monthlyIncome = 0;
  double _profileIncome = 0;
  double _monthSpending = 0;
  double _monthBudget = 0;
  String? _aiInsight;
  bool _aiLoading = false;

  double get _emi {
    if (_amount <= 0 || _tenure <= 0) return 0;
    final monthlyRate = (_rate / 12) / 100;
    if (monthlyRate == 0) return _amount / _tenure;
    return (_amount * monthlyRate * pow(1 + monthlyRate, _tenure)) /
        (pow(1 + monthlyRate, _tenure) - 1);
  }

  double get _totalPayment => _emi * _tenure;
  double get _totalInterest =>
      (_totalPayment - _amount).clamp(0, double.infinity).toDouble();
  double get _recommendedIncome => _emi <= 0 ? 0 : _emi / 0.3;
  double get _effectiveIncome =>
      _monthlyIncome > 0 ? _monthlyIncome : _profileIncome;
  double get _paymentRatio =>
      _effectiveIncome <= 0 ? 0 : _emi / _effectiveIncome;
  double get _incomeLeftAfterEmi => _effectiveIncome - _monthSpending - _emi;
  double get _totalMonthlyBurden => _monthSpending + _emi;
  double get _burdenRatio =>
      _effectiveIncome <= 0 ? 0 : _totalMonthlyBurden / _effectiveIncome;
  double get _costRatio => _amount <= 0 ? 0 : _totalPayment / _amount;

  _LoanVerdict get _verdict {
    if (_amount <= 0 || _tenure <= 0) {
      return const _LoanVerdict(
        label: 'Enter details',
        message: 'Add a loan amount and tenure to calculate affordability.',
        color: AppTheme.warning,
        icon: Icons.edit_rounded,
      );
    }
    if (_effectiveIncome <= 0) {
      return const _LoanVerdict(
        label: 'Income needed',
        message:
            'Add or edit monthly income to judge whether the EMI fits your real cash flow.',
        color: AppTheme.warning,
        icon: Icons.info_outline_rounded,
      );
    }
    if (_incomeLeftAfterEmi < 0 && _effectiveIncome > 0) {
      return const _LoanVerdict(
        label: 'Risky',
        message:
            'This EMI pushes your current month below zero after spending.',
        color: AppTheme.error,
        icon: Icons.report_problem_rounded,
      );
    }
    if (_paymentRatio <= 0.3 && _burdenRatio <= 0.75) {
      return const _LoanVerdict(
        label: 'Looks manageable',
        message:
            'The EMI stays near a safer income band and leaves monthly room.',
        color: AppTheme.success,
        icon: Icons.check_circle_rounded,
      );
    }
    if (_paymentRatio <= 0.45) {
      return const _LoanVerdict(
        label: 'Tight',
        message: 'The EMI may work, but it leaves less room for emergencies.',
        color: AppTheme.warning,
        icon: Icons.warning_amber_rounded,
      );
    }
    return const _LoanVerdict(
      label: 'Risky',
      message:
          'This EMI takes too much income. Try a smaller loan, lower markup, or longer plan.',
      color: AppTheme.error,
      icon: Icons.report_problem_rounded,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _getAIInsight() async {
    setState(() {
      _aiLoading = true;
      _aiInsight = null;
    });

    try {
      final prompt =
          'Analyze this loan for a user in Pakistan. Amount ${CurrencyUtils.exact(_amount)}, annual markup ${_rate.toStringAsFixed(1)}%, tenure $_tenure months, EMI ${CurrencyUtils.exact(_emi)}, total interest ${CurrencyUtils.exact(_totalInterest)}, monthly income ${_effectiveIncome <= 0 ? 'not provided' : CurrencyUtils.exact(_effectiveIncome)}, current monthly spending ${CurrencyUtils.exact(_monthSpending)}, budgeted commitments ${CurrencyUtils.exact(_monthBudget)}, cash left after EMI ${CurrencyUtils.exact(_incomeLeftAfterEmi)}. Give 3 concise bullets in PKR: affordability, repayment risk, and next action.';
      final response = await _aiService.generalFinancialAnswer(prompt);
      if (!mounted) return;
      setState(() {
        _aiInsight = response;
        _aiLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _aiInsight = 'AI analysis is unavailable right now.';
        _aiLoading = false;
      });
    }
  }

  void _syncValues() {
    setState(() {
      _amount = double.tryParse(_amountController.text.trim()) ?? 0;
      _rate = double.tryParse(_rateController.text.trim()) ?? 0;
      _tenure = int.tryParse(_tenureController.text.trim()) ?? 0;
      _monthlyIncome = double.tryParse(_incomeController.text.trim()) ?? 0;
      _aiInsight = null;
    });
  }

  void _applyPreset(_LoanPreset preset) {
    setState(() {
      _amount = preset.amount;
      _rate = preset.rate;
      _tenure = preset.tenure;
      _amountController.text = preset.amount.toStringAsFixed(0);
      _rateController.text = preset.rate.toStringAsFixed(1);
      _tenureController.text = preset.tenure.toString();
      _aiInsight = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;
    final verdict = _verdict;

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        child: firestoreService == null
            ? _LoanContent(
                embedded: widget.embedded,
                onBack: () => Navigator.maybePop(context),
                verdict: verdict,
                emi: _emi,
                paymentRatio: _paymentRatio,
                totalPayment: _totalPayment,
                totalInterest: _totalInterest,
                recommendedIncome: _recommendedIncome,
                costRatio: _costRatio,
                amountController: _amountController,
                rateController: _rateController,
                tenureController: _tenureController,
                incomeController: _incomeController,
                onChanged: (_) => _syncValues(),
                onPreset: _applyPreset,
                amount: _amount,
                tenure: _tenure,
                effectiveIncome: _effectiveIncome,
                monthSpending: _monthSpending,
                totalMonthlyBurden: _totalMonthlyBurden,
                incomeLeftAfterEmi: _incomeLeftAfterEmi,
                burdenRatio: _burdenRatio,
                aiLoading: _aiLoading,
                aiInsight: _aiInsight,
                onAiInsight: _getAIInsight,
              )
            : StreamBuilder<Map<String, dynamic>>(
                stream: firestoreService.getUserProfile(),
                builder: (context, profileSnapshot) {
                  return StreamBuilder<List<FinancialTransaction>>(
                    stream: firestoreService.getTransactions(),
                    builder: (context, transactionSnapshot) {
                      return StreamBuilder<List<BudgetPlan>>(
                        stream: firestoreService.getBudgetPlans(
                          monthKey: _monthKey(DateTime.now()),
                        ),
                        builder: (context, budgetSnapshot) {
                          _profileIncome = _number(
                            profileSnapshot.data?['monthlyIncome'],
                          );
                          final transactions =
                              transactionSnapshot.data ??
                              const <FinancialTransaction>[];
                          _monthSpending = transactions
                              .where(
                                (item) =>
                                    item.type == 'expense' &&
                                    _monthKey(item.date) ==
                                        _monthKey(DateTime.now()),
                              )
                              .fold(0, (total, item) => total + item.amount);
                          final budgets =
                              budgetSnapshot.data ?? const <BudgetPlan>[];
                          _monthBudget = budgets.fold(
                            0,
                            (total, item) => total + item.allocatedAmount,
                          );

                          return _LoanContent(
                            embedded: widget.embedded,
                            onBack: () => Navigator.maybePop(context),
                            verdict: _verdict,
                            emi: _emi,
                            paymentRatio: _paymentRatio,
                            totalPayment: _totalPayment,
                            totalInterest: _totalInterest,
                            recommendedIncome: _recommendedIncome,
                            costRatio: _costRatio,
                            amountController: _amountController,
                            rateController: _rateController,
                            tenureController: _tenureController,
                            incomeController: _incomeController,
                            onChanged: (_) => _syncValues(),
                            onPreset: _applyPreset,
                            amount: _amount,
                            tenure: _tenure,
                            effectiveIncome: _effectiveIncome,
                            monthSpending: _monthSpending,
                            totalMonthlyBurden: _totalMonthlyBurden,
                            incomeLeftAfterEmi: _incomeLeftAfterEmi,
                            burdenRatio: _burdenRatio,
                            aiLoading: _aiLoading,
                            aiInsight: _aiInsight,
                            onAiInsight: _getAIInsight,
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _LoanContent extends StatelessWidget {
  const _LoanContent({
    required this.embedded,
    required this.onBack,
    required this.verdict,
    required this.emi,
    required this.paymentRatio,
    required this.totalPayment,
    required this.totalInterest,
    required this.recommendedIncome,
    required this.costRatio,
    required this.amountController,
    required this.rateController,
    required this.tenureController,
    required this.incomeController,
    required this.onChanged,
    required this.onPreset,
    required this.amount,
    required this.tenure,
    required this.effectiveIncome,
    required this.monthSpending,
    required this.totalMonthlyBurden,
    required this.incomeLeftAfterEmi,
    required this.burdenRatio,
    required this.aiLoading,
    required this.aiInsight,
    required this.onAiInsight,
  });

  final bool embedded;
  final VoidCallback onBack;
  final _LoanVerdict verdict;
  final double emi;
  final double paymentRatio;
  final double totalPayment;
  final double totalInterest;
  final double recommendedIncome;
  final double costRatio;
  final TextEditingController amountController;
  final TextEditingController rateController;
  final TextEditingController tenureController;
  final TextEditingController incomeController;
  final ValueChanged<String> onChanged;
  final ValueChanged<_LoanPreset> onPreset;
  final double amount;
  final int tenure;
  final double effectiveIncome;
  final double monthSpending;
  final double totalMonthlyBurden;
  final double incomeLeftAfterEmi;
  final double burdenRatio;
  final bool aiLoading;
  final String? aiInsight;
  final VoidCallback onAiInsight;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        _LoanHeader(embedded: embedded, onBack: onBack),
        const SizedBox(height: 16),
        _VerdictCard(verdict: verdict, emi: emi, paymentRatio: paymentRatio),
        const SizedBox(height: 12),
        _BurdenCard(
          income: effectiveIncome,
          currentSpending: monthSpending,
          totalBurden: totalMonthlyBurden,
          leftAfterEmi: incomeLeftAfterEmi,
          burdenRatio: burdenRatio,
        ),
        const SizedBox(height: 14),
        _ResultGrid(
          totalPayment: totalPayment,
          totalInterest: totalInterest,
          recommendedIncome: recommendedIncome,
          costRatio: costRatio,
        ),
        const SizedBox(height: 22),
        _SectionTitle(title: 'Loan details'),
        const SizedBox(height: 12),
        _PlainCard(
          child: Column(
            children: [
              _MoneyField(
                controller: amountController,
                label: 'Loan amount',
                icon: Icons.payments_rounded,
                onChanged: onChanged,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MoneyField(
                      controller: rateController,
                      label: 'Markup %',
                      icon: Icons.percent_rounded,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MoneyField(
                      controller: tenureController,
                      label: 'Months',
                      icon: Icons.event_rounded,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MoneyField(
                controller: incomeController,
                label: 'Monthly income override',
                icon: Icons.account_balance_wallet_rounded,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PresetRow(onSelected: onPreset),
        const SizedBox(height: 22),
        _SectionTitle(title: 'Payment plan'),
        const SizedBox(height: 12),
        _RepaymentCard(
          amount: amount,
          emi: emi,
          totalInterest: totalInterest,
          totalPayment: totalPayment,
          tenure: tenure,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: aiLoading ? null : onAiInsight,
            icon: aiLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(aiLoading ? 'Analyzing...' : 'Get AI view'),
          ),
        ),
        if (aiInsight != null) ...[
          const SizedBox(height: 14),
          _PlainCard(
            child: Text(
              aiInsight!,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LoanHeader extends StatelessWidget {
  const _LoanHeader({required this.embedded, required this.onBack});

  final bool embedded;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!embedded) ...[
          IconButton.outlined(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loans',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Check EMI, risk, and total repayment',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({
    required this.verdict,
    required this.emi,
    required this.paymentRatio,
  });

  final _LoanVerdict verdict;
  final double emi;
  final double paymentRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(verdict.icon, color: verdict.color),
              const SizedBox(width: 8),
              Text(
                verdict.label,
                style: GoogleFonts.inter(
                  color: verdict.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyUtils.exact(emi),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'monthly EMI',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            verdict.message,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (paymentRatio > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: paymentRatio.clamp(0, 1),
                backgroundColor: AppTheme.mutedFillFor(context),
                valueColor: AlwaysStoppedAnimation<Color>(verdict.color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(paymentRatio * 100).toStringAsFixed(0)}% of income',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BurdenCard extends StatelessWidget {
  const _BurdenCard({
    required this.income,
    required this.currentSpending,
    required this.totalBurden,
    required this.leftAfterEmi,
    required this.burdenRatio,
  });

  final double income;
  final double currentSpending;
  final double totalBurden;
  final double leftAfterEmi;
  final double burdenRatio;

  @override
  Widget build(BuildContext context) {
    final isRisky = income > 0 && leftAfterEmi < 0;
    final color = isRisky
        ? AppTheme.error
        : burdenRatio >= 0.75
        ? AppTheme.warning
        : AppTheme.success;

    return _PlainCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monthly burden',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (income > 0)
                Text(
                  '${(burdenRatio * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Income',
                  value: income > 0 ? CurrencyUtils.exact(income) : 'Not set',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'After EMI',
                  value: income > 0
                      ? CurrencyUtils.exact(leftAfterEmi)
                      : 'Need income',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: burdenRatio.clamp(0, 1),
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            income <= 0
                ? 'Set income to see if this loan fits your real month.'
                : 'Current spending ${CurrencyUtils.exact(currentSpending)} plus EMI makes ${CurrencyUtils.exact(totalBurden)} monthly commitments.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultGrid extends StatelessWidget {
  const _ResultGrid({
    required this.totalPayment,
    required this.totalInterest,
    required this.recommendedIncome,
    required this.costRatio,
  });

  final double totalPayment;
  final double totalInterest;
  final double recommendedIncome;
  final double costRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _MetricTile(
          label: 'Total paid',
          value: CurrencyUtils.exact(totalPayment),
          color: AppTheme.primaryFor(context),
          icon: Icons.receipt_long_rounded,
        ),
        _MetricTile(
          label: 'Markup cost',
          value: CurrencyUtils.exact(totalInterest),
          color: AppTheme.warning,
          icon: Icons.trending_up_rounded,
        ),
        _MetricTile(
          label: 'Safe income',
          value: CurrencyUtils.exact(recommendedIncome),
          color: AppTheme.success,
          icon: Icons.verified_user_rounded,
        ),
        _MetricTile(
          label: 'Cost ratio',
          value: '${costRatio.toStringAsFixed(2)}x',
          color: AppTheme.error,
          icon: Icons.scale_rounded,
        ),
      ],
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.onSelected});

  final ValueChanged<_LoanPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    const presets = [
      _LoanPreset('Bike', 250000, 24, 18),
      _LoanPreset('Study', 500000, 36, 10),
      _LoanPreset('Business', 1500000, 48, 16.5),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              avatar: const Icon(Icons.tune_rounded, size: 18),
              label: Text(preset.label),
              onPressed: () => onSelected(preset),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RepaymentCard extends StatelessWidget {
  const _RepaymentCard({
    required this.amount,
    required this.emi,
    required this.totalInterest,
    required this.totalPayment,
    required this.tenure,
  });

  final double amount;
  final double emi;
  final double totalInterest;
  final double totalPayment;
  final int tenure;

  @override
  Widget build(BuildContext context) {
    return _PlainCard(
      child: Column(
        children: [
          _PlanRow(label: 'Principal', value: CurrencyUtils.exact(amount)),
          _PlanRow(label: 'Monthly EMI', value: CurrencyUtils.exact(emi)),
          _PlanRow(
            label: 'Total markup',
            value: CurrencyUtils.exact(totalInterest),
          ),
          _PlanRow(label: 'Tenure', value: '$tenure months'),
          _PlanRow(
            label: 'Total repayment',
            value: CurrencyUtils.exact(totalPayment),
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderFor(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: highlight
                  ? AppTheme.primaryFor(context)
                  : AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        color: AppTheme.textPrimaryFor(context),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _PlainCard extends StatelessWidget {
  const _PlainCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: child,
    );
  }
}

class _LoanVerdict {
  const _LoanVerdict({
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String label;
  final String message;
  final Color color;
  final IconData icon;
}

class _LoanPreset {
  const _LoanPreset(this.label, this.amount, this.tenure, this.rate);

  final String label;
  final double amount;
  final int tenure;
  final double rate;
}

double _number(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}
