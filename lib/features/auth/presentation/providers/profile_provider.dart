import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/models/profile_models.dart';

/// Trạng thái quản lý thông tin hồ sơ cá nhân và đổi mật khẩu (US-22).
class ProfileState {
  final UserProfileDto? profile;
  final bool isLoading;
  final bool isUpdatingContact;
  final bool isChangingPassword;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isUpdatingContact = false,
    this.isChangingPassword = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    UserProfileDto? profile,
    bool? isLoading,
    bool? isUpdatingContact,
    bool? isChangingPassword,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isUpdatingContact: isUpdatingContact ?? this.isUpdatingContact,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Tự động tải hồ sơ cá nhân khi khởi tạo
    Future.microtask(() => loadProfile());
    return const ProfileState(isLoading: true);
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final dataSource = ref.read(profileRemoteDataSourceProvider);
      final profile = await dataSource.getMyProfile();
      state = state.copyWith(
        isLoading: false,
        profile: profile,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> updateContactProfile({
    required String phoneNumber,
    String? email,
    String? address,
  }) async {
    state = state.copyWith(isUpdatingContact: true, clearError: true, clearSuccess: true);
    try {
      final dataSource = ref.read(profileRemoteDataSourceProvider);
      final request = UpdateContactProfileRequestDto(
        phoneNumber: phoneNumber,
        email: email,
        address: address,
      );
      final updated = await dataSource.updateContactProfile(request);
      state = state.copyWith(
        isUpdatingContact: false,
        profile: updated,
        successMessage: 'Cập nhật thông tin liên lạc thành công.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUpdatingContact: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isChangingPassword: true, clearError: true, clearSuccess: true);
    try {
      final dataSource = ref.read(profileRemoteDataSourceProvider);
      final request = ChangePasswordRequestDto(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      await dataSource.changePassword(request);
      state = state.copyWith(
        isChangingPassword: false,
        successMessage: 'Đổi mật khẩu tài khoản thành công.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isChangingPassword: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
