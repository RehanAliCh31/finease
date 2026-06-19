import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_config.dart';
import '../../models/budget_plan.dart';
import '../../models/saving_goal.dart';
import '../../models/transaction.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../utils/finance_consistency_utils.dart';
import '../../utils/profile_image_utils.dart';
import '../../widgets/app_config_gate.dart';
import '../analytics/analytics_screen.dart';
import '../budget/ai_budget_advisor_page.dart';
import '../chatbot/chatbot_page.dart';
import '../forecast/forecast_screen.dart';
import '../forum/community_forum_page.dart';
import '../literacy/literacy_hub_page.dart';
import '../loans/loan_simulator_page.dart';
import '../marketplace/marketplace_screen.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../savings/savings_tracker_page.dart';
import '../transactions/add_transaction_page.dart';
import '../transactions/all_transactions_page.dart';
import '../welfare/welfare_programs_page.dart';
import '../rewards/rewards_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.appConfig});

  final AppConfig? appConfig;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = authService.firestoreService;
    final appConfig = widget.appConfig ?? AppConfig.defaults();
    final primaryColor = appConfigColor(
      appConfig.primaryColorHex,
      AppTheme.primary,
    );
    final secondaryColor = appConfigColor(
      appConfig.secondaryColorHex,
      AppTheme.secondary,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _handleRefresh,
          color: primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _TopBar(
                    appConfig: appConfig,
                    primaryColor: primaryColor,
                    isRefreshing: _isRefreshing,
                    onNotificationsTap: () =>
                        _openPage(const NotificationsPage()),
                    onProfileTap: () => _openPage(const ProfilePage()),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: firestoreService == null
                      ? const SizedBox.shrink()
                      : StreamBuilder<List<FinancialTransaction>>(
                          stream: firestoreService.getTransactions(),
                          builder: (context, txnSnapshot) {
                            final transactions =
                                txnSnapshot.data ??
                                const <FinancialTransaction>[];
                            final monthly = _monthlyTransactions(transactions);
                            final income = monthly
                                .where((txn) => txn.type == 'income')
                                .fold<double>(
                                  0,
                                  (total, txn) => total + txn.amount,
                                );
                            final expenses = monthly
                                .where((txn) => txn.type == 'expense')
                                .fold<double>(
                                  0,
                                  (total, txn) => total + txn.amount,
                                );
                            return StreamBuilder<Map<String, dynamic>>(
                              stream: firestoreService.getMonthlySummary(),
                              builder: (context, summarySnapshot) {
                                final summary = summarySnapshot.data ?? {};
                                final summaryIncome =
                                    (summary['monthlyIncome'] as num?)
                                        ?.toDouble() ??
                                    income;
                                final summaryExpenses =
                                    (summary['totalExpenses'] as num?)
                                        ?.toDouble() ??
                                    expenses;
                                final balance =
                                    (summary['totalBalance'] as num?)
                                        ?.toDouble() ??
                                    summaryIncome - summaryExpenses;
                                return _BalanceCard(
                                  primaryColor: primaryColor,
                                  secondaryColor: secondaryColor,
                                  balance: balance,
                                  income: summaryIncome,
                                  expense: summaryExpenses,
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _PrimaryActionButton(
                    onTap: () => _openPage(const AddTransactionPage()),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: firestoreService == null
                      ? const SizedBox.shrink()
                      : _HomeSummaryPanel(
                          firestoreService: firestoreService,
                          onAddTransaction: () =>
                              _openPage(const AddTransactionPage()),
                          onViewTransactions: () =>
                              _openPage(const AllTransactionsPage()),
                          onOpenBudget: () =>
                              _openPage(const AIBudgetAdvisorPage()),
                          onOpenForecast: () =>
                              _openPage(const ForecastScreen()),
                          onOpenSavings: () =>
                              _openPage(const SavingsTrackerPage()),
                          onOpenAlerts: () =>
                              _openPage(const NotificationsPage()),
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _ToolsShortcutPanel(
                    onViewAll: () => _openToolsSheet(appConfig),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 118)),
            ],
          ),
        ),
      ),
    );
  }

  List<FinancialTransaction> _monthlyTransactions(
    List<FinancialTransaction> transactions,
  ) {
    final now = DateTime.now();
    return transactions
        .where(
          (txn) => txn.date.year == now.year && txn.date.month == now.month,
        )
        .toList();
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openDemoFlowSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DemoFlowSheet(),
    );
  }

  void _openToolsSheet(AppConfig appConfig) {
    final tools = [
      _ToolEntry(
        label: 'Demo flow',
        icon: Icons.play_circle_outline_rounded,
        color: AppTheme.primary,
        onTap: _openDemoFlowSheet,
      ),
      _ToolEntry(
        label: 'Budget',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF0EA5A4),
        onTap: () => _openPage(const AIBudgetAdvisorPage()),
      ),
      _ToolEntry(
        label: 'Savings',
        icon: Icons.savings_rounded,
        color: AppTheme.success,
        onTap: () => _openPage(const SavingsTrackerPage()),
      ),
      _ToolEntry(
        label: 'Transactions',
        icon: Icons.receipt_long_rounded,
        color: AppTheme.warning,
        onTap: () => _openPage(const AllTransactionsPage()),
      ),
      _ToolEntry(
        label: 'Analysis',
        icon: Icons.query_stats_rounded,
        color: const Color(0xFF4F46E5),
        onTap: () => _openPage(const AnalyticsScreen()),
      ),
      _ToolEntry(
        label: 'Forecast',
        icon: Icons.auto_graph_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: () => _openPage(const ForecastScreen()),
      ),
      _ToolEntry(
        label: 'Alerts',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFE11D48),
        onTap: () => _openPage(const NotificationsPage()),
      ),
      _ToolEntry(
        label: 'Loans',
        icon: Icons.calculate_rounded,
        color: const Color(0xFFD97706),
        onTap: () => _openPage(const LoanSimulatorPage()),
      ),
      _ToolEntry(
        label: 'Chatbot',
        icon: Icons.smart_toy_rounded,
        color: const Color(0xFF475569),
        enabled: appConfig.chatbotEnabled,
        onTap: () => _openFeature(
          enabled: appConfig.chatbotEnabled,
          title: 'AI chatbot is paused',
          message: appConfig.supportMessage,
          page: const ChatbotPage(),
        ),
      ),
      _ToolEntry(
        label: 'Marketplace',
        icon: Icons.storefront_rounded,
        color: AppTheme.primary,
        enabled: appConfig.marketplaceEnabled,
        onTap: () => _openFeature(
          enabled: appConfig.marketplaceEnabled,
          title: 'Marketplace is paused',
          message: appConfig.supportMessage,
          page: const MarketplaceScreen(),
        ),
      ),
      _ToolEntry(
        label: 'Literacy Hub',
        icon: Icons.school_rounded,
        color: const Color(0xFF4F46E5),
        onTap: () => _openPage(const LiteracyHubPage()),
      ),
      _ToolEntry(
        label: 'Welfare',
        icon: Icons.volunteer_activism_rounded,
        color: const Color(0xFFD97706),
        enabled: appConfig.welfareEnabled,
        onTap: () => _openFeature(
          enabled: appConfig.welfareEnabled,
          title: 'Welfare programs are paused',
          message: appConfig.supportMessage,
          page: const WelfareProgramsPage(),
        ),
      ),
      _ToolEntry(
        label: 'Forum',
        icon: Icons.forum_rounded,
        color: const Color(0xFF475569),
        enabled: appConfig.forumEnabled,
        onTap: () => _openFeature(
          enabled: appConfig.forumEnabled,
          title: 'Community forum is paused',
          message: appConfig.supportMessage,
          page: const CommunityForumPage(),
        ),
      ),
      _ToolEntry(
        label: 'Rewards',
        icon: Icons.card_giftcard_outlined,
        color: const Color(0xFF475569),
        onTap: () => _openPage(const RewardsScreen()),
        ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ToolsSheet(tools: tools),
    );
  }

  void _openFeature({
    required bool enabled,
    required String title,
    required String message,
    required Widget page,
  }) {
    if (!enabled) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$title. $message')));
      return;
    }

    _openPage(page);
  }
}

