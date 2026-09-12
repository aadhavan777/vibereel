import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String username, String password);
  Future<UserEntity> register(String email, String username, String password, String? fullName);
  Future<UserEntity?> getCurrentUser();
  Future<void> logout();
}
