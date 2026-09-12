import '../../domain/entities/user_entity.dart';

class UserDto {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final bool isCreator;

  UserDto({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    required this.isCreator,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isCreator: json['is_creator'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'is_creator': isCreator,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      bio: bio,
      avatarUrl: avatarUrl,
      isCreator: isCreator,
    );
  }
}
