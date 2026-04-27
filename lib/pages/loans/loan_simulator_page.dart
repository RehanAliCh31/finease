import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LoanSimulatorPage extends StatefulWidget {
  const LoanSimulatorPage({super.key});
  @override
  State<LoanSimulatorPage> createState() => _LoanSimulatorPageState();
}

class _LoanSimulatorPageState extends State<LoanSimulatorPage> {
  double _amount = 50000;
  double _rate = 7.5;
  double _tenure = 36;
  String? _aiInsight;
  bool _aiLoading = false;

  double get _emi {
    final r = (_rate / 12) / 100;
    if (r == 0) return _amount / _tenure;
    return (_amount * r * pow(1 + r, _tenure)) / (pow(1 + r, _tenure) - 1);
  }

  double get _totalInterest => (_emi * _tenure) - _amount;
  double get _totalPayment => _emi * _tenure;

  Future<void> _getAIInsight() async {
    setState(() { _aiLoading = true; _aiInsight = null; });
    try {
      final key = dotenv.env['GEMINI_API_KEY'] ?? '';
      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: key);
      final prompt = '''Analyze this loan: Amount \$${_amount.toStringAsFixed(0)}, Rate ${_rate.toStringAsFixed(1)}% annually, ${_tenure.toInt()} months tenure.
EMI: \$${_emi.toStringAsFixed(0)}/month, Total interest: \$${_totalInterest.toStringAsFixed(0)}.
Give 3 bullet points of personalized financial advice. Be concise (under 150 words total). Start each point with •''';
      final resp = await model.generateContent([Content.text(prompt)]);
      setState(() { _aiInsight = resp.text; _aiLoading = false; });
    } catch (_) {
      setState(() {
        _aiInsight = '• Your EMI of \$${_emi.toStringAsFixed(0)} should ideally be under 30% of your monthly income.\n\n'
            '• At ${_rate.toStringAsFixed(1)}%, you pay \$${_totalInterest.toStringAsFixed(0)} in interest — reducing tenure by 12 months could save ~\$${(_totalInterest * 0.25).toStringAsFixed(0)}.\n\n'
            '• ${_rate > 10 ? "Your rate is above market average (8.5%). Consider improving your credit score." : "Great rate! Lock it in before it rises."}';
        _aiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Text('Loan Simulator', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppTheme.cyanGradient, borderRadius: BorderRadius.circular(24), boxShadow: AppTheme.cardShadow),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly EMI', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('\$${_emi.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -2)),
                  Text('/month', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _statPill('Principal', '\$${(_amount / 1000).toStringAsFixed(0)}k'),
                      const SizedBox(width: 12),
                      _statPill('Interest', '\$${(_totalInterest / 1000).toStringAsFixed(1)}k'),
                      const SizedBox(width: 12),
                      _statPill('Total', '\$${(_totalPayment / 1000).toStringAsFixed(1)}k'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sliders
            _SimCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adjust Parameters', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 20),
                  _Slider(label: 'Loan Amount', value: _amount, min: 1000, max: 500000, display: '\$${(_amount / 1000).toStringAsFixed(0)}k', onChanged: (v) => setState(() => _amount = v)),
                  const SizedBox(height: 16),
                  _Slider(label: 'Interest Rate', value: _rate, min: 1, max: 30, display: '${_rate.toStringAsFixed(1)}%', onChanged: (v) => setState(() => _rate = v)),
                  const SizedBox(height: 16),
                  _Slider(label: 'Tenure', value: _tenure, min: 6, max: 120, display: '${_tenure.toInt()} mo', onChanged: (v) => setState(() => _tenure = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chart
            _SimCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amortization Breakdown', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text('Principal vs Interest over loan tenure', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _totalPayment,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24, getTitlesWidget: (v, m) {
                          final labels = ['M1', 'Q1', 'Mid', 'End'];
                          if (v.toInt() < labels.length) return SideTitleWidget(meta: m, child: Text(labels[v.toInt()], style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textSecondary)));
                          return const SizedBox();
                        })),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        _bar(0, _amount * 0.95, _totalInterest * 0.05),
                        _bar(1, _amount * 0.65, _totalInterest * 0.35),
                        _bar(2, _amount * 0.35, _totalInterest * 0.65),
                        _bar(3, _amount * 0.05, _totalInterest * 0.95),
                      ],
                    )),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _legend(AppTheme.primary, 'Principal'),
                      const SizedBox(width: 16),
                      _legend(AppTheme.secondary, 'Interest'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _aiLoading ? null : _getAIInsight,
                icon: _aiLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(_aiLoading ? 'Analyzing...' : 'Get AI Analysis', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),

            // AI Insight Panel
            if (_aiInsight != null) ...[
              const SizedBox(height: 16),
              _SimCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text('AI Analysis', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ]),
                    const SizedBox(height: 12),
                    Text(_aiInsight!, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textPrimary, height: 1.7)),
                  ],
                ),
              ),
            ],

            // Repayment Table
            const SizedBox(height: 16),
            _SimCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Repayment Overview', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  _row(context, 'Loan Amount', '\$${_amount.toStringAsFixed(2)}', first: true),
                  _row(context, 'Monthly EMI', '\$${_emi.toStringAsFixed(2)}'),
                  _row(context, 'Total Interest', '\$${_totalInterest.toStringAsFixed(2)}'),
                  _row(context, 'Total Payment', '\$${_totalPayment.toStringAsFixed(2)}', highlight: true),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String l, String v) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
    child: Column(
      children: [
        Text(l, style: GoogleFonts.inter(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
        Text(v, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    ),
  );

  BarChartGroupData _bar(int x, double principal, double interest) => BarChartGroupData(
    x: x,
    barRods: [BarChartRodData(
      toY: principal + interest,
      width: 22,
      borderRadius: BorderRadius.circular(6),
      rodStackItems: [
        BarChartRodStackItem(0, principal, AppTheme.primary),
        BarChartRodStackItem(principal, principal + interest, AppTheme.secondary),
      ],
    )],
  );

  Widget _legend(Color c, String l) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(l, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
  ]);

  Widget _row(BuildContext context, String l, String v, {bool first = false, bool highlight = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    decoration: BoxDecoration(
      border: first ? null : Border(top: BorderSide(color: AppTheme.divider)),
      color: highlight ? AppTheme.primary.withValues(alpha: 0.06) : null,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, fontWeight: highlight ? FontWeight.w600 : FontWeight.w400)),
        Text(v, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: highlight ? AppTheme.primary : AppTheme.textPrimary)),
      ],
    ),
  );
}

class _SimCard extends StatelessWidget {
  final Widget child;
  const _SimCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border), boxShadow: AppTheme.softShadow),
    child: child,
  );
}

class _Slider extends StatelessWidget {
  final String label;
  final double value, min, max;
  final String display;
  final ValueChanged<double> onChanged;
  const _Slider({required this.label, required this.value, required this.min, required this.max, required this.display, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          Text(display, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ],
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: AppTheme.primary, inactiveTrackColor: AppTheme.border,
          thumbColor: Colors.white, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
          overlayColor: AppTheme.primary.withValues(alpha: 0.1), trackHeight: 5,
        ),
        child: Slider(value: value, min: min, max: max, onChanged: onChanged),
      ),
    ],
  );
}
