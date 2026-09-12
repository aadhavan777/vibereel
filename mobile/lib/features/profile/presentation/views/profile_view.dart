import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../feed/domain/entities/video_entity.dart';
import '../../../feed/presentation/viewmodels/feed_viewmodel.dart';

class ProfileView extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileView({super.key, this.userId});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  bool _isFollowing = false;
  int _followersCount = 12400;

  @override
  Widget build(BuildContext context) {
    const user = MockData.currentUser;
    final isOwnProfile = widget.userId == null || widget.userId == user.id;

    final feedState = ref.watch(feedViewModelProvider);
    final userVideos = feedState.videos;

    // Drafts
    final drafts = [
      const VideoEntity(
        id: 'draft_1',
        creatorId: 'user_001',
        creatorUsername: 'vibemaster',
        caption: 'Draft: Top 5 Flutter animation secrets 🤫 #draft',
        videoUrl: 'https://assets.mixkit.co/videos/preview/mixkit-hands-typing-on-a-laptop-keyboard-4171-large.mp4',
        thumbnailUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600',
        likesCount: 0,
        commentsCount: 0,
        savesCount: 0,
      ),
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('@${user.username}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      onBackgroundImageError: user.avatarUrl != null ? (_, __) {} : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.username.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(user.fullName ?? user.username, style: AppTypography.headingMedium),
                    const SizedBox(height: 4),
                    Text(user.bio ?? '', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _StatItem(label: 'Following', count: '142'),
                        const _StatContainerDivider(),
                        _StatItem(label: 'Followers', count: _formatCount(_followersCount)),
                        const _StatContainerDivider(),
                        const _StatItem(label: 'Likes', count: '98.2K'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: isOwnProfile
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.surfaceVariant,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {},
                                    child: const Text('Edit Profile'),
                                  )
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFollowing ? AppColors.surfaceVariant : AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isFollowing = !_isFollowing;
                                        _followersCount += _isFollowing ? 1 : -1;
                                      });
                                    },
                                    child: Text(_isFollowing ? 'Following' : 'Follow'),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surfaceVariant,
                            ),
                            icon: const Icon(Icons.share_outlined, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SliverToBoxAdapter(
                child: TabBar(
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: [
                    Tab(icon: Icon(Icons.grid_on_rounded), text: 'Videos'),
                    Tab(icon: Icon(Icons.drafts_outlined), text: 'Drafts'),
                    Tab(icon: Icon(Icons.favorite_border_rounded), text: 'Liked'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _VideoGrid(items: userVideos),
              _DraftsGrid(drafts: drafts),
              _VideoGrid(items: userVideos.take(2).toList()),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;

  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(count, style: AppTypography.headingSmall),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _StatContainerDivider extends StatelessWidget {
  const _StatContainerDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.divider,
    );
  }
}

class _VideoGrid extends StatelessWidget {
  final List<VideoEntity> items;

  const _VideoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No videos posted yet', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final video = items[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.surfaceVariant,
              child: video.thumbnailUrl != null
                  ? Image.network(
                      video.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 36),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 36),
                    ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Row(
                children: [
                  const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '${video.likesCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DraftsGrid extends StatelessWidget {
  final List<VideoEntity> drafts;

  const _DraftsGrid({required this.drafts});

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) {
      return const Center(
        child: Text('No saved drafts', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: drafts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final draft = drafts[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.drafts_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.caption ?? 'Draft Reel',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    const Text('Saved as draft', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Draft published successfully!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                child: const Text('Publish', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}
