import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/privacy_setting_models.dart';
import '../../data/repositories/genealogy_repository_impl.dart';

/// Trạng thái quản lý quyền riêng tư cá nhân của thành viên (US-25).
class MemberPrivacyState {
  final MemberPrivacySettingDto? savedSettings;
  final bool draftShareDateOfBirth;
  final bool draftSharePhoneNumber;
  final bool draftShareEmail;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const MemberPrivacyState({
    this.savedSettings,
    this.draftShareDateOfBirth = false,
    this.draftSharePhoneNumber = false,
    this.draftShareEmail = false,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasChanges {
    if (savedSettings == null) return false;
    return draftShareDateOfBirth != savedSettings!.shareDateOfBirth ||
        draftSharePhoneNumber != savedSettings!.sharePhoneNumber ||
        draftShareEmail != savedSettings!.shareEmail;
  }

  MemberPrivacyState copyWith({
    MemberPrivacySettingDto? savedSettings,
    bool? draftShareDateOfBirth,
    bool? draftSharePhoneNumber,
    bool? draftShareEmail,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return MemberPrivacyState(
      savedSettings: savedSettings ?? this.savedSettings,
      draftShareDateOfBirth: draftShareDateOfBirth ?? this.draftShareDateOfBirth,
      draftSharePhoneNumber: draftSharePhoneNumber ?? this.draftSharePhoneNumber,
      draftShareEmail: draftShareEmail ?? this.draftShareEmail,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class MemberPrivacyNotifier extends Notifier<MemberPrivacyState> {
  @override
  MemberPrivacyState build() {
    // Tự động tải cài đặt khi khởi tạo provider
    Future.microtask(() => loadSettings());
    return const MemberPrivacyState(isLoading: true);
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final repository = ref.read(genealogyRepositoryProvider);
      final settings = await repository.getMyPrivacySettings();
      state = state.copyWith(
        isLoading: false,
        savedSettings: settings,
        draftShareDateOfBirth: settings.shareDateOfBirth,
        draftSharePhoneNumber: settings.sharePhoneNumber,
        draftShareEmail: settings.shareEmail,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void toggleShareDateOfBirth(bool val) {
    state = state.copyWith(draftShareDateOfBirth: val, clearSuccess: true);
  }

  void toggleSharePhoneNumber(bool val) {
    state = state.copyWith(draftSharePhoneNumber: val, clearSuccess: true);
  }

  void toggleShareEmail(bool val) {
    state = state.copyWith(draftShareEmail: val, clearSuccess: true);
  }

  void resetChanges() {
    if (state.savedSettings == null) return;
    state = state.copyWith(
      draftShareDateOfBirth: state.savedSettings!.shareDateOfBirth,
      draftSharePhoneNumber: state.savedSettings!.sharePhoneNumber,
      draftShareEmail: state.savedSettings!.shareEmail,
      clearError: true,
      clearSuccess: true,
    );
  }

  Future<bool> saveSettings() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final repository = ref.read(genealogyRepositoryProvider);
      final request = UpdateMemberPrivacySettingRequestDto(
        shareDateOfBirth: state.draftShareDateOfBirth,
        sharePhoneNumber: state.draftSharePhoneNumber,
        shareEmail: state.draftShareEmail,
      );
      final updated = await repository.updateMyPrivacySettings(request);
      state = state.copyWith(
        isSaving: false,
        savedSettings: updated,
        draftShareDateOfBirth: updated.shareDateOfBirth,
        draftSharePhoneNumber: updated.sharePhoneNumber,
        draftShareEmail: updated.shareEmail,
        successMessage: 'Đã lưu cấu hình quyền riêng tư thành công.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final memberPrivacyProvider =
    NotifierProvider<MemberPrivacyNotifier, MemberPrivacyState>(
  MemberPrivacyNotifier.new,
);
