import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../viewmodels/forum_viewmodel.dart';
import 'forum_post_details_view.dart';
import 'forum_post_form_view.dart';

class ForumView extends ConsumerStatefulWidget {
  const ForumView({super.key});

  @override
  ConsumerState<ForumView> createState() => _ForumViewState();
}

class _ForumViewState extends ConsumerState<ForumView> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': '🔥'},
    {'name': '🎬 Video Editing', 'key': 'video_editing'},
    {'name': '💡 Content Ideas', 'key': 'content_ideas'},
    {'name': '📈 Growth & Analytics', 'key': 'growth_analytics'},
    {'name': '🤝 Collaboration', 'key': 'collaboration'},
    {'name': '🎵 Music & Audio', 'key': 'music_audio'},
    {'name': '🎨 Design', 'key': 'design'},
    {'name': '💻 Technology', 'key': 'technology'},
    {'name': '💰 Monetization', 'key': 'monetization'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreatePostModal(BuildContext context) {
    final notifier = ref.read(forumViewModelProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ForumPostFormView(
        onSubmit: (title, content, category, tags) {
          notifier.createPost(title, content, category, tags);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumViewModelProvider);
    final notifier = ref.read(forumViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () => _showCreatePostModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _showCreatePostModal(context),
      ),
      body: Column(
        children: [
          // Search & Sort Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search discussions, ideas, equipment...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onSubmitted: (query) => notifier.setSearchQuery(query),
                ),
                const SizedBox(height: 10),

                // Sort By Tabs (Latest vs Trending)
                Row(
                  children: [
                    const Text('Sort by:', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Latest'),
                      selected: state.sortBy == 'latest',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: state.sortBy == 'latest' ? Colors.white : AppColors.textMuted,
                      ),
                      onSelected: (_) => notifier.setSortBy('latest'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('🔥 Trending'),
                      selected: state.sortBy == 'trending',
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        color: state.sortBy == 'trending' ? Colors.white : AppColors.textMuted,
                      ),
                      onSelected: (_) => notifier.setSortBy('trending'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Horizontal Categories Filter Chips Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((catMap) {
                  final catName = catMap['name']!;
                  final isSelected = state.selectedCategory == catName ||
                      (state.selectedCategory.toLowerCase() == (catMap['key'] ?? '').toLowerCase());

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(catName),
                      selected: isSelected,
                      onSelected: (_) => notifier.selectCategory(catName),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Post Feed List
          Expanded(
            child: _buildFeedBody(context, state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBody(BuildContext context, ForumState state, ForumViewModel notifier) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Failed to load discussions', style: AppTypography.headingSmall.copyWith(color: Colors.white)),
              const SizedBox(height: 8),
              Text(state.error!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                onPressed: () => notifier.fetchPosts(),
              ),
            ],
          ),
        ),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('No community posts found', style: AppTypography.headingSmall),
            const SizedBox(height: 8),
            const Text('Be the first to start a conversation in this topic!', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showCreatePostModal(context),
              child: const Text('Create Discussion'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => notifier.fetchPosts(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: state.posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = state.posts[index];
          return _ForumPostCard(
            post: post,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForumPostDetailsView(post: post),
                ),
              );
            },
            onLikeToggle: () => notifier.toggleLikePost(post.id),
          );
        },
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  final ForumPostEntity post;
  final VoidCallback onTap;
  final VoidCallback onLikeToggle;

  const _ForumPostCard({
    required this.post,
    required this.onTap,
    required this.onLikeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileView()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.secondary,
                      backgroundImage: post.authorAvatarUrl != null ? NetworkImage(post.authorAvatarUrl!) : null,
                      child: post.authorAvatarUrl == null
                          ? Text(
                              post.authorUsername.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileView()),
                      );
                    },
                    child: Text('@${post.authorUsername}', style: AppTypography.caption),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.category.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Content Snippet
              Text(post.title, style: AppTypography.headingSmall),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium,
              ),

              if (post.tags != null) ...[
                const SizedBox(height: 8),
                Text(
                  post.tags!.split(',').map((t) => '#${t.trim()}').join(' '),
                  style: const TextStyle(color: AppColors.accent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: AppColors.divider),

              // Footer Actions
              Row(
                children: [
                  InkWell(
                    onTap: onLikeToggle,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: post.isLiked ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text('${post.likesCount}', style: TextStyle(color: post.isLiked ? AppColors.primary : AppColors.textMuted, fontSize: 12, fontWeight: post.isLiked ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount} Replies', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Text('${post.viewsCount} views', style: AppTypography.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

