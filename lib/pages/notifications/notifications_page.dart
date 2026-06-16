import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/budget_plan.dart';
import '../../models/saving_goal.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _hideRead = false;
  final Set<String> _readIds = {};

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;

    if (firestoreService == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        child: StreamBuilder<List<FinancialTransaction>>(
          stream: firestoreService.getTransactions(),
          builder: (context, transactionSnapshot) {
            final transactions =
                transactionSnapshot.data ?? const <FinancialTransaction>[];
            return StreamBuilder<List<BudgetPlan>>(
              stream: firestoreService.getBudgetPlans(),
              builder: (context, budgetSnapshot) {
                final budgets = budgetSnapshot.data ?? const <BudgetPlan>[];
                return StreamBuilder<List<SavingGoal>>(
                  stream: firestoreService.getSavingGoals(),
                  builder: (context, goalSnapshot) {
                    final goals = goalSnapshot.data ?? const <SavingGoal>[];
                    final notifications = _buildNotifications(
                      transactions: transactions,
                      budgets: budgets,
                      goals: goals,
                    );
                    final visible = _hideRead
                        ? notifications
                              .where((item) => !_readIds.contains(item.id))
                              .toList()
                        : notifications;

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                      children: [
                        _NotificationsHeader(
                          unreadCount: notifications
                              .where((item) => !_readIds.contains(item.id))
                              .length,
                          hideRead: _hideRead,
                          onToggleHideRead: () =>
                              setState(() => _hideRead = !_hideRead),
                          onMarkAllRead: notifications.isEmpty
                              ? null
                              : () => setState(() {
                                  _readIds.addAll(
                                    notifications.map((item) => item.id),
                                  );
                                }),
                        ),
                        const SizedBox(height: 16),
                        if (visible.isEmpty)
                          _EmptyNotifications(hideRead: _hideRead)
                        else
                          ...visible.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _NotificationCard(
                                item: item,
                                read: _readIds.contains(item.id),
                                onTap: () =>
                                    setState(() => _readIds.add(item.id)),
                              ),
                            ),
                          ),
                      ],
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

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.hideRead,
    required this.onToggleHideRead,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final bool hideRead;
  final VoidCallback onToggleHideRead;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.outlined(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notifications',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onMarkAllRead,
              child: const Text('Mark read'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatusPill(
              label: '$unreadCount unread',
              color: unreadCount > 0 ? AppTheme.warning : AppTheme.success,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Unread only'),
              selected: hideRead,
              onSelected: (_) => onToggleHideRead(),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.read,
    required this.onTap,
  });

  final _AppNotification item;
  final bool read;
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
          border: Border.all(
            color: read
                ? AppTheme.borderFor(context)
                : item.color.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimaryFor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.timeLabel,
                    style: GoogleFonts.inter(
                      color: AppTheme.textHintFor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.hideRead});

  final bool hideRead;

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
          Icon(
            hideRead
                ? Icons.done_all_rounded
                : Icons.notifications_none_rounded,
            color: AppTheme.primaryFor(context),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            hideRead ? 'All caught up' : 'No alerts yet',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Budget limits, reminders, and savings milestones will appear here.',
            textAlign: TextAlign.center,
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
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AppNotification {
  const _AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.timeLabel,
    required this.sortDate,
  });

  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String timeLabel;
  final DateTime sortDate;
}

List<_AppNotification> _buildNotifications({
  required List<FinancialTransaction> transactions,
  required List<BudgetPlan> budgets,
  required List<SavingGoal> goals,
}) {
  final now = DateTime.now();
  final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final monthlyExpenses = transactions
      .where(
        (txn) =>
            txn.type == 'expense' &&
            (txn.monthKey == currentMonthKey ||
                (txn.date.year == now.year && txn.date.month == now.month)),
      )
      .toList();
  final notifications = <_AppNotification>[];

  for (final budget in budgets.where(
    (budget) => budget.monthKey == currentMonthKey,
  )) {
    final spent = monthlyExpenses
        .where(
          (txn) =>
              txn.category == budget.category ||
              txn.linkedBudgetCategory == budget.category,
        )
        .fold<double>(0, (total, txn) => total + txn.amount);
    if (budget.allocatedAmount > 0 && spent >= budget.allocatedAmount * 0.8) {
      final over = spent > budget.allocatedAmount;
      notifications.add(
        _AppNotification(
          id: 'budget-${budget.id}',
          title: over
              ? '${budget.category} is over budget'
              : 'Budget limit close',
          message: over
              ? '${CurrencyUtils.format(spent - budget.allocatedAmount)} over ${budget.category}.'
              : '${budget.category} has used ${(spent / budget.allocatedAmount * 100).toStringAsFixed(0)}% of its budget.',
          icon: Icons.account_balance_wallet_rounded,
          color: over ? AppTheme.error : AppTheme.warning,
          timeLabel: 'This month',
          sortDate: now,
        ),
      );
    }
    if (budget.reminderDate != null &&
        budget.reminderDate!.difference(now).inDays <= 3 &&
        !budget.reminderDate!.isBefore(
          DateTime(now.year, now.month, now.day),
        )) {
      notifications.add(
        _AppNotification(
          id: 'budget-reminder-${budget.id}',
          title: '${budget.category} reminder',
          message: 'Scheduled for ${_shortDate(budget.reminderDate!)}.',
          icon: Icons.notifications_active_rounded,
          color: AppTheme.primary,
          timeLabel: _relativeDate(budget.reminderDate!, now),
          sortDate: budget.reminderDate!,
        ),
      );
    }
  }

  for (final goal in goals) {
    if (goal.progress >= 0.75 && goal.remaining > 0) {
      notifications.add(
        _AppNotification(
          id: 'goal-${goal.id}',
          title: '${goal.title} is close',
          message:
              '${(goal.progress * 100).toStringAsFixed(0)}% complete. ${CurrencyUtils.format(goal.remaining)} left.',
          icon: Icons.savings_rounded,
          color: AppTheme.success,
          timeLabel: 'Savings goal',
          sortDate: goal.targetDate,
        ),
      );
    }
    if (goal.reminderDate != null &&
        goal.reminderDate!.difference(now).inDays <= 3 &&
        !goal.reminderDate!.isBefore(DateTime(now.year, now.month, now.day))) {
      notifications.add(
        _AppNotification(
          id: 'goal-reminder-${goal.id}',
          title: '${goal.title} reminder',
          message:
              'Payment or contribution reminder is due ${_relativeDate(goal.reminderDate!, now).toLowerCase()}.',
          icon: Icons.event_available_rounded,
          color: AppTheme.warning,
          timeLabel: _relativeDate(goal.reminderDate!, now),
          sortDate: goal.reminderDate!,
        ),
      );
    }
  }

  for (final transaction in transactions.where((txn) => txn.deadline != null)) {
    final deadline = transaction.deadline!;
    final days = deadline.difference(now).inDays;
    if (days >= 0 && days <= 3) {
      notifications.add(
        _AppNotification(
          id: 'transaction-${transaction.id}',
          title: '${transaction.title} due soon',
          message:
              '${CurrencyUtils.format(transaction.amount)} due ${_relativeDate(deadline, now).toLowerCase()}.',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.error,
          timeLabel: _relativeDate(deadline, now),
          sortDate: deadline,
        ),
      );
    }
  }

  notifications.sort((a, b) => a.sortDate.compareTo(b.sortDate));
  return notifications.take(20).toList();
}

String _shortDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}';
}

String _relativeDate(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final days = target.difference(today).inDays;
  if (days == 0) return 'Today';
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}
