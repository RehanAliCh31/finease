import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('system_metrics').doc('overview').snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final activeUsers = data['activeUsers'] ?? 12842;
          final latency = data['latencyMs'] ?? 12;
          final pendingWelfare = data['pendingWelfare'] ?? 42;
          final urgentReviews = data['urgentReviews'] ?? 12;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
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
                          Text('Admin Central', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                          SizedBox(height: 4),
                          Text('System oversight and moderation', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
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
                      // Metric cards
                      Row(children: [
                        Expanded(child: _metricCard('Active Users', '$activeUsers', Icons.people_rounded, const Color(0xFF2E3192), subtitle: '')),
                        const SizedBox(width: 12),
                        Expanded(child: _metricCard('System Health', 'Lat: ${latency}ms', Icons.monitor_heart_rounded, const Color(0xFF006A66), subtitle: '')),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFDAD6), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.assignment_late_rounded, color: Color(0xFFBA1A1A), size: 24)),
                          const SizedBox(width: 14),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Pending Welfare', style: TextStyle(color: Color(0xFF777683), fontSize: 12, fontFamily: 'Inter')),
                            Text('$pendingWelfare Applications', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0B1C30), fontFamily: 'Plus Jakarta Sans')),
                            Text('$urgentReviews urgent reviews required', style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 12, fontFamily: 'Inter')),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      const Text('Forum Moderation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30), fontFamily: 'Plus Jakarta Sans')),
                      const SizedBox(height: 12),
                      _forumFlag(context, '"Has anyone tried the new offshore investment vehicle for long-term growth? Thinking about moving..."', 'Potential spam post', Icons.flag_rounded, const Color(0xFFFF9800)),
                      _forumFlag(context, '"Reported: Potential phishing link shared in \'Tax Planning\' thread. Please investigate immediately."', 'Security threat', Icons.warning_rounded, const Color(0xFFBA1A1A)),
                      const SizedBox(height: 24),
                      const Text('Traffic Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30), fontFamily: 'Plus Jakarta Sans')),
                      const SizedBox(height: 12),
                      _trafficBar('Homepage', 0.85, '8.5K'),
                      _trafficBar('Marketplace', 0.62, '6.2K'),
                      _trafficBar('Savings', 0.48, '4.8K'),
                      _trafficBar('Rewards', 0.71, '7.1K'),
                      const SizedBox(height: 24),
                      const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30), fontFamily: 'Plus Jakarta Sans')),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        _actionChip(context, 'Manage Users', Icons.manage_accounts_rounded),
                        _actionChip(context, 'Approve Partners', Icons.handshake_rounded),
                        _actionChip(context, 'Generate Reports', Icons.analytics_rounded),
                        _actionChip(context, 'Suspend Account', Icons.block_rounded),
                      ]),
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

  Widget _metricCard(String label, String value, IconData icon, Color color, {required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const Spacer(),
        ]),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Color(0xFF777683), fontSize: 12, fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
      ]),
    );
  }

  Widget _forumFlag(BuildContext context, String quote, String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.4))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text(quote, style: const TextStyle(color: Color(0xFF464652), fontSize: 12, fontFamily: 'Inter', height: 1.4)),
          const SizedBox(height: 8),
          Row(children: [
            _actionBtn(context, 'Dismiss', const Color(0xFFE5EEFF), const Color(0xFF2E3192)),
            const SizedBox(width: 8),
            _actionBtn(context, 'Remove Post', const Color(0xFFFFDAD6), const Color(0xFFBA1A1A)),
          ]),
        ])),
      ]),
    );
  }

  Widget _actionBtn(BuildContext context, String label, Color bg, Color fg) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label action completed')));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ),
    );
  }

  Widget _trafficBar(String label, double value, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: Color(0xFF464652), fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          Text(count, style: const TextStyle(color: Color(0xFF2E3192), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: value, backgroundColor: const Color(0xFFE5EEFF), color: const Color(0xFF2E3192), minHeight: 8)),
      ]),
    );
  }

  Widget _actionChip(BuildContext context, String label, IconData icon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2E3192), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Executing: $label')));
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
    );
  }
}
