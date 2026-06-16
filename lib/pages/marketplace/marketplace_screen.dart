import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_models.dart';
import '../../models/saving_goal.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/app_config_gate.dart';
import 'partner_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _comparedIds = {};
  String _category = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<AuthService>().firestoreService;

    return AppFeatureGate(
      enabled: (config) => config.marketplaceEnabled,
      blockedTitle: 'Marketplace is paused',
      blockedMessage: 'Partner marketplace access is paused by admin.',
      blockedIcon: Icons.storefront_outlined,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundFor(context),
        body: SafeArea(
          child: firestoreService == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestoreService.getMarketplacePartners(),
                  builder: (context, partnerSnapshot) {
                    return StreamBuilder<Map<String, dynamic>>(
                      stream: firestoreService.getUserProfile(),
                      builder: (context, profileSnapshot) {
                        return StreamBuilder<List<SavingGoal>>(
                          stream: firestoreService.getSavingGoals(),
                          builder: (context, goalSnapshot) {
                            if (partnerSnapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !partnerSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final partners = (partnerSnapshot.data ?? const [])
                                .map(MarketplacePartner.fromMap)
                                .toList();
                            final profile =
                                profileSnapshot.data ??
                                const <String, dynamic>{};
                            final goals =
                                goalSnapshot.data ?? const <SavingGoal>[];
                            final model = _MarketplaceModel.from(
                              partners: partners,
                              profile: profile,
                              goals: goals,
                              query: _searchController.text,
                              category: _category,
                            );

                            return ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                120,
                              ),
                              children: [
                                _MarketplaceHeader(
                                  count: model.filtered.length,
                                  onCompare: _comparedIds.length < 2
                                      ? null
                                      : () => _showCompareSheet(
                                          context,
                                          partners,
                                          firestoreService,
                                        ),
                                ),
                                const SizedBox(height: 16),
                                _BestMatchCard(
                                  partner: model.bestMatch,
                                  onOpen: model.bestMatch == null
                                      ? null
                                      : () => _openPartner(
                                          model.bestMatch!,
                                          firestoreService,
                                        ),
                                ),
                                const SizedBox(height: 14),
                                _SearchBox(
                                  controller: _searchController,
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 10),
                                _CategoryChips(
                                  categories: model.categories,
                                  selected: _category,
                                  onSelected: (value) {
                                    setState(() => _category = value);
                                    firestoreService.logMarketplaceEvent(
                                      'marketplace_category_selected',
                                      payload: {'category': value},
                                    );
                                  },
                                ),
                                const SizedBox(height: 22),
                                _SectionTitle(
                                  title: 'Matches',
                                  trailing: '${_comparedIds.length}/3 compared',
                                ),
                                const SizedBox(height: 12),
                                if (model.filtered.isEmpty)
                                  const _EmptyMarketplace()
                                else
                                  ...model.filtered.map(
                                    (partner) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _PartnerCard(
                                        partner: partner,
                                        compared: _comparedIds.contains(
                                          partner.id,
                                        ),
                                        onOpen: () => _openPartner(
                                          partner,
                                          firestoreService,
                                        ),
                                        onCompare: () =>
                                            _toggleCompare(partner),
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
      ),
    );
  }

  void _toggleCompare(MarketplacePartner partner) {
    setState(() {
      if (_comparedIds.contains(partner.id)) {
        _comparedIds.remove(partner.id);
      } else if (_comparedIds.length < 3) {
        _comparedIds.add(partner.id);
      }
    });
  }

  void _openPartner(
    MarketplacePartner partner,
    FirestoreService firestoreService,
  ) {
    firestoreService.markMarketplacePartnerViewed(partner.id);
    firestoreService.logMarketplaceEvent(
      'marketplace_partner_opened',
      payload: {'partnerId': partner.id, 'category': partner.category},
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerDetailScreen(
          partner: partner,
          firestoreService: firestoreService,
          isCompared: _comparedIds.contains(partner.id),
          onToggleCompare: _toggleCompare,
        ),
      ),
    );
  }

  void _showCompareSheet(
    BuildContext context,
    List<MarketplacePartner> partners,
    FirestoreService firestoreService,
  ) {
    final selected = partners
        .where((partner) => _comparedIds.contains(partner.id))
        .toList();
    firestoreService.saveMarketplaceComparisonHistory(
      selected.map((partner) => partner.id).toList(),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompareSheet(partners: selected),
    );
  }
}

class _MarketplaceModel {
  const _MarketplaceModel({
    required this.filtered,
    required this.categories,
    required this.bestMatch,
  });

  final List<MarketplacePartner> filtered;
  final List<String> categories;
  final MarketplacePartner? bestMatch;

  factory _MarketplaceModel.from({
    required List<MarketplacePartner> partners,
    required Map<String, dynamic> profile,
    required List<SavingGoal> goals,
    required String query,
    required String category,
  }) {
    final categories = [
      'All',
      ...partners.map((partner) => partner.category).toSet().toList()..sort(),
    ];
    final filtered =
        partners
            .where((partner) => partner.matchesCategory(category))
            .where((partner) => partner.matchesQuery(query))
            .toList()
          ..sort((a, b) {
            final score = b
                .relevanceScore(profile: profile, goals: goals)
                .compareTo(a.relevanceScore(profile: profile, goals: goals));
            if (score != 0) return score;
            return b.trustScore.compareTo(a.trustScore);
          });
    return _MarketplaceModel(
      filtered: filtered,
      categories: categories,
      bestMatch: filtered.isEmpty ? null : filtered.first,
    );
  }
}

class _MarketplaceHeader extends StatelessWidget {
  const _MarketplaceHeader({required this.count, required this.onCompare});

  final int count;
  final VoidCallback? onCompare;

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
                'Marketplace',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count verified financial options',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: onCompare,
          icon: const Icon(Icons.compare_arrows_rounded),
          tooltip: 'Compare',
          style: IconButton.styleFrom(
            backgroundColor: onCompare == null
                ? AppTheme.mutedFillFor(context)
                : AppTheme.primaryFor(context),
            foregroundColor: onCompare == null
                ? AppTheme.textHintFor(context)
                : Colors.white,
          ),
        ),
      ],
    );
  }
}

class _BestMatchCard extends StatelessWidget {
  const _BestMatchCard({required this.partner, required this.onOpen});

  final MarketplacePartner? partner;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    if (partner == null) {
      return const SizedBox.shrink();
    }
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
          _StatusPill(label: 'Best match', color: AppTheme.success),
          const SizedBox(height: 10),
          Text(
            partner!.name,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            partner!.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Trust',
                  value: partner!.trustScore.toStringAsFixed(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(label: 'Rate', value: partner!.rateLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(partner!.ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.partner,
    required this.compared,
    required this.onOpen,
    required this.onCompare,
  });

  final MarketplacePartner partner;
  final bool compared;
  final VoidCallback onOpen;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
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
                  color: Color(partner.colorHex).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _partnerIcon(partner.category),
                  color: Color(partner.colorHex),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${partner.category} • Trust ${partner.trustScore.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCompare,
                icon: Icon(
                  compared
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                ),
                tooltip: compared ? 'Compared' : 'Compare',
                color: compared
                    ? AppTheme.success
                    : AppTheme.primaryFor(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            partner.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: partner.rateLabel),
              _InfoChip(label: partner.approvalSpeed),
              if (partner.isVerified) const _InfoChip(label: 'Verified'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onOpen,
              child: const Text('View details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Search loans, insurance, jobs',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: category == selected,
              onSelected: (_) => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompareSheet extends StatelessWidget {
  const _CompareSheet({required this.partners});

  final List<MarketplacePartner> partners;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            Text(
              'Compare',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimaryFor(context),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...partners.map(
              (partner) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CompareRow(partner: partner),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.partner});

  final MarketplacePartner partner;

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
            partner.name,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          _CompareLine(
            label: 'Trust',
            value: partner.trustScore.toStringAsFixed(0),
          ),
          _CompareLine(label: 'Rate', value: partner.rateLabel),
          _CompareLine(label: 'Speed', value: partner.approvalSpeed),
          if (partner.minimumIncome != null)
            _CompareLine(
              label: 'Income',
              value: CurrencyUtils.format(partner.minimumIncome!),
            ),
        ],
      ),
    );
  }
}

class _CompareLine extends StatelessWidget {
  const _CompareLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.mutedFillFor(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppTheme.textSecondaryFor(context),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

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

class _EmptyMarketplace extends StatelessWidget {
  const _EmptyMarketplace();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Text(
        'No partners match this search.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppTheme.textSecondaryFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _partnerIcon(String category) {
  final key = category.toLowerCase();
  if (key.contains('loan')) return Icons.payments_rounded;
  if (key.contains('insurance')) return Icons.health_and_safety_rounded;
  if (key.contains('job')) return Icons.work_rounded;
  if (key.contains('education')) return Icons.school_rounded;
  if (key.contains('utilities')) return Icons.bolt_rounded;
  return Icons.storefront_rounded;
}
