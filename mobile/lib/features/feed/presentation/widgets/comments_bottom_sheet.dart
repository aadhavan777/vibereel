import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/video_entity.dart';

class CommentsBottomSheet extends StatefulWidget {
  final VideoEntity video;

  const CommentsBottomSheet({super.key, required this.video});

  static Future<void> show(BuildContext context, VideoEntity video) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(video: video),
    );
  }

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  late final List<Map<String, dynamic>> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [
      {
        'username': 'alex_visuals',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
        'text': 'This is super smooth! Love the animation transitions 🔥',
        'time': '2h ago',
        'likes': 42,
        'isLiked': false,
      },
      {
        'username': 'tech_sarah',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
        'text': 'What library did you use for the preloading queue?',
        'time': '4h ago',
        'likes': 18,
        'isLiked': true,
      },
      {
        'username': 'dev_marcus',
        'avatar': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
        'text': 'VibeReel UI looks insane! Best video player implementation on Flutter.',
        'time': '1d ago',
        'likes': 95,
        'isLiked': false,
      },
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.insert(0, {
        'username': 'vibemaster',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
        'text': text,
        'time': 'Just now',
        'likes': 0,
        'isLiked': false,
      });
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65 + bottomInset,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.video.commentsCount} Comments',
                  style: AppTypography.headingSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),

          // Comments List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _comments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = _comments[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: NetworkImage(item['avatar'] as String),
                      onBackgroundImageError: (_, __) {},
                      child: Text(
                        (item['username'] as String).substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '@${item['username']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item['time'] as String,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['text'] as String,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final isLiked = item['isLiked'] as bool;
                          item['isLiked'] = !isLiked;
                          item['likes'] = (item['likes'] as int) + (isLiked ? -1 : 1);
                        });
                      },
                      child: Column(
                        children: [
                          Icon(
                            (item['isLiked'] as bool) ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: (item['isLiked'] as bool) ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['likes']}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Add Comment Input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + bottomInset,
            ),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text('V', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
