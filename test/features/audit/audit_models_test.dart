import 'package:flutter_test/flutter_test.dart';
import 'package:familyfund_app/features/audit/data/models/audit_log_models.dart';

void main() {
  group('Audit Log Models & Enums Tests', () {
    test('AuditCategory has 5 standard categories with Vietnamese labels', () {
      expect(AuditCategory.values.length, 5);
      expect(AuditCategory.all.code, 'ALL');
      expect(AuditCategory.assign.label, 'Phân quyền & Thu hồi');
      expect(AuditCategory.join.label, 'Duyệt đơn gia nhập');
      expect(AuditCategory.genealogy.label, 'Sửa Cây gia phả');
      expect(AuditCategory.event.label, 'Thay đổi sự kiện');
    });

    test('AuditLogItemModel parses JSON and maps display names and colors', () {
      final json = {
        'auditId': 'AUD_01HZX87K91',
        'actionType': 'ROLE_ASSIGN',
        'entityType': 'ROLE',
        'entityId': 'BR_02',
        'actorAccountId': 'ACC_01',
        'actorFullName': 'Nguyễn Văn Trưởng',
        'targetMemberId': 'MEM_08',
        'targetMemberFullName': 'Nguyễn Văn Hùng',
        'description': 'Bổ nhiệm Trưởng Chi 2',
        'ipAddress': '113.190.234.12',
        'createdAt': '2026-11-05T09:30:15Z',
        'hasDiff': true,
      };

      final model = AuditLogItemModel.fromJson(json);

      expect(model.auditId, 'AUD_01HZX87K91');
      expect(model.actionType, 'ROLE_ASSIGN');
      expect(model.actionDisplayName, 'PHÂN QUYỀN');
      expect(model.entityTypeDisplayName, 'VAI TRÒ');
      expect(model.hasDiff, true);
      expect(model.actorFullName, 'Nguyễn Văn Trưởng');
    });

    test('AuditLogDetailModel extracts and categorizes diff fields accurately', () {
      final detail = AuditLogDetailModel(
        auditId: 'AUD_01',
        actionType: 'ROLE_ASSIGN',
        entityType: 'ROLE',
        entityId: 'BR_02',
        oldValue: {
          'roleCode': 'MEMBER',
          'scopeId': 'BR_01',
        },
        newValue: {
          'roleCode': 'ROLE_BRANCH_HEAD',
          'scopeId': 'BR_01',
          'accountId': 'ACC_08',
        },
        createdAt: DateTime.now(),
      );

      final diffs = detail.diffFields;
      expect(diffs.length, 3);

      final roleDiff = diffs.firstWhere((d) => d.fieldKey == 'roleCode');
      expect(roleDiff.isModified, true);
      expect(roleDiff.oldValue, 'MEMBER');
      expect(roleDiff.newValue, 'ROLE_BRANCH_HEAD');

      final scopeDiff = diffs.firstWhere((d) => d.fieldKey == 'scopeId');
      expect(scopeDiff.isUnchanged, true);

      final accountDiff = diffs.firstWhere((d) => d.fieldKey == 'accountId');
      expect(accountDiff.isAdded, true);
      expect(accountDiff.oldValue, null);
      expect(accountDiff.newValue, 'ACC_08');
    });

    test('AuditLogPageResponse parses pagination attributes properly', () {
      final json = {
        'items': [
          {
            'auditId': 'AUD_01',
            'actionType': 'BRANCH_UPDATE',
            'entityType': 'GENEALOGY_BRANCH',
            'createdAt': '2026-11-05T06:40:02Z',
            'hasDiff': true,
          }
        ],
        'page': 1,
        'size': 10,
        'totalElements': 45,
        'totalPages': 5,
      };

      final page = AuditLogPageResponse.fromJson(json);
      expect(page.items.length, 1);
      expect(page.page, 1);
      expect(page.size, 10);
      expect(page.totalElements, 45);
      expect(page.totalPages, 5);
    });
  });
}
