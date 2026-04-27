import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _pushAlerts = true;
  bool _monthlyReports = true;
  bool _biometric = false;
  bool _darkTheme = false;
  String _language = 'English (US)';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    if (doc.exists) {
      final d = doc.data()!;
      setState(() {
        _pushAlerts = d['pushAlerts'] ?? true;
        _monthlyReports = d['monthlyReports'] ?? true;
        _biometric = d['biometricLogin'] ?? false;
        _darkTheme = d['darkTheme'] ?? false;
        _language = d['language'] ?? 'English (US)';
      });
    }
  }

  Future<void> _save(String key, dynamic val) async {
    if (_uid.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(_uid).set({key: val}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Alex Rivera';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF15157D),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF15157D), Color(0xFF2E3192)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null ? const Icon(Icons.person_rounded, size: 36, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                        const SizedBox(height: 4),
                        const Text('Premium Member since 2023', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter')),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF00F2EA).withOpacity(0.25), borderRadius: BorderRadius.circular(12)), child: const Text('Pro Member', style: TextStyle(color: Color(0xFF00F2EA), fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'Inter'))),
                      ]),
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
                  // Security & Privacy
                  _sectionHeader('Security & Privacy'),
                  _tile(Icons.lock_outline_rounded, 'Change Password', subtitle: 'Update your login credentials'),
                  _tile(Icons.fingerprint_rounded, 'Biometric Login', trailing: Switch(value: _biometric, onChanged: (v) { setState(() => _biometric = v); _save('biometricLogin', v); }, activeColor: const Color(0xFF00F2EA))),
                  _tile(Icons.security_rounded, 'Two-Factor Authentication', subtitle: 'Add an extra layer of security'),

                  const SizedBox(height: 20),
                  _sectionHeader('Notifications'),
                  _tile(Icons.notifications_active_rounded, 'Push Alerts', subtitle: 'Real-time spending updates', trailing: Switch(value: _pushAlerts, onChanged: (v) { setState(() => _pushAlerts = v); _save('pushAlerts', v); }, activeColor: const Color(0xFF00F2EA))),
                  _tile(Icons.bar_chart_rounded, 'Monthly Reports', subtitle: 'Detailed expense analysis', trailing: Switch(value: _monthlyReports, onChanged: (v) { setState(() => _monthlyReports = v); _save('monthlyReports', v); }, activeColor: const Color(0xFF00F2EA))),

                  const SizedBox(height: 20),
                  _sectionHeader('Language'),
                  _tile(Icons.language_rounded, _language, subtitle: 'App display language', trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C5D4))),

                  const SizedBox(height: 20),
                  _sectionHeader('Theme Selection'),
                  _tile(Icons.dark_mode_rounded, 'Dark Theme', trailing: Switch(value: _darkTheme, onChanged: (v) { setState(() => _darkTheme = v); _save('darkTheme', v); }, activeColor: const Color(0xFF00F2EA))),

                  const SizedBox(height: 20),
                  _sectionHeader('Danger Zone'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.3))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Delete Account', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', fontSize: 15)),
                      const SizedBox(height: 6),
                      const Text('Deleting your account will permanently erase all financial history, connected wallets, and custom insights.', style: TextStyle(color: Color(0xFF93000A), fontSize: 12, fontFamily: 'Inter', height: 1.5)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () => _confirmDelete(context),
                          child: const Text('Delete My Account', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5EEFF), foregroundColor: const Color(0xFF2E3192), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
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
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30), fontFamily: 'Plus Jakarta Sans')),
    );
  }

  Widget _tile(IconData icon, String title, {String? subtitle, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE5EEFF), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF2E3192), size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Inter', fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Color(0xFF777683), fontSize: 11, fontFamily: 'Inter')) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C5D4)),
        onTap: () {},
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
        content: const Text('This cannot be undone. All data will be permanently deleted.', style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)), onPressed: () => Navigator.pop(context), child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
