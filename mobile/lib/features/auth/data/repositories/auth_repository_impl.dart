import '../../../../core/services/storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final StorageService _storageService;

  AuthRepositoryImpl(this._remoteDatasource, this._storageService);

  @override
  Future<UserEntity> login(String username, String password) async {
    final response = await _remoteDatasource.login(username, password);
    final token = response['access_token'] as String;
    await _storageService.saveToken(token);
    final userDto = await _remoteDatasource.getCurrentUser();
    return userDto.toEntity();
  }

  @override
  Future<UserEntity> register(
    String email,
    String username,
    String password,
    String? fullName,
  ) async {
    final userDto = await _remoteDatasource.register(email, username, password, fullName);
    return userDto.toEntity();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final userDto = await _remoteDatasource.getCurrentUser();
      return userDto.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _storageService.clearAll();
  }
}