class _HomeSummaryPanel extends StatelessWidget {
  const _HomeSummaryPanel({
    required this.firestoreService,
    required this.onAddTransaction,
    required this.onViewTransactions,
    required this.onOpenBudget,
    required this.onOpenForecast,
    required this.onOpenSavings,
    required this.onOpenAlerts,
  });

  final FirestoreService firestoreService;
  final VoidCallback onAddTransaction;
  final VoidCallback onViewTransactions;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenForecast;
  final VoidCallback onOpenSavings;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return StreamBuilder<List<FinancialTransaction>>(
      stream: firestoreService.getTransactions(),
      builder: (context, txnSnapshot) {
        final transactions = txnSnapshot.data ?? const <FinancialTransaction>[];
        return StreamBuilder<List<SavingGoal>>(
          stream: firestoreService.getSavingGoals(),
          builder: (context, goalSnapshot) {
            final goals = goalSnapshot.data ?? const <SavingGoal>[];
            return StreamBuilder<List<BudgetPlan>>(
              stream: firestoreService.getBudgetPlans(monthKey: monthKey),
              builder: (context, budgetSnapshot) {
                final budgets = budgetSnapshot.data ?? const <BudgetPlan>[];
                return StreamBuilder<Map<String, dynamic>>(
                  stream: firestoreService.getUserProfile(),
                  builder: (context, profileSnapshot) {
                    final profile = profileSnapshot.data ?? const {};
                    final analytics = _HomeDashboardAnalytics.from(
                      transactions: transactions,
                      goals: goals,
                      budgets: budgets,
                      profile: profile,
                    );
                    return Column(
                      children: [
                        _SmartInsightCard(
                          analytics: analytics,
                          onAddTransaction: onAddTransaction,
                        ),
                        const SizedBox(height: 12),
                        _NextBestActionCard(
                          analytics: analytics,
                          onAddTransaction: onAddTransaction,
                          onOpenBudget: onOpenBudget,
                          onOpenForecast: onOpenForecast,
                          onOpenSavings: onOpenSavings,
                          onOpenAlerts: onOpenAlerts,
                        ),
                        const SizedBox(height: 12),
                        _CoreActionStrip(
                          onBudget: onOpenBudget,
                          onForecast: onOpenForecast,
                          onSavings: onOpenSavings,
                          onAlerts: onOpenAlerts,
                        ),
                        const SizedBox(height: 16),
                        _UpcomingCard(analytics: analytics),
                        const SizedBox(height: 16),
                        _RecentTransactionsPreview(
                          transactions: analytics.recentTransactions,
                          onViewAll: onViewTransactions,
                          onAddTransaction: onAddTransaction,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeDashboardAnalytics {
  const _HomeDashboardAnalytics({
    required this.transactions,
    required this.goals,
    required this.budgets,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.totalBudgeted,
    required this.totalSaved,
    required this.totalTarget,
    required this.profileSavings,
  });

  final List<FinancialTransaction> transactions;
  final List<SavingGoal> goals;
  final List<BudgetPlan> budgets;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double totalBudgeted;
  final double totalSaved;
  final double totalTarget;
  final double profileSavings;

  factory _HomeDashboardAnalytics.from({
    required List<FinancialTransaction> transactions,
    required List<SavingGoal> goals,
    required List<BudgetPlan> budgets,
    required Map<String, dynamic> profile,
  }) {
    final now = DateTime.now();
    final monthlyTransactions = transactions
        .where(
          (txn) => txn.date.year == now.year && txn.date.month == now.month,
        )
        .toList();
    final income = monthlyTransactions
        .where((txn) => txn.type == 'income')
        .fold<double>(0, (total, txn) => total + txn.amount);
    final expenses = monthlyTransactions
        .where((txn) => txn.type == 'expense')
        .fold<double>(0, (total, txn) => total + txn.amount);
    final profileIncome = ((profile['monthlyIncome'] ?? 0) as num).toDouble();

    return _HomeDashboardAnalytics(
      transactions: transactions,
      goals: goals,
      budgets: budgets,
      monthlyIncome: FinanceConsistencyUtils.resolveMonthlyIncome(
        profileMonthlyIncome: profileIncome,
        transactionIncome: income,
      ),
      monthlyExpenses: expenses,
      totalBudgeted: budgets.fold<double>(
        0,
        (total, budget) => total + budget.allocatedAmount,
      ),
      totalSaved: goals.fold<double>(
        0,
        (total, goal) => total + goal.currentAmount,
      ),
      totalTarget: goals.fold<double>(
        0,
        (total, goal) => total + goal.targetAmount,
      ),
      profileSavings:
          ((profile['savingsBalance'] ?? 0) as num).toDouble() +
          ((profile['extraSavingsBalance'] ?? 0) as num).toDouble(),
    );
  }

  double get moneyLeft =>
      (monthlyIncome - monthlyExpenses).clamp(0, double.infinity).toDouble();
  bool get hasFinancialData =>
      transactions.isNotEmpty ||
      goals.isNotEmpty ||
      budgets.isNotEmpty ||
      monthlyIncome > 0 ||
      profileSavings > 0;
  bool get overBudget => monthlyExpenses > totalBudgeted && totalBudgeted > 0;
  bool get overIncome => monthlyExpenses > monthlyIncome && monthlyIncome > 0;
  bool get hasBudgetPlan => totalBudgeted > 0;
  bool get hasSavingsGoal => goals.isNotEmpty;
  bool get hasUpcomingRisk => reminders.any((item) => item.urgent);
  double get savingsProgress =>
      totalTarget <= 0 ? 0 : (totalSaved / totalTarget).clamp(0, 1);
  List<FinancialTransaction> get recentTransactions =>
      transactions.take(3).toList();

  String get nextActionTitle {
    if (!hasFinancialData) return 'Start with one transaction';
    if (overIncome) return 'Fix cash shortfall first';
    if (overBudget) return 'Review budget limits';
    if (hasUpcomingRisk) return 'Check urgent alerts';
    if (!hasBudgetPlan) return 'Create your monthly plan';
    if (!hasSavingsGoal) return 'Set one savings goal';
    return 'Preview next month';
  }

  String get nextActionMessage {
    if (!hasFinancialData) {
      return 'Add income or an expense so every module has real data to work with.';
    }
    if (overIncome) {
      return 'Expenses are above income. Open alerts before adding new plans.';
    }
    if (overBudget) {
      return 'Your budget is over plan. Adjust allocations before more spending.';
    }
    if (hasUpcomingRisk) {
      return 'You have a deadline or reminder close enough to need attention.';
    }
    if (!hasBudgetPlan) {
      return 'A budget turns transactions into a clear monthly decision system.';
    }
    if (!hasSavingsGoal) {
      return 'A goal gives leftover money somewhere useful to go.';
    }
    return 'Use Forecast to see whether next month still looks safe.';
  }

  String get nextActionLabel {
    if (!hasFinancialData) return 'Add transaction';
    if (overIncome || hasUpcomingRisk) return 'Open alerts';
    if (overBudget || !hasBudgetPlan) return 'Open budget';
    if (!hasSavingsGoal) return 'Open savings';
    return 'Open forecast';
  }

  Color get nextActionColor {
    if (overIncome) return AppTheme.error;
    if (overBudget || hasUpcomingRisk) return AppTheme.warning;
    if (!hasFinancialData) return AppTheme.primary;
    return AppTheme.success;
  }

  String get insight {
    if (!hasFinancialData) {
      return 'Add income or one expense to unlock a useful monthly view.';
    }
    if (overIncome) {
      final overBy = monthlyExpenses - monthlyIncome;
      return 'Expenses are ${CurrencyUtils.format(overBy)} above income this month.';
    }
    if (overBudget) {
      final overBy = monthlyExpenses - totalBudgeted;
      return 'Budget is ${CurrencyUtils.format(overBy)} over plan. Pause optional spending first.';
    }
    if (monthlyIncome > 0) {
      return '${CurrencyUtils.format(moneyLeft)} is still available after this month\'s expenses.';
    }
    if (goals.isNotEmpty) {
      final percent = (savingsProgress * 100).round();
      return 'Savings goals are $percent% funded. Update the next goal when money moves.';
    }
    return 'Create a budget or savings goal so FinEase can guide the next decision.';
  }

  List<_ReminderItem> get reminders {
    final now = DateTime.now();
    final items = <_ReminderItem>[
      ...transactions
          .where((txn) => txn.deadline != null)
          .map(
            (txn) => _ReminderItem(
              title: txn.title,
              date: txn.deadline!,
              type: txn.category,
              urgent: txn.deadline!.difference(now).inDays <= 3,
            ),
          ),
      ...goals
          .where((goal) => goal.reminderDate != null)
          .map(
            (goal) => _ReminderItem(
              title: goal.title,
              date: goal.reminderDate!,
              type: goal.isDebtGoal ? 'Debt' : 'Goal',
              urgent: goal.reminderDate!.difference(now).inDays <= 5,
            ),
          ),
      ...budgets
          .where((budget) => budget.reminderDate != null)
          .map(
            (budget) => _ReminderItem(
              title: budget.title,
              date: budget.reminderDate!,
              type: budget.isDebtPayment ? 'Debt budget' : 'Budget',
              urgent: budget.reminderDate!.difference(now).inDays <= 5,
            ),
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return items.take(2).toList();
  }
}

class _ReminderItem {
  const _ReminderItem({
    required this.title,
    required this.date,
    required this.type,
    required this.urgent,
  });

  final String title;
  final DateTime date;
  final String type;
  final bool urgent;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.appConfig,
    required this.primaryColor,
    required this.isRefreshing,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final AppConfig appConfig;
  final Color primaryColor;
  final bool isRefreshing;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;
    return StreamBuilder<Map<String, dynamic>>(
      stream: firestoreService?.getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? const {};
        final user = context.watch<AuthService>().user;
        final name =
            (profile['fullName'] as String?)?.split(' ').first ??
            user?.displayName?.split(' ').first ??
            user?.email?.split('@').first ??
            'there';
        final image = profileImageProvider(
          photoUrl: profile['photoUrl'] as String? ?? user?.photoURL,
          photoDataUrl: profile['photoDataUrl'] as String?,
        );

        return Row(
          children: [
            AppBrandLogo(
              logoUrl: appConfig.logoUrl,
              size: 42,
              backgroundColor: primaryColor.withValues(alpha: 0.08),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isRefreshing ? 'Refreshing your money' : 'Your money today',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color:
                          (Theme.of(context).textTheme.bodyMedium?.color ??
                          AppTheme.textSecondaryFor(context)),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_none_rounded),
              color: primaryColor,
              tooltip: 'Open alerts',
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: AppTheme.softShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: image != null
                      ? Image(
                          image: image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _DefaultProfileAvatar(primaryColor: primaryColor),
                        )
                      : _DefaultProfileAvatar(primaryColor: primaryColor),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DefaultProfileAvatar extends StatelessWidget {
  const _DefaultProfileAvatar({required this.primaryColor});

  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: primaryColor,
      child: const Icon(Icons.person_rounded, color: Colors.white),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.primaryColor,
    required this.secondaryColor,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final moneyLeft = income - expense;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This month',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtils.format(balance),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current balance',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _BalanceStat(
                  label: 'Income',
                  value: CurrencyUtils.format(income),
                ),
              ),
              Expanded(
                child: _BalanceStat(
                  label: 'Spent',
                  value: CurrencyUtils.format(expense),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MoneyLeftPill(value: moneyLeft),
        ],
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  const _BalanceStat({required this.label, required this.value});

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
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _MoneyLeftPill extends StatelessWidget {
  const _MoneyLeftPill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final isShort = value < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isShort
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isShort
                  ? '${CurrencyUtils.format(value.abs())} over income'
                  : '${CurrencyUtils.format(value)} left after expenses',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add transaction'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _SmartInsightCard extends StatelessWidget {
  const _SmartInsightCard({
    required this.analytics,
    required this.onAddTransaction,
  });

  final _HomeDashboardAnalytics analytics;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final color = analytics.overIncome || analytics.overBudget
        ? AppTheme.warning
        : AppTheme.primary;
    return _HomeCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(
            icon: analytics.hasFinancialData
                ? Icons.auto_awesome_rounded
                : Icons.edit_note_rounded,
            color: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analytics.hasFinancialData
                      ? 'Today\'s insight'
                      : 'Start your setup',
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  analytics.insight,
                  style: GoogleFonts.inter(
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                        AppTheme.textSecondaryFor(context)),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!analytics.hasFinancialData) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onAddTransaction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Add first transaction'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBestActionCard extends StatelessWidget {
  const _NextBestActionCard({
    required this.analytics,
    required this.onAddTransaction,
    required this.onOpenBudget,
    required this.onOpenForecast,
    required this.onOpenSavings,
    required this.onOpenAlerts,
  });

  final _HomeDashboardAnalytics analytics;
  final VoidCallback onAddTransaction;
  final VoidCallback onOpenBudget;
  final VoidCallback onOpenForecast;
  final VoidCallback onOpenSavings;
  final VoidCallback onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final action = _resolveAction();
    final color = analytics.nextActionColor;
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
          _IconBadge(icon: action.icon, color: color, size: 42, iconSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analytics.nextActionTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analytics.nextActionMessage,
                  style: GoogleFonts.inter(
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                        AppTheme.textSecondaryFor(context)),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: action.onTap,
                    icon: Icon(action.icon, size: 18),
                    label: Text(analytics.nextActionLabel),
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
                        fontSize: 13,
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

  _ResolvedHomeAction _resolveAction() {
    if (!analytics.hasFinancialData) {
      return _ResolvedHomeAction(
        icon: Icons.add_rounded,
        onTap: onAddTransaction,
      );
    }
    if (analytics.overIncome || analytics.hasUpcomingRisk) {
      return _ResolvedHomeAction(
        icon: Icons.notifications_active_rounded,
        onTap: onOpenAlerts,
      );
    }
    if (analytics.overBudget || !analytics.hasBudgetPlan) {
      return _ResolvedHomeAction(
        icon: Icons.account_balance_wallet_rounded,
        onTap: onOpenBudget,
      );
    }
    if (!analytics.hasSavingsGoal) {
      return _ResolvedHomeAction(
        icon: Icons.savings_rounded,
        onTap: onOpenSavings,
      );
    }
    return _ResolvedHomeAction(
      icon: Icons.auto_graph_rounded,
      onTap: onOpenForecast,
    );
  }
}

class _CoreActionStrip extends StatelessWidget {
  const _CoreActionStrip({
    required this.onBudget,
    required this.onForecast,
    required this.onSavings,
    required this.onAlerts,
  });

  final VoidCallback onBudget;
  final VoidCallback onForecast;
  final VoidCallback onSavings;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickHomeAction(
        label: 'Budget',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF0EA5A4),
        onTap: onBudget,
      ),
      _QuickHomeAction(
        label: 'Forecast',
        icon: Icons.auto_graph_rounded,
        color: const Color(0xFF0EA5E9),
        onTap: onForecast,
      ),
      _QuickHomeAction(
        label: 'Savings',
        icon: Icons.savings_rounded,
        color: AppTheme.success,
        onTap: onSavings,
      ),
      _QuickHomeAction(
        label: 'Alerts',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFE11D48),
        onTap: onAlerts,
      ),
    ];

    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionButton(action: action);
        },
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.action});

  final _QuickHomeAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            _IconBadge(
              icon: action.icon,
              color: action.color,
              size: 34,
              iconSize: 17,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvedHomeAction {
  const _ResolvedHomeAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;
}

class _QuickHomeAction {
  const _QuickHomeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.analytics});

  final _HomeDashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final reminders = analytics.reminders;
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Upcoming', actionLabel: 'Next 2'),
          const SizedBox(height: 12),
          if (reminders.isEmpty)
            Text(
              'No urgent reminders. Bills, budgets, and saving goal dates will show here.',
              style: GoogleFonts.inter(
                color:
                    (Theme.of(context).textTheme.bodyMedium?.color ??
                    AppTheme.textSecondaryFor(context)),
                height: 1.4,
              ),
            )
          else
            Column(
              children: reminders
                  .map((item) => _ReminderTile(item: item))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.item});

  final _ReminderItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.urgent ? AppTheme.warning : AppTheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _IconBadge(
            icon: item.urgent
                ? Icons.priority_high_rounded
                : Icons.event_rounded,
            color: color,
            size: 38,
            iconSize: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.type} - ${DateFormat('MMM d').format(item.date)}',
                  style: GoogleFonts.inter(
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                        AppTheme.textSecondaryFor(context)),
                    fontSize: 12,
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

class _RecentTransactionsPreview extends StatelessWidget {
  const _RecentTransactionsPreview({
    required this.transactions,
    required this.onViewAll,
    required this.onAddTransaction,
  });

  final List<FinancialTransaction> transactions;
  final VoidCallback onViewAll;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Recent',
            actionLabel: transactions.isEmpty ? '' : 'See all',
            onTap: transactions.isEmpty ? null : onViewAll,
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            _EmptyState(onAddTransaction: onAddTransaction)
          else
            Column(
              children: transactions
                  .map((txn) => _TransactionTile(txn: txn))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.txn});

  final FinancialTransaction txn;

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.type == 'income';
    final isTransfer = txn.type == 'transfer';
    final color = isIncome
        ? AppTheme.success
        : isTransfer
        ? AppTheme.primary
        : AppTheme.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _IconBadge(
            icon: isIncome
                ? Icons.south_west_rounded
                : isTransfer
                ? Icons.swap_horiz_rounded
                : Icons.north_east_rounded,
            color: color,
            size: 42,
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  txn.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                        AppTheme.textSecondaryFor(context)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            CurrencyUtils.format(txn.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTransaction});

  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mutedFillFor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add one income or expense to make the home screen useful.',
            style: GoogleFonts.inter(
              color:
                  (Theme.of(context).textTheme.bodyMedium?.color ??
                  AppTheme.textSecondaryFor(context)),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onAddTransaction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Add transaction'),
          ),
        ],
      ),
    );
  }
}

class _DemoFlowSheet extends StatelessWidget {
  const _DemoFlowSheet();

  static const _steps = [
    _DemoStep(
      title: '1. Login with demo account',
      proof: 'Seeded Firebase data makes the app feel alive immediately.',
    ),
    _DemoStep(
      title: '2. Home command center',
      proof: 'Shows balance, current-month status, next action, and alerts.',
    ),
    _DemoStep(
      title: '3. Transactions',
      proof: 'Add income or expenses and show all modules update from data.',
    ),
    _DemoStep(
      title: '4. Budget',
      proof: 'Proves the core planning engine: income, allocation, spend risk.',
    ),
    _DemoStep(
      title: '5. Forecast and Alerts',
      proof: 'Shows future risk and a live financial risk inbox.',
    ),
    _DemoStep(
      title: '6. Savings and Loans',
      proof: 'Connects goals and borrowing decisions to affordability.',
    ),
    _DemoStep(
      title: '7. Literacy, Welfare, Marketplace',
      proof: 'Turns money risk into learning, support, and partner options.',
    ),
    _DemoStep(
      title: '8. Admin account',
      proof: 'Shows moderation, partners, feature flags, and platform control.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _IconBadge(
                icon: Icons.play_circle_outline_rounded,
                color: AppTheme.primary,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recruiter demo flow',
                      style: GoogleFonts.plusJakartaSans(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Follow this sequence to prove one clear resilience story.',
                      style: GoogleFonts.inter(
                        color:
                            (Theme.of(context).textTheme.bodyMedium?.color ??
                            AppTheme.textSecondaryFor(context)),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _steps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.mutedFillFor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title.substring(3),
                              style: GoogleFonts.plusJakartaSans(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.proof,
                              style: GoogleFonts.inter(
                                color:
                                    (Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    AppTheme.textSecondaryFor(context)),
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoStep {
  const _DemoStep({required this.title, required this.proof});

  final String title;
  final String proof;
}

class _ToolsShortcutPanel extends StatelessWidget {
  const _ToolsShortcutPanel({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _HomeCard(
      child: Row(
        children: [
          _IconBadge(icon: Icons.apps_rounded, color: AppTheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More tools',
                  style: GoogleFonts.plusJakartaSans(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Learning, support, community, partners, and demo flow.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color:
                        (Theme.of(context).textTheme.bodyMedium?.color ??
                        AppTheme.textSecondaryFor(context)),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onViewAll,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppTheme.primary,
            tooltip: 'Open tools',
          ),
        ],
      ),
    );
  }
}

class _ToolsSheet extends StatelessWidget {
  const _ToolsSheet({required this.tools});

  final List<_ToolEntry> tools;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'All tools',
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: tools.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.85,
              ),
              itemBuilder: (context, index) {
                final tool = tools[index];
                return _ToolTile(tool: tool);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.tool});

  final _ToolEntry tool;

  @override
  Widget build(BuildContext context) {
    final color = tool.enabled ? tool.color : AppTheme.textHintFor(context);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pop(context);
        tool.onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.mutedFillFor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            _IconBadge(icon: tool.icon, color: color, size: 38, iconSize: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  if (!tool.enabled) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Paused',
                      style: GoogleFonts.inter(
                        color: AppTheme.textHintFor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolEntry {
  const _ToolEntry({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel = '',
    this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onTap;

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
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        if (actionLabel.isNotEmpty)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel),
          ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 21,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
