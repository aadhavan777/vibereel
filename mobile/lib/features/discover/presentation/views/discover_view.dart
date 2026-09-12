import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover & Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Trigger Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search_rounded, color: AppColors.textMuted),
                      SizedBox(width: 12),
                      Text(
                        'Search creators, videos, or forum tags...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Trending Hashtags
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Trending Topics', style: AppTypography.headingSmall),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: MockData.trendingHashtags.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tag = MockData.trendingHashtags[index];
                  return Chip(
                    label: Text(tag),
                    backgroundColor: AppColors.surfaceVariant,
                    side: BorderSide.none,
                    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Featured Creators
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Featured Creators', style: AppTypography.headingSmall),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: MockData.videos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final video = MockData.videos[index];
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          video.creatorUsername.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '@${video.creatorUsername}',
                        style: AppTypography.caption,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Trending Short Video Grid
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Popular Reels', style: AppTypography.headingSmall),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: MockData.videos.length,
              itemBuilder: (context, index) {
                final video = MockData.videos[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.play_circle_fill, size: 44, color: Colors.white70),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.caption ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.favorite, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${video.likesCount}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
