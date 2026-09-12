import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../viewmodels/create_viewmodel.dart';

class CreateView extends ConsumerStatefulWidget {
  const CreateView({super.key});

  @override
  ConsumerState<CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends ConsumerState<CreateView> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createViewModelProvider);
    final notifier = ref.read(createViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Short Video'),
        actions: [
          if (state.currentStep > 0 && state.currentStep < 3)
            TextButton(
              onPressed: () => notifier.reset(),
              child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: _buildStepBody(context, state, notifier),
    );
  }

  Widget _buildStepBody(BuildContext context, CreateState state, CreateViewModel notifier) {
    switch (state.currentStep) {
      case 0:
        return _buildSelectSourceStep(context, notifier);
      case 1:
        return _buildPreviewTrimStep(context, state, notifier);
      case 2:
        return _buildMetadataStep(context, state, notifier);
      case 3:
        return _buildSuccessStep(context, state, notifier);
      default:
        return _buildSelectSourceStep(context, notifier);
    }
  }

  Widget _buildSelectSourceStep(BuildContext context, CreateViewModel notifier) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withAlpha(100), width: 2),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_outlined, size: 72, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Capture or Select Video', style: AppTypography.headingSmall),
                  SizedBox(height: 8),
                  Text('Record up to 60s vertical video', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Record with Camera'),
            onPressed: () => notifier.selectMediaSource('camera'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              side: const BorderSide(color: AppColors.surfaceVariant),
            ),
            icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
            label: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
            onPressed: () => notifier.selectMediaSource('gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTrimStep(BuildContext context, CreateState state, CreateViewModel notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Step 2: Preview & Trim Video', style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          Container(
            height: 360,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white70),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Source: ${state.videoPath}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Trim Duration (seconds)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          RangeSlider(
            values: RangeValues(state.trimStart, state.trimEnd),
            min: 0.0,
            max: 1.0,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceVariant,
            onChanged: (values) => notifier.setTrimRange(values.start, values.end),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0s', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('60s', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.previousStep(),
                  child: const Text('Back', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => notifier.nextStep(),
                  child: const Text('Next: Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataStep(BuildContext context, CreateState state, CreateViewModel notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Step 3: Caption & Hashtags', style: AppTypography.headingSmall),
          const SizedBox(height: 16),

          // Caption TextField
          TextField(
            controller: _captionController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Write a catchy caption for your video...',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
            onChanged: (val) => notifier.setCaption(val),
          ),
          const SizedBox(height: 20),

          // Hashtags Generator
          const Text('Add Hashtags', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hashtagController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g. flutter, cinematic',
                    prefixText: '# ',
                    isDense: true,
                  ),
                  onSubmitted: (tag) {
                    notifier.addHashtag(tag);
                    _hashtagController.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  notifier.addHashtag(_hashtagController.text);
                  _hashtagController.clear();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Active Hashtags Chips
          Wrap(
            spacing: 8,
            children: state.hashtags
                .map((tag) => Chip(
                      label: Text('#$tag'),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => notifier.removeHashtag(tag),
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: const TextStyle(color: AppColors.accent, fontSize: 12),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Error display if upload fails or is cancelled
          if (state.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit / Progress Actions
          if (state.isUploading)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Uploading Video...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(state.uploadProgress * 100).toInt()}%',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.uploadProgress > 0 ? state.uploadProgress : null,
                      minHeight: 10,
                      backgroundColor: Colors.black26,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.totalBytes > 0)
                    Text(
                      '${(state.sentBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${(state.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                    label: const Text('Cancel Upload', style: TextStyle(color: Colors.redAccent)),
                    onPressed: () => notifier.cancelUpload(),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text('Publish Video'),
                  onPressed: () => notifier.submitContent(saveAsDraft: false),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: AppColors.accent),
                  ),
                  icon: const Icon(Icons.drafts_outlined, color: AppColors.accent),
                  label: const Text('Save to Drafts', style: TextStyle(color: AppColors.accent)),
                  onPressed: () => notifier.submitContent(saveAsDraft: true),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep(BuildContext context, CreateState state, CreateViewModel notifier) {
    final isDraft = state.isDraft;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDraft ? Icons.bookmark_added_rounded : Icons.check_circle_rounded,
            size: 84,
            color: isDraft ? AppColors.accent : AppColors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            isDraft ? 'Saved to Drafts!' : 'Video Reel Published!',
            style: AppTypography.headingLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isDraft
                ? 'You can access and publish this draft anytime from your Profile.'
                : 'Your video is now live on the VibeReel feed!',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            onPressed: () => notifier.reset(),
            child: const Text('Create Another Video'),
          ),
        ],
      ),
    );
  }
}
