import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final FlutterSecureStorage _storage;

  static const String refreshTokenKey = 'vibe_refresh_token';

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: refreshTokenKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
