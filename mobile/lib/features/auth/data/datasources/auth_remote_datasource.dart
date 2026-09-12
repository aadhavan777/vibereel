import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_dto.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource(this._apiClient);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {
        'username': username,
        'password': password,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<UserDto> register(
    String email,
    String username,
    String password,
    String? fullName,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      body: {
        'email': email,
        'username': username,
        'password': password,
        'full_name': fullName,
      },
    );
    return UserDto.fromJson(response as Map<String, dynamic>);
  }

  Future<UserDto> getCurrentUser() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    return UserDto.fromJson(response as Map<String, dynamic>);
  }
}
