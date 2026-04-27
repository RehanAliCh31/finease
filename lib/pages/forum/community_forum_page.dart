import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({super.key});
  @override
  State<CommunityForumPage> createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _db = FirebaseFirestore.instance;
  String _selectedCategory = 'All';

  final _categories = ['All', 'Savings', 'Loans', 'Investing', 'Success', 'General'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.background,
            elevation: 0,
            title: Text('Community', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.textPrimary)),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
                onPressed: () {},
              ),
            ],
            bottom: TabBar(
              controller: _tab,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [Tab(text: 'Discussions'), Tab(text: 'Categories')],
            ),
          ),
          SliverToBoxAdapter(
            child: _CategoryFilter(
              categories: _categories,
              selected: _selectedCategory,
              onSelect: (c) => setState(() => _selectedCategory = c),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _PostsList(category: _selectedCategory),
            _CategoriesGrid(onCategoryTap: (c) {
              setState(() => _selectedCategory = c);
              _tab.animateTo(0);
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostSheet(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text('Post', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(db: _db),
    );
  }
}

// ─── Category Filter ────────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryFilter({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final sel = selected == cat;
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
              ),
              child: Text(cat, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.textSecondary)),
            ),
          );
        },
      ),
    );
  }
}

// ─── Posts List ──────────────────────────────────────────────────────────────
class _PostsList extends StatelessWidget {
  final String category;
  const _PostsList({required this.category});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    Query<Map<String, dynamic>> q = db.collection('forum_posts').orderBy('createdAt', descending: true);
    if (category != 'All') q = q.where('category', isEqualTo: category);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forum_outlined, size: 56, color: AppTheme.textHint),
                const SizedBox(height: 12),
                Text('No posts yet. Be the first!', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _PostCard(data: data, docId: docs[i].id);
          },
        );
      },
    );
  }
}

// ─── Post Card ───────────────────────────────────────────────────────────────
class _PostCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  const _PostCard({required this.data, required this.docId});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liked = false;

  static const Map<String, Color> _tagColors = {
    'Savings': Color(0xFF06C270),
    'Loans': Color(0xFF2E3192),
    'Investing': Color(0xFF8B5CF6),
    'Success': Color(0xFFFF6B35),
    'General': Color(0xFF6B7A99),
  };

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final cat = d['category'] ?? 'General';
    final tagColor = _tagColors[cat] ?? AppTheme.primary;
    final likes = (d['likes'] ?? 0) + (_liked ? 1 : 0);
    final comments = d['comments'] ?? 0;
    final avatar = d['authorAvatar'] as String?;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                child: (avatar == null || avatar.isEmpty)
                    ? Text((d['authorName'] ?? 'A')[0].toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primary))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['authorName'] ?? 'Anonymous', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    Text(_timeAgo(d['createdAt']), style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(cat, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: tagColor)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(d['title'] ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(d['content'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Divider(color: AppTheme.border, thickness: 1, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _liked = !_liked),
                child: Row(children: [
                  Icon(_liked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined, size: 18, color: _liked ? AppTheme.primary : AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('$likes', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _liked ? AppTheme.primary : AppTheme.textSecondary)),
                ]),
              ),
              const SizedBox(width: 20),
              Row(children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text('$comments', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              ]),
              const Spacer(),
              const Icon(Icons.share_outlined, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 16),
              const Icon(Icons.bookmark_border_rounded, size: 18, color: AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(dynamic ts) {
    if (ts == null) return 'just now';
    DateTime dt;
    if (ts is Timestamp) dt = ts.toDate();
    else return 'just now';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Categories Grid ─────────────────────────────────────────────────────────
class _CategoriesGrid extends StatelessWidget {
  final ValueChanged<String> onCategoryTap;
  const _CategoriesGrid({required this.onCategoryTap});

  static const _cats = [
    _CatInfo('Savings Tips', Icons.savings_rounded, Color(0xFF06C270), 'Budget hacks & wealth strategies'),
    _CatInfo('Loan Advice', Icons.description_rounded, Color(0xFF2E3192), 'Navigate rates & repayment'),
    _CatInfo('Investing', Icons.trending_up_rounded, Color(0xFF8B5CF6), 'Stocks, ETFs & mutual funds'),
    _CatInfo('Success Stories', Icons.celebration_rounded, Color(0xFFFF6B35), 'Journeys to financial freedom'),
    _CatInfo('General', Icons.chat_rounded, Color(0xFF6B7A99), 'General financial discussions'),
    _CatInfo('Ask an Expert', Icons.contact_support_rounded, Color(0xFF0099CC), 'Get professional advice'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: _cats.map((c) => GestureDetector(
        onTap: () => onCategoryTap(c.name.split(' ').first),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.icon, color: c.color, size: 22),
              ),
              const Spacer(),
              Text(c.name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 4),
              Text(c.subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _CatInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _CatInfo(this.name, this.icon, this.color, this.subtitle);
}

// ─── Create Post Sheet ───────────────────────────────────────────────────────
class _CreatePostSheet extends StatefulWidget {
  final FirebaseFirestore db;
  const _CreatePostSheet({required this.db});
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _category = 'General';
  bool _posting = false;

  final _cats = ['General', 'Savings', 'Loans', 'Investing', 'Success'];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Start a Discussion', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Title — what\'s your topic?'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Share your thoughts, question, or story...'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          Text('Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _cats.map((c) {
              final sel = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Text(c, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _posting ? null : _post,
              child: _posting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.send_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Publish', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                    ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _post() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }
    setState(() => _posting = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    await widget.db.collection('forum_posts').add({
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'category': _category,
      'authorName': user?.displayName ?? 'FinEase User',
      'authorAvatar': user?.photoURL ?? '',
      'authorId': user?.uid ?? '',
      'likes': 0,
      'comments': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      setState(() => _posting = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Discussion posted! ✓'), backgroundColor: AppTheme.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    }
  }
}
