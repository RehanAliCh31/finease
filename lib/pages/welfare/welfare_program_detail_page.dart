import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/welfare_program.dart';
import '../../services/url_launcher_service.dart';
import '../../theme/app_theme.dart';
import 'welfare_provider.dart';

class WelfareProgramDetailPage extends StatelessWidget {
  const WelfareProgramDetailPage({super.key, required this.program});

  final WelfareProgram program;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();
    final bookmarked = provider.isBookmarked(program.id);
    final status = provider.applicationStatus(program.id);

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _TopBar(
                  bookmarked: bookmarked,
                  onBack: () => Navigator.pop(context),
                  onBookmark: () => provider.toggleBookmark(program.id),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProgramHero(program: program, status: status),
                  const SizedBox(height: 16),
                  _QuickSummary(program: program),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Eligibility',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.success,
                    child: _BulletList(items: program.eligibilityCriteria),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Documents',
                    icon: Icons.folder_outlined,
                    color: AppTheme.warning,
                    child: _BulletList(items: program.requiredDocuments),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'How to apply',
                    icon: Icons.list_alt_rounded,
                    color: AppTheme.primary,
                    child: _StepList(steps: program.applicationSteps),
                  ),
                  const SizedBox(height: 12),
                  _ContactCard(program: program),
                  const SizedBox(height: 16),
                  _TrackingCard(program: program, currentStatus: status),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActions(program: program),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.bookmarked,
    required this.onBack,
    required this.onBookmark,
  });

  final bool bookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppTheme.textPrimaryFor(context),
          tooltip: 'Back',
        ),
        const Spacer(),
        IconButton(
          onPressed: onBookmark,
          icon: Icon(
            bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
          ),
          color: bookmarked
              ? AppTheme.primaryFor(context)
              : AppTheme.textPrimaryFor(context),
          tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
        ),
      ],
    );
  }
}

class _ProgramHero extends StatelessWidget {
  const _ProgramHero({required this.program, required this.status});

  final WelfareProgram program;
  final ApplicationStatus? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _IconBadge(
              icon: program.category.icon,
              color: program.category.badgeTextColor,
              background: program.category.badgeColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.category.displayName,
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryFor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    program.organization,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (program.isVerified)
              _MetaPill(
                icon: Icons.verified_rounded,
                label: 'Official',
                color: AppTheme.success,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          program.title,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimaryFor(context),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          program.description,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaPill(
              icon: Icons.payments_outlined,
              label: program.estimatedSupportValue,
              color: AppTheme.success,
            ),
            _MetaPill(
              icon: Icons.speed_rounded,
              label: program.difficulty.label,
              color: program.difficulty.color,
            ),
            if (program.regionRestriction != null)
              _MetaPill(
                icon: Icons.place_rounded,
                label: program.regionRestriction!,
                color: AppTheme.primary,
              ),
            if (status != null)
              _MetaPill(
                icon: _statusIcon(status!),
                label: _statusLabel(status!),
                color: _statusColor(status!),
              ),
          ],
        ),
      ],
    );
  }
}

class _QuickSummary extends StatelessWidget {
  const _QuickSummary({required this.program});

  final WelfareProgram program;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: program.supportValueLabel,
              value: program.estimatedSupportValue,
              icon: Icons.payments_outlined,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryItem(
              label: 'Process',
              value: program.difficulty.label,
              icon: Icons.speed_rounded,
              color: program.difficulty.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimaryFor(context),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallIcon(icon: icon, color: color),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No details provided.',
        style: GoogleFonts.inter(color: AppTheme.textSecondaryFor(context)),
      );
    }
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({required this.steps});

  final List<ApplicationStep> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return Text(
        'Visit the official website for application steps.',
        style: GoogleFonts.inter(color: AppTheme.textSecondaryFor(context)),
      );
    }
    return Column(
      children: steps
          .map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppTheme.primaryFor(context),
                    child: Text(
                      '${step.stepNumber}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimaryFor(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondaryFor(context),
                            height: 1.42,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.program});

  final WelfareProgram program;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (program.helplineNumber.isNotEmpty)
        _ContactAction(
          icon: Icons.phone_outlined,
          label: 'Call',
          value: program.helplineNumber,
          onTap: () => UrlLauncherService.instance.launchPhoneDialer(
            context,
            program.helplineNumber,
          ),
        ),
      if (program.helplineEmail.isNotEmpty)
        _ContactAction(
          icon: Icons.email_outlined,
          label: 'Email',
          value: program.helplineEmail,
          onTap: () => UrlLauncherService.instance.launchEmail(
            context,
            program.helplineEmail,
          ),
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallIcon(
                icon: Icons.contact_support_outlined,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Contact',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryFor(context), size: 20),
            const SizedBox(width: 10),
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
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimaryFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textHintFor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.program, required this.currentStatus});

  final WelfareProgram program;
  final ApplicationStatus? currentStatus;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WelfareProvider>();
    const statuses = [
      ApplicationStatus.saved,
      ApplicationStatus.applied,
      ApplicationStatus.inReview,
      ApplicationStatus.approved,
    ];

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SmallIcon(icon: Icons.timeline_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Track application',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses
                .map(
                  (status) => _StatusChip(
                    status: status,
                    selected: currentStatus == status,
                    onTap: () =>
                        provider.setApplicationStatus(program.id, status),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final ApplicationStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        _statusIcon(status),
        color: selected ? Colors.white : color,
        size: 17,
      ),
      label: Text(_statusLabel(status)),
      backgroundColor: selected ? color : color.withValues(alpha: 0.08),
      labelStyle: GoogleFonts.inter(
        color: selected ? Colors.white : color,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.program});

  final WelfareProgram program;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();
    final bookmarked = provider.isBookmarked(program.id);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          border: Border(top: BorderSide(color: AppTheme.borderFor(context))),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => provider.toggleBookmark(program.id),
              icon: Icon(
                bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
              ),
              color: AppTheme.primaryFor(context),
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.mutedFillFor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => UrlLauncherService.instance.launchExternalUrl(
                  context,
                  program.officialUrl,
                ),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Apply on official site'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderFor(context)),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
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
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

String _statusLabel(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.saved => 'Saved',
    ApplicationStatus.applied => 'Applied',
    ApplicationStatus.inReview => 'In review',
    ApplicationStatus.approved => 'Approved',
    ApplicationStatus.rejected => 'Not approved',
  };
}

IconData _statusIcon(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.saved => Icons.bookmark_rounded,
    ApplicationStatus.applied => Icons.send_rounded,
    ApplicationStatus.inReview => Icons.hourglass_top_rounded,
    ApplicationStatus.approved => Icons.check_circle_rounded,
    ApplicationStatus.rejected => Icons.cancel_rounded,
  };
}

Color _statusColor(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.saved => AppTheme.primary,
    ApplicationStatus.applied => AppTheme.warning,
    ApplicationStatus.inReview => AppTheme.warning,
    ApplicationStatus.approved => AppTheme.success,
    ApplicationStatus.rejected => AppTheme.error,
  };
}
