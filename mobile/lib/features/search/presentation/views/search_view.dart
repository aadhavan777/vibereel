import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../viewmodels/search_viewmodel.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQuerySubmitted(String query) {
    ref.read(searchViewModelProvider.notifier).performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchViewModelProvider);
    final viewModel = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: false,
          style: const TextStyle(color: Colors.white),
          onChanged: (val) {
            if (val.isEmpty) {
              viewModel.clearSearch();
            } else {
              viewModel.performSearch(val);
            }
          },
          onSubmitted: _onQuerySubmitted,
          decoration: const InputDecoration(
            hintText: 'Search creators, videos, hashtags or forum...',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () {
                _searchController.clear();
                viewModel.clearSearch();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          if (searchState.query.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildTabChip('All', 'all', searchState, viewModel),
                  const SizedBox(width: 8),
                  _buildTabChip('Videos', 'videos', searchState, viewModel),
                  const SizedBox(width: 8),
                  _buildTabChip('Creators', 'creators', searchState, viewModel),
                  const SizedBox(width: 8),
                  _buildTabChip('Forum', 'forum', searchState, viewModel),
                ],
              ),
            ),

          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : searchState.query.isEmpty
                    ? _buildDiscoveryHome(searchState, viewModel)
                    : _buildSearchResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, String value, SearchState state, SearchViewModel vm) {
    final isSelected = state.activeTab == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => vm.setActiveTab(value),
    );
  }

  Widget _buildDiscoveryHome(SearchState state, SearchViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.recentSearches.isNotEmpty) ...[
          const Text('Recent Searches', style: AppTypography.headingSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.recentSearches.map((tag) {
              return ActionChip(
                label: Text(tag),
                backgroundColor: AppColors.surface,
                labelStyle: const TextStyle(color: Colors.white),
                onPressed: () {
                  _searchController.text = tag;
                  vm.performSearch(tag);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Trending Searches', style: AppTypography.headingSmall),
        const SizedBox(height: 12),
        if (state.trendingSearches.isEmpty)
          _buildDefaultTrendingItems(vm)
        else
          Column(
            children: state.trendingSearches.map((item) {
              return ListTile(
                leading: const Icon(Icons.trending_up, color: AppColors.primary),
                title: Text(item['tag'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('${item['category'] ?? ''} • ${item['views'] ?? ''} views', style: const TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  final query = (item['tag'] as String).replaceAll('#', '');
                  _searchController.text = query;
                  vm.performSearch(query);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDefaultTrendingItems(SearchViewModel vm) {
    final defaults = [
      {'tag': '#FlutterDev', 'category': 'Tech & Mobile', 'views': '1.2M'},
      {'tag': '#VibeReel', 'category': 'Community', 'views': '890K'},
      {'tag': '#CinematicVibes', 'category': 'Video Editing', 'views': '2.4M'},
    ];
    return Column(
      children: defaults.map((item) {
        return ListTile(
          leading: const Icon(Icons.trending_up, color: AppColors.primary),
          title: Text(item['tag']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${item['category']} • ${item['views']} views', style: const TextStyle(color: AppColors.textMuted)),
          onTap: () {
            _searchController.text = item['tag']!;
            vm.performSearch(item['tag']!);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSearchResults(SearchState state) {
    final hasVideos = state.videos.isNotEmpty;
    final hasCreators = state.creators.isNotEmpty;
    final hasForum = state.forumPosts.isNotEmpty;

    if (!hasVideos && !hasCreators && !hasForum) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No results found for "${state.query}"', style: AppTypography.headingSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Try searching for different keywords or topics.', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (hasCreators && (state.activeTab == 'all' || state.activeTab == 'creators')) ...[
          const Text('Creators', style: AppTypography.headingSmall),
          const SizedBox(height: 12),
          ...state.creators.map((c) {
            final username = c['username'] ?? 'creator';
            final email = c['email'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withAlpha(40),
                    child: Text(username[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@$username', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Follow'),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        if (hasVideos && (state.activeTab == 'all' || state.activeTab == 'videos')) ...[
          const Text('Videos', style: AppTypography.headingSmall),
          const SizedBox(height: 12),
          ...state.videos.map((v) {
            final caption = v['caption'] ?? '';
            final username = v['creator_username'] ?? 'creator';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@$username', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(caption, style: AppTypography.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
        ],

        if (hasForum && (state.activeTab == 'all' || state.activeTab == 'forum')) ...[
          const Text('Forum Discussions', style: AppTypography.headingSmall),
          const SizedBox(height: 12),
          ...state.forumPosts.map((p) {
            final title = p['title'] ?? '';
            final category = p['category'] ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(category.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.accent)),
                    backgroundColor: AppColors.accent.withAlpha(20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
