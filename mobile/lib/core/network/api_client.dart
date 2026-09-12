import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../services/storage_service.dart';
import 'network_exception.dart';

class ApiClient {
  final http.Client _client;
  final StorageService _storageService;

  ApiClient({
    http.Client? client,
    required StorageService storageService,
  })  : _client = client ?? http.Client(),
        _storageService = storageService;

  String get _baseUrl {
    if (Platform.isAndroid) {
      return ApiEndpoints.baseUrl;
    }
    return ApiEndpoints.iosBaseUrl;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _storageService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.get(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.post(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.put(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final headers = await _getHeaders();
      final response = await _client.delete(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
      );
      return _processResponse(response);
    } catch (e) {
      throw NetworkException(message: e.toString());
    }
  }


  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      String errorMsg = 'HTTP Error ${response.statusCode}';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('detail')) {
          errorMsg = decoded['detail'];
        }
      } catch (_) {}
      throw NetworkException(message: errorMsg, statusCode: response.statusCode);
    }
  }
}
