import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Discover Unlimited Short Videos',
      'subtitle': 'Explore vertical reels, trending music, and viral creative content from top video creators worldwide.',
      'icon': 'movie_filter_rounded',
    },
    {
      'title': 'Dedicated Creator Community',
      'subtitle': 'Engage in open discussions, gear recommendations, and video editing advice inside our dedicated creator forum.',
      'icon': 'forum_rounded',
    },
    {
      'title': 'Collaborate & Grow Together',
      'subtitle': 'Find co-creators, post project proposals, and turn your short video passion into a thriving creator career.',
      'icon': 'handshake_rounded',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'movie_filter_rounded':
        return Icons.movie_filter_rounded;
      case 'forum_rounded':
        return Icons.forum_rounded;
      case 'handshake_rounded':
        return Icons.handshake_rounded;
      default:
        return Icons.video_library_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.surfaceVariant, AppColors.surface],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withAlpha(60), width: 2),
                          ),
                          child: Icon(
                            _getIconData(item['icon']!),
                            size: 80,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          item['title']!,
                          style: AppTypography.headingLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['subtitle']!,
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go('/login');
                  }
                },
                child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
