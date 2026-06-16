import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/welfare_program.dart';
import '../../services/auth_service.dart';
import '../../services/url_launcher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_config_gate.dart';
import 'welfare_program_detail_page.dart';
import 'welfare_provider.dart';

class WelfareProgramsPage extends StatelessWidget {
  const WelfareProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return ChangeNotifierProvider(
      create: (_) => WelfareProvider(
        uid: auth.user?.uid,
        firestoreService: auth.firestoreService,
      ),
      child: AppFeatureGate(
        enabled: (config) => config.welfareEnabled,
        blockedTitle: 'Welfare programs are paused',
        blockedMessage:
            'The welfare directory is temporarily paused by FinEase admin.',
        blockedIcon: Icons.volunteer_activism_outlined,
        child: const _WelfarePageContent(),
      ),
    );
  }
}

class _WelfarePageContent extends StatefulWidget {
  const _WelfarePageContent();

  @override
  State<_WelfarePageContent> createState() => _WelfarePageContentState();
}

class _WelfarePageContentState extends State<_WelfarePageContent> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppTheme.primaryFor(context),
          child: provider.isLoading
              ? const _LoadingList()
              : provider.error != null
              ? _ErrorState(message: provider.error!, onRetry: provider.refresh)
              : _ProgramList(searchController: _searchController),
        ),
      ),
    );
  }
}

class _ProgramList extends StatelessWidget {
  const _ProgramList({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();
    final filtered = provider.filteredPrograms;
    final recommended = provider.recommendedPrograms;
    final showRecommended =
        !provider.hasActiveFilters && recommended.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 116),
      children: [
        _Header(bookmarkCount: provider.bookmarkCount),
        const SizedBox(height: 18),
        _SearchAndFilter(
          controller: searchController,
          activeFilterCount: provider.activeFilterCount,
          onFilterTap: () => _openFilterSheet(context, searchController),
        ),
        const SizedBox(height: 12),
        const _CategoryRail(),
        if (provider.hasActiveFilters) ...[
          const SizedBox(height: 10),
          _ActiveFilters(controller: searchController),
        ],
        if (showRecommended) ...[
          const SizedBox(height: 20),
          const _SectionTitle(title: 'Best matches', subtitle: 'From profile'),
          const SizedBox(height: 10),
          ...recommended.map(
            (program) => _ProgramCard(program: program, recommended: true),
          ),
          const SizedBox(height: 10),
          _SectionTitle(
            title: 'All programs',
            subtitle: '${filtered.length} found',
          ),
          const SizedBox(height: 10),
        ] else ...[
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Programs',
            subtitle: '${filtered.length} found',
          ),
          const SizedBox(height: 10),
        ],
        if (filtered.isEmpty)
          _EmptyState(onClear: () => _clearFilters(provider, searchController))
        else
          ...filtered.map((program) => _ProgramCard(program: program)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.bookmarkCount});

  final int bookmarkCount;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Row(
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
                'Find support',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Verified aid, scholarships, health cover, and loans.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _BookmarkCount(count: bookmarkCount),
      ],
    );
  }
}

