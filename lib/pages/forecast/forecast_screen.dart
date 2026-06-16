import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/budget_plan.dart';
import '../../models/prediction_models.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/prediction_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/finance_consistency_utils.dart';
import '../budget/ai_budget_advisor_page.dart';
import '../savings/savings_tracker_page.dart';
import '../transactions/add_transaction_page.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({
    super.key,
    this.transactions,
    this.budgets,
    this.monthlyIncome,
  });

  final List<FinancialTransaction>? transactions;
  final Map<String, double>? budgets;
  final double? monthlyIncome;

  bool get _hasProvidedData =>
      transactions != null || budgets != null || monthlyIncome != null;

  @override
  Widget build(BuildContext context) {
    if (_hasProvidedData) {
      final data = _ForecastData.fromInputs(
        transactions: transactions ?? const [],
        budgets: budgets ?? const {},
        monthlyIncome: monthlyIncome ?? 0,
      );
      return _ForecastScaffold(data: data);
    }

    final firestore = context.watch<AuthService>().firestoreService;
    if (firestore == null) {
      return const _ForecastScaffold(
        child: _StateMessage(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in to view forecast',
          message: 'Your next-month outlook needs your private finance data.',
        ),
      );
    }

    return _ForecastLoader(firestore: firestore);
  }
}

class _ForecastLoader extends StatelessWidget {
  const _ForecastLoader({required this.firestore});

  final FirestoreService firestore;

  @override
  Widget build(BuildContext context) {
    final monthKey = _monthKey(DateTime.now());

    return StreamBuilder<List<FinancialTransaction>>(
      stream: firestore.getTransactions(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.hasError) {
          return _ForecastScaffold(child: _errorMessage());
        }
        if (!transactionSnapshot.hasData) {
          return const _ForecastScaffold(child: _LoadingMessage());
        }

        return StreamBuilder<List<BudgetPlan>>(
          stream: firestore.getBudgetPlans(monthKey: monthKey),
          builder: (context, budgetSnapshot) {
            if (budgetSnapshot.hasError) {
              return _ForecastScaffold(child: _errorMessage());
            }
            if (!budgetSnapshot.hasData) {
              return const _ForecastScaffold(child: _LoadingMessage());
            }

            return StreamBuilder<Map<String, dynamic>>(
              stream: firestore.getUserProfile(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.hasError) {
                  return _ForecastScaffold(child: _errorMessage());
                }
                if (!profileSnapshot.hasData) {
                  return const _ForecastScaffold(child: _LoadingMessage());
                }

                final transactions = transactionSnapshot.data ?? const [];
                final budgets = <String, double>{
                  for (final budget in budgetSnapshot.data ?? const [])
                    budget.category: budget.allocatedAmount,
                };
                final profile = profileSnapshot.data ?? const {};
                final profileIncome = _number(profile['monthlyIncome']);
                final transactionIncome = transactions
                    .where(
                      (txn) =>
                          txn.type == 'income' && _isCurrentMonth(txn.date),
                    )
                    .fold(0.0, (sum, txn) => sum + txn.amount);
                final income = FinanceConsistencyUtils.resolveMonthlyIncome(
                  profileMonthlyIncome: profileIncome,
                  transactionIncome: transactionIncome,
                );

                final data = _ForecastData.fromInputs(
                  transactions: transactions,
                  budgets: budgets,
                  monthlyIncome: income,
                );
                return _ForecastScaffold(data: data);
              },
            );
          },
        );
      },
    );
  }

  Widget _errorMessage() {
    return const _StateMessage(
      icon: Icons.cloud_off_rounded,
      title: 'Forecast could not load',
      message: 'Check your connection and try again in a moment.',
    );
  }
}

class _ForecastScaffold extends StatelessWidget {
  const _ForecastScaffold({this.data, this.child});

  final _ForecastData? data;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceFor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimaryFor(context),
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forecast',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimaryFor(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Next month outlook',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: child ?? _ForecastContent(data: data!),
    );
  }
}

