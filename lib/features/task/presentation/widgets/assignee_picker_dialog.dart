import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../event/data/models/event_models.dart';

/// Kết quả lựa chọn đối tượng nhận việc từ Assignee Picker.
class AssigneeSelection {
  final String? memberId;
  final String? memberName;
  final String? branchId;
  final String? branchName;

  const AssigneeSelection({
    this.memberId,
    this.memberName,
    this.branchId,
    this.branchName,
  });

  bool get isAssigned =>
      (memberId != null && memberId!.isNotEmpty) ||
      (branchId != null && branchId!.isNotEmpty);

  String get displayName {
    if (memberName != null && memberName!.isNotEmpty) {
      if (branchName != null && branchName!.isNotEmpty) {
        return '$memberName ($branchName)';
      }
      return memberName!;
    }
    if (branchName != null && branchName!.isNotEmpty) {
      return branchName!;
    }
    return 'Chưa chỉ định';
  }
}

/// Một chi nhánh được làm phẳng từ cây phả hệ để hiển thị danh sách thụt lề.
class _FlattenedBranch {
  final String branchId;
  final String branchName;
  final int? generationLevel;
  final String? representativeName;
  final int memberCount;
  final int depth;

  const _FlattenedBranch({
    required this.branchId,
    required this.branchName,
    this.generationLevel,
    this.representativeName,
    required this.memberCount,
    required this.depth,
  });
}

/// Bộ chọn người nhận việc 2 Tab: Cá nhân & Chi nhánh (US-07 & US-25).
/// Tuân thủ quy định bảo mật US-25: Tuyệt đối không hiển thị SĐT, email, ngày sinh.
class AssigneePickerDialog extends ConsumerStatefulWidget {
  final EventModel? event;
  final AssigneeSelection? initialSelection;

  const AssigneePickerDialog({
    super.key,
    this.event,
    this.initialSelection,
  });

