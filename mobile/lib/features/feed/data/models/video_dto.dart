import 'dart:io';
import '../../domain/entities/video_entity.dart';

class VideoDto {
  final String id;
  final String creatorId;
  final String creatorUsername;
  final String? creatorAvatarUrl;
  final String? caption;
  final String videoUrl;
  final String? thumbnailUrl;
  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final bool isLiked;
  final bool isSaved;
  final String? audioTitle;
  final String? audioArtist;
  final List<String> hashtags;

  VideoDto({
    required this.id,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorAvatarUrl,
    this.caption,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.savesCount,
    this.isLiked = false,
    this.isSaved = false,
    this.audioTitle,
    this.audioArtist,
    this.hashtags = const [],
  });

  factory VideoDto.fromJson(Map<String, dynamic> json) {
    final creatorMap = json['creator'] as Map<String, dynamic>?;

    String rawVideoUrl = json['video_url'] as String;
    String? rawThumbnailUrl = json['thumbnail_url'] as String?;

    if (Platform.isAndroid) {
      rawVideoUrl = rawVideoUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
      if (rawThumbnailUrl != null) {
        rawThumbnailUrl = rawThumbnailUrl.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
      }
    }

    return VideoDto(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      creatorUsername: json['creator_username'] as String? ?? creatorMap?['username'] as String? ?? 'vibemaster',
      creatorAvatarUrl: json['creator_avatar_url'] as String? ?? creatorMap?['avatar_url'] as String?,
      caption: json['caption'] as String?,
      videoUrl: rawVideoUrl,
      thumbnailUrl: rawThumbnailUrl,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      savesCount: json['saves_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isSaved: json['is_saved'] as bool? ?? false,
      audioTitle: json['audio_title'] as String?,
      audioArtist: json['audio_artist'] as String?,
      hashtags: (json['hashtags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  VideoEntity toEntity() {
    return VideoEntity(
      id: id,
      creatorId: creatorId,
      creatorUsername: creatorUsername,
      creatorAvatarUrl: creatorAvatarUrl,
      caption: caption,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      likesCount: likesCount,
      commentsCount: commentsCount,
      savesCount: savesCount,
      isLiked: isLiked,
      isSaved: isSaved,
      audioTitle: audioTitle,
      audioArtist: audioArtist,
      hashtags: hashtags,
    );
  }
}
