import 'package:flutter_riverpod/flutter_riverpod.dart';

class UploadState {
  final bool isUploading;
  final String? error;

  UploadState({this.isUploading = false, this.error});
}

class UploadViewModel extends StateNotifier<UploadState> {
  UploadViewModel() : super(UploadState());
}

final uploadViewModelProvider = StateNotifierProvider<UploadViewModel, UploadState>((ref) {
  return UploadViewModel();
});
