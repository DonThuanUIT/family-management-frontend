import 'package:familyfund_app/features/invitation/data/models/position_link_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PositionLinkModels Test (US-18)', () {
    test('CreateVirtualMemberRequestDto to json serializes correctly', () {
      const dto = CreateVirtualMemberRequestDto(
        fullName: 'Lê Hữu Tuấn',
        dateOfBirth: '2000-01-01',
        gender: 'Male',
        generation: 5,
        status: 'Living',
        deathDateLunar: null,
        validityDays: 14,
      );

      final json = dto.toJson();
      expect(json['fullName'], 'Lê Hữu Tuấn');
      expect(json['dateOfBirth'], '2000-01-01');
      expect(json['gender'], 'Male');
      expect(json['generation'], 5);
      expect(json['status'], 'Living');
      expect(json['validityDays'], 14);
      expect(json.containsKey('deathDateLunar'), false);
    });

    test('VirtualMemberDto from json deserializes correctly', () {
      final json = {
        'memberId': 'MEM-001',
        'fullName': 'Lê Hữu Tuấn',
        'gender': 'Male',
        'generation': 5,
        'status': 'Living',
        'branchId': 'chi-2',
        'branchName': 'Chi 2',
        'clanId': 'LE',
        'isPlaceholder': true,
        'createdAt': '2026-03-12T00:00:00Z',
      };

      final dto = VirtualMemberDto.fromJson(json);
      expect(dto.memberId, 'MEM-001');
      expect(dto.fullName, 'Lê Hữu Tuấn');
      expect(dto.generation, 5);
      expect(dto.branchId, 'chi-2');
      expect(dto.isPlaceholder, true);
    });

    test('CreateVirtualMemberResponseDto parses member and positionLinkCode', () {
      final json = {
        'member': {
          'memberId': 'MEM-002',
          'fullName': 'Lê Thu Trang',
          'gender': 'Female',
          'generation': 5,
          'status': 'Living',
          'branchId': 'chi-2',
          'branchName': 'Chi 2',
          'clanId': 'LE',
          'isPlaceholder': true,
        },
        'positionLinkCode': {
          'inviteCode': 'LE-CHI2-DOI5-7731',
          'clanId': 'LE',
          'shareableUrl': 'https://familyfund.app/join?clan=LE&code=CHI2-DOI5-7731',
          'targetBranchId': 'chi-2',
          'targetMemberId': 'MEM-002',
          'maxUses': 1,
          'usedCount': 0,
          'isActive': true,
        },
      };

      final response = CreateVirtualMemberResponseDto.fromJson(json);
      expect(response.member.fullName, 'Lê Thu Trang');
      expect(response.positionLinkCode.inviteCode, 'LE-CHI2-DOI5-7731');
      expect(response.positionLinkCode.maxUses, 1);
      expect(response.positionLinkCode.isActive, true);
    });
  });
}
