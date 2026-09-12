import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final bool isCreator;

  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    required this.isCreator,
  });

  @override
  List<Object?> get props => [id, email, username, fullName, bio, avatarUrl, isCreator];
}
