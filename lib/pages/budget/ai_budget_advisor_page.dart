import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';

class AIBudgetAdvisorPage extends StatefulWidget {
  const AIBudgetAdvisorPage({super.key});

  @override
  State<AIBudgetAdvisorPage> createState() => _AIBudgetAdvisorPageState();
}

class _AIBudgetAdvisorPageState extends State<AIBudgetAdvisorPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Color primaryColor = const Color(0xFF2E3192);
  final Color accentColor = const Color(0xFF1BFFFF);
  final Color darkBgColor = const Color(0xFF0F0F1E);
  final Color cardBgColor = const Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBgColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -50,
            child: _buildGlowOrb(accentColor.withValues(alpha: 0.15), 300),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: _buildGlowOrb(primaryColor.withValues(alpha: 0.2), 400),
          ),
          
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildAIConciergeHeader(),
                      const SizedBox(height: 32),
                      _buildBudgetPulseCard(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Strategic Insights'),
                      const SizedBox(height: 16),
                      _buildStrategicInsight(
                        'Subscription Optimization',
                        'You have 3 overlapping streaming services. Cancelling "StreamFlow" could save you \$18.99/mo.',
                        Icons.auto_fix_high_rounded,
                        accentColor,
                      ),
                      const SizedBox(height: 16),
                      _buildStrategicInsight(
                        'Spending Anomaly',
                        'Dining out is 22% higher this week. Consider a home-cooked meal to stay on track.',
                        Icons.psychology_alt_rounded,
                        const Color(0xFFFF4B2B),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Spending Distribution'),
                      const SizedBox(height: 16),
                      _buildDistributionChart(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Smart Alerts'),
                      const SizedBox(height: 16),
                      _buildAlertTile('Large Purchase Detected', 'Apple Store', '-\$1,299.00', Icons.shopping_cart_checkout_rounded),
                      _buildAlertTile('Recurring Charge Hike', 'Adobe Creative Cloud', '+\$5.00', Icons.trending_up_rounded),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Advisor',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  )),
                Text('Precision Intelligence',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  )),
              ],
            ),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIConciergeHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 60 * _pulseAnimation.value,
                    height: 60 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withOpacity(0.3),
                          accentColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, accentColor]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 15,
                    )
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Systems Optimal',
                  style: GoogleFonts.plusJakartaSans(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  )),
                const SizedBox(height: 4),
                Text('Hello! I\'ve analyzed 42 transactions since yesterday.',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetPulseCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Monthly Liquidity',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                  Text('June 2024',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: _buildMetric('Total Budget', '\$8,450', Colors.white)),
                  _buildDivider(),
                  Expanded(child: _buildMetric('Allocated', '\$5,280', accentColor)),
                  _buildDivider(),
                  Expanded(child: _buildMetric('Remaining', '\$3,170', const Color(0xFF00B09B))),
                ],
              ),
              const SizedBox(height: 32),
              Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.625,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, accentColor]),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 10,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('62.5% of your projected spending limit reached',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.4),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          )),
        const SizedBox(height: 6),
        Text(value,
          style: GoogleFonts.plusJakartaSans(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          )),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.1),
    );
  }

  Widget _buildStrategicInsight(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  )),
                const SizedBox(height: 6),
                Text(desc,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    height: 1.5,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 60,
                sections: [
                  _buildPieSection(45, primaryColor, 'Housing'),
                  _buildPieSection(25, accentColor, 'Food'),
                  _buildPieSection(15, const Color(0xFF6B63FF), 'Lifestyle'),
                  _buildPieSection(15, Colors.white.withOpacity(0.2), 'Other'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildChartLegend('Housing & Utilities', '45%', primaryColor),
          _buildChartLegend('Food & Dining', '25%', accentColor),
          _buildChartLegend('Lifestyle & Leisure', '15%', const Color(0xFF6B63FF)),
          _buildChartLegend('Others', '15%', Colors.white.withOpacity(0.2)),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(double value, Color color, String title) {
    return PieChartSectionData(
      color: color,
      value: value,
      radius: 12,
      showTitle: false,
      badgeWidget: null,
    );
  }

  Widget _buildChartLegend(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          const Spacer(),
          Text(percent, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAlertTile(String title, String subtitle, String amount, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: GoogleFonts.inter(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          Text(amount,
            style: GoogleFonts.plusJakartaSans(
              color: amount.startsWith('-') ? const Color(0xFFFF4B2B) : accentColor,
              fontWeight: FontWeight.w800,
            )),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ));
  }
}
