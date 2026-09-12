import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ProfileState {
  final bool isLoading;
  final UserEntity? user;
  final String? error;

  ProfileState({this.isLoading = false, this.user, this.error});
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel() : super(ProfileState());
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel();
});
