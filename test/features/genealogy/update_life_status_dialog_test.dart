import 'package:familyfund_app/features/genealogy/data/models/branch_models.dart';
import 'package:familyfund_app/features/genealogy/data/repositories/genealogy_repository_impl.dart';
import 'package:familyfund_app/features/genealogy/domain/entities/family_branch.dart';
import 'package:familyfund_app/features/genealogy/domain/repositories/genealogy_repository.dart';
import 'package:familyfund_app/features/genealogy/presentation/widgets/update_life_status_dialog.dart';
import 'package:familyfund_app/features/genealogy/data/models/privacy_setting_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGenealogyRepository implements GenealogyRepository {
  UpdateLifeStatusRequestDto? lastRequest;
  String? lastMemberId;

  @override
  Future<void> updateLifeStatus({
    required String memberId,
    required UpdateLifeStatusRequestDto request,
  }) async {
    lastMemberId = memberId;
    lastRequest = request;
  }

  @override
  Future<FamilyBranchDetail> getRootBranch() => throw UnimplementedError();

  @override
  Future<FamilyBranchDetail> updateRootBranch(UpdateRootBranchRequestDto request) =>
      throw UnimplementedError();

  @override
  Future<BranchTreeNodeDto> getBranchTree() => throw UnimplementedError();

  @override
  Future<List<BranchMemberItem>> getBranchMembers(String branchId) async => [];

  @override
  Future<List<BranchMemberItem>> getClanMembers() async => [];

  @override
  Future<MemberPrivacySettingDto> getMyPrivacySettings() => throw UnimplementedError();

  @override
  Future<MemberPrivacySettingDto> updateMyPrivacySettings(
          UpdateMemberPrivacySettingRequestDto request) =>
      throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('US-27: UpdateLifeStatusDialog Widget Tests', () {
    late FakeGenealogyRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeGenealogyRepository();
    });

    Widget createTestWidget(BranchMemberItem member) {
      return ProviderScope(
        overrides: [
          genealogyRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: UpdateLifeStatusDialog(
              member: member,
              branchId: 'BR_01',
            ),
          ),
        ),
      );
    }

    testWidgets('Renders member information and life status switches',
        (WidgetTester tester) async {
      final testMember = BranchMemberItem(
        memberId: 'MEM_001',
        fullName: 'Nguyễn Văn An',
        generation: 3,
        roleInBranch: 'Đời 3',
        status: 'Living',
        dateOfBirth: DateTime(1950, 5, 20),
      );

      await tester.pumpWidget(createTestWidget(testMember));
      await tester.pumpAndSettle();

      expect(find.text('Ghi Nhận Tình Trạng Sinh / Tử'), findsOneWidget);
      expect(find.text('Nguyễn Văn An • Đời 3'), findsOneWidget);
      expect(find.text('Còn Sống'), findsOneWidget);
      expect(find.text('Đã Mất'), findsOneWidget);
      expect(find.text('Lưu Cập Nhật'), findsOneWidget);
    });

    testWidgets('Switching to Đã Mất displays death date picker, lunar live preview, and age',
        (WidgetTester tester) async {
      final testMember = BranchMemberItem(
        memberId: 'MEM_001',
        fullName: 'Nguyễn Văn An',
        generation: 3,
        roleInBranch: 'Đời 3',
        status: 'Living',
        dateOfBirth: DateTime(1950, 5, 20),
      );

      await tester.pumpWidget(createTestWidget(testMember));
      await tester.pumpAndSettle();

      // Bấm vào tab "Đã Mất"
      final daMatButton = find.text('Đã Mất');
      await tester.tap(daMatButton);
      await tester.pumpAndSettle();

      // Phải hiển thị trường chọn ngày mất và xem trước ngày giỗ âm lịch
      expect(find.text('Ngày mất (Dương lịch) *'), findsOneWidget);
      expect(find.text('Ngày Giỗ Tự Động (Âm Lịch):'), findsOneWidget);
      expect(find.text('Nơi an táng / Phần mộ (Tùy chọn)'), findsOneWidget);
      expect(find.textContaining('Hưởng thọ:'), findsOneWidget);
      expect(
        find.textContaining('Chính sách phả hệ: Nút thành viên trên cây gia phả'),
        findsOneWidget,
      );
    });

    testWidgets('Submitting Deceased status calls repository with correct payload',
        (WidgetTester tester) async {
      final testMember = BranchMemberItem(
        memberId: 'MEM_001',
        fullName: 'Nguyễn Văn An',
        generation: 3,
        roleInBranch: 'Đời 3',
        status: 'Deceased',
        dateOfBirth: DateTime(1950, 5, 20),
        deathDate: DateTime(2024, 3, 24),
        deathDateLunar: '15/02 Giáp Thìn',
      );

      await tester.pumpWidget(createTestWidget(testMember));
      await tester.pumpAndSettle();

      // Nhập nơi an táng
      final burialField = find.widgetWithText(
          TextFormField, 'Nơi an táng / Phần mộ (Tùy chọn)');
      expect(burialField, findsOneWidget);
      await tester.enterText(burialField, 'Khu lăng mộ tổ họ Nguyễn');

      // Bấm Lưu Cập Nhật
      final saveBtn = find.text('Lưu Cập Nhật');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastMemberId, 'MEM_001');
      expect(fakeRepo.lastRequest?.status, 'Deceased');
      expect(fakeRepo.lastRequest?.burialPlace, 'Khu lăng mộ tổ họ Nguyễn');
    });

    testWidgets('Submitting Living status resets death fields and calls repository',
        (WidgetTester tester) async {
      final deceasedMember = BranchMemberItem(
        memberId: 'MEM_002',
        fullName: 'Nguyễn Thị Hoa',
        generation: 4,
        roleInBranch: 'Đời 4',
        status: 'Deceased',
        deathDate: DateTime(2023, 1, 1),
      );

      await tester.pumpWidget(createTestWidget(deceasedMember));
      await tester.pumpAndSettle();

      // Bấm chuyển về "Còn Sống"
      final conSongBtn = find.text('Còn Sống');
      await tester.tap(conSongBtn);
      await tester.pumpAndSettle();

      // Bấm Lưu
      final saveBtn = find.text('Lưu Cập Nhật');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.lastMemberId, 'MEM_002');
      expect(fakeRepo.lastRequest?.status, 'Living');
      expect(fakeRepo.lastRequest?.deathDate, isNull);
      expect(fakeRepo.lastRequest?.burialPlace, isNull);
    });
  });
}
