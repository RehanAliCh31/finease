import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import 'package:fl_chart/fl_chart.dart';

class AIBudgetAdvisorPage extends StatefulWidget {
  const AIBudgetAdvisorPage({super.key});

  @override
  State<AIBudgetAdvisorPage> createState() => _AIBudgetAdvisorPageState();
}

class _AIBudgetAdvisorPageState extends State<AIBudgetAdvisorPage> {
  final AIService _aiService = AIService(apiKey: ''); // Empty for now, uses mock
  String _advice = "Loading AI insights...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialAdvice();
  }

  Future<void> _fetchInitialAdvice() async {
    // This is just a placeholder. In a real app, you'd pass actual transactions.
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _advice = "Your spending on 'Dining' has increased by 15% this month. "
            "Consider setting a \$400 monthly limit for this category to save an additional \$200 by year-end.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Budget Advisor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyOverview(context),
            const SizedBox(height: 24),
            _buildAIAdviceCard(context),
            const SizedBox(height: 24),
            Text('Spending Breakdown', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildSpendingChart(context),
            const SizedBox(height: 24),
            _buildUnusualSpendingList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOverview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewItem(context, 'Total Income', '\$8,450', Colors.green),
              _buildOverviewItem(context, 'Total Expenses', '\$5,280', colorScheme.error),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: 0.62,
            backgroundColor: colorScheme.onSurface.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          const SizedBox(height: 10),
          Text('You have used 62.5% of your planned budget.', 
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(BuildContext context, String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAIAdviceCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary.withOpacity(0.1), colorScheme.secondary.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text('AI Insight', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isLoading)
                const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_advice, style: TextStyle(color: colorScheme.onSurface, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: 45, color: colorScheme.primary, title: 'Rent', radius: 50, showTitle: false),
            PieChartSectionData(value: 20, color: colorScheme.secondary, title: 'Food', radius: 50, showTitle: false),
            PieChartSectionData(value: 15, color: Colors.orange, title: 'Leisure', radius: 50, showTitle: false),
            PieChartSectionData(value: 20, color: Colors.green, title: 'Other', radius: 50, showTitle: false),
          ],
          centerSpaceRadius: 40,
          sectionsSpace: 5,
        ),
      ),
    );
  }

  Widget _buildUnusualSpendingList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unusual Spending Detected', 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        const SizedBox(height: 12),
        _buildUnusualItem(context, 'The Steakhouse Grill', '-\$154.00', '3x usual spend'),
        _buildUnusualItem(context, 'Urban Outfitters', '-\$89.99', 'Subscription renewal?'),
      ],
    );
  }

  Widget _buildUnusualItem(BuildContext context, String title, String amount, String reason) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
              Text(reason, style: const TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
          Text(amount, style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

