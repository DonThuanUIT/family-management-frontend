import 'package:flutter_test/flutter_test.dart';
import 'package:familyfund_app/features/role/data/models/role_models.dart';

void main() {
  group('Role Models & Enums Unit Tests', () {
    test('AssignableRoleCode maps correctly and preserves scope and display name', () {
      expect(
        AssignableRoleCode.roleBranchHead.code,
        'ROLE_BRANCH_HEAD',
      );
      expect(
        AssignableRoleCode.roleBranchHead.supportedScope,
        RoleScopeType.branch,
      );
      expect(
        AssignableRoleCode.roleBranchHead.displayName,
        'Trưởng Chi / Nhánh',
      );

      expect(
        AssignableRoleCode.headOfOrganizer.code,
        'HeadOfOrganizer',
      );
      expect(
        AssignableRoleCode.headOfOrganizer.supportedScope,
        RoleScopeType.event,
      );

      expect(
        AssignableRoleCode.eventTreasurer.code,
        'EventTreasurer',
      );

      expect(
        AssignableRoleCode.organizerMember.code,
        'OrganizerMember',
      );

      // Case-insensitive lookup
      expect(
        AssignableRoleCode.fromCode('role_branch_head'),
        AssignableRoleCode.roleBranchHead,
      );
      expect(
        AssignableRoleCode.fromCode('EVENTTREASURER'),
        AssignableRoleCode.eventTreasurer,
      );
    });

    test('RoleScopeType parses properly', () {
      expect(RoleScopeType.fromCode('BRANCH'), RoleScopeType.branch);
      expect(RoleScopeType.fromCode('EVENT'), RoleScopeType.event);
      expect(RoleScopeType.fromCode('unknown'), RoleScopeType.branch);
    });

    test('BranchRoleOverviewModel parses JSON and computes hasRepresentative', () {
      final appointedJson = {
        'branchId': 'b1',
        'branchName': 'Chi 1',
        'generationLevel': 10,
        'representativeMemberId': 'MEM_01',
        'representativeFullName': 'Nguyễn Văn Bình',
        'representativeAccountId': 'ACC_01',
      };
      final appointed = BranchRoleOverviewModel.fromJson(appointedJson);
      expect(appointed.hasRepresentative, isTrue);
      expect(appointed.branchName, 'Chi 1');

      final vacantJson = {
        'branchId': 'b3',
        'branchName': 'Chi 3',
        'generationLevel': 11,
        'representativeMemberId': null,
        'representativeFullName': null,
        'representativeAccountId': null,
      };
      final vacant = BranchRoleOverviewModel.fromJson(vacantJson);
      expect(vacant.hasRepresentative, isFalse);
    });

    test('MemberRoleOptionModel parses active status correctly', () {
      final memberJson = {
        'memberId': 'MEM_02',
        'fullName': 'Nguyễn Văn Hùng',
        'branchId': 'b2',
        'branchName': 'Chi 2',
        'hasActiveAccount': true,
        'accountId': 'ACC_02',
      };
      final member = MemberRoleOptionModel.fromJson(memberJson);
      expect(member.hasActiveAccount, isTrue);
      expect(member.fullName, 'Nguyễn Văn Hùng');
    });

    test('AuditLogModel distinguishes ASSIGN vs REVOKE', () {
      final assignLog = AuditLogModel.fromJson({
        'auditId': 'AUD_1',
        'clanId': 'CLAN_1',
        'actorFullName': 'Trưởng Tộc',
        'targetFullName': 'Nguyễn Văn Hùng',
        'actionType': 'ASSIGN',
        'roleCode': 'ROLE_BRANCH_HEAD',
        'roleDisplayName': 'Trưởng Chi / Nhánh',
        'scopeType': 'BRANCH',
        'scopeId': 'b2',
        'scopeName': 'Chi 2',
        'description': 'Bổ nhiệm Trưởng chi',
        'createdAt': '2026-11-04T10:00:00Z',
      });
      expect(assignLog.isAssign, isTrue);
      expect(assignLog.isRevoke, isFalse);

      final revokeLog = AuditLogModel.fromJson({
        'auditId': 'AUD_2',
        'clanId': 'CLAN_1',
        'actorFullName': 'Trưởng Tộc',
        'targetFullName': 'Nguyễn Văn D',
        'actionType': 'REVOKE',
        'roleCode': 'EventTreasurer',
        'roleDisplayName': 'Thủ Quỹ Sự Kiện',
        'scopeType': 'EVENT',
        'scopeId': 'EVT_01',
        'scopeName': 'Đại Lễ Giỗ Tổ',
        'description': 'Hết nhiệm kỳ',
      });
      expect(revokeLog.isRevoke, isTrue);
      expect(revokeLog.isAssign, isFalse);
    });

    test('RoleAssignmentRequestDto and RoleRevocationRequestDto serialize correctly', () {
      const assignReq = RoleAssignmentRequestDto(
        memberId: 'MEM_01',
        roleCode: 'ROLE_BRANCH_HEAD',
        scopeType: 'BRANCH',
        scopeId: 'b1',
        description: 'Bổ nhiệm',
      );
      final assignJson = assignReq.toJson();
      expect(assignJson['memberId'], 'MEM_01');
      expect(assignJson['roleCode'], 'ROLE_BRANCH_HEAD');
      expect(assignJson['scopeType'], 'BRANCH');
      expect(assignJson['scopeId'], 'b1');
      expect(assignJson['description'], 'Bổ nhiệm');

      const revokeReq = RoleRevocationRequestDto(
        memberId: 'MEM_02',
        roleCode: 'EventTreasurer',
        scopeType: 'EVENT',
        scopeId: 'EVT_01',
        reason: 'Hết hạn',
      );
      final revokeJson = revokeReq.toJson();
      expect(revokeJson['memberId'], 'MEM_02');
      expect(revokeJson['roleCode'], 'EventTreasurer');
      expect(revokeJson['scopeType'], 'EVENT');
      expect(revokeJson['scopeId'], 'EVT_01');
      expect(revokeJson['reason'], 'Hết hạn');
    });
  });
}
