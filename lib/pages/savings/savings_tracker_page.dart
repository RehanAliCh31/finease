import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/saving_goal.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SavingsTrackerPage extends StatelessWidget {
  const SavingsTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;
    const primaryColor = Color(0xFF2E3192);
    const accentColor = Color(0xFF1BFFFF);

    if (firestoreService == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: StreamBuilder<List<SavingGoal>>(
        stream: firestoreService.getSavingGoals(),
        builder: (context, snapshot) {
          final goals = snapshot.data ?? const <SavingGoal>[];
          final totalSaved = goals.fold<double>(
            0,
            (sum, goal) => sum + goal.currentAmount,
          );
          final totalTarget = goals.fold<double>(
            0,
            (sum, goal) => sum + goal.targetAmount,
          );
          final progress = totalTarget == 0 ? 0.0 : totalSaved / totalTarget;
          final aiService = AIService();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                pinned: true,
                backgroundColor: primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 18),
                  title: Text(
                    'Savings Tracker',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: primaryColor),
                      Positioned(
                        right: -24,
                        top: -24,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SummaryCard(
                      totalSaved: totalSaved,
                      totalTarget: totalTarget,
                      progress: progress.clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<String>(
                      future: aiService.getSavingsInsight(goals),
                      builder: (context, snapshot) => _AdviceCard(
                        title: 'AI Savings Suggestions',
                        body:
                            snapshot.data ??
                            'Generating savings suggestions...',
                        icon: Icons.auto_awesome_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<String>(
                      future: aiService.getInvestmentSuggestions(
                        goals,
                        totalSaved,
                      ),
                      builder: (context, snapshot) => _AdviceCard(
                        title: 'AI Investment Opportunities',
                        body:
                            snapshot.data ??
                            'Analyzing suitable opportunities...',
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Goals',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showGoalEditor(
                            context,
                            firestoreService: firestoreService,
                          ),
                          child: const Text('Add Goal'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (goals.isEmpty)
                      _EmptyState(
                        onPressed: () => _showGoalEditor(
                          context,
                          firestoreService: firestoreService,
                        ),
                      )
                    else
                      ...goals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _GoalCard(goal: goal),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showGoalEditor(context, firestoreService: firestoreService),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Goal',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalSaved,
    required this.totalTarget,
    required this.progress,
  });

  final double totalSaved;
  final double totalTarget;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved across all goals',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalSaved.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: const Color(0xFF1BFFFF),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(progress * 100).round()}% of \$${totalTarget.toStringAsFixed(0)} total targets funded.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF2E3192)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF475569),
                    height: 1.5,
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

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingGoal goal;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<AuthService>().firestoreService!;
    final aiService = AIService();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${goal.category} • ${goal.daysLeft} days left',
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showGoalEditor(
                      context,
                      firestoreService: firestoreService,
                      existingGoal: goal,
                    );
                  } else if (value == 'delete') {
                    await firestoreService.deleteSavingGoal(goal.id);
                  } else if (value == 'contribute') {
                    _showContributionDialog(context, firestoreService, goal);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'contribute',
                    child: Text('Add Contribution'),
                  ),
                  PopupMenuItem(value: 'edit', child: Text('Edit Goal')),
                  PopupMenuItem(value: 'delete', child: Text('Delete Goal')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${goal.currentAmount.toStringAsFixed(0)} saved',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E3192),
                ),
              ),
              Text(
                'Target \$${goal.targetAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF2E3192),
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<String>(
            future: aiService.getGoalImprovementTips(goal),
            builder: (context, snapshot) => Text(
              snapshot.data ?? 'Generating personalized goal suggestion...',
              style: GoogleFonts.inter(
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Recent contributions',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.getContributions(goal.id),
            builder: (context, snapshot) {
              final contributions = snapshot.data ?? const [];
              if (contributions.isEmpty) {
                return Text(
                  'No contributions yet. Add one to start tracking savings growth.',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                );
              }

              final monthlyGrowth = contributions.fold<double>(
                0,
                (sum, item) => sum + (item['amount'] as double? ?? 0),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Savings growth: +\$${monthlyGrowth.toStringAsFixed(0)} from recent contributions',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF059669),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...contributions
                      .take(4)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEF2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.north_east_rounded,
                                  color: Color(0xFF2E3192),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(item['date'] as DateTime),
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '+\$${(item['amount'] as double).toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.savings_rounded, size: 56, color: Color(0xFF2E3192)),
          const SizedBox(height: 16),
          Text(
            'No savings goals yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create a goal to track progress, contributions, AI savings tips, and investment-ready milestones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onPressed,
            child: const Text('Create Goal'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showGoalEditor(
  BuildContext context, {
  required FirestoreService firestoreService,
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
  final dateController = TextEditingController(
    text: existingGoal == null
        ? DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 180)))
        : DateFormat('yyyy-MM-dd').format(existingGoal.targetDate),
  );
  var category = existingGoal?.category ?? 'General';
  final categories = [
    'General',
    'Emergency',
    'Travel',
    'Home',
    'Education',
    'Investment',
    'Shopping',
  ];

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.fromLTRB(
              24,
              20,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  existingGoal == null ? 'Create Goal' : 'Edit Goal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _field(titleController, 'Goal title'),
                const SizedBox(height: 12),
                _field(targetController, 'Target amount', isNumber: true),
                const SizedBox(height: 12),
                _field(currentController, 'Current savings', isNumber: true),
                const SizedBox(height: 12),
                _field(dateController, 'Target date (YYYY-MM-DD)'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((item) {
                    final selected = item == category;
                    return ChoiceChip(
                      label: Text(item),
                      selected: selected,
                      onSelected: (_) => setModalState(() => category = item),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final targetDate =
                          DateTime.tryParse(dateController.text.trim()) ??
                          DateTime.now().add(const Duration(days: 180));
                      final data = {
                        'title': titleController.text.trim(),
                        'targetAmount':
                            double.tryParse(targetController.text.trim()) ?? 0,
                        'currentAmount':
                            double.tryParse(currentController.text.trim()) ?? 0,
                        'targetDate': targetDate,
                        'category': category,
                      };

                      if (existingGoal == null) {
                        await firestoreService.addSavingGoal(
                          SavingGoal(
                            id: '',
                            title: data['title']! as String,
                            targetAmount: data['targetAmount']! as double,
                            currentAmount: data['currentAmount']! as double,
                            targetDate: data['targetDate']! as DateTime,
                            category: data['category']! as String,
                          ),
                        );
                      } else {
                        await firestoreService
                            .updateSavingGoal(existingGoal.id, {
                              'title': data['title'],
                              'targetAmount': data['targetAmount'],
                              'currentAmount': data['currentAmount'],
                              'targetDate': data['targetDate'],
                              'category': data['category'],
                            });
                      }

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      existingGoal == null ? 'Save Goal' : 'Update Goal',
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
}

Future<void> _showContributionDialog(
  BuildContext context,
  FirestoreService firestoreService,
  SavingGoal goal,
) async {
  final controller = TextEditingController();
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Add contribution to ${goal.title}'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Amount'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await firestoreService.addContribution(
              goal.id,
              double.tryParse(controller.text.trim()) ?? 0,
            );
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  bool isNumber = false,
}) {
  return TextField(
    controller: controller,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(labelText: label),
  );
}
