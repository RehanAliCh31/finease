import 'package:flutter/material.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _cat = 'All';

  final _partners = [
    {'name': 'SecureLife Micro-Insurance', 'desc': 'Comprehensive health and accidental coverage for gig workers and small families. Low premiums with instant claim settlement.', 'icon': Icons.health_and_safety_rounded, 'color': const Color(0xFF2E3192), 'tag': 'Insurance', 'badge': 'Popular'},
    {'name': 'SwiftHire Platform', 'desc': 'Connect with top-tier employers seeking specialized talent. Exclusive placement services for FinEdge users.', 'icon': Icons.work_rounded, 'color': const Color(0xFF006A66), 'tag': 'Jobs', 'badge': 'New'},
    {'name': 'WellnessPlus Vouchers', 'desc': 'Get up to 40% discount on health checkups, medicine, and wellness kits with our network of 500+ clinics.', 'icon': Icons.spa_rounded, 'color': const Color(0xFF4CAF50), 'tag': 'All', 'badge': '40% Off'},
    {'name': 'GrowthPath SMB Grants', 'desc': 'Access non-repayable grants from \$1,000 to \$10,000 for verified businesses. Unlocking potential for entrepreneurs.', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFFFF9800), 'tag': 'All', 'badge': ''},
    {'name': 'EduLoan & Scholarships', 'desc': 'Flexible student loans with a 6-month grace period after graduation. Funding your future.', 'icon': Icons.school_rounded, 'color': const Color(0xFF9C27B0), 'tag': 'All', 'badge': ''},
    {'name': 'EcoGreen Equipment', 'desc': 'Affordable solar installations and energy-efficient tools for sustainable small business growth.', 'icon': Icons.eco_rounded, 'color': const Color(0xFF388E3C), 'tag': 'All', 'badge': 'Eco'},
    {'name': 'LegalShield Pro', 'desc': 'Expert legal consultation for contracts, property, and dispute resolution at discounted rates.', 'icon': Icons.gavel_rounded, 'color': const Color(0xFF795548), 'tag': 'All', 'badge': ''},
  ];

  @override
  Widget build(BuildContext context) {
    final cats = ['All', 'Insurance', 'Jobs'];
    final filtered = _cat == 'All' ? _partners : _partners.where((p) => p['tag'] == _cat).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            automaticallyImplyLeading: true,
            backgroundColor: const Color(0xFF15157D),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF15157D), Color(0xFF2E3192)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('Partner Marketplace', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                      SizedBox(height: 6),
                      Text('Empowering your journey with a curated ecosystem of financial security, growth, and wellness solutions.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter')),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: cats.map((c) {
                  final sel = _cat == c;
                  return GestureDetector(
                    onTap: () => setState(() => _cat = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF2E3192) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? const Color(0xFF2E3192) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(c == 'All' ? 'All Services' : c, style: TextStyle(color: sel ? Colors.white : const Color(0xFF0B1C30), fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Inter')),
                    ),
                  );
                }).toList()),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) => _card(filtered[i]), childCount: filtered.length)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF15157D), Color(0xFF2E3192)]), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_user_rounded, color: Color(0xFF00F2EA), size: 28)),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('The FinEdge Guarantee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Plus Jakarta Sans')),
                    SizedBox(height: 4),
                    Text('Every partner undergoes a rigorous 12-point vetting process. We ensure high-quality service, fair pricing, and data security.', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter')),
                  ])),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (p['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(p['icon'] as IconData, color: p['color'] as Color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(p['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B1C30), fontFamily: 'Plus Jakarta Sans'))),
          if ((p['badge'] as String).isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(20)), child: Text(p['badge'] as String, style: const TextStyle(color: Color(0xFF2E3192), fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        Text(p['desc'] as String, style: const TextStyle(color: Color(0xFF464652), fontSize: 13, fontFamily: 'Inter', height: 1.5)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E3192), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () {}, child: const Text('Learn More', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter')))),
      ]),
    );
  }
}
