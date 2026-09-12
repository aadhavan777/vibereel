import 'search_remote_datasource.dart';

abstract class SearchRepository {
  Future<Map<String, dynamic>> search(String query, {String type, int page});
  Future<List<Map<String, dynamic>>> getTrendingSearches();
}

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remoteDataSource;

  SearchRepositoryImpl({required SearchRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<Map<String, dynamic>> search(String query, {String type = 'all', int page = 1}) {
    return _remoteDataSource.search(query, type: type, page: page);
  }

  @override
  Future<List<Map<String, dynamic>>> getTrendingSearches() {
    return _remoteDataSource.getTrendingSearches();
  }
}
