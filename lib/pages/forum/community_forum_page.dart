import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/forum_models.dart';
import '../../services/auth_service.dart';
import '../../services/forum_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_config_gate.dart';

const _forumCategories = [
  'All',
  'Budgeting',
  'Savings',
  'Debt',
  'Loans',
  'Income',
  'Welfare',
];

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({super.key});

  @override
  State<CommunityForumPage> createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage> {
  String _category = 'All';
  String _sortBy = 'createdAt';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return AppFeatureGate(
      enabled: (config) => config.forumEnabled,
      blockedTitle: 'Community forum is paused',
      blockedMessage: 'Forum access is temporarily paused by admin.',
      blockedIcon: Icons.forum_outlined,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundFor(context),
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              _ForumHeader(
                sortBy: _sortBy,
                onSortChanged: (value) => setState(() => _sortBy = value),
                onNewPost: () => _showPostSheet(context, auth),
              ),
              const SizedBox(height: 14),
              _CategoryChips(
                selected: _category,
                onSelected: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<ForumPost>>(
                stream: ForumService.instance.watchPosts(
                  category: _category,
                  sortBy: _sortBy,
                  limit: 60,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final posts = snapshot.data ?? const <ForumPost>[];
                  if (posts.isEmpty) {
                    return _EmptyForum(
                      onPost: () => _showPostSheet(context, auth),
                    );
                  }
                  return Column(
                    children: posts
                        .map(
                          (post) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PostCard(
                              post: post,
                              userId: auth.user?.uid ?? '',
                              onOpen: () =>
                                  _showPostDetail(context, post, auth),
                              onReact: () => _toggleHelpful(post, auth),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: ElevatedButton.icon(
            onPressed: () => _showPostSheet(context, auth),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Ask community'),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleHelpful(ForumPost post, AuthService auth) async {
    final userId = auth.user?.uid ?? '';
    if (userId.isEmpty) {
      _showSnack(context, 'Sign in to react.', isError: true);
      return;
    }
    await ForumService.instance.togglePostReaction(
      postId: post.id,
      userId: userId,
      reactionType: ReactionType.helpful,
    );
  }

  void _showPostDetail(BuildContext context, ForumPost post, AuthService auth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostDetailSheet(post: post, auth: auth),
    );
  }

  void _showPostSheet(BuildContext context, AuthService auth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(auth: auth),
    );
  }
}

class _ForumHeader extends StatelessWidget {
  const _ForumHeader({
    required this.sortBy,
    required this.onSortChanged,
    required this.onNewPost,
  });

  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onNewPost;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forum',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Ask, answer, and learn from finance stories',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          initialValue: sortBy,
          onSelected: onSortChanged,
          icon: const Icon(Icons.sort_rounded),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'createdAt', child: Text('Newest')),
            PopupMenuItem(value: 'hotScore', child: Text('Hot')),
            PopupMenuItem(value: 'engagementScore', child: Text('Helpful')),
          ],
        ),
        IconButton.filled(
          onPressed: onNewPost,
          icon: const Icon(Icons.add_rounded),
          tooltip: 'New post',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryFor(context),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _forumCategories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.userId,
    required this.onOpen,
    required this.onReact,
  });

  final ForumPost post;
  final String userId;
  final VoidCallback onOpen;
  final VoidCallback onReact;

  @override
  Widget build(BuildContext context) {
    final reacted = post.userReaction(userId) == ReactionType.helpful;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceFor(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderFor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PostTypeIcon(type: post.postType),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.category,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondaryFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _relativeTime(post.createdAt),
                  style: GoogleFonts.inter(
                    color: AppTheme.textHintFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimaryFor(context),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondaryFor(context),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.displayAuthorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppTheme.textHintFor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onReact,
                  icon: Icon(
                    reacted
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text('${post.reactionCount(ReactionType.helpful)}'),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppTheme.textSecondaryFor(context),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentsCount}',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailSheet extends StatefulWidget {
  const _PostDetailSheet({required this.post, required this.auth});

  final ForumPost post;
  final AuthService auth;

  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  final _commentController = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _commentController.dispose();
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
            widget.post.title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.post.content,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Replies',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<ForumComment>>(
            stream: ForumService.instance.watchComments(widget.post.id),
            builder: (context, snapshot) {
              final comments = snapshot.data ?? const <ForumComment>[];
              if (comments.isEmpty) {
                return Text(
                  'No replies yet.',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                  ),
                );
              }
              return Column(
                children: comments
                    .where((comment) => !comment.isReply)
                    .take(8)
                    .map((comment) => _CommentTile(comment: comment))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Write a helpful reply',
              prefixIcon: Icon(Icons.reply_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _posting ? null : _postComment,
              icon: _posting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_posting ? 'Posting...' : 'Reply'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    final user = widget.auth.user;
    final content = _commentController.text.trim();
    if (user == null) {
      _showSnack(context, 'Sign in to reply.', isError: true);
      return;
    }
    if (content.length < 3) {
      _showSnack(context, 'Reply is too short.', isError: true);
      return;
    }
    setState(() => _posting = true);
    try {
      await ForumService.instance.createComment(
        postId: widget.post.id,
        authorId: user.uid,
        authorName: user.displayName ?? user.email ?? 'FinEase User',
        authorAvatar: '',
        content: content,
      );
      _commentController.clear();
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({required this.auth});

  final AuthService auth;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'Budgeting';
  PostType _type = PostType.question;
  bool _anonymous = false;
  bool _posting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
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
            'Ask community',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'What do you need help with?',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            items: _forumCategories
                .where((category) => category != 'All')
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PostType>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Post type',
              prefixIcon: Icon(Icons.forum_rounded),
            ),
            items: PostType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _anonymous,
            activeThumbColor: AppTheme.primaryFor(context),
            title: const Text('Post anonymously'),
            onChanged: (value) => setState(() => _anonymous = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _posting ? null : _createPost,
              icon: _posting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(_posting ? 'Posting...' : 'Post'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost() async {
    final user = widget.auth.user;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (user == null) {
      _showSnack(context, 'Sign in to post.', isError: true);
      return;
    }
    if (title.length < 4 || body.length < 8) {
      _showSnack(context, 'Add a clearer title and details.', isError: true);
      return;
    }
    setState(() => _posting = true);
    try {
      await ForumService.instance.createPost(
        authorId: user.uid,
        authorName: user.displayName ?? user.email ?? 'FinEase User',
        authorAvatar: '',
        title: title,
        content: body,
        category: _category,
        postType: _type,
        tags: [_category],
        isAnonymous: _anonymous,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final ForumComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCardFor(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (comment.isBestAnswer)
                const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.success,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.content,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTypeIcon extends StatelessWidget {
  const _PostTypeIcon({required this.type});

  final PostType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(type.icon, color: type.color, size: 18),
    );
  }
}

class _EmptyForum extends StatelessWidget {
  const _EmptyForum({required this.onPost});

  final VoidCallback onPost;

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
          Icon(
            Icons.forum_outlined,
            color: AppTheme.primaryFor(context),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            'No posts here yet',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start a practical finance discussion.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onPost,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Create post'),
          ),
        ],
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

String _relativeTime(DateTime? date) {
  if (date == null) return 'Now';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

void _showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ),
  );
}
