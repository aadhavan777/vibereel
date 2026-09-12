import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/views/profile_view.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../viewmodels/forum_viewmodel.dart';
import 'forum_post_form_view.dart';
import 'forum_report_dialog.dart';

class ForumPostDetailsView extends ConsumerStatefulWidget {
  final ForumPostEntity post;

  const ForumPostDetailsView({super.key, required this.post});

  @override
  ConsumerState<ForumPostDetailsView> createState() => _ForumPostDetailsViewState();
}

class _ForumPostDetailsViewState extends ConsumerState<ForumPostDetailsView> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToCommentId;
  String? _replyingToUsername;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(forumViewModelProvider.notifier).fetchComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumViewModelProvider);
    final notifier = ref.read(forumViewModelProvider.notifier);

    // Find current post in state to get real-time optimistic likes/comments updates
    final currentPost = forumState.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );

    final comments = forumState.commentsMap[currentPost.id] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.orangeAccent),
            tooltip: 'Report Post',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ForumReportDialog(
                  postId: currentPost.id,
                  onReport: notifier.reportContent,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppColors.surfaceVariant,
            onSelected: (val) {
              if (val == 'edit') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => ForumPostFormView(
                    initialPost: currentPost,
                    onSubmit: (title, content, category, tags) {
                      notifier.updatePost(currentPost.id, title, content, category, tags);
                    },
                  ),
                );
              } else if (val == 'delete') {
                notifier.deletePost(currentPost.id);
                Navigator.pop(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.white), SizedBox(width: 8), Text('Edit Post', style: TextStyle(color: Colors.white))])),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('Delete Post', style: TextStyle(color: Colors.redAccent))])),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Header Card
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
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          backgroundImage: currentPost.authorAvatarUrl != null ? NetworkImage(currentPost.authorAvatarUrl!) : null,
                          child: currentPost.authorAvatarUrl == null
                              ? Text(
                                  currentPost.authorUsername.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ProfileView()),
                              );
                            },
                            child: Text('@${currentPost.authorUsername}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                          Text(
                            _formatDate(currentPost.createdAt),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currentPost.category.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title & Body
                  Text(currentPost.title, style: AppTypography.headingMedium),
                  const SizedBox(height: 12),
                  Text(
                    currentPost.content,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                  ),

                  if (currentPost.tags != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      children: currentPost.tags!
                          .split(',')
                          .map((t) => Chip(
                                label: Text('#${t.trim()}'),
                                backgroundColor: AppColors.surfaceVariant,
                                labelStyle: const TextStyle(color: AppColors.accent, fontSize: 11),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.divider),

                  // Post Action Bar (Likes, Comments Count, Views)
                  Row(
                    children: [
                      InkWell(
                        onTap: () => notifier.toggleLikePost(currentPost.id),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                currentPost.isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 22,
                                color: currentPost.isLiked ? AppColors.primary : AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${currentPost.likesCount}',
                                style: TextStyle(
                                  color: currentPost.isLiked ? AppColors.primary : AppColors.textMuted,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text('${currentPost.commentsCount} Comments', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text('${currentPost.viewsCount} views', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),

                  // Comments Section Header
                  const Text('Comments & Community Replies', style: AppTypography.headingSmall),
                  const SizedBox(height: 12),

                  if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'No comments yet. Start the conversation!',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return _CommentCard(
                          comment: comment,
                          onReply: (commentId, username) {
                            setState(() {
                              _replyingToCommentId = commentId;
                              _replyingToUsername = username;
                            });
                          },
                          onReport: notifier.reportContent,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom Add Comment / Reply Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToUsername != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Replying to @$_replyingToUsername', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                        InkWell(
                          onTap: () => setState(() {
                            _replyingToCommentId = null;
                            _replyingToUsername = null;
                          }),
                          child: const Icon(Icons.close, size: 16, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _replyingToUsername != null ? 'Write a reply...' : 'Add a community comment...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () async {
                        final text = _commentController.text.trim();
                        if (text.isNotEmpty) {
                          await notifier.addComment(
                            currentPost.id,
                            text,
                            parentCommentId: _replyingToCommentId,
                          );
                          _commentController.clear();
                          setState(() {
                            _replyingToCommentId = null;
                            _replyingToUsername = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _CommentCard extends StatelessWidget {
  final ForumCommentEntity comment;
  final void Function(String commentId, String username) onReply;
  final Future<bool> Function({String? postId, String? commentId, required String reason, String? details}) onReport;

  const _CommentCard({
    required this.comment,
    required this.onReply,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.secondary,
                child: Text(
                  comment.authorUsername.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text('@${comment.authorUsername}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.flag_outlined, size: 14, color: AppColors.textMuted),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ForumReportDialog(
                      commentId: comment.id,
                      onReport: onReport,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                onTap: () => onReply(comment.id, comment.authorUsername),
                child: const Text('Reply', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // Threaded Replies
          if (comment.replies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                children: comment.replies
                    .map((reply) => Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${reply.authorUsername}', style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(reply.content, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
