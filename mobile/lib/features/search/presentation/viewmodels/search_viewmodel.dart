import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

import '../../data/search_remote_datasource.dart';
import '../../data/search_repository.dart';

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchRemoteDataSource(apiClient: apiClient);
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final remote = ref.watch(searchRemoteDataSourceProvider);
  return SearchRepositoryImpl(remoteDataSource: remote);
});

class SearchState {
  final bool isLoading;
  final String query;
  final String activeTab; // 'all', 'videos', 'creators', 'forum'
  final List<dynamic> videos;
  final List<dynamic> creators;
  final List<dynamic> hashtags;
  final List<dynamic> forumPosts;
  final List<dynamic> trendingSearches;
  final List<String> recentSearches;
  final String? error;

  SearchState({
    this.isLoading = false,
    this.query = '',
    this.activeTab = 'all',
    this.videos = const [],
    this.creators = const [],
    this.hashtags = const [],
    this.forumPosts = const [],
    this.trendingSearches = const [],
    this.recentSearches = const ['#FlutterDev', '#VibeReel', '#ShortVideos'],
    this.error,
  });

  SearchState copyWith({
    bool? isLoading,
    String? query,
    String? activeTab,
    List<dynamic>? videos,
    List<dynamic>? creators,
    List<dynamic>? hashtags,
    List<dynamic>? forumPosts,
    List<dynamic>? trendingSearches,
    List<String>? recentSearches,
    String? error,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      activeTab: activeTab ?? this.activeTab,
      videos: videos ?? this.videos,
      creators: creators ?? this.creators,
      hashtags: hashtags ?? this.hashtags,
      forumPosts: forumPosts ?? this.forumPosts,
      trendingSearches: trendingSearches ?? this.trendingSearches,
      recentSearches: recentSearches ?? this.recentSearches,
      error: error,
    );
  }
}

class SearchViewModel extends StateNotifier<SearchState> {
  final SearchRepository _repository;

  SearchState get currentState => state;

  SearchViewModel(this._repository) : super(SearchState()) {
    fetchTrending();
  }


  Future<void> fetchTrending() async {
    try {
      final trending = await _repository.getTrendingSearches();
      state = state.copyWith(trendingSearches: trending);
    } catch (_) {}
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
    if (state.query.trim().isNotEmpty) {
      performSearch(state.query);
    }
  }

  Future<void> performSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        query: '',
        videos: [],
        creators: [],
        hashtags: [],
        forumPosts: [],
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true, query: trimmed, error: null);

    // Save to recent searches if unique
    final recents = List<String>.from(state.recentSearches);
    if (!recents.contains(trimmed)) {
      recents.insert(0, trimmed);
      if (recents.length > 5) recents.removeLast();
    }

    try {
      final result = await _repository.search(trimmed, type: state.activeTab);
      state = state.copyWith(
        isLoading: false,
        recentSearches: recents,
        videos: result['videos'] ?? [],
        creators: result['creators'] ?? [],
        hashtags: result['hashtags'] ?? [],
        forumPosts: result['forum_posts'] ?? [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearSearch() {
    state = state.copyWith(
      query: '',
      videos: [],
      creators: [],
      hashtags: [],
      forumPosts: [],
    );
  }
}

final searchViewModelProvider = StateNotifierProvider<SearchViewModel, SearchState>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchViewModel(repo);
});
