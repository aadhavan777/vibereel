import 'package:flutter_test/flutter_test.dart';
import 'package:vibereel/core/network/dio_client.dart';
import 'package:vibereel/core/services/file_storage_service.dart';
import 'package:vibereel/core/services/storage_service.dart';
import 'package:vibereel/core/services/video_upload_service.dart';
import 'package:vibereel/features/create/data/datasources/create_remote_datasource.dart';
import 'package:vibereel/features/create/presentation/viewmodels/create_viewmodel.dart';

class MockUploadDatasource implements CreateRemoteDatasource {
  @override
  Future<Map<String, dynamic>> createVideo({
    required String videoUrl,
    String? thumbnailUrl,
    String? caption,
    List<String> hashtags = const [],
    bool isDraft = false,
  }) async {
    return {'id': 'mock_id', 'video_url': videoUrl};
  }

  @override
  Future<Map<String, dynamic>> updateVideo({
    required String videoId,
    String? caption,
    String? thumbnailUrl,
    bool isDraft = false,
  }) async {
    return {'id': videoId};
  }
}

class MockStorageServiceForTest implements StorageService {
  @override
  Future<void> clearAll() async {}
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> saveRefreshToken(String token) async {}
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> deleteRefreshToken() async {}
  @override
  Future<void> deleteToken() async {}
}

void main() {
  test('CreateViewModel handles submission and upload progress state', () async {
    final mockStorage = MockFileStorageService();
    final mockRemote = MockUploadDatasource();
    final mockStorageService = MockStorageServiceForTest();
    final mockDioClient = DioClient(mockStorageService);
    final uploadService = VideoUploadService(mockDioClient);

    final viewModel = CreateViewModel(
      mockStorage,
      uploadService,
      mockRemote,
    );

    viewModel.selectMediaSource('camera');
    expect(viewModel.state.currentStep, equals(1));

    viewModel.nextStep();
    expect(viewModel.state.currentStep, equals(2));

    final future = viewModel.submitContent(saveAsDraft: false);
    expect(viewModel.state.isUploading, isTrue);

    await future;
    expect(viewModel.state.isUploading, isFalse);
    expect(viewModel.state.isSuccess, isTrue);
    expect(viewModel.state.currentStep, equals(3));
  });
}
