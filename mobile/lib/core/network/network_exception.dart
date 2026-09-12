class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException({required this.message, this.statusCode});

  @override
  String toString() => 'NetworkException: $message (code: $statusCode)';
}
