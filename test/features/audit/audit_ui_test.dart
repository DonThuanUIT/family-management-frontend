import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:familyfund_app/features/audit/data/models/audit_log_models.dart';
import 'package:familyfund_app/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:familyfund_app/features/audit/domain/repositories/audit_repository.dart';
import 'package:familyfund_app/features/audit/presentation/screens/system_audit_log_screen.dart';
import 'package:familyfund_app/features/audit/presentation/widgets/diff_viewer_dialog.dart';

class MockAuditRepository implements AuditRepository {
  @override
  Future<AuditLogPageResponse> getAuditLogs(AuditLogFilter filter) async {
    return AuditLogPageResponse(
      items: [
        AuditLogItemModel(
          auditId: 'AUD_01HZX87K91',
          actionType: 'ROLE_ASSIGN',
          entityType: 'ROLE',
          entityId: 'BR_02',
          actorAccountId: 'ACC_01',
          actorFullName: 'Nguyễn Văn Trưởng',
          description: 'Bổ nhiệm Nguyễn Văn Hùng làm Trưởng Chi 2',
          createdAt: DateTime(2026, 11, 5, 9, 30),
          hasDiff: true,
        ),
      ],
      page: 0,
      size: 20,
      totalElements: 128,
      totalPages: 7,
    );
  }

  @override
  Future<AuditLogDetailModel> getAuditLogDetail(String auditId) async {
    return AuditLogDetailModel(
      auditId: auditId,
      actionType: 'ROLE_ASSIGN',
      entityType: 'ROLE',
      entityId: 'BR_02',
      actorAccountId: 'ACC_01',
      actorFullName: 'Nguyễn Văn Trưởng',
      targetMemberFullName: 'Nguyễn Văn Hùng',
      description: 'Bổ nhiệm Trưởng Chi 2',
      oldValue: {'roleCode': 'MEMBER'},
      newValue: {'roleCode': 'ROLE_BRANCH_HEAD'},
      createdAt: DateTime(2026, 11, 5, 9, 30),
    );
  }
}

