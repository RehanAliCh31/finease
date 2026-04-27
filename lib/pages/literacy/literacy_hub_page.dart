import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/demo_finance_data.dart';
import '../../models/lesson.dart';
import '../../services/auth_service.dart';

class LiteracyHubPage extends StatelessWidget {
  const LiteracyHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = authService.firestoreService;
    const primaryColor = Color(0xFF2E3192);
    const secondaryColor = Color(0xFF1BFFFF);
    const darkColor = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, Color(0xFF1B1B4D)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -20,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: secondaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Literacy Hub',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Original courses, saved lesson progress, and working quizzes.',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 15,
                          ),
                        ),
                      ],
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
                _buildOverviewCard(firestoreService),
                const SizedBox(height: 28),
                _buildCategoryRow(darkColor),
                const SizedBox(height: 28),
                ...DemoFinanceData.courses.map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _CourseCard(course: course),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(dynamic firestoreService) {
    final totalLessons = DemoFinanceData.courses.fold<int>(
      0,
      (sum, course) => sum + course.lessons.length,
    );
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: firestoreService == null
          ? Future.value(const [])
          : Future.wait(
              DemoFinanceData.courses.map((course) async {
                final progress = await firestoreService
                    .getCourseProgress(course.id)
                    .first;
                final completedIds = List<String>.from(
                  progress['completedLessonIds'] ?? const [],
                );
                return {
                  'completed': completedIds.length,
                  'xp': completedIds.length * 45,
                };
              }),
            ),
      builder: (context, snapshot) {
        final values = snapshot.data ?? const [];
        final completed = values.fold<int>(
          0,
          (sum, item) => sum + (item['completed'] as int? ?? 0),
        );
        final xp = values.fold<int>(
          0,
          (sum, item) => sum + (item['xp'] as int? ?? 0),
        );
        final progress = totalLessons == 0 ? 0.0 : completed / totalLessons;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF131525),
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEARNING PROGRESS',
                        style: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(progress * 100).round()}% complete',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1BFFFF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$xp XP',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1BFFFF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
              const SizedBox(height: 18),
              Text(
                '$completed of $totalLessons lessons completed across ${DemoFinanceData.courses.length} original courses.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryRow(Color darkColor) {
    final categories = DemoFinanceData.courses
        .map((course) => course.category)
        .toSet()
        .toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories
            .map(
              (category) => Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF1F1F1)),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: darkColor,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final LessonCourse course;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;
    return StreamBuilder<Map<String, dynamic>>(
      stream: firestoreService?.getCourseProgress(course.id),
      builder: (context, progressSnapshot) {
        final progress = progressSnapshot.data ?? const {};
        final completedLessonIds = List<String>.from(
          progress['completedLessonIds'] ?? const [],
        );
        final courseProgress = course.lessons.isEmpty
            ? 0.0
            : completedLessonIds.length / course.lessons.length;

        return StreamBuilder<Map<String, dynamic>>(
          stream: firestoreService?.getQuizScore(course.id, course.quiz.id),
          builder: (context, quizSnapshot) {
            final quizScore = quizSnapshot.data ?? const {};
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F1F1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Image.network(
                      course.coverImageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                course.category,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF2E3192),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber[700],
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              course.rating.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          course.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          course.description,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: courseProgress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF3F4F6),
                            color: const Color(0xFF2E3192),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatPill(label: '${course.durationMinutes} min'),
                            const SizedBox(width: 8),
                            _StatPill(
                              label: '${course.lessons.length} lessons',
                            ),
                            const SizedBox(width: 8),
                            _StatPill(label: '${course.xpReward} XP'),
                          ],
                        ),
                        if (quizScore.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Latest quiz score: ${quizScore['score'] ?? 0}/${quizScore['total'] ?? 0}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF059669),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ...course.lessons.map(
                          (lesson) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LessonTile(
                              course: course,
                              lesson: lesson,
                              completed: completedLessonIds.contains(lesson.id),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: firestoreService == null
                                ? null
                                : () => showDialog(
                                    context: context,
                                    builder: (_) => _QuizDialog(course: course),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E3192),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Take Quiz',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
          },
        );
      },
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.course,
    required this.lesson,
    required this.completed,
  });

  final LessonCourse course;
  final Lesson lesson;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<AuthService>().firestoreService;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            DemoFinanceData.courseIcon(lesson.icon),
            color: const Color(0xFF2E3192),
          ),
        ),
        title: Text(
          lesson.title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            lesson.description,
            style: GoogleFonts.inter(height: 1.4),
          ),
        ),
        trailing: Checkbox(
          value: completed,
          onChanged: firestoreService == null
              ? null
              : (value) async {
                  await firestoreService.setLessonCompleted(
                    course.id,
                    lesson.id,
                    value ?? false,
                  );
                },
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _LessonDetailSheet(
            course: course,
            lesson: lesson,
            completed: completed,
          ),
        ),
      ),
    );
  }
}

class _LessonDetailSheet extends StatelessWidget {
  const _LessonDetailSheet({
    required this.course,
    required this.lesson,
    required this.completed,
  });

  final LessonCourse course;
  final Lesson lesson;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<AuthService>().firestoreService;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
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
            const SizedBox(height: 20),
            Text(
              lesson.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.description,
              style: GoogleFonts.inter(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            Text(
              lesson.content,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: firestoreService == null
                    ? null
                    : () async {
                        await firestoreService.setLessonCompleted(
                          course.id,
                          lesson.id,
                          !completed,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: Text(completed ? 'Mark Incomplete' : 'Mark Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizDialog extends StatefulWidget {
  const _QuizDialog({required this.course});

  final LessonCourse course;

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  final Map<String, int> _answers = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.course.quiz.title,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.course.quiz.questions.map((question) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.prompt,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    RadioGroup<int>(
                      groupValue: _answers[question.id],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _answers[question.id] = value);
                        }
                      },
                      child: Column(
                        children: List.generate(question.options.length, (
                          index,
                        ) {
                          return RadioListTile<int>(
                            value: index,
                            title: Text(
                              question.options[index],
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submitQuiz,
          child: Text(_isSaving ? 'Saving...' : 'Submit Quiz'),
        ),
      ],
    );
  }

  Future<void> _submitQuiz() async {
    final firestoreService = context.read<AuthService>().firestoreService;
    if (firestoreService == null) {
      return;
    }

    setState(() => _isSaving = true);
    var score = 0;
    for (final question in widget.course.quiz.questions) {
      if (_answers[question.id] == question.correctIndex) {
        score++;
      }
    }

    await firestoreService.saveQuizSubmission(
      widget.course.id,
      widget.course.quiz.id,
      score,
      widget.course.quiz.questions.length,
      _answers,
    );

    if (mounted) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Quiz Saved'),
          content: Text(
            'You scored $score/${widget.course.quiz.questions.length}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: const Color(0xFF334155),
        ),
      ),
    );
  }
}
