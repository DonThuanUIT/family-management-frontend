import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyfund_app/features/genealogy/data/models/branch_models.dart';
import 'package:familyfund_app/features/genealogy/data/models/member_import_models.dart';
import 'package:familyfund_app/features/genealogy/data/models/privacy_setting_models.dart';
import 'package:familyfund_app/features/genealogy/data/repositories/genealogy_repository_impl.dart';
import 'package:familyfund_app/features/genealogy/domain/entities/family_branch.dart';
import 'package:familyfund_app/features/genealogy/domain/repositories/genealogy_repository.dart';
import 'package:familyfund_app/features/genealogy/presentation/providers/member_import_provider.dart';
import 'package:familyfund_app/features/genealogy/presentation/screens/member_import_screen.dart';
import 'package:familyfund_app/features/genealogy/presentation/widgets/member_import_preview_table.dart';

class _FakeGenealogyRepository implements GenealogyRepository {
  bool confirmCalled = false;

  @override
  Future<ImportMembersConfirmResponseDto> confirmMemberImport(
    ConfirmMemberImportRequestDto request,
  ) async {
    confirmCalled = true;
    return ImportMembersConfirmResponseDto(
      insertedCount: request.rows.length,
      skippedCount: 0,
      skippedRows: const [],
    );
  }

  @override
  Future<Uint8List> downloadImportTemplate() async => Uint8List.fromList([1, 2, 3]);

  @override
  Future<ImportMembersPreviewResponseDto> previewMemberImport({
    required Uint8List bytes,
    required String fileName,
  }) async {
    return ImportMembersPreviewResponseDto(
      fileName: fileName,
      totalRows: 2,
      validCount: 1,
      errorCount: 1,
      rows: const [
        ImportMemberPreviewRowDto(
          rowNumber: 2,
          valid: true,
          errors: [],
          fullName: 'Nguyễn Văn Hợp Lệ',
          gender: 'Male',
          generation: 2,
          branchId: 'BR_01',
          status: 'Living',
        ),
        ImportMemberPreviewRowDto(
          rowNumber: 3,
          valid: false,
          errors: ['Thiếu mã nhánh (branch_id)', 'Sai định dạng ngày sinh'],
          fullName: 'Nguyễn Văn Lỗi',
          gender: 'Male',
          generation: 2,
          status: 'Living',
        ),
      ],
    );
  }

  @override
  Future<List<BranchMemberItem>> getBranchMembers(String branchId) async => const [];

  @override
  Future<BranchTreeNodeDto> getBranchTree() => throw UnimplementedError();

  @override
  Future<List<BranchMemberItem>> getClanMembers() async => const [];

  @override
  Future<MemberPrivacySettingDto> getMyPrivacySettings() => throw UnimplementedError();

  @override
  Future<FamilyBranchDetail> getRootBranch() => throw UnimplementedError();

  @override
  Future<void> updateLifeStatus({
    required String memberId,
    required UpdateLifeStatusRequestDto request,
  }) async {}

  @override
  Future<MemberPrivacySettingDto> updateMyPrivacySettings(
    UpdateMemberPrivacySettingRequestDto request,
  ) =>
      throw UnimplementedError();

  @override
  Future<FamilyBranchDetail> updateRootBranch(UpdateRootBranchRequestDto request) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('MemberImportPreviewTable tô đỏ dòng lỗi và hiển thị nguyên nhân', (tester) async {
    const rows = [
      ImportMemberPreviewRowDto(
        rowNumber: 2,
        valid: true,
        errors: [],
        fullName: 'Nguyễn Văn Hợp Lệ',
        gender: 'Male',
        generation: 2,
        branchId: 'BR_01',
        status: 'Living',
      ),
      ImportMemberPreviewRowDto(
        rowNumber: 3,
        valid: false,
        errors: ['Thiếu mã nhánh (branch_id)'],
        fullName: 'Nguyễn Văn Lỗi',
        gender: 'Female',
        generation: 2,
        status: 'Living',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MemberImportPreviewTable(rows: rows),
        ),
      ),
    );

    expect(find.text('Hợp lệ'), findsOneWidget);
    expect(find.text('Lỗi'), findsOneWidget);
    expect(find.text('• Thiếu mã nhánh (branch_id)'), findsOneWidget);

    final dataTable = tester.widget<DataTable>(find.byType(DataTable));
    final errorRowColor = dataTable.rows[1].color?.resolve(<WidgetState>{});
    expect(errorRowColor, Colors.red.shade50);
  });

  testWidgets('MemberImportScreen cho phép xác nhận nhập các dòng hợp lệ', (tester) async {
    final fakeRepo = _FakeGenealogyRepository();
    final container = ProviderContainer(
      overrides: [
        genealogyRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(memberImportProvider.notifier).uploadAndPreview(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'members.csv',
          sizeBytes: 3,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MemberImportScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final confirmButton = find.text('Xác nhận nhập các dòng hợp lệ (1)');
    expect(confirmButton, findsOneWidget);

    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(fakeRepo.confirmCalled, isTrue);
    expect(
      find.textContaining('Đã nhập thành công 1 thành viên vào cơ sở dữ liệu'),
      findsOneWidget,
    );
  });
}
