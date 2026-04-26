import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LoanSimulatorPage extends StatefulWidget {
  const LoanSimulatorPage({super.key});

  @override
  State<LoanSimulatorPage> createState() => _LoanSimulatorPageState();
}


class _LoanSimulatorPageState extends State<LoanSimulatorPage> {
  double _loanAmount = 50000;
  double _interestRate = 7.5;
  double _tenure = 36;

  double get _emi {
    double p = _loanAmount;
    double r = (_interestRate / 12) / 100;
    double n = _tenure;
    if (r == 0) return p / n;
    return (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
  }

  double get _totalInterest {
    return (_emi * _tenure) - _loanAmount;
  }

  double get _totalPayment {
    return _emi * _tenure;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF29FCF3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'EDUCATIONAL SUITE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF00504D),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Master Your\nBorrowing\nStrategy',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppTheme.primary,
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Understanding loans doesn\'t have to be complex. Our interactive simulation tool helps you visualize repayment structures and compare interest impacts before you commit.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildFeatureChips(context),
            const SizedBox(height: 32),
            _buildSavingsCard(context),
            const SizedBox(height: 24),
            _buildSimulatorCard(context),
            const SizedBox(height: 16),
            _buildResults(context),
            const SizedBox(height: 16),
            _buildAmortizationChart(context),
            const SizedBox(height: 32),
            _buildRepaymentSchedule(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppTheme.primary),
        onPressed: () {},
      ),
      title: Text(
        'FinEase',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 20.0, left: 8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(context, 'Fixed Rates', Icons.check_circle_outline),
        _buildChip(context, 'Lower EMI Options', Icons.trending_down),
        _buildChip(context, 'Smart Simulations', Icons.school_outlined),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF00716D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1554224155-6726b3ff858f?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80'),
              fit: BoxFit.cover,
              opacity: 0.4,
            ),
          ),
        ),
        Positioned(
          left: -8,
          bottom: -16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12.5%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Average Interest Savings\nfor FinEase Users',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loan Simulator', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary)),
              const Icon(Icons.tune, color: AppTheme.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          _buildSlider(
            context,
            label: 'Loan Amount',
            value: _loanAmount,
            min: 1000,
            max: 500000,
            valueLabel: '\$ ${(_loanAmount / 1000).toStringAsFixed(0)},000',
            minLabel: '\$1k',
            maxLabel: '\$500k',
            onChanged: (val) => setState(() => _loanAmount = val),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            context,
            label: 'Interest Rate (Annual %)',
            value: _interestRate,
            min: 1,
            max: 24,
            valueLabel: '${_interestRate.toStringAsFixed(1)}%',
            minLabel: '1%',
            maxLabel: '24%',
            onChanged: (val) => setState(() => _interestRate = val),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            context,
            label: 'Tenure (Months)',
            value: _tenure,
            min: 6,
            max: 120,
            valueLabel: '${_tenure.toInt()} Mo.',
            minLabel: '6 Mo.',
            maxLabel: '120 Mo.',
            onChanged: (val) => setState(() => _tenure = val),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showAIInsights(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Get AI Insights', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'No impact on your credit score',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required String valueLabel,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.textSecondary)),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: const Color(0xFFEAF1FF),
            thumbColor: Colors.white,
            overlayColor: AppTheme.primary.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
            Text(maxLabel, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'MONTHLY REPAYMENT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_emi.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                    child: Text(
                      '/Month',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFD3E4FE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline, color: AppTheme.primary.withOpacity(0.7), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'TOTAL INTEREST',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_totalInterest.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.primary,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.trending_up, color: const Color(0xFF00716D), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${((_totalInterest / _loanAmount) * 100).toStringAsFixed(2)}% of principal',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF00716D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildAmortizationChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amortization', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Breakdown', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text('Principal vs. Interest over time', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildLegendItem(context, 'Principal', AppTheme.primary),
                  const SizedBox(width: 12),
                  _buildLegendItem(context, 'Interest', const Color(0xFF00F2EA)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _loanAmount + _totalInterest,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(fontSize: 10, color: AppTheme.textSecondary);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('M1', style: style); break;
                          case 1: text = const Text('M12', style: style); break;
                          case 2: text = const Text('M24', style: style); break;
                          case 3: text = const Text('M36', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, child: text);
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildFlBarGroup(0, _loanAmount * 0.9, _totalInterest * 0.1),
                  _buildFlBarGroup(1, _loanAmount * 0.6, _totalInterest * 0.4),
                  _buildFlBarGroup(2, _loanAmount * 0.3, _totalInterest * 0.7),
                  _buildFlBarGroup(3, 0, _totalInterest),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildFlBarGroup(int x, double principal, double interest) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: _loanAmount + _totalInterest,
          width: 20,
          borderRadius: BorderRadius.circular(4),
          rodStackItems: [
            BarChartRodStackItem(0, principal, AppTheme.primary),
            BarChartRodStackItem(principal, principal + interest, const Color(0xFF00F2EA)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildRepaymentSchedule(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repayment Schedule Overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download, size: 14, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text('Export PDF', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 1, child: Text('YEAR', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10))),
                    Expanded(flex: 2, child: Text('BEGINNING\nBALANCE', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10))),
                    Expanded(flex: 2, child: Text('TOTAL\nPAYMENT', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10))),
                  ],
                ),
              ),
              _buildTableRow(context, 'Year 1', '\$${_loanAmount.toStringAsFixed(2)}', '\$${(_emi * 12).toStringAsFixed(2)}', isLast: false),
              _buildTableRow(context, 'Year 2', '\$${(_loanAmount * 0.66).toStringAsFixed(2)}', '\$${(_emi * 12).toStringAsFixed(2)}', isLast: false),
              _buildTableRow(context, 'Year 3', '\$${(_loanAmount * 0.33).toStringAsFixed(2)}', '\$${(_emi * 12).toStringAsFixed(2)}', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(BuildContext context, String year, String balance, String payment, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(year, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(balance, style: Theme.of(context).textTheme.labelSmall)),
          Expanded(flex: 2, child: Text(payment, style: Theme.of(context).textTheme.labelSmall)),
        ],
      ),
    );
  }

  void _showAIInsights(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text('FinEase AI Analysis', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAIInsightItem(
                        context,
                        title: 'Affordability Check',
                        content: 'For a \$${_loanAmount.toStringAsFixed(0)} loan over ${_tenure.toInt()} months, your monthly EMI is \$${_emi.toStringAsFixed(0)}. Ensure this is less than 30% of your monthly income.',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF29FCF3),
                      ),
                      const SizedBox(height: 16),
                      _buildAIInsightItem(
                        context,
                        title: 'Interest Optimization',
                        content: 'At ${_interestRate.toStringAsFixed(1)}%, you are paying \$${_totalInterest.toStringAsFixed(0)} in total interest. Reducing the tenure to ${max(6, _tenure - 12).toInt()} months could save you approximately \$${(_totalInterest * 0.3).toStringAsFixed(0)} in interest.',
                        icon: Icons.trending_down,
                        color: const Color(0xFFDCE9FF),
                      ),
                      const SizedBox(height: 16),
                      _buildAIInsightItem(
                        context,
                        title: 'Market Comparison',
                        content: _interestRate > 10
                            ? 'Your current rate of ${_interestRate.toStringAsFixed(1)}% is higher than the market average of 8.5%. Consider improving your credit score to negotiate better rates.'
                            : 'Great! Your rate of ${_interestRate.toStringAsFixed(1)}% is competitive compared to the current market average of 8.5%.',
                        icon: Icons.analytics_outlined,
                        color: const Color(0xFFFFDBCB),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close Insights', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAIInsightItem(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF00504D), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(content, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
