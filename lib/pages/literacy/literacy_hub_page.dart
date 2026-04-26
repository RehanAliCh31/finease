import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiteracyHubPage extends StatefulWidget {
  const LiteracyHubPage({super.key});

  @override
  State<LiteracyHubPage> createState() => _LiteracyHubPageState();
}

class _LiteracyHubPageState extends State<LiteracyHubPage> {
  final Color primaryColor = const Color(0xFF2E3192);
  final Color secondaryColor = const Color(0xFF1BFFFF);
  final Color darkColor = const Color(0xFF1A1A1A);
  final Color cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressDashboard(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Explore Topics', 'Broaden your knowledge'),
                  const SizedBox(height: 20),
                  _buildCategoryScroll(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Featured Course', 'Recommended for you'),
                  const SizedBox(height: 20),
                  _buildFeaturedCard(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Bite-sized Lessons', '5-10 min reads'),
                  const SizedBox(height: 20),
                  _buildLessonList(),
                  const SizedBox(height: 40),
                  _buildCommunityCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryColor, const Color(0xFF1B1B4D)],
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
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Mastery',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Elevate your wealth with expert knowledge.',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressDashboard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LEARNING LEVEL', 
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Executive', 
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: secondaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: secondaryColor, size: 14),
                    const SizedBox(width: 6),
                    Text('1,240 XP', style: GoogleFonts.inter(color: secondaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [secondaryColor, primaryColor]),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('70% to Level 5', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
              Text('Next: Visionary', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, 
          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: darkColor)),
        const SizedBox(height: 4),
        Text(subtitle, 
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCategoryScroll() {
    final categories = [
      {'name': 'Investing', 'icon': Icons.trending_up, 'color': const Color(0xFFE8F5E9)},
      {'name': 'Crypto', 'icon': Icons.currency_bitcoin, 'color': const Color(0xFFFFF3E0)},
      {'name': 'Real Estate', 'icon': Icons.home_work_rounded, 'color': const Color(0xFFE3F2FD)},
      {'name': 'Taxes', 'icon': Icons.receipt_long, 'color': const Color(0xFFF3E5F5)},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          return Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cat['color'] as Color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(cat['icon'] as IconData, color: darkColor.withOpacity(0.7)),
                const SizedBox(height: 12),
                Text(cat['name'] as String, 
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: darkColor)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?q=80&w=800&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('NEW', 
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
            const SizedBox(height: 12),
            Text('Advanced Portfolio Diversification', 
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('4.9 (1.2k reviews)', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                Text('45 min', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonList() {
    return Column(
      children: [
        _buildLessonItem('The 50/30/20 Rule', 'Budgeting basics', '8 min', Icons.pie_chart_rounded),
        const SizedBox(height: 16),
        _buildLessonItem('Understanding ETFs', 'Investment vehicles', '12 min', Icons.layers_rounded),
        const SizedBox(height: 16),
        _buildLessonItem('Credit Score Secrets', 'Debt management', '10 min', Icons.credit_score_rounded),
      ],
    );
  }

  Widget _buildLessonItem(String title, String category, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: darkColor)),
                Text('$category • $time', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 16),
        ],
      ),
    );
  }

  Widget _buildCommunityCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryColor, const Color(0xFF6A11CB)]),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.groups_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 16),
          Text('Join the FinEase Circle', 
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Connect with 10k+ learners and experts.', 
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Enter Community', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
