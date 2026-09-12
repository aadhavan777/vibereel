import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ForumReportDialog extends StatefulWidget {
  final String? postId;
  final String? commentId;
  final Future<bool> Function({
    String? postId,
    String? commentId,
    required String reason,
    String? details,
  }) onReport;

  const ForumReportDialog({
    super.key,
    this.postId,
    this.commentId,
    required this.onReport,
  });

  @override
  State<ForumReportDialog> createState() => _ForumReportDialogState();
}

class _ForumReportDialogState extends State<ForumReportDialog> {
  String _selectedReason = 'inappropriate';
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _reasons = [
    {'value': 'inappropriate', 'label': 'Inappropriate Content'},
    {'value': 'spam', 'label': 'Spam or Misleading'},
    {'value': 'harassment', 'label': 'Harassment or Hate Speech'},
    {'value': 'copyright', 'label': 'Copyright Infringement'},
    {'value': 'other', 'label': 'Other Issue'},
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.flag_rounded, color: Colors.orangeAccent),
          SizedBox(width: 8),
          Text('Report Content', style: AppTypography.headingSmall),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help us keep VibeReel safe and productive for creators.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ..._reasons.map(
              (r) => InkWell(
                onTap: () => setState(() => _selectedReason = r['value']!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: r['value']!,
                        // ignore: deprecated_member_use
                        groupValue: _selectedReason,
                        activeColor: AppColors.primary,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedReason = val);
                        },
                      ),
                      Text(r['label']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  final success = await widget.onReport(
                    postId: widget.postId,
                    commentId: widget.commentId,
                    reason: _selectedReason,
                    details: _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted. Thank you for keeping VibeReel safe!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Report'),
        ),
      ],
    );
  }
}