class _ForecastContent extends StatelessWidget {
  const _ForecastContent({required this.data});

  final _ForecastData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _DecisionCard(data: data),
        const SizedBox(height: 12),
        _MetricGrid(data: data),
        const SizedBox(height: 12),
        _ActionPlanCard(data: data),
        const SizedBox(height: 20),
        if (!data.hasForecast) ...[
          const _StateMessage(
            icon: Icons.auto_graph_rounded,
            title: 'Not enough history yet',
            message:
                'Add expenses from the last few months so FinEase can forecast the next month with confidence.',
          ),
        ] else ...[
          const _SectionTitle(
            icon: Icons.trending_up_rounded,
            title: 'Likely spending',
            subtitle: 'Top categories for next month',
          ),
          const SizedBox(height: 10),
          ...data.topCategories.map(
            (entry) => _CategoryForecastTile(
              category: entry.key,
              predicted: entry.value,
              budget: data.budgets[entry.key],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            icon: data.warnings.isEmpty
                ? Icons.verified_rounded
                : Icons.warning_amber_rounded,
            title: 'Budget risks',
            subtitle: data.warnings.isEmpty
                ? 'No current category is projected to break its limit'
                : '${data.warnings.length} category needs attention',
          ),
          const SizedBox(height: 10),
          if (data.warnings.isEmpty)
            const _QuietTile(
              icon: Icons.check_circle_rounded,
              title: 'Budgets look steady',
              message:
                  'Keep logging expenses; the forecast will update as your spending changes.',
            )
          else
            ...data.warnings.map(_WarningTile.new),
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.stacked_bar_chart_rounded,
            title: 'Recent pattern',
            subtitle: 'Last 3 months compared with forecast',
          ),
          const SizedBox(height: 10),
          _MonthPattern(bars: data.monthBars),
        ],
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.data});

  final _ForecastData data;

  @override
  Widget build(BuildContext context) {
    final verdict = data.verdict;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: verdict.color.withValues(alpha: 0.22)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: verdict.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(verdict.icon, color: verdict.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verdict.title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      verdict.message,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InlineAmount(
                  label: 'Predicted spend',
                  value: CurrencyUtils.format(data.forecast.totalPredicted),
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: AppTheme.borderFor(context),
              ),
              Expanded(
                child: _InlineAmount(
                  label: 'Expected saving',
                  value: CurrencyUtils.format(data.savings.predictedSavings),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data});

  final _ForecastData data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.52,
      children: [
        _MetricTile(
          icon: Icons.payments_rounded,
          label: 'Income',
          value: data.monthlyIncome > 0
              ? CurrencyUtils.format(data.monthlyIncome)
              : 'Missing',
          color: AppTheme.primary,
        ),
        _MetricTile(
          icon: Icons.savings_rounded,
          label: 'Savings rate',
          value: data.monthlyIncome > 0
              ? '${data.savings.savingsPercentage.toStringAsFixed(0)}%'
              : 'Set income',
          color: AppTheme.success,
        ),
        _MetricTile(
          icon: Icons.receipt_long_rounded,
          label: 'Categories',
          value: '${data.forecast.categoryPredictions.length}',
          color: const Color(0xFF4F46E5),
        ),
        _MetricTile(
          icon: Icons.warning_amber_rounded,
          label: 'At risk',
          value: '${data.warnings.length}',
          color: data.warnings.isEmpty ? AppTheme.success : AppTheme.warning,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
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
        ],
      ),
    );
  }
}

class _ActionPlanCard extends StatelessWidget {
  const _ActionPlanCard({required this.data});

  final _ForecastData data;

