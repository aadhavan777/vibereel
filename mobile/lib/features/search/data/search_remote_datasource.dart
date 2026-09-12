import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class SearchRemoteDataSource {
  final ApiClient _apiClient;

  SearchRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<Map<String, dynamic>> search(String query, {String type = 'all', int page = 1}) async {
    final path = '${ApiEndpoints.search}?q=${Uri.encodeComponent(query)}&type=$type&page=$page';
    final response = await _apiClient.get(path);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> getTrendingSearches() async {
    final response = await _apiClient.get(ApiEndpoints.trendingSearches);
    final list = response as List;
    return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
