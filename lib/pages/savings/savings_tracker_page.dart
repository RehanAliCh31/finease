import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/saving_goal.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';

class SavingsTrackerPage extends StatefulWidget {
  const SavingsTrackerPage({super.key});

  @override
  State<SavingsTrackerPage> createState() => _SavingsTrackerPageState();
}

class _SavingsTrackerPageState extends State<SavingsTrackerPage> {
  bool _rolloverChecked = false;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;

    if (firestoreService == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _scheduleRollover(context, firestoreService);

    return StreamBuilder<List<SavingGoal>>(
      stream: firestoreService.getSavingGoals(),
      builder: (context, goalSnapshot) {
        return StreamBuilder<Map<String, dynamic>>(
          stream: firestoreService.getUserProfile(),
          builder: (context, profileSnapshot) {
            final goals = goalSnapshot.data ?? const <SavingGoal>[];
            final profile = profileSnapshot.data ?? const <String, dynamic>{};
            final summary = _SavingsSummary.from(goals, profile);
            final sortedGoals = _sortGoals(goals);

            return Scaffold(
              backgroundColor: AppTheme.backgroundFor(context),
              body: SafeArea(
                child:
                    goalSnapshot.connectionState == ConnectionState.waiting &&
                        !goalSnapshot.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        children: [
                          _SavingsHeader(
                            summary: summary,
                            onNewGoal: () => _showGoalEditor(
                              context,
                              firestoreService: firestoreService,
                              summary: summary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SavingsOverviewCard(summary: summary),
                          if (summary.nextGoal != null) ...[
                            const SizedBox(height: 12),
                            _PriorityGoalCard(
                              goal: summary.nextGoal!,
                              summary: summary,
                              onContribute: () => _showContributionSheet(
                                context,
                                firestoreService,
                                summary.nextGoal!,
                                summary,
                              ),
                              onDetails: () => _showGoalDetailSheet(
                                context,
                                firestoreService: firestoreService,
                                goal: summary.nextGoal!,
                                summary: summary,
                              ),
                            ),
                          ],
                          if (summary.warningMessage != null) ...[
                            const SizedBox(height: 12),
                            _NoticeBanner(message: summary.warningMessage!),
                          ],
                          const SizedBox(height: 22),
                          _SectionTitle(
                            title: 'Goals',
                            trailing: '${summary.activeGoals} active',
                          ),
                          const SizedBox(height: 12),
                          if (sortedGoals.isEmpty)
                            _EmptySavingsState(
                              onPressed: () => _showGoalEditor(
                                context,
                                firestoreService: firestoreService,
                                summary: summary,
                              ),
                            )
                          else
                            ...sortedGoals.map(
                              (goal) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GoalCard(
                                  goal: goal,
                                  summary: summary,
                                  onContribute: () => _showContributionSheet(
                                    context,
                                    firestoreService,
                                    goal,
                                    summary,
                                  ),
                                  onDetails: () => _showGoalDetailSheet(
                                    context,
                                    firestoreService: firestoreService,
                                    goal: goal,
                                    summary: summary,
                                  ),
                                  onEdit: () => _showGoalEditor(
                                    context,
                                    firestoreService: firestoreService,
                                    summary: summary,
                                    existingGoal: goal,
                                  ),
                                  onDelete: () => _confirmDeleteGoal(
                                    context,
                                    firestoreService,
                                    goal,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: ElevatedButton.icon(
                  onPressed: () => _showGoalEditor(
                    context,
                    firestoreService: firestoreService,
                    summary: summary,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New goal'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scheduleRollover(
    BuildContext context,
    FirestoreService firestoreService,
  ) {
    if (_rolloverChecked) return;
    _rolloverChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await firestoreService.ensureMonthlySavingsRollover();
      final now = DateTime.now();
      final previous = DateTime(now.year, now.month - 1);
      final periodKey = _monthKey(previous);
      final leftover = await firestoreService.previewBudgetLeftover(
        periodType: 'monthly',
        periodKey: periodKey,
      );
      if (!context.mounted || leftover <= 0) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Move leftover to savings?'),
          content: Text(
            '${CurrencyUtils.format(leftover)} is left from last month.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Move'),
            ),
          ],
        ),
      );
      if (approved != true) return;
      await firestoreService.carryForwardBudgetLeftover(
        periodType: 'monthly',
        periodKey: periodKey,
        periodEnd: DateTime(now.year, now.month),
      );
    });
  }

  Future<void> _confirmDeleteGoal(
    BuildContext context,
    FirestoreService firestoreService,
    SavingGoal goal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text(
          'This removes "${goal.title}" and its contribution history.',
        ),
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

    if (confirmed != true) return;
    try {
      await firestoreService.deleteSavingGoal(goal.id);
      if (!context.mounted) return;
      _showSnack(context, '"${goal.title}" deleted');
    } on FinanceValidationException catch (error) {
      if (!context.mounted) return;
      _showSnack(context, error.message, isError: true);
    }
  }
}

class _SavingsSummary {
  const _SavingsSummary({
    required this.goals,
    required this.availableSavings,
    required this.totalSaved,
    required this.totalTarget,
    required this.monthlyNeed,
  });

  final List<SavingGoal> goals;
  final double availableSavings;
  final double totalSaved;
  final double totalTarget;
  final double monthlyNeed;

  factory _SavingsSummary.from(
    List<SavingGoal> goals,
    Map<String, dynamic> profile,
  ) {
    final availableSavings =
        ((profile['savingsBalance'] ?? 0) as num).toDouble() +
        ((profile['extraSavingsBalance'] ?? 0) as num).toDouble();
    final totalSaved = goals.fold<double>(
      0,
      (total, goal) => total + goal.currentAmount,
    );
    final totalTarget = goals.fold<double>(
      0,
      (total, goal) => total + goal.targetAmount,
    );
    final monthlyNeed = goals.fold<double>(
      0,
      (total, goal) => total + goal.monthlyTarget,
    );

    return _SavingsSummary(
      goals: goals,
      availableSavings: availableSavings,
      totalSaved: totalSaved,
      totalTarget: totalTarget,
      monthlyNeed: monthlyNeed,
    );
  }

  double get progress =>
      totalTarget <= 0 ? 0 : (totalSaved / totalTarget).clamp(0.0, 1.0);
  double get unallocated =>
      (availableSavings - totalSaved).clamp(0, double.infinity).toDouble();
  double get remainingTarget =>
      (totalTarget - totalSaved).clamp(0, double.infinity).toDouble();
  bool get isOverAllocated =>
      availableSavings > 0 && totalSaved > availableSavings + 0.01;
  int get activeGoals => goals.where((goal) => goal.remaining > 0).length;
  int get completedGoals => goals.where((goal) => goal.remaining <= 0).length;
  int get debtGoals => goals.where((goal) => goal.isDebtGoal).length;

  SavingGoal? get nextGoal {
    final active = goals.where((goal) => goal.remaining > 0).toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return active.isEmpty ? null : active.first;
  }

  String get motivationTitle {
    if (goals.isEmpty) return 'Start one goal';
    if (nextGoal != null && nextGoal!.daysLeft < 0) return 'Goal is overdue';
    if (nextGoal != null && nextGoal!.daysLeft <= 30) return 'Due soon';
    if (progress >= 0.75) return 'Strong progress';
    return 'Keep saving steady';
  }

  String get motivationMessage {
    if (goals.isEmpty) {
      return 'One clear target is easier to fund than many vague intentions.';
    }
    final goal = nextGoal;
    if (goal == null) {
      return 'All active goals are funded. Create the next target.';
    }
    if (goal.daysLeft < 0) {
      return '${goal.title} is past its target date. Add money or update the date.';
    }
    if (goal.daysLeft <= 30) {
      return '${goal.title} needs ${CurrencyUtils.format(goal.remaining)} within ${goal.daysLeft} days.';
    }
    return '${CurrencyUtils.format(goal.monthlyTarget)} per month keeps ${goal.title} on track.';
  }

  String? get warningMessage {
    if (isOverAllocated) {
      return 'Goals use more money than the savings pool. Reduce an allocation or add savings first.';
    }
    if (activeGoals >= 5) {
      return 'Many active goals can split attention. Keep the top priorities visible.';
    }
    if (nextGoal != null && nextGoal!.daysLeft < 0) {
      return '${nextGoal!.title} is past its target date.';
    }
    return null;
  }
}

class _SavingsHeader extends StatelessWidget {
  const _SavingsHeader({required this.summary, required this.onNewGoal});

  final _SavingsSummary summary;
  final VoidCallback onNewGoal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Savings',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.nextGoal == null
                    ? 'Start with one clear target.'
                    : 'Next: ${summary.nextGoal!.title}',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: onNewGoal,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'New goal',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryFor(context),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SavingsOverviewCard extends StatelessWidget {
  const _SavingsOverviewCard({required this.summary});

  final _SavingsSummary summary;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Saved in goals',
                  value: CurrencyUtils.format(summary.totalSaved),
                ),
              ),
              _StatusPill(
                label: '${(summary.progress * 100).toStringAsFixed(0)}%',
                color: AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: summary.progress,
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryFor(context),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  label: 'Pool left',
                  value: CurrencyUtils.format(summary.unallocated),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallStat(
                  label: 'Monthly need',
                  value: CurrencyUtils.format(summary.monthlyNeed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.summary,
    required this.onContribute,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingGoal goal;
  final _SavingsSummary summary;
  final VoidCallback onContribute;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final completed = goal.remaining <= 0;
    final late = goal.daysLeft < 0 && !completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GoalIcon(goal: goal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _goalSubtitle(goal),
                      style: GoogleFonts.inter(
                        color: late
                            ? AppTheme.error
                            : AppTheme.textSecondaryFor(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: goal.progress,
              backgroundColor: AppTheme.mutedFillFor(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                completed ? AppTheme.success : AppTheme.primaryFor(context),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CurrencyUtils.format(goal.currentAmount)} of ${CurrencyUtils.format(goal.targetAmount)}',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                completed
                    ? 'Done'
                    : '${CurrencyUtils.format(goal.remaining)} left',
                style: GoogleFonts.inter(
                  color: completed
                      ? AppTheme.success
                      : AppTheme.primaryFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: completed ? null : onContribute,
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text('Add money'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                onPressed: onDetails,
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'Details',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityGoalCard extends StatelessWidget {
  const _PriorityGoalCard({
    required this.goal,
    required this.summary,
    required this.onContribute,
    required this.onDetails,
  });

  final SavingGoal goal;
  final _SavingsSummary summary;
  final VoidCallback onContribute;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final urgent = goal.daysLeft <= 30 && goal.remaining > 0;
    final color = goal.daysLeft < 0
        ? AppTheme.error
        : urgent
        ? AppTheme.warning
        : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.isDark(context) ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GoalIcon(goal: goal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.motivationTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.motivationMessage,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    height: 1.4,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: goal.remaining <= 0 ? null : onContribute,
                        icon: const Icon(Icons.add_card_rounded, size: 18),
                        label: const Text('Contribute'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: onDetails,
                      icon: const Icon(Icons.info_outline_rounded),
                      tooltip: 'Details',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalIcon extends StatelessWidget {
  const _GoalIcon({required this.goal});

  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: goal.isDebtGoal
            ? AppTheme.warningFillFor(context)
            : AppTheme.successFillFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        goal.isDebtGoal ? Icons.payments_rounded : _categoryIcon(goal.category),
        color: goal.isDebtGoal ? AppTheme.warning : AppTheme.success,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryFor(context),
            ),
          ),
        ),
        Text(
          trailing,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

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
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimaryFor(context),
          ),
        ),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

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
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningFillFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.priority_high_rounded,
            color: AppTheme.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySavingsState extends StatelessWidget {
  const _EmptySavingsState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.successFillFor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.savings_rounded, color: AppTheme.success),
          ),
          const SizedBox(height: 12),
          Text(
            'No goals yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create one target and fund it from your savings pool.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create goal'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showGoalEditor(
  BuildContext context, {
  required FirestoreService firestoreService,
  required _SavingsSummary summary,
  SavingGoal? existingGoal,
}) async {
  final titleController = TextEditingController(
    text: existingGoal?.title ?? '',
  );
  final targetController = TextEditingController(
    text: existingGoal?.targetAmount.toStringAsFixed(0) ?? '',
  );
  final currentController = TextEditingController(
    text: existingGoal?.currentAmount.toStringAsFixed(0) ?? '0',
  );
  final today = DateTime.now();
  final firstDate = DateTime(today.year, today.month, today.day);
  var targetDate =
      existingGoal?.targetDate ?? today.add(const Duration(days: 180));
  if (targetDate.isBefore(firstDate)) targetDate = firstDate;
  var category =
      existingGoal?.goalType ?? existingGoal?.category ?? 'Emergency Fund';
  var isDebtGoal = existingGoal?.isDebtGoal ?? category == 'Debt Payoff';
  var payoffStrategy = existingGoal?.payoffStrategy ?? 'steady';
  DateTime? reminderDate = existingGoal?.reminderDate;

  const categories = [
    'Emergency Fund',
    'Debt Payoff',
    'Education',
    'House',
    'Vehicle',
    'Vacation',
    'Investment',
    'General',
  ];

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final target = double.tryParse(targetController.text.trim()) ?? 0;
            final current = double.tryParse(currentController.text.trim()) ?? 0;
            final allocationAfterEdit =
                summary.totalSaved -
                (existingGoal?.currentAmount ?? 0) +
                current;
            final allocationWarning =
                allocationAfterEdit > summary.availableSavings + 0.01;
            final invalid =
                titleController.text.trim().isEmpty ||
                target <= 0 ||
                current < 0 ||
                current > target ||
                allocationWarning;
            final draft = SavingGoal(
              id: existingGoal?.id ?? '',
              title: titleController.text.trim(),
              targetAmount: target,
              currentAmount: current,
              targetDate: targetDate,
              category: category,
              emoji: category,
              goalType: category,
              isDebtGoal: isDebtGoal,
              payoffStrategy: payoffStrategy,
              reminderDate: reminderDate,
            );

            return _BottomSheetFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SheetHandle(),
                  Text(
                    existingGoal == null ? 'New goal' : 'Edit goal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryFor(sheetContext),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SheetHint(
                    leading: 'Pool left',
                    value: CurrencyUtils.format(summary.unallocated),
                  ),
                  const SizedBox(height: 14),
                  _SheetField(
                    controller: titleController,
                    label: 'Goal name',
                    icon: Icons.flag_rounded,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SheetField(
                          controller: targetController,
                          label: 'Target',
                          icon: Icons.track_changes_rounded,
                          isNumber: true,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SheetField(
                          controller: currentController,
                          label: 'Saved now',
                          icon: Icons.account_balance_wallet_rounded,
                          isNumber: true,
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(category)
                        ? category
                        : 'General',
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: categories
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setSheetState(() {
                      category = value ?? 'General';
                      isDebtGoal = category == 'Debt Payoff';
                    }),
                  ),
                  const SizedBox(height: 12),
                  _PickerTile(
                    icon: Icons.event_rounded,
                    label: 'Target date',
                    value: DateFormat('MMM dd, yyyy').format(targetDate),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: targetDate,
                        firstDate: firstDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setSheetState(() => targetDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: isDebtGoal,
                    activeThumbColor: AppTheme.primaryFor(sheetContext),
                    title: const Text('Debt payoff goal'),
                    onChanged: (value) => setSheetState(() {
                      isDebtGoal = value;
                      if (value) category = 'Debt Payoff';
                    }),
                  ),
                  if (isDebtGoal) ...[
                    Wrap(
                      spacing: 8,
                      children: ['steady', 'snowball', 'avalanche'].map((item) {
                        return ChoiceChip(
                          label: Text(item),
                          selected: payoffStrategy == item,
                          onSelected: (_) =>
                              setSheetState(() => payoffStrategy = item),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _PickerTile(
                      icon: Icons.notifications_active_rounded,
                      label: 'Reminder',
                      value: reminderDate == null
                          ? 'Not set'
                          : DateFormat('MMM dd, yyyy').format(reminderDate!),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: reminderDate ?? firstDate,
                          firstDate: firstDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setSheetState(() => reminderDate = picked);
                        }
                      },
                    ),
                  ],
                  if (allocationWarning) ...[
                    const SizedBox(height: 12),
                    const _NoticeBanner(
                      message:
                          'This allocation is higher than the available savings pool.',
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: invalid
                          ? null
                          : () async {
                              final goal = draft.copyWith(
                                milestones: JourneyMilestone.generate(
                                  targetAmount: target,
                                  currentAmount: current,
                                  targetDate: targetDate,
                                ),
                              );
                              try {
                                if (existingGoal == null) {
                                  await firestoreService.addSavingGoal(goal);
                                } else {
                                  final data = goal.toMap();
                                  if (reminderDate == null) {
                                    data['reminderDate'] = null;
                                  }
                                  await firestoreService.updateSavingGoal(
                                    existingGoal.id,
                                    data,
                                  );
                                }
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } on FinanceValidationException catch (error) {
                                if (sheetContext.mounted) {
                                  _showSnack(
                                    sheetContext,
                                    error.message,
                                    isError: true,
                                  );
                                }
                              }
                            },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        existingGoal == null ? 'Save goal' : 'Update goal',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  } finally {
    titleController.dispose();
    targetController.dispose();
    currentController.dispose();
  }
}

Future<void> _showContributionSheet(
  BuildContext context,
  FirestoreService firestoreService,
  SavingGoal goal,
  _SavingsSummary summary,
) async {
  final controller = TextEditingController();
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _BottomSheetFrame(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              Text(
                'Add money',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryFor(sheetContext),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                goal.title,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(sheetContext),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _SheetHint(
                leading: 'Available',
                value: CurrencyUtils.format(summary.unallocated),
              ),
              const SizedBox(height: 14),
              _ContributionQuickAmounts(
                goal: goal,
                available: summary.unallocated,
                onSelected: (amount) {
                  controller.text = CurrencyUtils.exact(amount);
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                },
              ),
              const SizedBox(height: 14),
              _SheetField(
                controller: controller,
                label: 'Amount',
                icon: Icons.add_card_rounded,
                isNumber: true,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final amount =
                          double.tryParse(controller.text.trim()) ?? 0;
                      await firestoreService.addContribution(goal.id, amount);
                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      _showSnack(sheetContext, 'Money added to ${goal.title}');
                    } on FinanceValidationException catch (error) {
                      if (sheetContext.mounted) {
                        _showSnack(sheetContext, error.message, isError: true);
                      }
                    }
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Add contribution'),
                ),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

void _showGoalDetailSheet(
  BuildContext context, {
  required FirestoreService firestoreService,
  required SavingGoal goal,
  required _SavingsSummary summary,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _BottomSheetFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoalIcon(goal: goal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryFor(sheetContext),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _goalSubtitle(goal),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondaryFor(sheetContext),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SmallStat(
                    label: 'Remaining',
                    value: CurrencyUtils.format(goal.remaining),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SmallStat(
                    label: 'Each month',
                    value: CurrencyUtils.format(goal.monthlyTarget),
                  ),
                ),
              ],
            ),
            if (goal.isDebtGoal) ...[
              const SizedBox(height: 10),
              _SheetHint(leading: 'Payoff plan', value: goal.payoffStrategy),
            ],
            const SizedBox(height: 18),
            Text(
              'Recent contributions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryFor(sheetContext),
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestoreService.getContributions(goal.id),
              builder: (context, snapshot) {
                final contributions =
                    snapshot.data ?? const <Map<String, dynamic>>[];
                if (contributions.isEmpty) {
                  return Text(
                    'No contributions yet.',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(sheetContext),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return Column(
                  children: contributions.take(3).map((item) {
                    final amount = (item['amount'] as num).toDouble();
                    final date = item['date'] as DateTime;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.savings_rounded),
                      title: Text(CurrencyUtils.format(amount)),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(date)),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: goal.remaining <= 0
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            _showContributionSheet(
                              context,
                              firestoreService,
                              goal,
                              summary,
                            );
                          },
                    icon: const Icon(Icons.add_card_rounded),
                    label: const Text('Add money'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showGoalEditor(
                      context,
                      firestoreService: firestoreService,
                      summary: summary,
                      existingGoal: goal,
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit goal',
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppTheme.borderFor(context),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isNumber = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNumber;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryFor(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _SheetHint extends StatelessWidget {
  const _SheetHint({required this.leading, required this.value});

  final String leading;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              leading,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionQuickAmounts extends StatelessWidget {
  const _ContributionQuickAmounts({
    required this.goal,
    required this.available,
    required this.onSelected,
  });

  final SavingGoal goal;
  final double available;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final rawValues = <double>[
      if (goal.monthlyTarget > 0) goal.monthlyTarget,
      if (goal.remaining > 0) goal.remaining,
      if (available > 0) available,
    ];
    final values = <double>[];
    for (final raw in rawValues) {
      final value = raw.clamp(0, goal.remaining).toDouble();
      final isDuplicate = values.any(
        (existing) => (existing - value).abs() < 0.01,
      );
      if (value > 0 && !isDuplicate) values.add(value);
    }

    if (values.isEmpty) return const SizedBox.shrink();

    String labelFor(double amount) {
      if ((amount - goal.monthlyTarget).abs() < 0.01) return 'Monthly';
      if ((amount - goal.remaining).abs() < 0.01) return 'Finish';
      return 'Pool left';
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final amount = values[index];
          return ActionChip(
            avatar: const Icon(Icons.flash_on_rounded, size: 15),
            label: Text('${labelFor(amount)} ${CurrencyUtils.format(amount)}'),
            onPressed: () => onSelected(amount),
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

List<SavingGoal> _sortGoals(List<SavingGoal> goals) {
  return [...goals]..sort((a, b) {
    final aDone = a.remaining <= 0;
    final bDone = b.remaining <= 0;
    if (aDone != bDone) return aDone ? 1 : -1;
    return a.targetDate.compareTo(b.targetDate);
  });
}

String _goalSubtitle(SavingGoal goal) {
  if (goal.remaining <= 0) return 'Completed';
  if (goal.daysLeft < 0) return 'Past target date';
  if (goal.daysLeft == 0) return 'Due today';
  return '${goal.daysLeft} days left';
}

IconData _categoryIcon(String category) {
  final key = category.toLowerCase();
  if (key.contains('education')) return Icons.school_rounded;
  if (key.contains('house')) return Icons.home_rounded;
  if (key.contains('vehicle')) return Icons.directions_car_rounded;
  if (key.contains('vacation')) return Icons.flight_takeoff_rounded;
  if (key.contains('investment')) return Icons.trending_up_rounded;
  if (key.contains('emergency')) return Icons.health_and_safety_rounded;
  return Icons.savings_rounded;
}

String _monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ),
  );
}