  @override
  Widget build(BuildContext context) {
    final color = data.actionColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.isDark(context) ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.actionIcon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.actionTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.actionMessage,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openAction(context),
                    icon: Icon(data.actionIcon, size: 18),
                    label: Text(data.actionLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      textStyle: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openAction(BuildContext context) {
    final page = switch (data.actionTarget) {
      _ForecastActionTarget.addTransaction => const AddTransactionPage(),
      _ForecastActionTarget.budget => const AIBudgetAdvisorPage(),
      _ForecastActionTarget.savings => const SavingsTrackerPage(),
      _ForecastActionTarget.none => null,
    };
    if (page == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Keep logging transactions to improve the forecast.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _CategoryForecastTile extends StatelessWidget {
  const _CategoryForecastTile({
    required this.category,
    required this.predicted,
    required this.budget,
  });

  final String category;
  final double predicted;
  final double? budget;

  @override
  Widget build(BuildContext context) {
    final limit = budget ?? 0;
    final hasBudget = limit > 0;
    final ratio = hasBudget ? predicted / limit : 0.0;
    final color = !hasBudget
        ? AppTheme.primary
        : ratio >= 1
        ? AppTheme.error
        : ratio >= 0.85
        ? AppTheme.warning
        : AppTheme.success;
    final progress = hasBudget ? ratio.clamp(0.0, 1.0) : 0.18;
    final status = !hasBudget
        ? 'No budget set'
        : ratio >= 1
        ? 'Over planned limit'
        : ratio >= 0.85
        ? 'Close to limit'
        : 'Inside budget';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_categoryIcon(category), color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryName(category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimaryFor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.format(predicted),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimaryFor(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasBudget ? 'of ${CurrencyUtils.format(limit)}' : 'next',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningTile extends StatelessWidget {
  const _WarningTile(this.warning);

  final BudgetWarning warning;

  @override
  Widget build(BuildContext context) {
    final alreadyOver = warning.daysUntilExceed <= 0;
    final title = alreadyOver
        ? '${_categoryName(warning.category)} is already over'
        : '${_categoryName(warning.category)} may break in ${warning.daysUntilExceed} days';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warningFillFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warning,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Projected over by ${CurrencyUtils.format(warning.projectedOverspend)}.',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    height: 1.35,
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

class _MonthPattern extends StatelessWidget {
  const _MonthPattern({required this.bars});

  final List<_MonthBar> bars;

  @override
  Widget build(BuildContext context) {
    final maxAmount = bars.fold(0.0, (max, bar) {
      return bar.amount > max ? bar.amount : max;
    });

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: bars.map((bar) {
          final factor = maxAmount <= 0 ? 0.0 : (bar.amount / maxAmount);
          final color = bar.isForecast ? AppTheme.primary : AppTheme.success;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    bar.label,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 10,
                          color: AppTheme.mutedFillFor(context),
                        ),
                        FractionallySizedBox(
                          widthFactor: factor.clamp(0.0, 1.0),
                          child: Container(height: 10, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 86,
                  child: Text(
                    CurrencyUtils.format(bar.amount),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimaryFor(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InlineAmount extends StatelessWidget {
  const _InlineAmount({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryFor(context), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontSize: 12,
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

class _QuietTile extends StatelessWidget {
  const _QuietTile({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successFillFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    height: 1.35,
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

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.mutedFillFor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryFor(context), size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimaryFor(context),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastData {
  const _ForecastData({
    required this.forecast,
    required this.savings,
    required this.warnings,
    required this.budgets,
    required this.monthlyIncome,
    required this.monthBars,
    required this.forecastBasis,
  });

  final ForecastResult forecast;
  final ForecastResult savings;
  final List<BudgetWarning> warnings;
  final Map<String, double> budgets;
  final double monthlyIncome;
  final List<_MonthBar> monthBars;
  final String forecastBasis;

  bool get hasForecast => forecast.categoryPredictions.isNotEmpty;

  List<MapEntry<String, double>> get topCategories {
    final entries = forecast.categoryPredictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  _ForecastActionTarget get actionTarget {
    if (!hasForecast || monthlyIncome <= 0) {
      return _ForecastActionTarget.addTransaction;
    }
    if (savings.predictedSavings < 0 || warnings.isNotEmpty) {
      return _ForecastActionTarget.budget;
    }
    if (savings.savingsPercentage < 10) {
      return _ForecastActionTarget.savings;
    }
    return _ForecastActionTarget.none;
  }

  String get actionTitle {
    if (!hasForecast) return 'Build forecast history';
    if (monthlyIncome <= 0) return 'Add income to judge safety';
    if (savings.predictedSavings < 0) return 'Fix next month before it starts';
    if (warnings.isNotEmpty) return 'Protect risky categories';
    if (savings.savingsPercentage < 10) return 'Savings margin is thin';
    return 'Keep the pattern steady';
  }

  String get actionMessage {
    if (!hasForecast) {
      return 'Add recent expenses so FinEase can estimate next month instead of guessing.';
    }
    if (monthlyIncome <= 0) {
      return 'Forecast can predict spending, but income is needed to judge whether next month is safe.';
    }
    if (savings.predictedSavings < 0) {
      return 'Projected spending is higher than income. Reduce a top category or update the budget.';
    }
    if (warnings.isNotEmpty) {
      return 'One or more current categories may break budget limits if spending continues.';
    }
    if (savings.savingsPercentage < 10) {
      return 'You may stay positive, but the savings buffer is below a healthy margin.';
    }
    return '$forecastBasis. Keep logging transactions so this stays accurate.';
  }

  String get actionLabel {
    return switch (actionTarget) {
      _ForecastActionTarget.addTransaction => 'Add transaction',
      _ForecastActionTarget.budget => 'Open budget',
      _ForecastActionTarget.savings => 'Open savings',
      _ForecastActionTarget.none => 'Got it',
    };
  }

  IconData get actionIcon {
    return switch (actionTarget) {
      _ForecastActionTarget.addTransaction => Icons.add_rounded,
      _ForecastActionTarget.budget => Icons.account_balance_wallet_rounded,
      _ForecastActionTarget.savings => Icons.savings_rounded,
      _ForecastActionTarget.none => Icons.check_circle_rounded,
    };
  }

  Color get actionColor {
    if (!hasForecast || monthlyIncome <= 0) return AppTheme.primary;
    if (savings.predictedSavings < 0) return AppTheme.error;
    if (warnings.isNotEmpty || savings.savingsPercentage < 10) {
      return AppTheme.warning;
    }
    return AppTheme.success;
  }

  _Verdict get verdict {
    if (!hasForecast) {
      return const _Verdict(
        title: 'Forecast needs history',
        message: 'Log a few months of expenses to unlock a useful prediction.',
        icon: Icons.history_rounded,
        color: AppTheme.primary,
      );
    }
    if (monthlyIncome <= 0) {
      return const _Verdict(
        title: 'Income is missing',
        message: 'Add income so the forecast can judge savings risk.',
        icon: Icons.payments_rounded,
        color: AppTheme.warning,
      );
    }
    if (savings.predictedSavings < 0) {
      return const _Verdict(
        title: 'Next month may go negative',
        message: 'Cut one high category or raise income before month end.',
        icon: Icons.priority_high_rounded,
        color: AppTheme.error,
      );
    }
    if (warnings.isNotEmpty) {
      return const _Verdict(
        title: 'Budget risk ahead',
        message: 'You are safe overall, but one category may cross its limit.',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.warning,
      );
    }
    return const _Verdict(
      title: 'Next month looks manageable',
      message: 'Your predicted spend is within income and current budgets.',
      icon: Icons.verified_rounded,
      color: AppTheme.success,
    );
  }

  factory _ForecastData.fromInputs({
    required List<FinancialTransaction> transactions,
    required Map<String, double> budgets,
    required double monthlyIncome,
  }) {
    final service = PredictionService();
    var forecast = service.predictNextMonthExpenses(transactions);
    var forecastBasis = 'Based on the weighted last 3 months';
    if (forecast.categoryPredictions.isEmpty) {
      final fallback = _currentMonthRunRateForecast(transactions);
      if (fallback.categoryPredictions.isNotEmpty) {
        forecast = fallback;
        forecastBasis = 'Based on this month\'s spending pace';
      }
    }
    final savings = service.forecastSavings(
      monthlyIncome,
      forecast.categoryPredictions,
    );
    final currentMonthTransactions = transactions
        .where((transaction) => _isCurrentMonth(transaction.date))
        .toList();
    final warnings = service.getBudgetWarnings(
      currentMonthTransactions,
      budgets,
    );
    final now = DateTime.now();
    final bars = <_MonthBar>[
      for (var offset = 3; offset >= 1; offset--)
        _MonthBar(
          label: _monthLabel(_monthOffset(now, -offset)),
          amount: service.getTotalForMonth(
            transactions,
            _monthOffset(now, -offset).year,
            _monthOffset(now, -offset).month,
          ),
          isForecast: false,
        ),
      _MonthBar(
        label: 'Next',
        amount: forecast.totalPredicted,
        isForecast: true,
      ),
    ];

    return _ForecastData(
      forecast: forecast,
      savings: savings,
      warnings: warnings,
      budgets: budgets,
      monthlyIncome: monthlyIncome,
      monthBars: bars,
      forecastBasis: forecastBasis,
    );
  }
}

enum _ForecastActionTarget { addTransaction, budget, savings, none }

class _Verdict {
  const _Verdict({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

class _MonthBar {
  const _MonthBar({
    required this.label,
    required this.amount,
    required this.isForecast,
  });

  final String label;
  final double amount;
  final bool isForecast;
}

String _monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

DateTime _monthOffset(DateTime base, int months) {
  var month = base.month + months;
  var year = base.year;
  while (month <= 0) {
    month += 12;
    year--;
  }
  while (month > 12) {
    month -= 12;
    year++;
  }
  final maxDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, base.day.clamp(1, maxDay).toInt());
}

String _monthLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[date.month - 1];
}

bool _isCurrentMonth(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}

double _number(Object? value) {
  return value is num ? value.toDouble() : 0;
}

ForecastResult _currentMonthRunRateForecast(
  List<FinancialTransaction> transactions,
) {
  final now = DateTime.now();
  final currentExpenses = transactions.where(
    (transaction) =>
        transaction.type == 'expense' && _isCurrentMonth(transaction.date),
  );
  final totals = <String, double>{};
  for (final transaction in currentExpenses) {
    totals[transaction.category] =
        (totals[transaction.category] ?? 0) + transaction.amount;
  }
  if (totals.isEmpty) {
    return const ForecastResult(
      categoryPredictions: {},
      totalPredicted: 0,
      predictedSavings: 0,
      savingsPercentage: 0,
    );
  }
  final daysPassed = now.day.clamp(1, 31);
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final pace = daysInMonth / daysPassed;
  final projected = {
    for (final entry in totals.entries) entry.key: entry.value * pace,
  };
  final total = projected.values.fold<double>(0, (sum, value) => sum + value);
  return ForecastResult(
    categoryPredictions: projected,
    totalPredicted: total,
    predictedSavings: 0,
    savingsPercentage: 0,
  );
}

String _categoryName(String category) {
  final trimmed = category.trim();
  return trimmed.isEmpty ? 'General' : trimmed;
}

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('food') || value.contains('grocery')) {
    return Icons.restaurant_rounded;
  }
  if (value.contains('transport') || value.contains('fuel')) {
    return Icons.directions_car_rounded;
  }
  if (value.contains('rent') || value.contains('home')) {
    return Icons.home_rounded;
  }
  if (value.contains('bill') || value.contains('util')) {
    return Icons.receipt_rounded;
  }
  if (value.contains('health') || value.contains('medical')) {
    return Icons.local_hospital_rounded;
  }
  if (value.contains('education') || value.contains('school')) {
    return Icons.school_rounded;
  }
  return Icons.category_rounded;
}
