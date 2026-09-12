import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class FileStorageService {
  Future<String> uploadVideoFile(String filePath);
  Future<String> uploadThumbnailFile(String filePath);
}

class MockFileStorageService implements FileStorageService {
  @override
  Future<String> uploadVideoFile(String filePath) async {
    // Simulates media upload, returning public URL
    await Future.delayed(const Duration(milliseconds: 600));
    if (filePath.contains('mixkit') || filePath.startsWith('http')) {
      return filePath;
    }
    return 'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4';
  }

  @override
  Future<String> uploadThumbnailFile(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (filePath.startsWith('http')) {
      return filePath;
    }
    return 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600';
  }
}

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return MockFileStorageService();
});
