import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member_import_models.dart';
import '../../data/repositories/genealogy_repository_impl.dart';
import '../../domain/repositories/genealogy_repository.dart';
import 'genealogy_providers.dart';

enum MemberImportFilterMode { all, validOnly, errorOnly }

class MemberImportState {
  final bool isDownloadingTemplate;
  final bool isUploadingPreview;
  final bool isConfirming;
  final String? selectedFileName;
  final int? selectedFileSizeBytes;
  final ImportMembersPreviewResponseDto? preview;
  final ImportMembersConfirmResponseDto? confirmResult;
  final MemberImportFilterMode filterMode;
  final String? errorMessage;

  const MemberImportState({
    this.isDownloadingTemplate = false,
    this.isUploadingPreview = false,
    this.isConfirming = false,
    this.selectedFileName,
    this.selectedFileSizeBytes,
    this.preview,
    this.confirmResult,
    this.filterMode = MemberImportFilterMode.all,
    this.errorMessage,
  });

  List<ImportMemberPreviewRowDto> get filteredRows {
    final rows = preview?.rows ?? const [];
    return switch (filterMode) {
      MemberImportFilterMode.all => rows,
      MemberImportFilterMode.validOnly => rows.where((r) => r.valid).toList(),
      MemberImportFilterMode.errorOnly => rows.where((r) => !r.valid).toList(),
    };
  }

  MemberImportState copyWith({
    bool? isDownloadingTemplate,
    bool? isUploadingPreview,
    bool? isConfirming,
    String? selectedFileName,
    int? selectedFileSizeBytes,
    ImportMembersPreviewResponseDto? preview,
    bool clearPreview = false,
    ImportMembersConfirmResponseDto? confirmResult,
    bool clearConfirmResult = false,
    MemberImportFilterMode? filterMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MemberImportState(
      isDownloadingTemplate: isDownloadingTemplate ?? this.isDownloadingTemplate,
      isUploadingPreview: isUploadingPreview ?? this.isUploadingPreview,
      isConfirming: isConfirming ?? this.isConfirming,
      selectedFileName: selectedFileName ?? this.selectedFileName,
      selectedFileSizeBytes: selectedFileSizeBytes ?? this.selectedFileSizeBytes,
      preview: clearPreview ? null : (preview ?? this.preview),
      confirmResult: clearConfirmResult ? null : (confirmResult ?? this.confirmResult),
      filterMode: filterMode ?? this.filterMode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class MemberImportNotifier extends Notifier<MemberImportState> {
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  GenealogyRepository get _repository => ref.read(genealogyRepositoryProvider);

  @override
  MemberImportState build() => const MemberImportState();

  Future<Uint8List?> downloadTemplateBytes() async {
    state = state.copyWith(isDownloadingTemplate: true, clearError: true);
    try {
      final bytes = await _repository.downloadImportTemplate();
      state = state.copyWith(isDownloadingTemplate: false);
      return bytes;
    } catch (e) {
      state = state.copyWith(
        isDownloadingTemplate: false,
        errorMessage: _cleanError(e),
      );
      return null;
    }
  }

  Future<void> uploadAndPreview({
    required Uint8List bytes,
    required String fileName,
    required int sizeBytes,
  }) async {
    if (sizeBytes <= 0) {
      state = state.copyWith(errorMessage: 'File được chọn không có dữ liệu.');
      return;
    }
    if (sizeBytes > maxFileSizeBytes) {
      state = state.copyWith(
        errorMessage: 'Dung lượng file vượt quá giới hạn tối đa 5 MB.',
      );
      return;
    }

    state = state.copyWith(
      isUploadingPreview: true,
      selectedFileName: fileName,
      selectedFileSizeBytes: sizeBytes,
      clearPreview: true,
      clearConfirmResult: true,
      filterMode: MemberImportFilterMode.all,
      clearError: true,
    );

    try {
      final result = await _repository.previewMemberImport(
        bytes: bytes,
        fileName: fileName,
      );
      state = state.copyWith(
        isUploadingPreview: false,
        preview: result,
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingPreview: false,
        errorMessage: _cleanError(e),
      );
    }
  }

  Future<bool> confirmValidRows() async {
    final preview = state.preview;
    if (preview == null) return false;

    final validRows = preview.rows
        .where((row) => row.valid)
        .map((row) => row.toConfirmRowRequest())
        .toList();

    if (validRows.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Không có dòng hợp lệ nào để xác nhận nhập.',
      );
      return false;
    }

    state = state.copyWith(isConfirming: true, clearError: true);
    try {
      final result = await _repository.confirmMemberImport(
        ConfirmMemberImportRequestDto(rows: validRows),
      );
      state = state.copyWith(
        isConfirming: false,
        confirmResult: result,
      );

      if (result.insertedCount > 0) {
        ref.invalidate(branchTreeProvider);
        ref.invalidate(clanMembersProvider);
        ref.invalidate(genealogyMemberListProvider);
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isConfirming: false,
        errorMessage: _cleanError(e),
      );
      return false;
    }
  }

  void setFilterMode(MemberImportFilterMode mode) {
    state = state.copyWith(filterMode: mode);
  }

  void reset() {
    state = const MemberImportState();
  }

  static String _cleanError(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}

final memberImportProvider =
    NotifierProvider<MemberImportNotifier, MemberImportState>(
  MemberImportNotifier.new,
);
