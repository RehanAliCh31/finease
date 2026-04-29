import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_constants.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _AdminTab('Overview', Icons.dashboard_rounded),
      _AdminTab('Users', Icons.manage_accounts_rounded),
      _AdminTab('Forum', Icons.forum_rounded),
      _AdminTab('Partners', Icons.handshake_rounded),
      _AdminTab('Welfare', Icons.volunteer_activism_rounded),
      _AdminTab('Reports', Icons.analytics_rounded),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              AppConstants.adminEmail,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Seed review samples',
            icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.white),
            onPressed: _seedAdminSamples,
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.primary,
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final selected = index == _tabIndex;
                return ChoiceChip(
                  selected: selected,
                  avatar: Icon(
                    tab.icon,
                    size: 17,
                    color: selected ? AppTheme.primary : Colors.black,
                  ),
                  label: Text(tab.label),
                  labelStyle: GoogleFonts.inter(
                    color: selected ? AppTheme.primary : Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: selected ? 1 : 0.28),
                  ),
                  onSelected: (_) => setState(() => _tabIndex = index),
                );
              },
            ),
          ),
          Expanded(child: _buildTab()),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildTab() {
    switch (_tabIndex) {
      case 1:
        return _usersTab();
      case 2:
        return _forumTab();
      case 3:
        return _partnersTab();
      case 4:
        return _welfareTab();
      case 5:
        return _reportsTab();
      default:
        return _overviewTab();
    }
  }

  Widget? _buildFab() {
    if (_tabIndex == 3) {
      return FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text(
  'Partner',
  style: TextStyle(color: Colors.white),
),
        onPressed: () => _showPartnerDialog(),
      );
    }
    if (_tabIndex == 4) {
      return FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: const Text(
          'Case',
            style: TextStyle(color: Colors.white),
        ),
        onPressed: _showWelfareDialog,
      );
    }
    return null;
  }

  Widget _overviewTab() {
    return _Stream4(
      users: _db.collection('users').snapshots(),
      posts: _db.collection('forum_posts').snapshots(),
      partners: _db.collection('marketplace_partners').snapshots(),
      welfare: _db.collection('welfare_applications').snapshots(),
      builder: (context, users, posts, partners, welfare) {
        final userDocs = users.docs;
        final postDocs = posts.docs;
        final partnerDocs = partners.docs;
        final welfareDocs = welfare.docs;
        final suspended = userDocs
            .where((d) => d.data()['accountStatus'] == 'suspended')
            .length;
        final flagged = postDocs
            .where((d) => d.data()['moderationStatus'] == 'flagged')
            .length;
        final activePartners = partnerDocs
            .where((d) => (d.data()['status'] ?? 'active') == 'active')
            .length;
        final pendingCases = welfareDocs
            .where((d) => (d.data()['status'] ?? 'pending') == 'pending')
            .length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
          children: [
            _metricsEditor(),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 760 ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _MetricTile(
                  'Users',
                  '${userDocs.length}',
                  '$suspended suspended',
                  Icons.people_rounded,
                  AppTheme.primary,
                ),
                _MetricTile(
                  'Forum Posts',
                  '${postDocs.length}',
                  '$flagged flagged',
                  Icons.forum_rounded,
                  AppTheme.warning,
                ),
                _MetricTile(
                  'Partners',
                  '$activePartners',
                  '${partnerDocs.length} total',
                  Icons.handshake_rounded,
                  AppTheme.success,
                ),
                _MetricTile(
                  'Welfare Cases',
                  '$pendingCases',
                  '${welfareDocs.length} total',
                  Icons.assignment_late_rounded,
                  AppTheme.error,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Operations'),
            const SizedBox(height: 10),
            _ActionGrid(
              actions: [
                _AdminAction(
                  'Review users',
                  Icons.manage_accounts_rounded,
                  () => setState(() => _tabIndex = 1),
                ),
                _AdminAction(
                  'Moderate forum',
                  Icons.shield_rounded,
                  () => setState(() => _tabIndex = 2),
                ),
                _AdminAction(
                  'Approve partners',
                  Icons.verified_rounded,
                  () => setState(() => _tabIndex = 3),
                ),
                _AdminAction(
                  'Welfare queue',
                  Icons.volunteer_activism_rounded,
                  () => setState(() => _tabIndex = 4),
                ),
                _AdminAction(
                  'Copy report',
                  Icons.file_copy_rounded,
                  _copyReport,
                ),
                _AdminAction(
                  'Seed samples',
                  Icons.auto_fix_high_rounded,
                  _seedAdminSamples,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle('Recent Activity'),
            const SizedBox(height: 10),
            ...postDocs.take(4).map((doc) {
              final data = doc.data();
              return _InfoCard(
                icon: Icons.forum_rounded,
                title: data['title'] ?? 'Forum discussion',
                subtitle:
                    '${data['category'] ?? 'General'} by ${data['authorName'] ?? 'User'}',
                trailing: data['moderationStatus'] ?? 'visible',
              );
            }),
          ],
        );
      },
    );
  }

  Widget _metricsEditor() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('system_metrics').doc('overview').snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.monitor_heart_rounded,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _sectionTitle('System Health')),
                  TextButton.icon(
                    onPressed: () => _showMetricsDialog(data),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniStat('Active users', data['activeUsers'] ?? 0),
                  ),
                  Expanded(
                    child: _miniStat('Latency', '${data['latencyMs'] ?? 0}ms'),
                  ),
                  Expanded(
                    child: _miniStat('Urgent', data['urgentReviews'] ?? 0),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _usersTab() {
    return Column(
      children: [
        _searchBox('Search users by name, email, or role'),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db.collection('users').orderBy('email').snapshots(),
            builder: (context, snapshot) {
              final users = _filterDocs(snapshot.data?.docs ?? []);
              if (users.isEmpty) {
                return _emptyState(
                  Icons.people_outline_rounded,
                  'No users found',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                itemCount: users.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final data = doc.data();
                  final status = data['accountStatus'] ?? 'active';
                  final isAdmin = data['role'] == 'admin';
                  return _InfoCard(
                    icon: isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.person_rounded,
                    title: data['fullName'] ?? data['email'] ?? 'FinEase user',
                    subtitle:
                        '${data['email'] ?? 'No email'}\nRole: ${data['role'] ?? 'user'}',
                    trailing: status,
                    actions: [
                      _smallButton(
                        status == 'suspended' ? 'Activate' : 'Suspend',
                        status == 'suspended'
                            ? Icons.check_circle_rounded
                            : Icons.block_rounded,
                        () => _setUserStatus(
                          doc.id,
                          status == 'suspended' ? 'active' : 'suspended',
                        ),
                      ),
                      _smallButton(
                        'Profile',
                        Icons.badge_rounded,
                        () => _showUserDetails(doc),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _forumTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('forum_posts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final posts = snapshot.data?.docs ?? [];
        if (posts.isEmpty) {
          return _emptyState(Icons.forum_outlined, 'No forum posts yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
          itemCount: posts.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = posts[index];
            final data = doc.data();
            final status = data['moderationStatus'] ?? 'visible';
            return _InfoCard(
              icon: status == 'removed'
                  ? Icons.visibility_off_rounded
                  : Icons.forum_rounded,
              title: data['title'] ?? 'Discussion',
              subtitle:
                  '${data['content'] ?? ''}\n${data['category'] ?? 'General'} by ${data['authorName'] ?? 'User'}',
              trailing: status,
              actions: [
                _smallButton(
                  'Flag',
                  Icons.flag_rounded,
                  () => _setPostStatus(doc.id, 'flagged'),
                ),
                _smallButton(
                  'Restore',
                  Icons.visibility_rounded,
                  () => _setPostStatus(doc.id, 'visible'),
                ),
                _smallButton(
                  'Remove',
                  Icons.delete_outline_rounded,
                  () => _setPostStatus(doc.id, 'removed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _partnersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('marketplace_partners')
          .orderBy('priority')
          .snapshots(),
      builder: (context, snapshot) {
        final partners = snapshot.data?.docs ?? [];
        if (partners.isEmpty) {
          return _emptyState(Icons.storefront_outlined, 'No partners yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
          itemCount: partners.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = partners[index];
            final data = doc.data();
            final active = (data['status'] ?? 'active') == 'active';
            final approved = (data['approved'] ?? true) == true;
            return _InfoCard(
              icon: Icons.handshake_rounded,
              title: data['name'] ?? 'Partner',
              subtitle:
                  '${data['category'] ?? 'General'}\n${data['description'] ?? ''}',
              trailing: active && approved ? 'active' : 'hidden',
              actions: [
                _smallButton(
                  'Edit',
                  Icons.edit_rounded,
                  () => _showPartnerDialog(doc: doc),
                ),
                _smallButton(
                  active ? 'Disable' : 'Enable',
                  active
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  () {
                    doc.reference.set({
                      'status': active ? 'inactive' : 'active',
                    }, SetOptions(merge: true));
                  },
                ),
                _smallButton(
                  approved ? 'Unapprove' : 'Approve',
                  Icons.verified_rounded,
                  () {
                    doc.reference.set({
                      'approved': !approved,
                    }, SetOptions(merge: true));
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _welfareTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('welfare_applications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final cases = snapshot.data?.docs ?? [];
        if (cases.isEmpty) {
          return _emptyState(Icons.assignment_outlined, 'No welfare cases yet');
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
          itemCount: cases.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = cases[index];
            final data = doc.data();
            return _InfoCard(
              icon: Icons.volunteer_activism_rounded,
              title: data['applicantName'] ?? 'Applicant',
              subtitle:
                  '${data['program'] ?? 'Support request'}\n${data['notes'] ?? ''}',
              trailing: data['status'] ?? 'pending',
              actions: [
                _smallButton(
                  'Approve',
                  Icons.check_circle_rounded,
                  () => _setWelfareStatus(doc.id, 'approved'),
                ),
                _smallButton(
                  'Reject',
                  Icons.cancel_rounded,
                  () => _setWelfareStatus(doc.id, 'rejected'),
                ),
                _smallButton(
                  'Resolve',
                  Icons.task_alt_rounded,
                  () => _setWelfareStatus(doc.id, 'resolved'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _reportsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        _InfoCard(
          icon: Icons.file_copy_rounded,
          title: 'Operational report',
          subtitle:
              'Copies a current CSV-style summary for users, forum posts, partners, welfare cases, and system metrics.',
          trailing: 'ready',
          actions: [
            _smallButton('Copy Report', Icons.copy_rounded, _copyReport),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          icon: Icons.security_rounded,
          title: 'Admin controls',
          subtitle:
              'Suspended users are blocked during email/password sign in. Disabled partners are hidden from the marketplace. Removed forum posts are hidden from users.',
          trailing: 'active',
        ),
        const SizedBox(height: 12),
        _metricsEditor(),
      ],
    );
  }

  Widget _searchBox(String hint) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _search = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_search.isEmpty) {
      return docs;
    }
    return docs.where((doc) {
      final haystack = doc.data().values.join(' ').toLowerCase();
      return haystack.contains(_search);
    }).toList();
  }

  Future<void> _setUserStatus(String uid, String status) async {
    await _db.collection('users').doc(uid).set({
      'accountStatus': status,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _snack('User marked $status.');
  }

  Future<void> _setPostStatus(String postId, String status) async {
    await _db.collection('forum_posts').doc(postId).set({
      'moderationStatus': status,
      'moderatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': AppConstants.adminEmail,
    }, SetOptions(merge: true));
    _snack('Post marked $status.');
  }

  Future<void> _setWelfareStatus(String id, String status) async {
    await _db.collection('welfare_applications').doc(id).set({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': AppConstants.adminEmail,
    }, SetOptions(merge: true));
    _snack('Case marked $status.');
  }

  Future<void> _seedAdminSamples() async {
    final batch = _db.batch();
    final welfare = _db.collection('welfare_applications');
    batch.set(welfare.doc('sample-bisp-review'), {
      'applicantName': 'Ayesha Khan',
      'program': 'Benazir Income Support Programme',
      'status': 'pending',
      'priority': 'urgent',
      'notes': 'Household income verification needed before referral.',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(welfare.doc('sample-scholarship-review'), {
      'applicantName': 'Usman Ali',
      'program': 'Education Scholarship Desk',
      'status': 'pending',
      'priority': 'normal',
      'notes': 'Student uploaded fee estimate and CNIC details offline.',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(
      _db.collection('forum_posts').doc('sample-admin-flag'),
      {
        'title': 'Suspicious investment link review',
        'content':
            'A user reported a high-return link that needs moderation before it spreads.',
        'category': 'Investing',
        'authorName': 'FinEase Monitor',
        'authorAvatar': '',
        'authorId': 'system',
        'likes': 0,
        'comments': 0,
        'moderationStatus': 'flagged',
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    _snack('Admin sample data is ready.');
  }

  Future<void> _copyReport() async {
    final users = await _db.collection('users').get();
    final posts = await _db.collection('forum_posts').get();
    final partners = await _db.collection('marketplace_partners').get();
    final welfare = await _db.collection('welfare_applications').get();
    final metrics = await _db
        .collection('system_metrics')
        .doc('overview')
        .get();
    final report = StringBuffer()
      ..writeln('FinEase Admin Report')
      ..writeln(
        'Generated,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      )
      ..writeln('Users,${users.size}')
      ..writeln(
        'Suspended Users,${users.docs.where((d) => d.data()['accountStatus'] == 'suspended').length}',
      )
      ..writeln('Forum Posts,${posts.size}')
      ..writeln(
        'Flagged Posts,${posts.docs.where((d) => d.data()['moderationStatus'] == 'flagged').length}',
      )
      ..writeln('Partners,${partners.size}')
      ..writeln('Welfare Cases,${welfare.size}')
      ..writeln('System Metrics,"${metrics.data()}"');
    await Clipboard.setData(ClipboardData(text: report.toString()));
    _snack('Report copied to clipboard.');
  }

  void _showUserDetails(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.all(20),
        children: data.entries
            .map(
              (entry) => ListTile(
                title: Text(entry.key),
                subtitle: Text('${entry.value}'),
              ),
            )
            .toList(),
      ),
    );
  }

  void _showMetricsDialog(Map<String, dynamic> data) {
    final activeUsers = TextEditingController(
      text: '${data['activeUsers'] ?? 12842}',
    );
    final latency = TextEditingController(text: '${data['latencyMs'] ?? 12}');
    final pending = TextEditingController(
      text: '${data['pendingWelfare'] ?? 42}',
    );
    final urgent = TextEditingController(
      text: '${data['urgentReviews'] ?? 12}',
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('System metrics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _numberField(activeUsers, 'Active users'),
            const SizedBox(height: 10),
            _numberField(latency, 'Latency ms'),
            const SizedBox(height: 10),
            _numberField(pending, 'Pending welfare'),
            const SizedBox(height: 10),
            _numberField(urgent, 'Urgent reviews'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('system_metrics').doc('overview').set({
                'activeUsers': int.tryParse(activeUsers.text) ?? 0,
                'latencyMs': int.tryParse(latency.text) ?? 0,
                'pendingWelfare': int.tryParse(pending.text) ?? 0,
                'urgentReviews': int.tryParse(urgent.text) ?? 0,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                _snack('Metrics updated.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPartnerDialog({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    final data = doc?.data() ?? {};
    final name = TextEditingController(text: data['name'] ?? '');
    final category = TextEditingController(text: data['category'] ?? 'Finance');
    final description = TextEditingController(text: data['description'] ?? '');
    final badge = TextEditingController(text: data['badge'] ?? 'Verified');
    final cta = TextEditingController(text: data['ctaLabel'] ?? 'Learn More');
    final priority = TextEditingController(text: '${data['priority'] ?? 10}');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(doc == null ? 'Add partner' : 'Edit partner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: badge,
                decoration: const InputDecoration(labelText: 'Badge'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cta,
                decoration: const InputDecoration(labelText: 'CTA label'),
              ),
              const SizedBox(height: 10),
              _numberField(priority, 'Priority'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                'name': name.text.trim(),
                'category': category.text.trim(),
                'description': description.text.trim(),
                'badge': badge.text.trim(),
                'ctaLabel': cta.text.trim(),
                'priority': int.tryParse(priority.text) ?? 10,
                'iconName': data['iconName'] ?? 'bank',
                'colorHex': data['colorHex'] ?? AppTheme.primary.toARGB32(),
                'status': data['status'] ?? 'active',
                'approved': data['approved'] ?? true,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (doc == null) {
                await _db.collection('marketplace_partners').add(payload);
              } else {
                await doc.reference.set(payload, SetOptions(merge: true));
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                _snack('Partner saved.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWelfareDialog() {
    final applicant = TextEditingController();
    final program = TextEditingController(text: 'Financial support review');
    final notes = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add welfare case'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: applicant,
              decoration: const InputDecoration(labelText: 'Applicant name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: program,
              decoration: const InputDecoration(labelText: 'Program'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('welfare_applications').add({
                'applicantName': applicant.text.trim().isEmpty
                    ? 'Applicant'
                    : applicant.text.trim(),
                'program': program.text.trim(),
                'notes': notes.text.trim(),
                'status': 'pending',
                'priority': 'normal',
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                _snack('Welfare case added.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _smallButton(String label, IconData icon, VoidCallback onPressed) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _miniStat(String label, Object value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppTheme.textHint),
          const SizedBox(height: 10),
          Text(text, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.border),
      boxShadow: AppTheme.softShadow,
    );
  }

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Stream4 extends StatelessWidget {
  const _Stream4({
    required this.users,
    required this.posts,
    required this.partners,
    required this.welfare,
    required this.builder,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> users;
  final Stream<QuerySnapshot<Map<String, dynamic>>> posts;
  final Stream<QuerySnapshot<Map<String, dynamic>>> partners;
  final Stream<QuerySnapshot<Map<String, dynamic>>> welfare;
  final Widget Function(
    BuildContext,
    QuerySnapshot<Map<String, dynamic>>,
    QuerySnapshot<Map<String, dynamic>>,
    QuerySnapshot<Map<String, dynamic>>,
    QuerySnapshot<Map<String, dynamic>>,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: users,
      builder: (context, usersSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: posts,
          builder: (context, postsSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: partners,
              builder: (context, partnersSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: welfare,
                  builder: (context, welfareSnapshot) {
                    if (!usersSnapshot.hasData ||
                        !postsSnapshot.hasData ||
                        !partnersSnapshot.hasData ||
                        !welfareSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return builder(
                      context,
                      usersSnapshot.data!,
                      postsSnapshot.data!,
                      partnersSnapshot.data!,
                      welfareSnapshot.data!,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(
    this.label,
    this.value,
    this.subtitle,
    this.icon,
    this.color,
  );

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(trailing),
                visualDensity: VisualDensity.compact,
                backgroundColor: AppTheme.surfaceCard,
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 4, runSpacing: 4, children: actions),
          ],
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_AdminAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 760 ? 3 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: actions
          .map(
            (action) => OutlinedButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.white,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AdminAction {
  const _AdminAction(this.label, this.icon, this.onPressed);

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _AdminTab {
  const _AdminTab(this.label, this.icon);

  final String label;
  final IconData icon;
}
