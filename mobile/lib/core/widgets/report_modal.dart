import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/moderation/presentation/viewmodels/moderation_viewmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class ReportModal extends ConsumerStatefulWidget {
  final String entityType; // 'video', 'forum_post', 'forum_comment', 'video_comment'
  final String entityId;
  final String contentTitle;

  const ReportModal({
    super.key,
    required this.entityType,
    required this.entityId,
    required this.contentTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String entityType,
    required String entityId,
    required String contentTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportModal(
          entityType: entityType,
          entityId: entityId,
          contentTitle: contentTitle,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends ConsumerState<ReportModal> {
  String _selectedReason = 'Spam or Scam';
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _reasons = [
    'Spam or Scam',
    'Inappropriate Content or Nudity',
    'Harassment or Bullying',
    'Copyright Violation',
    'Violence or Dangerous Content',
    'Misinformation',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final success = await ref.read(moderationViewModelProvider.notifier).reportContent(
          entityType: widget.entityType,
          entityId: widget.entityId,
          reason: _selectedReason,
          details: _detailsController.text.trim().isNotEmpty ? _detailsController.text.trim() : null,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Report submitted. Thank you for helping keep VibeReel safe.'
                : 'Failed to submit report. Please try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Report ${widget.entityType.replaceAll('_', ' ').toUpperCase()}', style: AppTypography.headingSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Reporting: "${widget.contentTitle}"',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          const Text('Select Reason', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          ..._reasons.map((reason) {
            final isSelected = _selectedReason == reason;
            return InkWell(
              onTap: () => setState(() => _selectedReason = reason),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Additional details (optional)...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