class _BookmarkCount extends StatelessWidget {
  const _BookmarkCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryFor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bookmark_rounded,
            color: AppTheme.primaryFor(context),
            size: 18,
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: GoogleFonts.inter(
              color: AppTheme.primaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.controller,
    required this.activeFilterCount,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final int activeFilterCount;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WelfareProvider>();
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: provider.setSearch,
                decoration: InputDecoration(
                  hintText: 'Search program or need',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            controller.clear();
                            provider.setSearch('');
                          },
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Clear search',
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onFilterTap,
              icon: const Icon(Icons.tune_rounded),
              color: AppTheme.primaryFor(context),
              tooltip: 'Filters',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.surfaceFor(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppTheme.borderFor(context)),
                ),
              ),
            ),
            if (activeFilterCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: AppTheme.primaryFor(context),
                  child: Text(
                    '$activeFilterCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();
    final items = <({String label, IconData icon, WelfareCategory? category})>[
      (label: 'All', icon: Icons.apps_rounded, category: null),
      ...WelfareCategory.values.map(
        (category) => (
          label: category.displayName,
          icon: category.icon,
          category: category,
        ),
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final selected = provider.selectedCategory == item.category;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => provider.setCategory(item.category),
            avatar: Icon(
              item.icon,
              size: 17,
              color: selected ? Colors.white : AppTheme.primaryFor(context),
            ),
            label: Text(item.label),
            selectedColor: AppTheme.primaryFor(context),
            backgroundColor: AppTheme.surfaceFor(context),
            labelStyle: GoogleFonts.inter(
              color: selected ? Colors.white : AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
              fontSize: 12,
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

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();
    return Row(
      children: [
        Icon(
          Icons.filter_list_rounded,
          size: 16,
          color: AppTheme.textSecondaryFor(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${provider.activeFilterCount} filter${provider.activeFilterCount == 1 ? '' : 's'} active',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () => _clearFilters(provider, controller),
          child: const Text('Clear'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
          subtitle,
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

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.program, this.recommended = false});

  final WelfareProgram program;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();
    final bookmarked = provider.isBookmarked(program.id);
    final status = provider.applicationStatus(program.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetail(context, provider, program),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceFor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: recommended
                  ? AppTheme.primaryFor(context).withValues(alpha: 0.35)
                  : AppTheme.borderFor(context),
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                program.category.displayName,
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
                          program.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimaryFor(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.organization,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondaryFor(context),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => provider.toggleBookmark(program.id),
                    icon: Icon(
                      bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                    ),
                    color: bookmarked
                        ? AppTheme.primaryFor(context)
                        : AppTheme.textSecondaryFor(context),
                    tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                program.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  height: 1.45,
                  fontSize: 13,
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
                  if (status != null)
                    _MetaPill(
                      icon: _statusIcon(status),
                      label: _statusLabel(status),
                      color: _statusColor(status),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _openDetail(context, provider, program),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => UrlLauncherService.instance
                          .launchExternalUrl(context, program.officialUrl),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
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

class _RecommendedPill extends StatelessWidget {
  const _RecommendedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryFor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Match',
        style: GoogleFonts.inter(
          color: AppTheme.primaryFor(context),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WelfareProvider>();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
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
                color: AppTheme.borderFor(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(
            title: 'Filters',
            subtitle: '${provider.activeFilterCount} active',
          ),
          const SizedBox(height: 16),
          Text(
            'Category',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: provider.selectedCategory == null,
                onTap: () => provider.setCategory(null),
              ),
              ...WelfareCategory.values.map(
                (category) => _FilterChip(
                  label: category.displayName,
                  selected: provider.selectedCategory == category,
                  onTap: () => provider.setCategory(category),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Needs',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kWelfareTags
                    .map(
                      (tag) => _FilterChip(
                        label: tag,
                        selected: provider.selectedTags.contains(tag),
                        onTap: () => provider.toggleTag(tag),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _clearFilters(provider, searchController),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Show results'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      label: Text(label),
      avatar: selected
          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
          : null,
      backgroundColor: selected
          ? AppTheme.primaryFor(context)
          : AppTheme.mutedFillFor(context),
      labelStyle: GoogleFonts.inter(
        color: selected ? Colors.white : AppTheme.textPrimaryFor(context),
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: AppTheme.borderFor(context)),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 116),
      children: [
        const _SkeletonLine(width: 170, height: 34),
        const SizedBox(height: 10),
        const _SkeletonLine(width: double.infinity, height: 16),
        const SizedBox(height: 22),
        const _SkeletonLine(width: double.infinity, height: 54, radius: 14),
        const SizedBox(height: 18),
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceFor(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderFor(context)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonLine(width: 190, height: 18),
                  SizedBox(height: 10),
                  _SkeletonLine(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  _SkeletonLine(width: 220, height: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.borderFor(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: AppTheme.textHintFor(context),
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'No programs found',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing filters or searching a broader need.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.error),
        const SizedBox(height: 16),
        Text(
          'Could not load programs',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimaryFor(context),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondaryFor(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

void _openDetail(
  BuildContext context,
  WelfareProvider provider,
  WelfareProgram program,
) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: WelfareProgramDetailPage(program: program),
      ),
    ),
  );
}

void _openFilterSheet(BuildContext context, TextEditingController controller) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<WelfareProvider>(),
      child: _FilterSheet(searchController: controller),
    ),
  );
}

void _clearFilters(WelfareProvider provider, TextEditingController controller) {
  controller.clear();
  provider.clearFilters();
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
