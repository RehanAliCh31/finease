import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class CommunityForumPage extends StatefulWidget {
  const CommunityForumPage({super.key});

  @override
  State<CommunityForumPage> createState() => _CommunityForumPageState();
}

class _CommunityForumPageState extends State<CommunityForumPage> {
  final List<Map<String, dynamic>> _mockDiscussions = [
    {
      'authorName': 'Sarah Jenkins',
      'title': 'Best high-yield savings accounts in 2024?',
      'content': 'I am currently using a traditional bank but want to switch to a HYSA to beat inflation. Any recommendations?',
      'tag': 'SAVINGS',
      'tagColor': const Color(0xFF29FCF3),
      'likes': '124',
      'comments': '32',
      'timeAgo': '2 hours ago',
      'avatarUrl': 'https://i.pravatar.cc/150?img=5',
    },
    {
      'authorName': 'Marcus Thorne',
      'title': 'How I paid off \$20k in student loans',
      'content': 'Just wanted to share my journey! It took 3 years of aggressive budgeting using the 50/30/20 rule. AMA!',
      'tag': 'LOANS',
      'tagColor': const Color(0xFFDCE9FF),
      'likes': '512',
      'comments': '89',
      'timeAgo': '5 hours ago',
      'avatarUrl': 'https://i.pravatar.cc/150?img=11',
    },
    {
      'authorName': 'Elena Rostova',
      'title': 'Is it the right time to buy an index fund?',
      'content': 'The market seems volatile lately. Should I wait for a dip or just dollar-cost average my way in?',
      'tag': 'INVESTING',
      'tagColor': const Color(0xFFD3E4FE),
      'likes': '89',
      'comments': '45',
      'timeAgo': '1 day ago',
      'avatarUrl': 'https://i.pravatar.cc/150?img=9',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Forum',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with fellow members to share financial wisdom, ask questions, and celebrate milestones together.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            _buildExploreCategories(context),
            const SizedBox(height: 32),
            _buildRecentDiscussions(context),
            const SizedBox(height: 80), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _mockDiscussions.insert(0, {
              'authorName': 'FinEase User (You)',
              'title': 'How to start investing with \$50?',
              'content': 'I am looking for some advice on how to get started with investing small amounts. Any tips?',
              'tag': 'INVESTING',
              'tagColor': const Color(0xFFD3E4FE),
              'likes': '0',
              'comments': '0',
              'timeAgo': 'Just now',
              'avatarUrl': 'https://i.pravatar.cc/150?img=12',
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Discussion posted successfully!')),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Start Discussion',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.background,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppTheme.primary),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu coming soon')));
        },
      ),
      title: Text(
        'FinEase',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 20.0, left: 8.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildExploreCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Explore Categories', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categories coming soon!')));
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View all '),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: [
            _buildCategoryCard(
              context,
              title: 'Savings Tips',
              subtitle: 'Budget hacks and long-term wealth strategies.',
              icon: Icons.savings_outlined,
              iconBgColor: const Color(0xFF29FCF3),
              iconColor: Colors.white,
            ),
            _buildCategoryCard(
              context,
              title: 'Loan Advice',
              subtitle: 'Navigate repayment and interest rates with ease.',
              icon: Icons.description_outlined,
              iconBgColor: const Color(0xFFDCE9FF),
              iconColor: AppTheme.primary,
            ),
            _buildCategoryCard(
              context,
              title: 'Success Stories',
              subtitle: 'Inspiring journeys from debt to financial freedom.',
              icon: Icons.celebration_outlined,
              iconBgColor: const Color(0xFFFFDBCB),
              iconColor: const Color(0xFF773207),
            ),
            _buildCategoryCard(
              context,
              title: 'Investments',
              subtitle: 'Start your journey into stocks and mutual funds.',
              icon: Icons.trending_up,
              iconBgColor: const Color(0xFFD3E4FE),
              iconColor: AppTheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiscussions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent\nDiscussions', style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Trending',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Newest',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Column(
          children: _mockDiscussions.map((data) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildDiscussionPost(
                context,
                authorName: data['authorName'] ?? 'Anonymous',
                timeAgo: data['timeAgo'] ?? 'Just now',
                tag: data['tag'] ?? 'GENERAL',
                tagColor: data['tagColor'] ?? const Color(0xFF29FCF3),
                title: data['title'] ?? 'No Title',
                content: data['content'] ?? '',
                likes: data['likes'] ?? '0',
                comments: data['comments'] ?? '0',
                avatarUrl: data['avatarUrl'] ?? 'https://i.pravatar.cc/150',
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscussionPost(
    BuildContext context, {
    required String authorName,
    required String timeAgo,
    required String tag,
    required Color tagColor,
    Color? tagTextColor,
    required String title,
    required String content,
    required String likes,
    required String comments,
    required String avatarUrl,
    bool showComment = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '• $timeAgo',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tagTextColor ?? const Color(0xFF00504D),
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.thumb_up_outlined, size: 20, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(likes, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(width: 24),
              if (showComment) ...[
                const Icon(Icons.chat_bubble_outline, size: 20, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(comments, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textSecondary)),
              ],
              const Spacer(),
              const Icon(Icons.bookmark_border, size: 20, color: AppTheme.textSecondary),
            ],
          ),
        ],
      ),
    );
  }
}
