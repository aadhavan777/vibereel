import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/feed_remote_datasource.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/entities/video_entity.dart';
import '../../domain/repositories/feed_repository.dart';

final feedRemoteDatasourceProvider = Provider<FeedRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return FeedRemoteDatasource(apiClient);
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final remoteDatasource = ref.watch(feedRemoteDatasourceProvider);
  return FeedRepositoryImpl(remoteDatasource);
});

class FeedState {
  final bool isLoading;
  final List<VideoEntity> videos;
  final String? error;

  FeedState({
    this.isLoading = false,
    this.videos = const [],
    this.error,
  });

  FeedState copyWith({
    bool? isLoading,
    List<VideoEntity>? videos,
    String? error,
  }) {
    return FeedState(
      isLoading: isLoading ?? this.isLoading,
      videos: videos ?? this.videos,
      error: error,
    );
  }
}

class FeedViewModel extends StateNotifier<FeedState> {
  final FeedRepository _repository;

  FeedViewModel(this._repository) : super(FeedState()) {
    fetchFeed();
  }

  Future<void> fetchFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final videos = await _repository.getFeed();
      state = state.copyWith(isLoading: false, videos: videos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleLike(String videoId) async {
    final index = state.videos.indexWhere((v) => v.id == videoId);
    if (index == -1) return;

    final video = state.videos[index];
    final isLikedNow = !video.isLiked;
    final updatedCount = video.likesCount + (isLikedNow ? 1 : -1);

    final updatedVideo = video.copyWith(
      isLiked: isLikedNow,
      likesCount: updatedCount < 0 ? 0 : updatedCount,
    );

    final updatedList = List<VideoEntity>.from(state.videos);
    updatedList[index] = updatedVideo;
    state = state.copyWith(videos: updatedList);

    if (isLikedNow) {
      await _repository.likeVideo(videoId);
    } else {
      await _repository.unlikeVideo(videoId);
    }
  }

  Future<void> toggleSave(String videoId) async {
    final index = state.videos.indexWhere((v) => v.id == videoId);
    if (index == -1) return;

    final video = state.videos[index];
    final isSavedNow = !video.isSaved;
    final updatedCount = video.savesCount + (isSavedNow ? 1 : -1);

    final updatedVideo = video.copyWith(
      isSaved: isSavedNow,
      savesCount: updatedCount < 0 ? 0 : updatedCount,
    );

    final updatedList = List<VideoEntity>.from(state.videos);
    updatedList[index] = updatedVideo;
    state = state.copyWith(videos: updatedList);

    if (isSavedNow) {
      await _repository.saveVideo(videoId);
    } else {
      await _repository.unsaveVideo(videoId);
    }
  }
}

final feedViewModelProvider = StateNotifierProvider<FeedViewModel, FeedState>((ref) {
  final repository = ref.watch(feedRepositoryProvider);
  return FeedViewModel(repository);
});
