import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/saving_goal.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_utils.dart';
import '../admin/admin_dashboard_screen.dart';
import '../profile/about_page.dart';
import '../settings/settings_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final firestoreService = authService.firestoreService;
    final user = authService.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.primary, Color(0xFF1D2671)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<Map<String, dynamic>>(
                          stream: firestoreService?.getUserProfile(),
                          builder: (context, snapshot) {
                            final profile = snapshot.data ?? const {};
                            final name =
                                profile['fullName'] as String? ??
                                user?.displayName ??
                                user?.email?.split('@').first ??
                                'User';
                            final role = profile['role'] as String? ?? 'user';
                            return Column(
                              children: [
                                Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user?.email ?? '',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.74),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    role == 'admin'
                                        ? 'Admin account'
                                        : (profile['isDemoAccount'] == true
                                              ? 'Demo account'
                                              : 'Personal account'),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (firestoreService != null)
                    StreamBuilder<List<SavingGoal>>(
                      stream: firestoreService.getSavingGoals(),
                      builder: (context, snapshot) {
                        final goals = snapshot.data ?? const <SavingGoal>[];
                        final saved = goals.fold<double>(
                          0,
                          (sum, goal) => sum + goal.currentAmount,
                        );
                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Saved',
                                value: CurrencyUtils.format(
                                  saved,
                                  compact: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Goals',
                                value: '${goals.length}',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Biometric',
                                value: authService.isBiometricEnabled
                                    ? 'On'
                                    : 'Off',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: authService.isBiometricEnabled,
                          onChanged: (value) async {
                            if (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sign in again from the login screen to enable biometric unlock.',
                                  ),
                                ),
                              );
                            } else {
                              await authService.disableBiometricLogin();
                            }
                          },
                          title: Text(
                            'Touch ID / Face ID',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            authService.isBiometricEnabled
                                ? 'Biometric quick login is active on this device.'
                                : 'Enable this from login after entering your password.',
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Settings'),
                          subtitle: const Text(
                            'Notifications, security, language, and app preferences',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.info_outline_rounded),
                          title: const Text('About FinEase'),
                          subtitle: const Text(
                            'App overview, features, and developer details',
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutPage(),
                            ),
                          ),
                        ),
                        if (authService.isAdmin) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            title: const Text('Admin Panel'),
                            subtitle: const Text(
                              'Moderation, metrics, and operational controls',
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminDashboardScreen(),
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 1),
                        // ListTile(
                        //   leading: const Icon(Icons.shield_outlined),
                        //   title: const Text('Security'),
                        //   subtitle: const Text(
                        //     'Firebase authentication with secure local storage',
                        //   ),
                        // ),
                        const Divider(height: 1),
                        // ListTile(
                        //   leading: const Icon(Icons.school_rounded),
                        //   title: const Text('Learning Progress'),
                        //   subtitle: const Text(
                        //     'Course progress and quiz scores sync to your profile',
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Launch readiness',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          authService.isDemoAccount
                              ? 'You are in the presentation account. Create a personal account to store your own transactions, budgets, savings goals, forum activity, and quiz progress in Firebase.'
                              : 'Your account stores transactions, budgets, savings goals, literacy progress, and community activity directly in Firebase.',
                          style: GoogleFonts.inter(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => authService.signOut(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                      ),
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