void main() {
  group('System Audit Log UI Tests', () {
    testWidgets('Renders SystemAuditLogScreen in Desktop mode with Data Table', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          ],
          child: const MaterialApp(
            home: SystemAuditLogScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check header and titles
      expect(find.text('Nhật Ký Thao Tác Quan Trọng'), findsOneWidget);
      expect(find.text('Bộ Lọc & Tìm Kiếm Nhật Ký'), findsOneWidget);

      // Check Stat Cards
      expect(find.text('TỔNG THAO TÁC'), findsOneWidget);
      expect(find.text('PHÂN QUYỀN / THU HỒI'), findsOneWidget);
      expect(find.text('DUYỆT GIA NHẬP'), findsOneWidget);
      expect(find.text('BIẾN ĐỘNG CÂY GIA PHẢ'), findsOneWidget);

      // Check Quick Category Pills
      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Phân quyền & Thu hồi'), findsOneWidget);

      // Check Table headers on Desktop
      expect(find.text('THỜI ĐIỂM'), findsOneWidget);
      expect(find.text('NGƯỜI THỰC HIỆN'), findsOneWidget);
      expect(find.text('HÀNH ĐỘNG'), findsOneWidget);
      expect(find.text('ĐỐI TƯỢNG'), findsOneWidget);
      expect(find.text('NỘI DUNG TÓM TẮT'), findsOneWidget);
    });

    testWidgets('Renders SystemAuditLogScreen in Mobile mode (390x844)', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          ],
          child: const MaterialApp(
            home: SystemAuditLogScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Header remains visible
      expect(find.text('Nhật Ký Thao Tác Quan Trọng'), findsOneWidget);
      expect(find.text('Bộ Lọc & Tìm Kiếm Nhật Ký'), findsOneWidget);

      // Stat cards are rendered
      expect(find.text('TỔNG THAO TÁC'), findsOneWidget);
      expect(find.text('PHÂN QUYỀN / THU HỒI'), findsOneWidget);

      // Desktop table headers are NOT shown on mobile
      expect(find.text('THỜI ĐIỂM'), findsNothing);
      expect(find.text('NỘI DUNG TÓM TẮT'), findsNothing);

      // Mobile cards have full-width button
      expect(find.text('Xem So Sánh Chi Tiết (Diff)'), findsOneWidget);
    });

    testWidgets('Opens DiffViewerDialog on tap and switches between Visual and Raw JSON tabs', (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiffViewerDialog(
                auditId: 'AUD_01HZX87K91',
                isDesktop: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check dialog elements
      expect(find.text('So Sánh Trực Quan'), findsOneWidget);
      expect(find.text('{ } Dữ Liệu Gốc (Raw JSON)'), findsOneWidget);
      expect(find.text('Bản ghi kiểm toán bất biến (Audit Immutability) • Chống giả mạo'), findsOneWidget);
      expect(find.text('Đóng cửa sổ'), findsOneWidget);

      // Switch to Raw JSON tab
      await tester.tap(find.text('{ } Dữ Liệu Gốc (Raw JSON)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('DỮ LIỆU CŨ (old_value JSON)'), findsOneWidget);
      expect(find.text('DỮ LIỆU MỚI (new_value JSON)'), findsOneWidget);
    });

    testWidgets('Renders DiffViewerDialog in Mobile Bottom Sheet mode (390x844)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiffViewerDialog(
                auditId: 'AUD_01HZX87K91',
                isDesktop: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Visual diff is rendered on mobile
      expect(find.text('So Sánh Trực Quan'), findsOneWidget);
      expect(find.text('{ } Dữ Liệu Gốc (Raw JSON)'), findsOneWidget);
      expect(find.text('Bản ghi kiểm toán bất biến (Audit Immutability)'), findsOneWidget);
      expect(find.text('Đóng cửa sổ'), findsOneWidget);

      // Switch to Raw JSON on mobile
      await tester.ensureVisible(find.text('{ } Dữ Liệu Gốc (Raw JSON)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('{ } Dữ Liệu Gốc (Raw JSON)'));
      await tester.pumpAndSettle();

      expect(find.text('DỮ LIỆU CŨ (old_value JSON)'), findsOneWidget);
      expect(find.text('DỮ LIỆU MỚI (new_value JSON)'), findsOneWidget);
    });

    testWidgets('Search input and quick category chips update audit filter', (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          ],
          child: const MaterialApp(
            home: SystemAuditLogScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search keyword
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Nguyễn Văn Hùng');
      await tester.pump();

      expect(find.text('Nguyễn Văn Hùng'), findsWidgets);

      // Tap on a category chip
      final roleChip = find.text('Phân quyền & Thu hồi');
      expect(roleChip, findsOneWidget);
      await tester.tap(roleChip);
      await tester.pump();

      // Tap reset filter button
      final resetButton = find.text('Đặt lại bộ lọc');
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pump();

      // Search field is cleared
      final fieldWidget = tester.widget<TextField>(searchField);
      expect(fieldWidget.controller?.text, isEmpty);
    });

    testWidgets('Tapping on interactive demo pill opens DiffViewerDialog', (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auditRepositoryProvider.overrideWithValue(MockAuditRepository()),
          ],
          child: const MaterialApp(
            home: SystemAuditLogScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Demo 1 Pill
      final demo1Pill = find.text('1. Phân quyền Trưởng chi');
      expect(demo1Pill, findsOneWidget);
      await tester.tap(demo1Pill);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog opens
      expect(find.byType(DiffViewerDialog), findsOneWidget);
      expect(find.text('So Sánh Trực Quan'), findsOneWidget);

      // Tap close button in dialog
      final closeBtn = find.text('Đóng cửa sổ');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Dialog is dismissed
      expect(find.byType(DiffViewerDialog), findsNothing);
    });
  });
}
