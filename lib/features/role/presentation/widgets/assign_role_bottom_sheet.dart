import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../event/presentation/providers/event_providers.dart';
import '../../data/models/role_models.dart';
import '../providers/role_providers.dart';

class AssignRoleBottomSheet extends ConsumerStatefulWidget {
  final RoleScopeType initialScope;
  final String? initialTargetId;
  final AssignableRoleCode? initialRole;

  const AssignRoleBottomSheet({
    super.key,
    this.initialScope = RoleScopeType.branch,
    this.initialTargetId,
    this.initialRole,
  });

  @override
  ConsumerState<AssignRoleBottomSheet> createState() =>
      _AssignRoleBottomSheetState();
}

class _AssignRoleBottomSheetState extends ConsumerState<AssignRoleBottomSheet> {
  late RoleScopeType _selectedScope;
  late AssignableRoleCode _selectedEventRole;
  String? _selectedBranchId;
  String? _selectedEventId;
  String? _selectedMemberId;

  final _searchController = TextEditingController();
  final _reasonController = TextEditingController(
    text: 'Bổ nhiệm nhân sự theo nghị quyết Hội Đồng Tộc Biểu',
  );

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedScope = widget.initialScope;
    _selectedEventRole = widget.initialRole ?? AssignableRoleCode.headOfOrganizer;
    if (_selectedScope == RoleScopeType.branch) {
      _selectedBranchId = widget.initialTargetId;
    } else {
      _selectedEventId = widget.initialTargetId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitAssignment() async {
    if (_selectedMemberId == null || _selectedMemberId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn thành viên thụ hưởng!'),
          backgroundColor: Color(0xFFBA1A1A),
        ),
      );
      return;
    }

    final String finalRoleCode;
    final String finalScopeId;

    if (_selectedScope == RoleScopeType.branch) {
      if (_selectedBranchId == null || _selectedBranchId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn chi nhánh cần bổ nhiệm!'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
        return;
      }
      finalRoleCode = AssignableRoleCode.roleBranchHead.code;
      finalScopeId = _selectedBranchId!;
    } else {
      if (_selectedEventId == null || _selectedEventId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn sự kiện cụ thể!'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
        return;
      }
      finalRoleCode = _selectedEventRole.code;
      finalScopeId = _selectedEventId!;
    }

    setState(() => _isSubmitting = true);

    final request = RoleAssignmentRequestDto(
      memberId: _selectedMemberId!,
      roleCode: finalRoleCode,
      scopeType: _selectedScope.code,
      scopeId: finalScopeId,
      description: _reasonController.text.trim(),
    );

    final success =
        await ref.read(roleManagementProvider.notifier).assignRole(request);

    if (mounted) {
      setState(() => _isSubmitting = false);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(success);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Đã chỉ định vai trò thành công và ghi Sổ Bộ!'
                : ref.read(roleManagementProvider).errorMessage ??
                    'Không thể chỉ định vai trò',
          ),
          backgroundColor:
              success ? const Color(0xFF1B873F) : const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleState = ref.watch(roleManagementProvider);
    final eventState = ref.watch(eventListProvider);

    final branches = roleState.overview?.branches ?? [];
    final members = roleState.overview?.members ?? [];
    final events = eventState.events;

    // Default branch and event if not selected yet
    if (_selectedBranchId == null && branches.isNotEmpty) {
      _selectedBranchId = branches.first.branchId;
    }
    if (_selectedEventId == null && events.isNotEmpty) {
      _selectedEventId = events.first.eventId;
    }

