import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import 'storage_service.dart';

class VideoUploadService {
  final DioClient _dioClient;

  VideoUploadService(this._dioClient);

  String _getFilename(String filePath) {
    return filePath.split(RegExp(r'[/\\]')).last;
  }

  Future<Map<String, dynamic>> uploadVideoFile({
    required String videoPath,
    String? thumbnailPath,
    String? caption,
    bool isDraft = false,
    void Function(int sentBytes, int totalBytes)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final Map<String, dynamic> map = {
      'caption': caption ?? '',
      'is_draft': isDraft.toString(),
    };

    if (videoPath.isNotEmpty && File(videoPath).existsSync()) {
      map['file'] = await MultipartFile.fromFile(
        videoPath,
        filename: _getFilename(videoPath),
      );
    }

    if (thumbnailPath != null && thumbnailPath.isNotEmpty && File(thumbnailPath).existsSync()) {
      map['thumbnail_file'] = await MultipartFile.fromFile(
        thumbnailPath,
        filename: _getFilename(thumbnailPath),
      );
    }

    final formData = FormData.fromMap(map);

    try {
      final response = await _dioClient.dio.post(
        '/videos/upload-file',
        data: formData,
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'success'};
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Upload cancelled by user');
      }
      final msg = e.response?.data is Map ? e.response?.data['detail'] : e.message;
      throw Exception(msg ?? 'Failed to upload video');
    }
  }
}

final dioClientProvider = Provider<DioClient>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return DioClient(storageService);
});

final videoUploadServiceProvider = Provider<VideoUploadService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return VideoUploadService(dioClient);
});
