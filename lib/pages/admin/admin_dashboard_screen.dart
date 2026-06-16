import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_constants.dart';
import '../../models/app_config.dart';
import '../../services/app_config_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _tabs = [
    _AdminTab('Overview', Icons.dashboard_rounded),
    _AdminTab('Users', Icons.people_alt_rounded),
    _AdminTab('Review', Icons.fact_check_rounded),
    _AdminTab('Partners', Icons.handshake_rounded),
    _AdminTab('App', Icons.tune_rounded),
  ];

  final _db = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  final _configService = AppConfigService();

  int _tabIndex = 0;
  String _search = '';
  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundFor(context),
      body: SafeArea(
        child: Column(
          children: [
            _AdminHeader(
              tabs: _tabs,
              selectedIndex: _tabIndex,
              busy: _busy,
              onSelected: (index) => setState(() => _tabIndex = index),
              onCopyReport: _copyReport,
              onSignOut: () => context.read<AuthService>().signOut(),
            ),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tabIndex) {
      case 1:
        return _usersTab();
      case 2:
        return _reviewTab();
      case 3:
        return _partnersTab();
      case 4:
        return _appTab();
      default:
        return _overviewTab();
    }
  }

  Widget _overviewTab() {
    return _AdminDataBuilder(
      db: _db,
      builder: (context, data) {
        final stats = _AdminStats.from(data);
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            _HeroStatus(stats: stats),
            const SizedBox(height: 14),
            _MetricGrid(stats: stats),
            const SizedBox(height: 22),
            _SectionTitle(
              title: 'Needs review',
              trailing: '${stats.reviewLoad}',
            ),
            const SizedBox(height: 12),
            if (stats.reviewLoad == 0)
              const _EmptyPanel(
                icon: Icons.verified_rounded,
                title: 'No urgent queue',
                message:
                    'Flagged posts, pending welfare, and partner reviews are clear.',
              )
            else ...[
              if (stats.flaggedPosts > 0)
                _QueueCard(
                  icon: Icons.flag_rounded,
                  title: 'Flagged forum posts',
                  count: stats.flaggedPosts,
                  color: AppTheme.warning,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
              if (stats.pendingCases > 0)
                _QueueCard(
                  icon: Icons.volunteer_activism_rounded,
                  title: 'Pending welfare cases',
                  count: stats.pendingCases,
                  color: AppTheme.error,
                  onTap: () => setState(() => _tabIndex = 2),
                ),
              if (stats.unapprovedPartners > 0)
                _QueueCard(
                  icon: Icons.handshake_rounded,
                  title: 'Partner approvals',
                  count: stats.unapprovedPartners,
                  color: AppTheme.primary,
                  onTap: () => setState(() => _tabIndex = 3),
                ),
            ],
            const SizedBox(height: 22),
            _SectionTitle(title: 'Recent activity', trailing: 'Audit'),
            const SizedBox(height: 12),
            _AuditList(db: _db),
          ],
        );
      },
    );
  }

  Widget _usersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        final users = docs.where(_matchesSearch).toList()
          ..sort(
            (a, b) =>
                _text(a.data(), 'email').compareTo(_text(b.data(), 'email')),
          );
        return _AdminListShell(
          title: 'Users',
          subtitle: '${users.length} accounts',
          searchController: _searchController,
          search: _search,
          onSearch: (value) => setState(() => _search = value),
          children: [
            if (users.isEmpty)
              const _EmptyPanel(
                icon: Icons.people_outline_rounded,
                title: 'No users found',
                message: 'Try another search.',
              )
            else
              ...users.map(
                (doc) => _UserCard(doc: doc, onAction: _setUserState),
              ),
          ],
        );
      },
    );
  }

  Widget _reviewTab() {
    return _AdminDataBuilder(
      db: _db,
      builder: (context, data) {
        final posts = data.posts.where((doc) {
          final status = _text(doc.data(), 'moderationStatus', 'visible');
          return status == 'flagged' || status == 'visible';
        }).toList();
        final welfare = data.welfare.where((doc) {
          final status = _text(doc.data(), 'status', 'pending');
          return status == 'pending' || status == 'urgent';
        }).toList();
        return _AdminListShell(
          title: 'Review',
          subtitle: '${posts.length + welfare.length} open items',
          searchController: _searchController,
          search: _search,
          onSearch: (value) => setState(() => _search = value),
          children: [
            _SectionTitle(
              title: 'Forum moderation',
              trailing: '${posts.length}',
            ),
            const SizedBox(height: 10),
            if (posts.isEmpty)
              const _MiniEmpty(message: 'No forum posts need review.')
            else
              ...posts
                  .where(_matchesSearch)
                  .map(
                    (doc) => _ReviewCard(
                      icon: Icons.forum_rounded,
                      title: _text(doc.data(), 'title', 'Discussion'),
                      subtitle: _text(doc.data(), 'content', 'No content'),
                      status: _text(doc.data(), 'moderationStatus', 'visible'),
                      actions: [
                        _CardAction(
                          'Visible',
                          Icons.visibility_rounded,
                          () => _setPostStatus(doc.id, 'visible'),
                        ),
                        _CardAction(
                          'Flag',
                          Icons.flag_rounded,
                          () => _setPostStatus(doc.id, 'flagged'),
                        ),
                        _CardAction(
                          'Remove',
                          Icons.visibility_off_rounded,
                          () => _setPostStatus(doc.id, 'removed'),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Welfare cases',
              trailing: '${welfare.length}',
            ),
            const SizedBox(height: 10),
            if (welfare.isEmpty)
              const _MiniEmpty(message: 'No welfare cases need review.')
            else
              ...welfare
                  .where(_matchesSearch)
                  .map(
                    (doc) => _ReviewCard(
                      icon: Icons.volunteer_activism_rounded,
                      title: _text(doc.data(), 'applicantName', 'Applicant'),
                      subtitle: _text(
                        doc.data(),
                        'programName',
                        'Welfare application',
                      ),
                      status: _text(doc.data(), 'status', 'pending'),
                      actions: [
                        _CardAction(
                          'Approve',
                          Icons.check_circle_rounded,
                          () => _setWelfareStatus(doc.id, 'approved'),
                        ),
                        _CardAction(
                          'Reject',
                          Icons.cancel_rounded,
                          () => _setWelfareStatus(doc.id, 'rejected'),
                        ),
                        _CardAction(
                          'Resolve',
                          Icons.done_all_rounded,
                          () => _setWelfareStatus(doc.id, 'resolved'),
                        ),
                      ],
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _partnersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('marketplace_partners').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final partners =
            (snapshot.data?.docs ?? []).where(_matchesSearch).toList()
              ..sort((a, b) {
                final pa = _num(a.data()['priority'], 99);
                final pb = _num(b.data()['priority'], 99);
                return pa.compareTo(pb);
              });
        return _AdminListShell(
          title: 'Partners',
          subtitle: '${partners.length} marketplace records',
          searchController: _searchController,
          search: _search,
          onSearch: (value) => setState(() => _search = value),
          trailing: IconButton.filled(
            onPressed: () => _showPartnerSheet(),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add partner',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryFor(context),
              foregroundColor: Colors.white,
            ),
          ),
          children: [
            if (partners.isEmpty)
              const _EmptyPanel(
                icon: Icons.handshake_outlined,
                title: 'No partners found',
                message: 'Add a partner or adjust search.',
              )
            else
              ...partners.map(
                (doc) => _PartnerAdminCard(
                  doc: doc,
                  onApprove: () =>
                      _setPartnerState(doc, approved: true, status: 'active'),
                  onHide: () =>
                      _setPartnerState(doc, approved: false, status: 'hidden'),
                  onEdit: () => _showPartnerSheet(doc: doc),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _appTab() {
    return StreamBuilder<AppConfig>(
      stream: _configService.watchConfig(),
      initialData: AppConfig.defaults(),
      builder: (context, snapshot) {
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            _AppConfigEditor(
              config: snapshot.data ?? AppConfig.defaults(),
              onSave: _saveConfig,
            ),
          ],
        );
      },
    );
  }

  Future<void> _setUserState(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String status,
  ) async {
    final email = _text(doc.data(), 'email');
    if (email == AppConstants.adminEmail) {
      _snack('Primary admin account is protected.', isError: true);
      return;
    }
    await _runAction('User marked $status', () async {
      await doc.reference.set({
        'accountStatus': status,
        'adminUpdatedAt': FieldValue.serverTimestamp(),
        'adminUpdatedBy': AppConstants.adminEmail,
      }, SetOptions(merge: true));
      await _log('user_status_$status', doc.reference.path, {'email': email});
    });
  }

  Future<void> _setPostStatus(String postId, String status) async {
    await _runAction('Post marked $status', () async {
      await _db.collection('forum_posts').doc(postId).set({
        'moderationStatus': status,
        'moderatedAt': FieldValue.serverTimestamp(),
        'moderatedBy': AppConstants.adminEmail,
      }, SetOptions(merge: true));
      await _log('post_status_$status', 'forum_posts/$postId', {});
    });
  }

  Future<void> _setWelfareStatus(String id, String status) async {
    await _runAction('Case marked $status', () async {
      await _db.collection('welfare_applications').doc(id).set({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': AppConstants.adminEmail,
      }, SetOptions(merge: true));
      await _log('welfare_status_$status', 'welfare_applications/$id', {});
    });
  }

  Future<void> _setPartnerState(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool approved,
    required String status,
  }) async {
    await _runAction('Partner updated', () async {
      await doc.reference.set({
        'approved': approved,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': AppConstants.adminEmail,
      }, SetOptions(merge: true));
      await _log('partner_$status', doc.reference.path, {'approved': approved});
    });
  }

  Future<void> _saveConfig(AppConfig config) async {
    await _runAction('App controls saved', () async {
      await _configService.saveConfig(config);
      await _log('app_config_updated', 'app_config/global', {
        'maintenanceMode': config.maintenanceMode,
        'announcementEnabled': config.announcementEnabled,
        'marketplaceEnabled': config.marketplaceEnabled,
        'forumEnabled': config.forumEnabled,
        'welfareEnabled': config.welfareEnabled,
      });
    });
  }

  Future<void> _copyReport() async {
    final users = await _db.collection('users').get();
    final posts = await _db.collection('forum_posts').get();
    final partners = await _db.collection('marketplace_partners').get();
    final welfare = await _db.collection('welfare_applications').get();
    final stats = _AdminStats.from(
      _AdminData(
        users: users.docs,
        posts: posts.docs,
        partners: partners.docs,
        welfare: welfare.docs,
      ),
    );
    final report = StringBuffer()
      ..writeln('FinEase Admin Report')
      ..writeln('Generated,${DateTime.now().toIso8601String()}')
      ..writeln('Users,${stats.users}')
      ..writeln('Suspended Users,${stats.suspendedUsers}')
      ..writeln('Forum Posts,${stats.forumPosts}')
      ..writeln('Flagged Posts,${stats.flaggedPosts}')
      ..writeln('Partners,${stats.partners}')
      ..writeln('Unapproved Partners,${stats.unapprovedPartners}')
      ..writeln('Welfare Cases,${stats.welfareCases}')
      ..writeln('Pending Welfare,${stats.pendingCases}');
    await Clipboard.setData(ClipboardData(text: report.toString()));
    _snack('Admin report copied');
  }

  void _showPartnerSheet({QueryDocumentSnapshot<Map<String, dynamic>>? doc}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PartnerEditorSheet(
        doc: doc,
        onSave: (data) async {
          await _runAction('Partner saved', () async {
            if (doc == null) {
              final ref = await _db.collection('marketplace_partners').add({
                ...data,
                'createdAt': FieldValue.serverTimestamp(),
              });
              await _log('partner_created', ref.path, {'name': data['name']});
            } else {
              await doc.reference.set({
                ...data,
                'updatedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              await _log('partner_updated', doc.reference.path, {
                'name': data['name'],
              });
            }
          });
        },
      ),
    );
  }

  Future<void> _runAction(
    String success,
    Future<void> Function() action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _snack(success);
    } catch (error) {
      if (!mounted) return;
      _snack('Admin action failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _log(
    String action,
    String target,
    Map<String, dynamic> details,
  ) {
    return _db.collection('admin_audit_logs').add({
      'action': action,
      'target': target,
      'details': details,
      'adminEmail': AppConstants.adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  bool _matchesSearch(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return true;
    final data = doc.data();
    final haystack = [
      doc.id,
      _text(data, 'email'),
      _text(data, 'fullName'),
      _text(data, 'role'),
      _text(data, 'title'),
      _text(data, 'content'),
      _text(data, 'name'),
      _text(data, 'category'),
      _text(data, 'applicantName'),
      _text(data, 'programName'),
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.tabs,
    required this.selectedIndex,
    required this.busy,
    required this.onSelected,
    required this.onCopyReport,
    required this.onSignOut,
  });

  final List<_AdminTab> tabs;
  final int selectedIndex;
  final bool busy;
  final ValueChanged<int> onSelected;
  final VoidCallback onCopyReport;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        border: Border(bottom: BorderSide(color: AppTheme.borderFor(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      AppConstants.adminEmail,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondaryFor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: busy ? null : onCopyReport,
                icon: const Icon(Icons.file_copy_rounded),
                tooltip: 'Copy report',
              ),
              IconButton(
                onPressed: busy ? null : onSignOut,
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign out',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (index) {
                final selected = index == selectedIndex;
                final tab = tabs[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    avatar: Icon(tab.icon, size: 17),
                    label: Text(tab.label),
                    onSelected: (_) => onSelected(index),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminListShell extends StatelessWidget {
  const _AdminListShell({
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.search,
    required this.onSearch,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearch;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        Row(
          children: [
            Expanded(
              child: _SectionTitle(title: title, trailing: subtitle),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          onChanged: onSearch,
          decoration: const InputDecoration(
            labelText: 'Search',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.stats});

  final _AdminStats stats;

  @override
  Widget build(BuildContext context) {
    final healthy = stats.reviewLoad == 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusPill(
            label: healthy ? 'Stable' : 'Needs review',
            color: healthy ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(height: 12),
          Text(
            healthy
                ? 'Operations are clear.'
                : '${stats.reviewLoad} items need action.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Users, moderation, marketplace partners, welfare cases, and app switches are controlled here.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});

  final _AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _MetricTile(
          'Users',
          '${stats.users}',
          Icons.people_rounded,
          AppTheme.primary,
        ),
        _MetricTile(
          'Suspended',
          '${stats.suspendedUsers}',
          Icons.block_rounded,
          AppTheme.error,
        ),
        _MetricTile(
          'Forum',
          '${stats.forumPosts}',
          Icons.forum_rounded,
          AppTheme.warning,
        ),
        _MetricTile(
          'Partners',
          '${stats.activePartners}/${stats.partners}',
          Icons.handshake_rounded,
          AppTheme.success,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
          Icon(icon, color: color),
          const Spacer(),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.doc, required this.onAction});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<void> Function(
    QueryDocumentSnapshot<Map<String, dynamic>>,
    String,
  )
  onAction;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final email = _text(data, 'email', 'No email');
    final name = _text(data, 'fullName', email);
    final status = _text(data, 'accountStatus', 'active');
    final role = _text(data, 'role', 'user');
    final protected = email == AppConstants.adminEmail;
    return _AdminCard(
      icon: protected
          ? Icons.admin_panel_settings_rounded
          : Icons.person_rounded,
      title: name,
      subtitle: email,
      status: protected ? 'protected' : status,
      statusColor: protected ? AppTheme.primary : _statusColor(status),
      meta: [
        'Role: $role',
        data['emailVerified'] == true ? 'Verified' : 'Unverified',
      ],
      actions: [
        if (!protected)
          _CardAction(
            status == 'suspended' ? 'Activate' : 'Suspend',
            status == 'suspended'
                ? Icons.check_circle_rounded
                : Icons.block_rounded,
            () => onAction(doc, status == 'suspended' ? 'active' : 'suspended'),
          ),
        _CardAction(
          'Copy',
          Icons.copy_rounded,
          () => Clipboard.setData(ClipboardData(text: email)),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final List<_CardAction> actions;

  @override
  Widget build(BuildContext context) {
    return _AdminCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      status: status,
      statusColor: _statusColor(status),
      meta: const [],
      actions: actions,
    );
  }
}

class _PartnerAdminCard extends StatelessWidget {
  const _PartnerAdminCard({
    required this.doc,
    required this.onApprove,
    required this.onHide,
    required this.onEdit,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onApprove;
  final VoidCallback onHide;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final approved = data['approved'] as bool? ?? true;
    final status = _text(data, 'status', approved ? 'active' : 'review');
    return _AdminCard(
      icon: Icons.handshake_rounded,
      title: _text(data, 'name', 'Partner'),
      subtitle: _text(data, 'description', 'No description'),
      status: approved ? status : 'unapproved',
      statusColor: approved ? _statusColor(status) : AppTheme.warning,
      meta: [
        _text(data, 'category', 'General'),
        'Priority ${_num(data['priority'], 99).toStringAsFixed(0)}',
      ],
      actions: [
        _CardAction('Approve', Icons.check_circle_rounded, onApprove),
        _CardAction('Hide', Icons.visibility_off_rounded, onHide),
        _CardAction('Edit', Icons.edit_rounded, onEdit),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.meta,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final List<String> meta;
  final List<_CardAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryFor(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimaryFor(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
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
              _StatusPill(label: status, color: statusColor),
            ],
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meta.map((item) => _InfoChip(label: item)).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions
                .map(
                  (action) => OutlinedButton.icon(
                    onPressed: action.onTap,
                    icon: Icon(action.icon, size: 17),
                    label: Text(action.label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AppConfigEditor extends StatefulWidget {
  const _AppConfigEditor({required this.config, required this.onSave});

  final AppConfig config;
  final ValueChanged<AppConfig> onSave;

  @override
  State<_AppConfigEditor> createState() => _AppConfigEditorState();
}

class _AppConfigEditorState extends State<_AppConfigEditor> {
  late bool _maintenance;
  late bool _announcement;
  late bool _marketplace;
  late bool _forum;
  late bool _posting;
  late bool _comments;
  late bool _welfare;
  late bool _chatbot;
  late bool _budgetAi;
  late final TextEditingController _brand;
  late final TextEditingController _support;
  late final TextEditingController _announcementTitle;
  late final TextEditingController _announcementMessage;

  @override
  void initState() {
    super.initState();
    _brand = TextEditingController();
    _support = TextEditingController();
    _announcementTitle = TextEditingController();
    _announcementMessage = TextEditingController();
    _apply(widget.config);
  }

  @override
  void didUpdateWidget(covariant _AppConfigEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.updatedAt != widget.config.updatedAt) {
      _apply(widget.config);
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    _support.dispose();
    _announcementTitle.dispose();
    _announcementMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ConfigPanel(
          title: 'Feature switches',
          children: [
            _SwitchRow(
              'Maintenance',
              Icons.construction_rounded,
              _maintenance,
              (value) => setState(() => _maintenance = value),
              danger: true,
            ),
            _SwitchRow(
              'Marketplace',
              Icons.storefront_rounded,
              _marketplace,
              (value) => setState(() => _marketplace = value),
            ),
            _SwitchRow(
              'Forum',
              Icons.forum_rounded,
              _forum,
              (value) => setState(() => _forum = value),
            ),
            _SwitchRow(
              'Posting',
              Icons.edit_rounded,
              _posting,
              (value) => setState(() => _posting = value),
            ),
            _SwitchRow(
              'Comments',
              Icons.chat_rounded,
              _comments,
              (value) => setState(() => _comments = value),
            ),
            _SwitchRow(
              'Welfare',
              Icons.volunteer_activism_rounded,
              _welfare,
              (value) => setState(() => _welfare = value),
            ),
            _SwitchRow(
              'Chatbot',
              Icons.smart_toy_rounded,
              _chatbot,
              (value) => setState(() => _chatbot = value),
            ),
            _SwitchRow(
              'Budget AI',
              Icons.auto_awesome_rounded,
              _budgetAi,
              (value) => setState(() => _budgetAi = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ConfigPanel(
          title: 'Live copy',
          children: [
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _support,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Support message'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _announcementTitle,
              decoration: const InputDecoration(
                labelText: 'Announcement title',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _announcementMessage,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Announcement message',
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _announcement,
              activeThumbColor: AppTheme.primaryFor(context),
              title: const Text('Show announcement'),
              onChanged: (value) => setState(() => _announcement = value),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save app controls'),
          ),
        ),
      ],
    );
  }

  void _apply(AppConfig config) {
    _maintenance = config.maintenanceMode;
    _announcement = config.announcementEnabled;
    _marketplace = config.marketplaceEnabled;
    _forum = config.forumEnabled;
    _posting = config.forumPostingEnabled;
    _comments = config.forumCommentsEnabled;
    _welfare = config.welfareEnabled;
    _chatbot = config.chatbotEnabled;
    _budgetAi = config.budgetAiEnabled;
    _brand.text = config.brandName;
    _support.text = config.supportMessage;
    _announcementTitle.text = config.announcementTitle;
    _announcementMessage.text = config.announcementMessage;
  }

  void _save() {
    widget.onSave(
      widget.config.copyWith(
        maintenanceMode: _maintenance,
        announcementEnabled: _announcement,
        marketplaceEnabled: _marketplace,
        forumEnabled: _forum,
        forumPostingEnabled: _posting,
        forumCommentsEnabled: _comments,
        welfareEnabled: _welfare,
        chatbotEnabled: _chatbot,
        budgetAiEnabled: _budgetAi,
        brandName: _brand.text.trim(),
        supportMessage: _support.text.trim(),
        announcementTitle: _announcementTitle.text.trim(),
        announcementMessage: _announcementMessage.text.trim(),
      ),
    );
  }
}

class _PartnerEditorSheet extends StatefulWidget {
  const _PartnerEditorSheet({required this.doc, required this.onSave});

  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<_PartnerEditorSheet> createState() => _PartnerEditorSheetState();
}

class _PartnerEditorSheetState extends State<_PartnerEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _priority;
  bool _approved = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data() ?? const <String, dynamic>{};
    _name = TextEditingController(text: _text(data, 'name'));
    _category = TextEditingController(text: _text(data, 'category', 'Loans'));
    _description = TextEditingController(text: _text(data, 'description'));
    _priority = TextEditingController(
      text: '${_num(data['priority'], 20).round()}',
    );
    _approved = data['approved'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _priority.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          Text(
            widget.doc == null ? 'Add partner' : 'Edit partner',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priority,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Priority'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _approved,
            activeThumbColor: AppTheme.primaryFor(context),
            title: const Text('Approved and visible'),
            onChanged: (value) => setState(() => _approved = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save partner'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave({
      'name': _name.text.trim(),
      'category': _category.text.trim().isEmpty
          ? 'General'
          : _category.text.trim(),
      'description': _description.text.trim(),
      'priority': int.tryParse(_priority.text.trim()) ?? 20,
      'approved': _approved,
      'status': _approved ? 'active' : 'review',
      'badge': _approved ? 'Verified' : 'Review',
      'ctaLabel': 'View details',
      'colorHex': 0xFF2E3192,
      'iconName': 'storefront',
    });
    if (mounted) Navigator.pop(context);
  }
}

class _ConfigPanel extends StatelessWidget {
  const _ConfigPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(
    this.title,
    this.icon,
    this.value,
    this.onChanged, {
    this.danger = false,
  });

  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        icon,
        color: danger ? AppTheme.error : AppTheme.primaryFor(context),
      ),
      title: Text(title),
      value: value,
      activeThumbColor: danger ? AppTheme.error : AppTheme.primaryFor(context),
      onChanged: onChanged,
    );
  }
}

class _AuditList extends StatelessWidget {
  const _AuditList({required this.db});

  final FirebaseFirestore db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db
          .collection('admin_audit_logs')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const _MiniEmpty(message: 'Admin actions will appear here.');
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            return _AdminCard(
              icon: Icons.history_rounded,
              title: _text(data, 'action', 'Admin action'),
              subtitle: _text(data, 'target', 'No target'),
              status: 'audit',
              statusColor: AppTheme.primary,
              meta: [_formatTimestamp(data['createdAt'])],
              actions: const [],
            );
          }).toList(),
        );
      },
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderFor(context)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimaryFor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
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

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryFor(context), size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppTheme.textSecondaryFor(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
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
      child: SafeArea(top: false, child: SingleChildScrollView(child: child)),
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

class _AdminDataBuilder extends StatelessWidget {
  const _AdminDataBuilder({required this.db, required this.builder});

  final FirebaseFirestore db;
  final Widget Function(BuildContext context, _AdminData data) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').snapshots(),
      builder: (context, users) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('forum_posts').snapshots(),
          builder: (context, posts) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db.collection('marketplace_partners').snapshots(),
              builder: (context, partners) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: db.collection('welfare_applications').snapshots(),
                  builder: (context, welfare) {
                    if (!users.hasData ||
                        !posts.hasData ||
                        !partners.hasData ||
                        !welfare.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return builder(
                      context,
                      _AdminData(
                        users: users.data!.docs,
                        posts: posts.data!.docs,
                        partners: partners.data!.docs,
                        welfare: welfare.data!.docs,
                      ),
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

class _AdminData {
  const _AdminData({
    required this.users,
    required this.posts,
    required this.partners,
    required this.welfare,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> users;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> posts;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> partners;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> welfare;
}

class _AdminStats {
  const _AdminStats({
    required this.users,
    required this.suspendedUsers,
    required this.forumPosts,
    required this.flaggedPosts,
    required this.partners,
    required this.activePartners,
    required this.unapprovedPartners,
    required this.welfareCases,
    required this.pendingCases,
  });

  final int users;
  final int suspendedUsers;
  final int forumPosts;
  final int flaggedPosts;
  final int partners;
  final int activePartners;
  final int unapprovedPartners;
  final int welfareCases;
  final int pendingCases;

  int get reviewLoad => flaggedPosts + unapprovedPartners + pendingCases;

  factory _AdminStats.from(_AdminData data) {
    final suspended = data.users
        .where(
          (doc) => _text(doc.data(), 'accountStatus', 'active') == 'suspended',
        )
        .length;
    final flagged = data.posts
        .where(
          (doc) =>
              _text(doc.data(), 'moderationStatus', 'visible') == 'flagged',
        )
        .length;
    final activePartners = data.partners
        .where(
          (doc) =>
              (_text(doc.data(), 'status', 'active') == 'active') &&
              (doc.data()['approved'] as bool? ?? true),
        )
        .length;
    final unapproved = data.partners
        .where((doc) => (doc.data()['approved'] as bool? ?? true) != true)
        .length;
    final pending = data.welfare
        .where((doc) => _text(doc.data(), 'status', 'pending') == 'pending')
        .length;
    return _AdminStats(
      users: data.users.length,
      suspendedUsers: suspended,
      forumPosts: data.posts.length,
      flaggedPosts: flagged,
      partners: data.partners.length,
      activePartners: activePartners,
      unapprovedPartners: unapproved,
      welfareCases: data.welfare.length,
      pendingCases: pending,
    );
  }
}

class _CardAction {
  const _CardAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _AdminTab {
  const _AdminTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

String _text(Map<String, dynamic> data, String key, [String fallback = '']) {
  final value = data[key];
  if (value == null) return fallback;
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}

double _num(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'active':
    case 'visible':
    case 'approved':
    case 'resolved':
      return AppTheme.success;
    case 'pending':
    case 'flagged':
    case 'review':
    case 'unapproved':
      return AppTheme.warning;
    case 'suspended':
    case 'removed':
    case 'rejected':
    case 'hidden':
      return AppTheme.error;
    default:
      return AppTheme.primary;
  }
}

String _formatTimestamp(Object? value) {
  if (value is Timestamp) {
    return DateFormat('MMM d, h:mm a').format(value.toDate());
  }
  return 'No date';
}
