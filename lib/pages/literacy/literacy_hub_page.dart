import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../data/demo_finance_data.dart';
import '../../models/lesson.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class LiteracyHubPage extends StatelessWidget {
  const LiteracyHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.select<AuthService, FirestoreService?>(
      (auth) => auth.firestoreService,
    );

    if (firestoreService == null) {
      return const _LiteracyExperience(
        progressByCourse: {},
        quizScores: {},
        firestoreService: null,
      );
    }

    return StreamBuilder<Map<String, Map<String, dynamic>>>(
      stream: firestoreService.getAllCourseProgress(),
      initialData: const {},
      builder: (context, progressSnapshot) {
        return StreamBuilder<Map<String, Map<String, dynamic>>>(
          stream: firestoreService.getAllQuizScores(),
          initialData: const {},
          builder: (context, quizSnapshot) {
            return _LiteracyExperience(
              progressByCourse: progressSnapshot.data ?? const {},
              quizScores: quizSnapshot.data ?? const {},
              firestoreService: firestoreService,
            );
          },
        );
      },
    );
  }
}

class _LiteracyExperience extends StatefulWidget {
  const _LiteracyExperience({
    required this.progressByCourse,
    required this.quizScores,
    required this.firestoreService,
  });

  final Map<String, Map<String, dynamic>> progressByCourse;
  final Map<String, Map<String, dynamic>> quizScores;
  final FirestoreService? firestoreService;

  @override
  State<_LiteracyExperience> createState() => _LiteracyExperienceState();
}

