import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/models/position_link_models.dart';
import '../../data/repositories/position_link_repository_impl.dart';

@immutable
class ClaimPositionState {
  final String inviteCode;
  final PositionLinkPreviewDto? preview;
  final bool isLoadingPreview;
  final String? previewError;
  final bool isClaiming;
  final String? claimError;
  final ClaimPositionResponseDto? claimSuccess;

  const ClaimPositionState({
    this.inviteCode = '',
    this.preview,
    this.isLoadingPreview = false,
    this.previewError,
    this.isClaiming = false,
    this.claimError,
    this.claimSuccess,
  });

  bool get isValidCode => preview != null && previewError == null;

  ClaimPositionState copyWith({
    String? inviteCode,
    PositionLinkPreviewDto? preview,
    bool clearPreview = false,
    bool? isLoadingPreview,
    String? previewError,
    bool clearPreviewError = false,
    bool? isClaiming,
    String? claimError,
    bool clearClaimError = false,
    ClaimPositionResponseDto? claimSuccess,
    bool clearClaimSuccess = false,
  }) {
    return ClaimPositionState(
      inviteCode: inviteCode ?? this.inviteCode,
      preview: clearPreview ? null : (preview ?? this.preview),
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      previewError:
          clearPreviewError ? null : (previewError ?? this.previewError),
      isClaiming: isClaiming ?? this.isClaiming,
      claimError: clearClaimError ? null : (claimError ?? this.claimError),
      claimSuccess:
          clearClaimSuccess ? null : (claimSuccess ?? this.claimSuccess),
    );
  }
}

class ClaimPositionNotifier extends Notifier<ClaimPositionState> {
  Timer? _debounceTimer;

  @override
  ClaimPositionState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return const ClaimPositionState();
  }

  void onCodeChanged(String newCode) {
    final trimmed = newCode.trim().toUpperCase();
    if (trimmed == state.inviteCode) return;

    state = state.copyWith(
      inviteCode: trimmed,
      clearPreview: true,
      clearPreviewError: true,
      clearClaimError: true,
      clearClaimSuccess: true,
    );

    _debounceTimer?.cancel();
    if (trimmed.length >= 4) {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        lookupCode(trimmed);
      });
    }
  }

  Future<void> lookupCode([String? codeToLookup]) async {
    final code = (codeToLookup ?? state.inviteCode).trim().toUpperCase();
    if (code.isEmpty) {
      state = state.copyWith(
        clearPreview: true,
        previewError: 'Vui lòng nhập mã liên kết vị trí gia phả',
      );
      return;
    }

    state = state.copyWith(
      inviteCode: code,
      isLoadingPreview: true,
      clearPreviewError: true,
    );

    try {
      final repository = ref.read(positionLinkRepositoryProvider);
      final preview = await repository.getPositionLinkPreview(code);
      state = state.copyWith(
        isLoadingPreview: false,
        preview: preview,
        clearPreviewError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPreview: false,
        clearPreview: true,
        previewError: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> claim({
    String? inviteCode,
    required String phoneNumber,
    required String password,
    String? email,
  }) async {
    final code = (inviteCode ?? state.inviteCode).trim().toUpperCase();
    if (code.isEmpty) {
      state = state.copyWith(claimError: 'Thiếu mã liên kết vị trí');
      return false;
    }

    state = state.copyWith(
      inviteCode: code,
      isClaiming: true,
      clearClaimError: true,
    );

    try {
      final repository = ref.read(positionLinkRepositoryProvider);
      final response = await repository.claimPosition(
        inviteCode: code,
        request: ClaimPositionRequestDto(
          phoneNumber: phoneNumber.trim(),
          password: password,
          email: email?.trim(),
        ),
      );

      state = state.copyWith(
        isClaiming: false,
        claimSuccess: response,
        clearClaimError: true,
      );

      // Tự động đăng nhập vào hệ thống sau khi kích hoạt thành công (không chặn tiến trình nhận vị trí)
      unawaited(
        ref
            .read(authStateProvider.notifier)
            .login(phoneNumber.trim(), password)
            .catchError((_) {}),
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isClaiming: false,
        claimError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    _debounceTimer?.cancel();
    state = const ClaimPositionState();
  }
}

final claimPositionProvider =
    NotifierProvider<ClaimPositionNotifier, ClaimPositionState>(
  ClaimPositionNotifier.new,
);
