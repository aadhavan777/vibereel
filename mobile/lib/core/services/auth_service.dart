import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class AuthService {
  final StorageService _storageService;

  AuthService(this._storageService);

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(storageService);
});
