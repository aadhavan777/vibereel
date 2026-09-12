import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/services/video_upload_service.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/create_remote_datasource.dart';

final createRemoteDatasourceProvider = Provider<CreateRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CreateRemoteDatasource(apiClient);
});

class CreateState {
  final int currentStep; // 0 = Select Source, 1 = Preview/Trim, 2 = Caption/Hashtags, 3 = Done
  final String? videoPath;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final List<String> hashtags;
  final double trimStart;
  final double trimEnd;
  final bool isDraft;
  final bool isUploading;
  final double uploadProgress;
  final int sentBytes;
  final int totalBytes;
  final bool isCancelled;
  final String? error;
  final bool isSuccess;

  CreateState({
    this.currentStep = 0,
    this.videoPath,
    this.videoUrl,
    this.thumbnailUrl,
    this.caption = '',
    this.hashtags = const ['flutter', 'vibereel'],
    this.trimStart = 0.0,
    this.trimEnd = 1.0,
    this.isDraft = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.sentBytes = 0,
    this.totalBytes = 0,
    this.isCancelled = false,
    this.error,
    this.isSuccess = false,
  });

  CreateState copyWith({
    int? currentStep,
    String? videoPath,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    List<String>? hashtags,
    double? trimStart,
    double? trimEnd,
    bool? isDraft,
    bool? isUploading,
    double? uploadProgress,
    int? sentBytes,
    int? totalBytes,
    bool? isCancelled,
    String? error,
    bool? isSuccess,
  }) {
    return CreateState(
      currentStep: currentStep ?? this.currentStep,
      videoPath: videoPath ?? this.videoPath,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      isDraft: isDraft ?? this.isDraft,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      sentBytes: sentBytes ?? this.sentBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      isCancelled: isCancelled ?? this.isCancelled,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class CreateViewModel extends StateNotifier<CreateState> {
  final FileStorageService _storageService;
  final VideoUploadService _videoUploadService;
  final CreateRemoteDatasource _remoteDatasource;
  CancelToken? _cancelToken;

  CreateViewModel(
    this._storageService,
    this._videoUploadService,
    this._remoteDatasource,
  ) : super(CreateState());

  void selectMediaSource(String source) {
    // Simulates picking video file from camera or gallery
    final samplePath = source == 'camera'
        ? 'camera_rec_${DateTime.now().millisecondsSinceEpoch}.mp4'
        : 'gallery_clip_${DateTime.now().millisecondsSinceEpoch}.mp4';

    state = state.copyWith(
      videoPath: samplePath,
      currentStep: 1,
    );
  }

  void setTrimRange(double start, double end) {
    state = state.copyWith(trimStart: start, trimEnd: end);
  }

  void setCaption(String caption) {
    state = state.copyWith(caption: caption);
  }

  void addHashtag(String tag) {
    final clean = tag.replaceAll('#', '').trim();
    if (clean.isEmpty || state.hashtags.contains(clean)) return;
    state = state.copyWith(hashtags: [...state.hashtags, clean]);
  }

  void removeHashtag(String tag) {
    state = state.copyWith(
      hashtags: state.hashtags.where((t) => t != tag).toList(),
    );
  }

  void selectThumbnail(String url) {
    state = state.copyWith(thumbnailUrl: url);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void cancelUpload() {
    _cancelToken?.cancel('Cancelled by user');
    state = state.copyWith(
      isUploading: false,
      isCancelled: true,
      error: 'Upload cancelled by user',
    );
  }

  Future<void> submitContent({required bool saveAsDraft}) async {
    _cancelToken = CancelToken();
    state = state.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
      sentBytes: 0,
      totalBytes: 0,
      isCancelled: false,
      error: null,
      isDraft: saveAsDraft,
    );

    try {
      final path = state.videoPath ?? 'sample_video.mp4';

      // Check if real file exists for direct upload, else fallback to mock service URL
      if (path.endsWith('.mp4') && !path.contains('_')) {
        await _videoUploadService.uploadVideoFile(
          videoPath: path,
          thumbnailPath: state.thumbnailUrl,
          caption: state.caption.isEmpty ? 'New VibeReel short video 🚀' : state.caption,
          isDraft: saveAsDraft,
          onProgress: (sent, total) {
            final progress = total > 0 ? (sent / total) : 0.0;
            state = state.copyWith(
              uploadProgress: progress,
              sentBytes: sent,
              totalBytes: total,
            );
          },
          cancelToken: _cancelToken,
        );
      } else {
        // Simulated progress steps for smooth UX demo when using mock camera/gallery clips
        for (int i = 1; i <= 10; i++) {
          if (_cancelToken?.isCancelled ?? false) {
            throw Exception('Upload cancelled by user');
          }
          await Future.delayed(const Duration(milliseconds: 100));
          state = state.copyWith(
            uploadProgress: i / 10.0,
            sentBytes: i * 1000000,
            totalBytes: 10000000,
          );
        }

        final uploadedUrl = await _storageService.uploadVideoFile(path);
        final thumbUrl = state.thumbnailUrl ??
            await _storageService.uploadThumbnailFile('sample_thumb.jpg');

        await _remoteDatasource.createVideo(
          videoUrl: uploadedUrl,
          thumbnailUrl: thumbUrl,
          caption: state.caption.isEmpty ? 'New VibeReel short video 🚀' : state.caption,
          hashtags: state.hashtags,
          isDraft: saveAsDraft,
        );
      }

      state = state.copyWith(
        isUploading: false,
        isSuccess: true,
        uploadProgress: 1.0,
        currentStep: 3,
      );
    } catch (e) {
      if (state.isCancelled) return;
      state = state.copyWith(
        isUploading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = CreateState();
  }
}

final createViewModelProvider = StateNotifierProvider<CreateViewModel, CreateState>((ref) {
  final storageService = ref.watch(fileStorageServiceProvider);
  final videoUploadService = ref.watch(videoUploadServiceProvider);
  final remoteDatasource = ref.watch(createRemoteDatasourceProvider);
  return CreateViewModel(storageService, videoUploadService, remoteDatasource);
});

