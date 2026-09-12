import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiClient(storageService: storageService);
});

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDatasource(apiClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDatasource = ref.watch(authRemoteDatasourceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepositoryImpl(remoteDatasource, storageService);
});

class AuthState {
  final bool isLoading;
  final UserEntity? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    UserEntity? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(AuthState());

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.login(username, password);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(
    String email,
    String username,
    String password,
    String? fullName,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.register(email, username, password, fullName);
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState();
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
});
