import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../widgets/video_player_item.dart';

class FeedView extends ConsumerStatefulWidget {
  const FeedView({super.key});

  @override
  ConsumerState<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends ConsumerState<FeedView> with WidgetsBindingObserver {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isMuted = false;
  bool _isAppActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() => _isAppActive = false);
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _isAppActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Feed Video List or Loading State
          if (feedState.isLoading && feedState.videos.isEmpty)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (feedState.error != null && feedState.videos.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load video feed',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(feedViewModelProvider.notifier).fetchFeed(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: feedState.videos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final video = feedState.videos[index];
                final isActive = (index == _currentIndex) && _isAppActive;

                return VideoPlayerItem(
                  key: ValueKey(video.id),
                  video: video,
                  isActive: isActive,
                  isMuted: _isMuted,
                  onToggleMute: () {
                    setState(() => _isMuted = !_isMuted);
                  },
                );
              },
            ),

          // Top Header Overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ).createShader(bounds),
                      child: const Text(
                        'VibeReel',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.redAccent, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white, size: 26),
                      onPressed: () => context.push('/search'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
                      onPressed: () => context.push('/notifications'),
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
}