  /// Hiển thị dạng Dialog thích ứng trên Web hoặc Bottom Sheet trên Mobile.
  static Future<AssigneeSelection?> show(
    BuildContext context, {
    EventModel? event,
    AssigneeSelection? initialSelection,
  }) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      return showDialog<AssigneeSelection>(
        context: context,
        builder: (_) => AssigneePickerDialog(
          event: event,
          initialSelection: initialSelection,
        ),
      );
    } else {
      return showModalBottomSheet<AssigneeSelection>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.85,
          child: AssigneePickerDialog(
            event: event,
            initialSelection: initialSelection,
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<AssigneePickerDialog> createState() =>
      _AssigneePickerDialogState();
}

class _AssigneePickerDialogState extends ConsumerState<AssigneePickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoadingBranches = false;
  String? _branchError;
  List<_FlattenedBranch> _flattenedBranches = [];

  AssigneeSelection? _currentSelection;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentSelection = widget.initialSelection;
    _loadBranchTree();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBranchTree() async {
    setState(() {
      _isLoadingBranches = true;
      _branchError = null;
    });

    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.get('/branches/tree');
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        final treeRoot = OnboardingBranchTreeNodeDto.fromJson(
          data['data'] as Map<String, dynamic>,
        );
        final list = <_FlattenedBranch>[];
        _flattenNode(treeRoot, 0, list);
        setState(() {
          _flattenedBranches = list;
          _isLoadingBranches = false;
        });
      } else {
        setState(() {
          _isLoadingBranches = false;
        });
      }
    } catch (e) {
      setState(() {
        _branchError = 'Không thể tải cây chi nhánh: $e';
        _isLoadingBranches = false;
      });
    }
  }

  void _flattenNode(
    OnboardingBranchTreeNodeDto node,
    int depth,
    List<_FlattenedBranch> target,
  ) {
    target.add(
      _FlattenedBranch(
        branchId: node.branchId,
        branchName: node.branchName,
        generationLevel: node.generationLevel,
        representativeName: node.representativeName,
        memberCount: node.memberCount,
        depth: depth,
      ),
    );
    for (final child in node.children) {
      _flattenNode(child, depth + 1, target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle for mobile
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCrimson.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_ind_outlined,
                    color: AppTheme.primaryCrimson,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn Đối Tượng Nhận Việc',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F1610),
                        ),
                      ),
                      Text(
                        'Tuân thủ bảo mật US-25: Không để lộ SĐT, email, ngày sinh',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryCrimson,
            unselectedLabelColor: const Color(0xFF6B5E55),
            indicatorColor: AppTheme.primaryCrimson,
            indicatorWeight: 2.5,
            tabs: const [
              Tab(
                icon: Icon(Icons.person_outline, size: 18),
                text: 'Cá Nhân (Gia Phả)',
              ),
              Tab(
                icon: Icon(Icons.account_tree_outlined, size: 18),
                text: 'Chi Nhánh Gia Đình',
              ),
            ],
          ),

          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMemberTab(),
                _buildBranchTab(),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F6),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentSelection = const AssigneeSelection();
                    });
                    Navigator.pop(context, const AssigneeSelection());
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Bỏ chọn (Chưa giao)'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _currentSelection);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Xác Nhận Chọn',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final isDesktop = MediaQuery.of(context).size.width >= 768;
    if (isDesktop) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
          child: content,
        ),
      );
    }

    return content;
  }

  /// Tab 1: Danh sách cá nhân
  Widget _buildMemberTab() {
    final personnelList = widget.event?.personnel ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo họ tên thành viên...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() => _searchController.clear());
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (val) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              if (personnelList.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Nhân sự Ban Tổ Chức sự kiện',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryCrimson,
                    ),
                  ),
                ),
                ...personnelList.map((p) {
                  final name = p.memberName ?? p.memberId;
                  final isSelected = _currentSelection?.memberId == p.memberId;
                  return _memberTile(
                    memberId: p.memberId,
                    fullName: name,
                    subtitle: 'Vai trò BTC: ${p.roleDisplayName}',
                    isSelected: isSelected,
                  );
                }),
                const SizedBox(height: 12),
              ],

              // Danh sách đại diện các chi nhánh
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Đại diện các chi nhánh gia phả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1610),
                  ),
                ),
              ),
              if (_flattenedBranches.isEmpty && _isLoadingBranches)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                ..._flattenedBranches
                    .where((b) =>
                        b.representativeName != null &&
                        b.representativeName!.isNotEmpty)
                    .map((b) {
                  final isSelected =
                      _currentSelection?.memberName == b.representativeName;
                  return _memberTile(
                    memberId: 'REP_${b.branchId}',
                    fullName: b.representativeName!,
                    subtitle:
                        'Đại diện ${b.branchName} (Đời ${b.generationLevel ?? '?'})',
                    branchId: b.branchId,
                    branchName: b.branchName,
                    isSelected: isSelected,
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _memberTile({
    required String memberId,
    required String fullName,
    required String subtitle,
    String? branchId,
    String? branchName,
    required bool isSelected,
  }) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty &&
        !fullName.toLowerCase().contains(query) &&
        !subtitle.toLowerCase().contains(query)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryCrimson.withAlpha(15)
            : const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryCrimson : Colors.grey.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? AppTheme.primaryCrimson
              : const Color(0xFFB8860B).withAlpha(40),
          foregroundColor:
              isSelected ? Colors.white : const Color(0xFF8B1E1E),
          child: Text(
            fullName.isNotEmpty ? fullName.characters.first : '?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          fullName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF1F1610),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle,
                color: AppTheme.primaryCrimson, size: 20)
            : const Icon(Icons.radio_button_unchecked,
                color: Colors.grey, size: 20),
        onTap: () {
          setState(() {
            _currentSelection = AssigneeSelection(
              memberId: memberId,
              memberName: fullName,
              branchId: branchId,
              branchName: branchName,
            );
          });
        },
      ),
    );
  }

  /// Tab 2: Cây chi nhánh gia đình
  Widget _buildBranchTab() {
    if (_isLoadingBranches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_branchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                _branchError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadBranchTree,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_flattenedBranches.isEmpty) {
      return const Center(
        child: Text(
          'Không có chi nhánh gia phả nào',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _flattenedBranches.length,
      itemBuilder: (context, index) {
        final b = _flattenedBranches[index];
        final isSelected = _currentSelection?.branchId == b.branchId &&
            (_currentSelection?.memberId == null ||
                _currentSelection!.memberId!.isEmpty);

        return Padding(
          padding: EdgeInsets.only(
            left: b.depth * 16.0,
            bottom: 6,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.immutableLedgerTeal.withAlpha(20)
                  : const Color(0xFFFDFBF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.immutableLedgerTeal
                    : Colors.grey.shade200,
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: Icon(
                b.depth == 0
                    ? Icons.holiday_village_outlined
                    : Icons.subdirectory_arrow_right,
                color: isSelected
                    ? AppTheme.immutableLedgerTeal
                    : const Color(0xFF8B1E1E),
                size: 20,
              ),
              title: Text(
                b.branchName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: const Color(0xFF1F1610),
                ),
              ),
              subtitle: Text(
                'Đời thứ ${b.generationLevel ?? 1} • Đại diện: ${b.representativeName ?? "Chưa có"} • ${b.memberCount} thành viên',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle,
                      color: AppTheme.immutableLedgerTeal, size: 20)
                  : const Icon(Icons.radio_button_unchecked,
                      color: Colors.grey, size: 20),
              onTap: () {
                setState(() {
                  _currentSelection = AssigneeSelection(
                    branchId: b.branchId,
                    branchName: b.branchName,
                  );
                });
              },
            ),
          ),
        );
      },
    );
  }
}
