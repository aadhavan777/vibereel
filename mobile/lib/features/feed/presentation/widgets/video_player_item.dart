import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/video_entity.dart';
import 'comments_bottom_sheet.dart';
import 'share_bottom_sheet.dart';

class VideoPlayerItem extends StatefulWidget {
  final VideoEntity video;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback? onLikeToggle;
  final VoidCallback? onSaveToggle;

  const VideoPlayerItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.isMuted,
    required this.onToggleMute,
    this.onLikeToggle,
    this.onSaveToggle,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;
  bool _showPauseOverlay = false;
  bool _showDoubleTapHeart = false;
  Offset _heartPosition = Offset.zero;

  late AnimationController _discAnimationController;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isSaved = false;
  int _savesCount = 0;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.video.isLiked;
    _likesCount = widget.video.likesCount;
    _isSaved = widget.video.isSaved;
    _savesCount = widget.video.savesCount;

    _discAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      final uri = Uri.parse(widget.video.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);

      await _controller!.initialize();
      if (!mounted) return;

      _controller!.setLooping(true);
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);

      _controller!.addListener(_videoListener);

      setState(() {
        _isInitialized = true;
        _hasError = false;
      });

      if (widget.isActive) {
        _controller!.play();
        _discAnimationController.repeat();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_controller != null && _isInitialized) {
      // Mute handling
      _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);

      // Active state handling
      if (widget.isActive && !oldWidget.isActive) {
        _controller!.play();
        _discAnimationController.repeat();
        setState(() => _isPlaying = true);
      } else if (!widget.isActive && oldWidget.isActive) {
        _controller!.pause();
        _discAnimationController.stop();
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _discAnimationController.dispose();
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
      _discAnimationController.stop();
      setState(() {
        _isPlaying = false;
        _showPauseOverlay = true;
      });
    } else {
      _controller!.play();
      _discAnimationController.repeat();
      setState(() {
        _isPlaying = true;
        _showPauseOverlay = true;
      });
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showPauseOverlay = false);
      });
    }
  }

  void _handleDoubleTap(TapDownDetails details) {
    setState(() {
      _heartPosition = details.localPosition;
      _showDoubleTapHeart = true;
      if (!_isLiked) {
        _isLiked = true;
        _likesCount += 1;
        widget.onLikeToggle?.call();
      }
    });

    Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showDoubleTapHeart = false);
    });
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player or loading / error state
          GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTapDown: _handleDoubleTap,
            onDoubleTap: () {},
            child: _buildVideoContent(),
          ),

          // Double tap heart splash
          if (_showDoubleTapHeart)
            Positioned(
              left: _heartPosition.dx - 40,
              top: _heartPosition.dy - 40,
              child: const Icon(
                Icons.favorite_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),

          // Center Pause / Play indicator overlay
          if (_showPauseOverlay && _isInitialized)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

          // Top Mute button & live indicator
          Positioned(
            top: 50,
            right: 16,
            child: GestureDetector(
              onTap: widget.onToggleMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          // Right Side Action Sidebar
          Positioned(
            right: 12,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Creator Avatar with Follow Button
                _buildAvatarWidget(),
                const SizedBox(height: 20),

                // Like Button
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isLiked ? AppColors.primary : Colors.white,
                  label: _formatCount(_likesCount),
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _likesCount += _isLiked ? 1 : -1;
                    });
                    widget.onLikeToggle?.call();
                  },
                ),
                const SizedBox(height: 18),

                // Comment Button
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  label: _formatCount(widget.video.commentsCount),
                  onTap: () => CommentsBottomSheet.show(context, widget.video),
                ),
                const SizedBox(height: 18),

                // Bookmark / Save Button
                _buildActionButton(
                  icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _isSaved ? AppColors.accent : Colors.white,
                  label: _formatCount(_savesCount),
                  onTap: () {
                    setState(() {
                      _isSaved = !_isSaved;
                      _savesCount += _isSaved ? 1 : -1;
                    });
                    widget.onSaveToggle?.call();
                  },
                ),
                const SizedBox(height: 18),

                // Share Button
                _buildActionButton(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  label: 'Share',
                  onTap: () => ShareBottomSheet.show(context, widget.video),
                ),
                const SizedBox(height: 22),

                // Rotating Vinyl Disc
                _buildRotatingDisc(),
              ],
            ),
          ),

          // Bottom Left Content Details
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Username & Verified badge
                Row(
                  children: [
                    Text(
                      '@${widget.video.creatorUsername}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: AppColors.secondary, size: 16),
                  ],
                ),
                const SizedBox(height: 6),

                // Caption
                if (widget.video.caption != null)
                  Text(
                    widget.video.caption!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.3,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // Hashtags
                if (widget.video.hashtags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.video.hashtags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                const SizedBox(height: 10),

                // Audio Info Marquee
                Row(
                  children: [
                    const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.video.audioTitle ?? 'Original Sound - @${widget.video.creatorUsername}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Seek Progress Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildProgressBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_hasError) {
      return Container(
        color: AppColors.background,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Unable to play video',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check network connection or try again.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceVariant,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() => _hasError = false);
                _initializeVideo();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tap to Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final isBuffering = _controller!.value.isBuffering;

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
        if (isBuffering)
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
      ],
    );
  }

  Widget _buildAvatarWidget() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: widget.video.creatorAvatarUrl != null
                ? NetworkImage(widget.video.creatorAvatarUrl!)
                : null,
            onBackgroundImageError: widget.video.creatorAvatarUrl != null ? (_, __) {} : null,
            child: Text(widget.video.creatorUsername.substring(0, 1).toUpperCase()),
          ),
        ),
        Positioned(
          bottom: -8,
          left: 16,
          child: GestureDetector(
            onTap: () {
              setState(() => _isFollowing = !_isFollowing);
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _isFollowing ? Colors.grey : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFollowing ? Icons.check : Icons.add,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingDisc() {
    return RotationTransition(
      turns: _discAnimationController,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.cardBackground,
          child: Icon(Icons.music_note_rounded, color: AppColors.accent, size: 18),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (_controller == null || !_isInitialized) {
      return const SizedBox.shrink();
    }

    final duration = _controller!.value.duration.inMilliseconds;
    final position = _controller!.value.position.inMilliseconds;
    final progress = duration > 0 ? (position / duration).clamp(0.0, 1.0) : 0.0;

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.white24,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 2.5,
    );
  }
}
