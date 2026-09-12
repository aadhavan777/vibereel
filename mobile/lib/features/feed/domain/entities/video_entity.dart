import 'package:equatable/equatable.dart';

class VideoEntity extends Equatable {
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

  const VideoEntity({
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

  VideoEntity copyWith({
    String? id,
    String? creatorId,
    String? creatorUsername,
    String? creatorAvatarUrl,
    String? caption,
    String? videoUrl,
    String? thumbnailUrl,
    int? likesCount,
    int? commentsCount,
    int? savesCount,
    bool? isLiked,
    bool? isSaved,
    String? audioTitle,
    String? audioArtist,
    List<String>? hashtags,
  }) {
    return VideoEntity(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      caption: caption ?? this.caption,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      savesCount: savesCount ?? this.savesCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      audioTitle: audioTitle ?? this.audioTitle,
      audioArtist: audioArtist ?? this.audioArtist,
      hashtags: hashtags ?? this.hashtags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        creatorId,
        creatorUsername,
        creatorAvatarUrl,
        caption,
        videoUrl,
        thumbnailUrl,
        likesCount,
        commentsCount,
        savesCount,
        isLiked,
        isSaved,
        audioTitle,
        audioArtist,
        hashtags,
      ];
}
