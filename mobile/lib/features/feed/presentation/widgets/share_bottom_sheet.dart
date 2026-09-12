import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/video_entity.dart';

class ShareBottomSheet extends StatelessWidget {
  final VideoEntity video;

  const ShareBottomSheet({super.key, required this.video});

  static Future<void> show(BuildContext context, VideoEntity video) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(video: video),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shareActions = [
      {'icon': Icons.link, 'label': 'Copy Link', 'color': AppColors.primary},
      {'icon': Icons.send_rounded, 'label': 'Direct Message', 'color': Colors.blueAccent},
      {'icon': Icons.camera_alt_outlined, 'label': 'Share to Story', 'color': Colors.purpleAccent},
      {'icon': Icons.bookmark_add_outlined, 'label': 'Save Video', 'color': AppColors.accent},
      {'icon': Icons.flag_outlined, 'label': 'Report', 'color': Colors.redAccent},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Share Video',
            style: AppTypography.headingSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '@${video.creatorUsername} • ${video.caption ?? "VibeReel Video"}',
            style: AppTypography.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shareActions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final action = shareActions[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${action['label']} performed!'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: (action['color'] as Color).withAlpha(40),
                        child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'] as String,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
