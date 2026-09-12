import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

class UploadView extends ConsumerWidget {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Video Post')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider, width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 56, color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('Tap to select video file', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a catchy caption & hashtags...',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Post Video'),
            ),
          ],
        ),
      ),
    );
  }
}