    final query = _searchController.text.toLowerCase().trim();
    final filteredMembers = members.where((m) {
      if (query.isEmpty) return true;
      return m.fullName.toLowerCase().contains(query) ||
          (m.branchName?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3E2E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.how_to_reg,
                    color: Color(0xFF6A020A),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chỉ Định Quyền & Chức Sự',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                      Text(
                        'Cập nhật ma trận phân quyền và ghi Sổ Bộ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFEFEEEB)),

            // Step 1: Chọn Phạm Vi
            Row(
              children: [
                _buildStepBadge(1),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chọn Phạm Vi Đảm Trách:',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildScopeCard(
                    scope: RoleScopeType.branch,
                    title: 'Cấp Chi Nhánh',
                    subtitle: 'Bổ nhiệm Trưởng Chi',
                    icon: Icons.account_tree_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildScopeCard(
                    scope: RoleScopeType.event,
                    title: 'Cấp Sự Kiện',
                    subtitle: 'BTC, Thủ Quỹ, Điều Phối',
                    icon: Icons.festival_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Conditional dropdown based on Scope
            if (_selectedScope == RoleScopeType.branch) ...[
              const Text(
                'Chọn Chi Nhánh:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranchId,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A1C1A)),
                decoration: _inputDecoration(),
                items: branches
                    .map(
                      (b) => DropdownMenuItem(
                        value: b.branchId,
                        child: Text(
                          '${b.branchName} ${b.hasRepresentative ? "(Đang có: ${b.representativeFullName})" : "(Khuyết Trưởng Chi)"}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: b.hasRepresentative
                                ? FontWeight.normal
                                : FontWeight.bold,
                            color: b.hasRepresentative
                                ? const Color(0xFF1A1C1A)
                                : const Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBranchId = val);
                },
              ),
            ] else ...[
              const Text(
                'Chọn Sự Kiện Cụ Thể:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedEventId,
                isExpanded: true,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A1C1A)),
                decoration: _inputDecoration(),
                items: events
                    .map(
                      (e) => DropdownMenuItem(
                        value: e.eventId,
                        child: Text(
                          e.eventName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedEventId = val);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Chọn Vai Trò Sự Kiện (Role):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _buildRoleChip(
                      AssignableRoleCode.headOfOrganizer,
                      'Trưởng BTC',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildRoleChip(
                      AssignableRoleCode.eventTreasurer,
                      'Thủ Quỹ',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildRoleChip(
                      AssignableRoleCode.organizerMember,
                      'Thành Viên',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Step 2: Chọn Thành Viên
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _buildStepBadge(2),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Chọn Thành Viên Thụ Hưởng:',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1C1A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Row(
                  children: [
                    Icon(Icons.verified_user,
                        size: 13, color: Color(0xFF1B873F)),
                    SizedBox(width: 3),
                    Text(
                      'Chỉ chọn TK Active',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B873F),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search box
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc chi tộc...',
                hintStyle:
                    const TextStyle(fontSize: 11.5, color: Color(0xFF8B716E)),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF4F3F1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE9E8E5)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Member list container
            Container(
              constraints: const BoxConstraints(maxHeight: 170),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEFEEEB)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: filteredMembers.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Không tìm thấy thành viên nào',
                          style:
                              TextStyle(fontSize: 11, color: Color(0xFF8B716E)),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(6),
                      itemCount: filteredMembers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final member = filteredMembers[index];
                        final isSelected = _selectedMemberId == member.memberId;
                        final isInactive = !member.hasActiveAccount;

                        return InkWell(
                          onTap: () {
                            if (isInactive) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Thành viên chưa kích hoạt tài khoản! Vui lòng chọn thành viên có trạng thái Active.',
                                  ),
                                  backgroundColor: Color(0xFFBA1A1A),
                                ),
                              );
                              return;
                            }
                            setState(() => _selectedMemberId = member.memberId);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFDAD6).withAlpha(120)
                                  : (isInactive
                                      ? const Color(0xFFF9F9F9)
                                      : Colors.white),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6A020A)
                                    : const Color(0xFFEFEEEB),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isSelected
                                      ? const Color(0xFF6A020A)
                                      : const Color(0xFFEFEEEB),
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : const Color(0xFF58413F),
                                  child: Text(
                                    member.fullName.isNotEmpty
                                        ? member.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.fullName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isInactive
                                              ? const Color(0xFF8B716E)
                                              : const Color(0xFF1A1C1A),
                                        ),
                                      ),
                                      Text(
                                        member.branchName ?? 'Chưa phân chi',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF8B716E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: member.hasActiveAccount
                                        ? const Color(0xFFDCF5E3)
                                        : const Color(0xFFE9E8E5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    member.hasActiveAccount
                                        ? 'Active'
                                        : 'Chưa kích hoạt',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: member.hasActiveAccount
                                          ? const Color(0xFF1B873F)
                                          : const Color(0xFF8B716E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Step 3: Lý do chỉ định
            Row(
              children: [
                _buildStepBadge(3),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lý Do Chỉ Định (Ghi vào Sổ Bộ):',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              style: const TextStyle(fontSize: 12),
              decoration: _inputDecoration(
                hintText: 'Nhập lý do hoặc căn cứ quyết định...',
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFFDFBFBC)),
                    ),
                    child: const Text(
                      'Hủy Bỏ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF58413F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A020A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Xác Nhận Chỉ Định',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBadge(int number) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFF6A020A),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScopeCard({
    required RoleScopeType scope,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedScope == scope;
    return InkWell(
      onTap: () => setState(() => _selectedScope = scope),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFDAD6).withAlpha(100)
              : const Color(0xFFF4F3F1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A020A) : const Color(0xFFE9E8E5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFF6A020A)
                      : const Color(0xFF58413F),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFF6A020A)
                      : const Color(0xFF8B716E),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color(0xFF6A020A)
                    : const Color(0xFF1A1C1A),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9.5,
                color: Color(0xFF58413F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(AssignableRoleCode role, String label) {
    final isSelected = _selectedEventRole == role;
    return InkWell(
      onTap: () => setState(() => _selectedEventRole = role),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFDAD6) : const Color(0xFFF4F3F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A020A) : const Color(0xFFE9E8E5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF6A020A) : const Color(0xFF1A1C1A),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF8B716E)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      filled: true,
      fillColor: const Color(0xFFF4F3F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9E8E5)),
      ),
    );
  }
}
