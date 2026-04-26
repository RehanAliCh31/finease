import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final primaryColor = const Color(0xFF2E3192);


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            backgroundColor: primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                          child: Icon(Icons.person_rounded, size: 50, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.email?.split('@')[0].toUpperCase() ?? 'ALEX JOHNSON', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      )),
                    const SizedBox(height: 4),
                    Text(user?.email ?? 'alex.johnson@example.com', 
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      )),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF7941D), size: 16),
                          const SizedBox(width: 8),
                          Text('ELITE MEMBER', 
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    Text('ACCOUNT SETTINGS', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      )),
                    const SizedBox(height: 16),
                    _buildSettingsGroup([
                      _buildSettingItem('Personal Info', Icons.person_outline_rounded, primaryColor),
                      _buildSettingItem('My Cards', Icons.credit_card_rounded, const Color(0xFF1BFFFF)),
                      _buildSettingItem('Security', Icons.shield_outlined, const Color(0xFFFFB7B7)),
                    ]),
                    const SizedBox(height: 32),
                    Text('PREFERENCES', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      )),
                    const SizedBox(height: 16),
                    _buildSettingsGroup([
                      _buildSettingItem('Notifications', Icons.notifications_none_rounded, const Color(0xFFF7941D)),
                      _buildSettingItem('Appearance', Icons.palette_outlined, const Color(0xFF00B09B)),
                      _buildSettingItem('Language', Icons.language_rounded, const Color(0xFF2E3192)),
                    ]),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => authService.signOut(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF4B2B),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFFFFE5E0)),
                          ),
                        ),
                        child: Text('Log Out', 
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('Savings', '\$12.5k')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Credits', '742')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Goals', '4/6')),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(value, 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            )),
          const SizedBox(height: 4),
          Text(label, 
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, 
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                )),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 14),
          ],
        ),
      ),
    );
  }
}