class _LiteracyExperienceState extends State<_LiteracyExperience> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedTrackId = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = _LearningPlan(
      courses: DemoFinanceData.courses,
      progressByCourse: widget.progressByCourse,
      quizScores: widget.quizScores,
    );
    final filteredCourses = plan.filteredCourses(
      query: _query,
      trackId: _selectedTrackId,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _Header(plan: plan),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _ContinueCard(
                  action: plan.nextAction,
                  plan: plan,
                  enabled: widget.firestoreService != null,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(child: _ProgressCard(plan: plan)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _TrackFilter(
                  selectedTrackId: _selectedTrackId,
                  onSelected: (trackId) {
                    setState(() => _selectedTrackId = trackId);
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Courses',
                  actionLabel: '${filteredCourses.length} available',
                ),
              ),
            ),
            if (filteredCourses.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(child: _EmptyCoursesCard()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList.separated(
                  itemCount: filteredCourses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final course = filteredCourses[index];
                    return _CourseCard(
                      course: course,
                      plan: plan,
                      recommended: plan.nextAction?.course.id == course.id,
                      enabled: widget.firestoreService != null,
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 116)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plan});

  final _LearningPlan plan;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPop) ...[
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppTheme.textPrimaryFor(context),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learn',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.completedLessons == 0
                    ? 'Start with one practical money lesson.'
                    : '${plan.completedLessons}/${plan.totalLessons} lessons complete',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _LevelBadge(level: plan.level),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.action,
    required this.plan,
    required this.enabled,
  });

  final _NextLearningAction? action;
  final _LearningPlan plan;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final currentAction = action;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LightIconBadge(
                icon: currentAction?.isQuiz == true
                    ? Icons.quiz_rounded
                    : Icons.play_arrow_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Next best step',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${plan.earnedXp} XP',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currentAction?.title ?? 'You finished every course',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentAction?.reason ??
                'Retake quizzes or explore a specialist course when you want a refresher.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (currentAction != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: enabled
                    ? () => _openLearningAction(context, currentAction, plan)
                    : null,
                icon: Icon(
                  currentAction.isQuiz
                      ? Icons.sports_score_rounded
                      : Icons.menu_book_rounded,
                ),
                label: Text(
                  currentAction.isQuiz ? 'Start quiz' : 'Open lesson',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.plan});

  final _LearningPlan plan;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (plan.overallProgress * 100).round();
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Progress', actionLabel: '$progressPercent%'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: plan.overallProgress,
              minHeight: 10,
              backgroundColor: AppTheme.mutedFillFor(context),
              color: AppTheme.primaryFor(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CompactStat(
                  label: 'Lessons',
                  value: '${plan.completedLessons}/${plan.totalLessons}',
                  icon: Icons.menu_book_rounded,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactStat(
                  label: 'Quizzes',
                  value: '${plan.completedQuizzes}/${plan.totalQuizzes}',
                  icon: Icons.quiz_rounded,
                  color: const Color(0xFF0EA5A4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackFilter extends StatelessWidget {
  const _TrackFilter({required this.selectedTrackId, required this.onSelected});

  final String selectedTrackId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tracks = [
      const _TrackOption(id: 'all', title: 'All', icon: Icons.apps_rounded),
      ...DemoFinanceData.learningTracks.map(
        (track) => _TrackOption(
          id: track.id,
          title: track.title,
          icon: DemoFinanceData.courseIcon(track.iconName),
        ),
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tracks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final track = tracks[index];
          final selected = selectedTrackId == track.id;
          return ChoiceChip(
            selected: selected,
            avatar: Icon(
              track.icon,
              size: 18,
              color: selected ? Colors.white : AppTheme.primaryFor(context),
            ),
            label: Text(track.title),
            onSelected: (_) => onSelected(track.id),
            selectedColor: AppTheme.primaryFor(context),
            backgroundColor: AppTheme.surfaceFor(context),
            labelStyle: GoogleFonts.inter(
              color: selected ? Colors.white : AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: AppTheme.borderFor(context)),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search topics, skills, or questions',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Clear search',
              ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.plan,
    required this.recommended,
    required this.enabled,
  });

  final LessonCourse course;
  final _LearningPlan plan;
  final bool recommended;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final progress = plan.courseProgress(course);
    final completed = plan.completedLessonIds(course).length;
    final quizPercentage = plan.quizPercentage(course);
    final nextLesson = plan.nextLessonFor(course);

    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconBadge(
                icon: DemoFinanceData.courseIcon(
                  course.lessons.isEmpty ? 'school' : course.lessons.first.icon,
                ),
                color: _difficultyColor(course.difficulty),
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
                            course.pathLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryFor(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (recommended) const _RecommendedPill(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                icon: Icons.signal_cellular_alt_rounded,
                label: course.difficulty,
                color: _difficultyColor(course.difficulty),
              ),
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: '${course.durationMinutes} min',
                color: AppTheme.primary,
              ),
              _MetaPill(
                icon: Icons.bolt_rounded,
                label: '${course.xpReward} XP',
                color: const Color(0xFFD97706),
              ),
              if (quizPercentage > 0)
                _MetaPill(
                  icon: Icons.school_rounded,
                  label: '$quizPercentage% quiz',
                  color: quizPercentage >= 80
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
            ],
          ),
          const SizedBox(height: 14),
          _CourseProgressSummary(
            completedLessons: completed,
            totalLessons: course.lessons.length,
            quizPercentage: quizPercentage,
            hasVideo:
                course.videoId != null ||
                _extractYoutubeVideoId(course.videoUrl) != null,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.mutedFillFor(context),
              color: AppTheme.primaryFor(context),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  nextLesson == null
                      ? 'Lessons complete. Take or review the quiz.'
                      : 'Next: ${nextLesson.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: enabled
                      ? () => _openCourseSheet(context, course, plan)
                      : null,
                  icon: Icon(
                    nextLesson == null
                        ? Icons.fact_check_rounded
                        : Icons.menu_book_rounded,
                  ),
                  label: Text(nextLesson == null ? 'Review' : 'Open'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => _showCourseVideo(context, course),
                icon: const Icon(Icons.play_circle_outline_rounded),
                color: const Color(0xFFDC2626),
                tooltip: 'Watch video',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.mutedFillFor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => _openUrl(course.externalUrl),
                icon: const Icon(Icons.open_in_new_rounded),
                color: AppTheme.primaryFor(context),
                tooltip: 'Open course link',
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.mutedFillFor(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseSheet extends StatelessWidget {
  const _CourseSheet({required this.course, required this.plan});

  final LessonCourse course;
  final _LearningPlan plan;

  @override
  Widget build(BuildContext context) {
    final completedIds = plan.completedLessonIds(course);
    final quizScore = plan.quizScore(course);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceFor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderFor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    children: [
                      Text(
                        course.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimaryFor(context),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course.outcome,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondaryFor(context),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _CourseSheetActionCard(
                        course: course,
                        completedLessons: completedIds.length,
                        totalLessons: course.lessons.length,
                        quizPercentage: plan.quizPercentage(course),
                      ),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Lessons',
                        actionLabel:
                            '${completedIds.length}/${course.lessons.length}',
                      ),
                      const SizedBox(height: 10),
                      ...course.lessons.asMap().entries.map((entry) {
                        final lesson = entry.value;
                        return _LessonRow(
                          course: course,
                          lesson: lesson,
                          index: entry.key,
                          completed: completedIds.contains(lesson.id),
                        );
                      }),
                      const SizedBox(height: 16),
                      if (quizScore.isNotEmpty)
                        _QuizScoreCard(
                          score: quizScore['score'] as int? ?? 0,
                          total:
                              quizScore['total'] as int? ??
                              course.quiz.questions.length,
                          percentage: plan.quizPercentage(course),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => _QuizDialog(course: course),
                      ),
                      icon: const Icon(Icons.quiz_rounded),
                      label: Text(
                        quizScore.isEmpty ? 'Take quiz' : 'Retake quiz',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CourseProgressSummary extends StatelessWidget {
  const _CourseProgressSummary({
    required this.completedLessons,
    required this.totalLessons,
    required this.quizPercentage,
    required this.hasVideo,
  });

  final int completedLessons;
  final int totalLessons;
  final int quizPercentage;
  final bool hasVideo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LearningStepPill(
            icon: Icons.menu_book_rounded,
            label: '$completedLessons/$totalLessons lessons',
            color: AppTheme.primaryFor(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LearningStepPill(
            icon: hasVideo
                ? Icons.play_circle_outline_rounded
                : Icons.link_rounded,
            label: hasVideo ? 'Video in app' : 'Video link',
            color: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LearningStepPill(
            icon: Icons.quiz_rounded,
            label: quizPercentage == 0 ? 'Quiz ready' : '$quizPercentage%',
            color: quizPercentage >= 80 ? AppTheme.success : AppTheme.warning,
          ),
        ),
      ],
    );
  }
}

class _CourseSheetActionCard extends StatelessWidget {
  const _CourseSheetActionCard({
    required this.course,
    required this.completedLessons,
    required this.totalLessons,
    required this.quizPercentage,
  });

  final LessonCourse course;
  final int completedLessons;
  final int totalLessons;
  final int quizPercentage;

  @override
  Widget build(BuildContext context) {
    final videoId = course.videoId ?? _extractYoutubeVideoId(course.videoUrl);
    final lessonsDone = totalLessons > 0 && completedLessons == totalLessons;
    final quizDone = quizPercentage > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route_rounded,
                color: AppTheme.primaryFor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Best path',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PathStep(
            icon: Icons.play_circle_outline_rounded,
            title: videoId == null ? 'Open video link' : 'Watch video in app',
            subtitle: 'Preview the idea before reading.',
            done: false,
            color: const Color(0xFFDC2626),
            onTap: () => _showCourseVideo(context, course),
          ),
          _PathStep(
            icon: Icons.menu_book_rounded,
            title: 'Finish lessons',
            subtitle: '$completedLessons/$totalLessons lessons complete',
            done: lessonsDone,
            color: AppTheme.primaryFor(context),
          ),
          _PathStep(
            icon: Icons.quiz_rounded,
            title: quizDone ? 'Retake quiz' : 'Take quiz',
            subtitle: quizDone
                ? 'Latest score $quizPercentage%.'
                : 'Check whether the lesson stuck.',
            done: quizPercentage >= 80,
            color: quizPercentage >= 80 ? AppTheme.success : AppTheme.warning,
            onTap: () => showDialog(
              context: context,
              builder: (_) => _QuizDialog(course: course),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningStepPill extends StatelessWidget {
  const _LearningStepPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
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
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            done ? Icons.check_rounded : icon,
            color: color,
            size: 19,
          ),
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
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textHintFor(context),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: content,
              ),
            ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.course,
    required this.lesson,
    required this.index,
    required this.completed,
  });

  final LessonCourse course;
  final Lesson lesson;
  final int index;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openLessonSheet(
          context,
          course: course,
          lesson: lesson,
          completed: completed,
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCardFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderFor(context)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: completed
                    ? AppTheme.success
                    : AppTheme.primaryFor(context).withValues(alpha: 0.1),
                child: completed
                    ? const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Colors.white,
                      )
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryFor(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${lesson.points} XP',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryFor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonSheet extends StatelessWidget {
  const _LessonSheet({
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
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceFor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderFor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    children: [
                      Text(
                        course.pathLabel,
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryFor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.title,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimaryFor(context),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lesson.description,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondaryFor(context),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReadableBlock(text: lesson.content),
                      const SizedBox(height: 16),
                      _LessonResources(lesson: lesson),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: firestoreService == null
                          ? null
                          : () async {
                              final nextCompleted = !completed;
                              await firestoreService.setLessonCompleted(
                                course.id,
                                lesson.id,
                                nextCompleted,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              _showLessonFeedback(
                                context,
                                lesson: lesson,
                                completed: nextCompleted,
                              );
                            },
                      icon: Icon(
                        completed
                            ? Icons.remove_done_rounded
                            : Icons.check_circle_rounded,
                      ),
                      label: Text(
                        completed ? 'Mark incomplete' : 'Complete lesson',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: completed
                            ? AppTheme.textHintFor(context)
                            : AppTheme.primaryFor(context),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LessonResources extends StatelessWidget {
  const _LessonResources({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final sections = [
      if (lesson.keyTakeaways.isNotEmpty)
        _ResourceSection(
          title: 'Takeaways',
          icon: Icons.checklist_rounded,
          items: lesson.keyTakeaways,
          color: AppTheme.success,
        ),
      if (lesson.practiceTasks.isNotEmpty)
        _ResourceSection(
          title: 'Practice',
          icon: Icons.edit_note_rounded,
          items: lesson.practiceTasks,
          color: AppTheme.primary,
        ),
      if (lesson.localExample.isNotEmpty)
        _ResourceSection(
          title: 'Local example',
          icon: Icons.place_rounded,
          items: [lesson.localExample],
          color: const Color(0xFFD97706),
        ),
      if (lesson.mythBusters.isNotEmpty)
        _ResourceSection(
          title: 'Myth buster',
          icon: Icons.psychology_alt_rounded,
          items: lesson.mythBusters,
          color: const Color(0xFF7C3AED),
        ),
      if (lesson.calculators.isNotEmpty)
        _ResourceSection(
          title: 'Calculators',
          icon: Icons.calculate_rounded,
          items: lesson.calculators,
          color: const Color(0xFF0EA5A4),
        ),
      if (lesson.templates.isNotEmpty)
        _ResourceSection(
          title: 'Templates',
          icon: Icons.description_rounded,
          items: lesson.templates,
          color: AppTheme.primary,
        ),
    ];

    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(children: sections);
  }
}

class _ResourceSection extends StatelessWidget {
  const _ResourceSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
    final questions = widget.course.quiz.questions;
    final answered = _answers.length;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.quiz.title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$answered/${questions.length} answered',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return _QuizQuestionCard(
                    index: index,
                    question: question,
                    selectedIndex: _answers[question.id],
                    onSelected: (value) {
                      setState(() => _answers[question.id] = value);
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submitQuiz,
                    icon: Icon(
                      _isSaving
                          ? Icons.sync_rounded
                          : Icons.sports_score_rounded,
                    ),
                    label: Text(_isSaving ? 'Saving...' : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Future<void> _submitQuiz() async {
    final firestoreService = context.read<AuthService>().firestoreService;
    if (firestoreService == null || _isSaving) return;

    setState(() => _isSaving = true);

    var score = 0;
    for (final question in widget.course.quiz.questions) {
      if (_answers[question.id] == question.correctIndex) score++;
    }

    await firestoreService.saveQuizSubmission(
      widget.course.id,
      widget.course.quiz.id,
      score,
      widget.course.quiz.questions.length,
      _answers,
    );

    if (!mounted) return;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (_) => _QuizResultDialog(
        course: widget.course,
        answers: Map<String, int>.from(_answers),
        score: score,
      ),
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({
    required this.index,
    required this.question,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int index;
  final QuizQuestion question;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${question.prompt}',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
              fontSize: 16,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(question.options.length, (optionIndex) {
            final selected = selectedIndex == optionIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSelected(optionIndex),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryFor(context).withValues(alpha: 0.08)
                        : AppTheme.surfaceCardFor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryFor(context)
                          : AppTheme.borderFor(context),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected
                            ? AppTheme.primaryFor(context)
                            : AppTheme.textHintFor(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.options[optionIndex],
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimaryFor(context),
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuizResultDialog extends StatelessWidget {
  const _QuizResultDialog({
    required this.course,
    required this.answers,
    required this.score,
  });

  final LessonCourse course;
  final Map<String, int> answers;
  final int score;

  @override
  Widget build(BuildContext context) {
    final total = course.quiz.questions.length;
    final percentage = total == 0 ? 0 : ((score / total) * 100).round();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        percentage >= 80 ? 'Great work' : 'Quiz saved',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score $score/$total - $percentage%',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...course.quiz.questions.map((question) {
              final answer = answers[question.id];
              final correct = answer == question.correctIndex;
              final selected = answer == null
                  ? 'No answer'
                  : question.options[answer];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          correct
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: correct ? AppTheme.success : AppTheme.error,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            question.prompt,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimaryFor(context),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your answer: $selected',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 13,
                      ),
                    ),
                    if (!correct)
                      Text(
                        'Correct: ${question.options[question.correctIndex]}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimaryFor(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _EmbeddedVideoSheet extends StatefulWidget {
  const _EmbeddedVideoSheet({required this.course, required this.videoId});

  final LessonCourse course;
  final String videoId;

  @override
  State<_EmbeddedVideoSheet> createState() => _EmbeddedVideoSheetState();
}

class _EmbeddedVideoSheetState extends State<_EmbeddedVideoSheet> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderFor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.course.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lesson video',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.course.outcome,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(widget.course.videoUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 17),
                    label: const Text('Open'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningPlan {
  const _LearningPlan({
    required this.courses,
    required this.progressByCourse,
    required this.quizScores,
  });

  final List<LessonCourse> courses;
  final Map<String, Map<String, dynamic>> progressByCourse;
  final Map<String, Map<String, dynamic>> quizScores;

  int get totalLessons =>
      courses.fold<int>(0, (total, course) => total + course.lessons.length);

  int get completedLessons => courses.fold<int>(
    0,
    (total, course) => total + completedLessonIds(course).length,
  );

  int get totalQuizzes => courses.length;

  int get completedQuizzes => courses.where((course) {
    final score = quizScore(course);
    final total = score['total'] as int? ?? course.quiz.questions.length;
    final earned = score['score'] as int? ?? 0;
    return score.isNotEmpty && total > 0 && earned / total >= 0.8;
  }).length;

  int get earnedXp => courses.fold<int>(0, (total, course) {
    final completedIds = completedLessonIds(course);
    final lessonXp = course.lessons
        .where((lesson) => completedIds.contains(lesson.id))
        .fold<int>(0, (sum, lesson) => sum + lesson.points);
    final score = quizScore(course);
    final quizTotal = score['total'] as int? ?? course.quiz.questions.length;
    final earned = score['score'] as int? ?? 0;
    final quizXp = score.isEmpty || quizTotal == 0
        ? 0
        : ((earned / quizTotal) * course.xpReward).round();
    return total + lessonXp + quizXp;
  });

  int get level => math.max(1, (earnedXp ~/ 500) + 1);

  double get overallProgress {
    if (totalLessons == 0) return 0;
    return completedLessons / totalLessons;
  }

  _NextLearningAction? get nextAction {
    final inProgress = courses.where((course) {
      final completed = completedLessonIds(course).length;
      return completed > 0 && completed < course.lessons.length;
    });
    for (final course in inProgress) {
      final lesson = nextLessonFor(course);
      if (lesson != null) {
        return _NextLearningAction.lesson(
          course: course,
          lesson: lesson,
          reason: 'You already started this course. Finish the next lesson.',
        );
      }
    }

    for (final course in courses) {
      if (completedLessonIds(course).length == course.lessons.length &&
          quizScore(course).isEmpty) {
        return _NextLearningAction.quiz(
          course: course,
          reason: 'All lessons are done. Take the quiz to lock it in.',
        );
      }
    }

    for (final course in courses) {
      final lesson = nextLessonFor(course);
      if (lesson != null) {
        return _NextLearningAction.lesson(
          course: course,
          lesson: lesson,
          reason: 'Start here for the most practical next money skill.',
        );
      }
    }
    return null;
  }

  Set<String> completedLessonIds(LessonCourse course) {
    final progress = progressByCourse[course.id] ?? const {};
    return List<String>.from(
      progress['completedLessonIds'] ?? const [],
    ).toSet();
  }

  bool isLessonCompleted(LessonCourse course, Lesson lesson) {
    return completedLessonIds(course).contains(lesson.id);
  }

  double courseProgress(LessonCourse course) {
    if (course.lessons.isEmpty) return 0;
    return completedLessonIds(course).length / course.lessons.length;
  }

  Lesson? nextLessonFor(LessonCourse course) {
    final completed = completedLessonIds(course);
    for (final lesson in course.lessons) {
      if (!completed.contains(lesson.id)) return lesson;
    }
    return null;
  }

  Map<String, dynamic> quizScore(LessonCourse course) {
    return quizScores['${course.id}_${course.quiz.id}'] ?? const {};
  }

  int quizPercentage(LessonCourse course) {
    final score = quizScore(course);
    if (score.isEmpty) return 0;
    final percentage = score['percentage'];
    if (percentage is int) return percentage;
    if (percentage is num) return percentage.round();
    final total = score['total'] as int? ?? course.quiz.questions.length;
    final earned = score['score'] as int? ?? 0;
    return total == 0 ? 0 : ((earned / total) * 100).round();
  }

  List<LessonCourse> filteredCourses({
    required String query,
    required String trackId,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return courses.where((course) {
      final trackMatches = trackId == 'all' || course.trackId == trackId;
      if (!trackMatches) return false;
      if (normalizedQuery.isEmpty) return true;
      final searchText = [
        course.title,
        course.subtitle,
        course.description,
        course.category,
        course.difficulty,
        course.outcome,
        course.pathLabel,
        ...course.skillTags,
        for (final lesson in course.lessons) ...[
          lesson.title,
          lesson.description,
          lesson.content,
          ...lesson.keyTakeaways,
        ],
      ].join(' ').toLowerCase();
      return searchText.contains(normalizedQuery);
    }).toList();
  }
}

class _NextLearningAction {
  const _NextLearningAction._({
    required this.course,
    required this.lesson,
    required this.isQuiz,
    required this.reason,
  });

  factory _NextLearningAction.lesson({
    required LessonCourse course,
    required Lesson lesson,
    required String reason,
  }) {
    return _NextLearningAction._(
      course: course,
      lesson: lesson,
      isQuiz: false,
      reason: reason,
    );
  }

  factory _NextLearningAction.quiz({
    required LessonCourse course,
    required String reason,
  }) {
    return _NextLearningAction._(
      course: course,
      lesson: null,
      isQuiz: true,
      reason: reason,
    );
  }

  final LessonCourse course;
  final Lesson? lesson;
  final bool isQuiz;
  final String reason;

  String get title =>
      isQuiz ? course.quiz.title : lesson?.title ?? course.title;
}

class _TrackOption {
  const _TrackOption({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.primaryFor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Level $level',
        style: GoogleFonts.inter(
          color: AppTheme.primaryFor(context),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CompactStat extends StatelessWidget {
  const _CompactStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _RecommendedPill extends StatelessWidget {
  const _RecommendedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Next',
        style: GoogleFonts.inter(
          color: AppTheme.success,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuizScoreCard extends StatelessWidget {
  const _QuizScoreCard({
    required this.score,
    required this.total,
    required this.percentage,
  });

  final int score;
  final int total;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: AppTheme.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Latest quiz: $score/$total - $percentage%',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadableBlock extends StatelessWidget {
  const _ReadableBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppTheme.textSecondaryFor(context),
          height: 1.58,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyCoursesCard extends StatelessWidget {
  const _EmptyCoursesCard();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppTheme.textHintFor(context),
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'No matching courses',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another track or search term.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderFor(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          actionLabel,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _LightIconBadge extends StatelessWidget {
  const _LightIconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}

Color _difficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'beginner':
      return AppTheme.success;
    case 'intermediate':
      return const Color(0xFFD97706);
    case 'advanced':
      return const Color(0xFF7C3AED);
    default:
      return AppTheme.primary;
  }
}

void _openLearningAction(
  BuildContext context,
  _NextLearningAction action,
  _LearningPlan plan,
) {
  if (action.isQuiz) {
    showDialog(
      context: context,
      builder: (_) => _QuizDialog(course: action.course),
    );
    return;
  }

  final lesson = action.lesson;
  if (lesson == null) return;
  _openLessonSheet(
    context,
    course: action.course,
    lesson: lesson,
    completed: plan.isLessonCompleted(action.course, lesson),
  );
}

void _openCourseSheet(
  BuildContext context,
  LessonCourse course,
  _LearningPlan plan,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CourseSheet(course: course, plan: plan),
  );
}

void _openLessonSheet(
  BuildContext context, {
  required LessonCourse course,
  required Lesson lesson,
  required bool completed,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _LessonSheet(course: course, lesson: lesson, completed: completed),
  );
}

Future<void> _openUrl(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

void _showCourseVideo(BuildContext context, LessonCourse course) {
  final videoId = course.videoId ?? _extractYoutubeVideoId(course.videoUrl);
  if (videoId == null) {
    _openUrl(course.videoUrl);
    return;
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EmbeddedVideoSheet(course: course, videoId: videoId),
  );
}

String? _extractYoutubeVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.first;
  }
  if (uri.queryParameters['v'] case final id?) {
    return id;
  }
  if (uri.pathSegments.contains('embed')) {
    final index = uri.pathSegments.indexOf('embed');
    if (uri.pathSegments.length > index + 1) {
      return uri.pathSegments[index + 1];
    }
  }
  return null;
}

void _showLessonFeedback(
  BuildContext context, {
  required Lesson lesson,
  required bool completed,
}) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? 'Lesson complete. +${lesson.points} XP added.'
              : 'Lesson marked incomplete.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
