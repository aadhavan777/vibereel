import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsView extends ConsumerWidget {
  const NotificationsView({super.key});

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.chat_bubble;
      case 'reply':
        return Icons.reply;
      case 'follow':
        return Icons.person_add;
      case 'mention':
        return Icons.alternate_email;
      case 'forum_reply':
        return Icons.forum;
      case 'collaboration_request':
        return Icons.handshake;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return AppColors.primary;
      case 'comment':
      case 'reply':
        return AppColors.accent;
      case 'follow':
        return AppColors.secondary;
      case 'forum_reply':
        return Colors.orangeAccent;
      case 'collaboration_request':
        return Colors.purpleAccent;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsViewModelProvider);
    final viewModel = ref.read(notificationsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (state.items.isNotEmpty)
            TextButton(
              onPressed: () => viewModel.markAllAsRead(),
              child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Unread Only'),
                  selected: state.unreadOnlyFilter,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: state.unreadOnlyFilter ? Colors.black : Colors.white,
                    fontWeight: state.unreadOnlyFilter ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) => viewModel.toggleUnreadFilter(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textMuted),
                  onPressed: () => viewModel.fetchNotifications(),
                ),
              ],
            ),
          ),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : state.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              state.unreadOnlyFilter ? 'No unread notifications' : 'No notifications yet',
                              style: AppTypography.headingSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'When creators like, comment or follow you,\nyou will see alerts here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final id = item['id'] as String;
                          final type = item['type'] as String? ?? 'general';
                          final title = item['title'] as String? ?? '';
                          final message = item['message'] as String? ?? '';
                          final isRead = item['is_read'] as bool? ?? false;
                          final createdAt = item['created_at'] as String? ?? '';

                          return InkWell(
                            onTap: () {
                              if (!isRead) viewModel.markAsRead(id);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isRead ? AppColors.surface : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isRead
                                      ? AppColors.divider.withAlpha(40)
                                      : AppColors.primary.withAlpha(100),
                                  width: isRead ? 1 : 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getNotificationColor(type).withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getNotificationIcon(type),
                                      color: _getNotificationColor(type),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          message,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          createdAt.length > 10 ? createdAt.substring(0, 10) : createdAt,
                                          style: AppTypography.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
