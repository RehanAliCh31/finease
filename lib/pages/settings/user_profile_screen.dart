import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final name = data['fullName'] ?? user?.displayName ?? 'Alex Rivera';
          final email = data['email'] ?? user?.email ?? 'alex.rivera@finease.io';
          final memberSince = data['memberSince'] ?? '2023';
          final netWorth = data['netWorth'] ?? 142500;
          final points = data['points'] ?? 1240;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                automaticallyImplyLeading: true,
                backgroundColor: const Color(0xFF15157D),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF15157D), Color(0xFF2E3192)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const SizedBox(height: 8),
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null ? const Icon(Icons.person_rounded, size: 44, color: Colors.white) : null,
                          ),
                          const SizedBox(height: 12),
                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                          const SizedBox(height: 4),
                          Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Net Worth card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF2E3192), Color(0xFF4F54B4)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF2E3192).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Estimated Net Worth', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
                            const SizedBox(height: 6),
                            Text('\$${_formatNum(netWorth)}', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                            const SizedBox(height: 4),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: Text('Member since $memberSince', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Inter'))),
                          ]),
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.trending_up_rounded, color: Color(0xFF00F2EA), size: 30)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      // Points summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(16)),
                        child: Row(children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFF2E3192), size: 28),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('FinEdge Points', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E3192), fontFamily: 'Plus Jakarta Sans')),
                            Text('$points pts available', style: const TextStyle(color: Color(0xFF464652), fontSize: 13, fontFamily: 'Inter')),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2E3192), borderRadius: BorderRadius.circular(12)), child: const Text('Redeem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Inter'))),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      const Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30), fontFamily: 'Plus Jakarta Sans')),
                      const SizedBox(height: 12),
                      _settingsTile(context, Icons.person_outline_rounded, 'Edit Profile', 'Update your personal information', () {}),
                      _settingsTile(context, Icons.lock_outline_rounded, 'Security', 'Password, 2FA, and biometrics', () {}),
                      _settingsTile(context, Icons.notifications_none_rounded, 'Notifications', 'Manage alert preferences', () {}),
                      _settingsTile(context, Icons.account_balance_wallet_rounded, 'Linked Accounts', 'Manage connected bank accounts', () {}),
                      _settingsTile(context, Icons.settings_rounded, 'Settings', 'App preferences and more', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFDAD6), foregroundColor: const Color(0xFFBA1A1A), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () async => await FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 15)),
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
    );
  }

  Widget _settingsTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF2E3192), size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Plus Jakarta Sans', fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF777683), fontSize: 12, fontFamily: 'Inter')),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C5D4)),
        onTap: onTap,
      ),
    );
  }

  String _formatNum(dynamic n) {
    final num val = n is num ? n : 0;
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toString();
  }
}
