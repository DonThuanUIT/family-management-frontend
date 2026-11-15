import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/branch_models.dart';
import '../../data/repositories/genealogy_repository_impl.dart';
import '../../domain/repositories/genealogy_repository.dart';
import '../providers/genealogy_providers.dart';

/// Hộp thoại điều chuyển chi nhánh hoặc thành viên kèm cảnh báo lỗi đệ quy trực quan (US-28, Task #108).
class TransferNodeDialog extends ConsumerStatefulWidget {
  final BranchTreeNodeDto rootTree;
  final String? initialBranchId;
  final BranchMemberItem? initialMember;

  const TransferNodeDialog({
    super.key,
    required this.rootTree,
    this.initialBranchId,
    this.initialMember,
  });

  @override
  ConsumerState<TransferNodeDialog> createState() => _TransferNodeDialogState();
}

class _TransferNodeDialogState extends ConsumerState<TransferNodeDialog> {
  // 0: Điều chuyển chi nhánh, 1: Điều chuyển thành viên
  int _transferMode = 0;

  // Chi nhánh đang được chọn để chuyển
  late String _selectedSourceBranchId;

  // Chi nhánh cha đích muốn chuyển đến
  String? _selectedTargetParentBranchId;

  // Thành viên đang được chọn để chuyển
  BranchMemberItem? _selectedMember;

  // Chi nhánh đích cho thành viên
  String? _selectedTargetBranchForMember;

  bool _isSubmitting = false;
  String? _backendErrorMessage;

  @override
  void initState() {
    super.initState();
    _transferMode = widget.initialMember != null ? 1 : 0;
    _selectedSourceBranchId = widget.initialBranchId ?? widget.rootTree.branchId;
    _selectedMember = widget.initialMember;
  }

  /// Thu thập phẳng tất cả các chi nhánh từ cây phả hệ
  List<BranchTreeNodeDto> _flattenBranches(BranchTreeNodeDto node) {
    final list = <BranchTreeNodeDto>[node];
    for (final child in node.children) {
      list.addAll(_flattenBranches(child));
    }
    return list;
  }

  /// Tìm node chi nhánh theo ID
  BranchTreeNodeDto? _findBranch(BranchTreeNodeDto node, String branchId) {
    if (node.branchId == branchId) return node;
    for (final child in node.children) {
      final found = _findBranch(child, branchId);
      if (found != null) return found;
    }
    return null;
  }

  /// Thu thập tất cả các ID nhánh con/cháu hậu duệ của một nhánh
  Set<String> _getDescendantBranchIds(BranchTreeNodeDto node) {
    final result = <String>{};
    void dfs(BranchTreeNodeDto current) {
      for (final c in current.children) {
        result.add(c.branchId);
        dfs(c);
      }
    }
    dfs(node);
    return result;
  }

  /// Kiểm tra xem việc gán nhánh cha mới có tạo thành chu trình đệ quy không
  String? _checkBranchCycleError() {
    if (_selectedTargetParentBranchId == null) {
      return null;
    }

    if (_selectedSourceBranchId == _selectedTargetParentBranchId) {
      return 'Chi nhánh không thể tự nhận chính nó làm nhánh cha!';
    }

    final sourceNode = _findBranch(widget.rootTree, _selectedSourceBranchId);
    if (sourceNode == null) return null;

    final descendants = _getDescendantBranchIds(sourceNode);
    if (descendants.contains(_selectedTargetParentBranchId)) {
      final targetNode = _findBranch(widget.rootTree, _selectedTargetParentBranchId!);
      final targetName = targetNode?.branchName ?? _selectedTargetParentBranchId;
      return 'VI PHẠM VÒNG LẶP ĐỆ QUY (CYCLIC LOOP): Chi nhánh đích "$targetName" hiện là nhánh con/cháu trực thuộc của "${sourceNode.branchName}". Việc đảo ngược quan hệ cha-con sẽ tạo vòng lặp khép kín làm sập cấu trúc cây gia phả!';
    }

    return null;
  }

  /// Kiểm tra thế hệ khi điều chuyển thành viên
  String? _checkMemberGenerationError() {
    if (_selectedMember == null || _selectedTargetBranchForMember == null) {
      return null;
    }
    final targetBranch = _findBranch(widget.rootTree, _selectedTargetBranchForMember!);
    if (targetBranch != null && _selectedMember!.generation < targetBranch.generationLevel) {
      return 'LỖI PHÂN CẤP THẾ HỆ: Thành viên đời ${_selectedMember!.generation} không thể chuyển sang chi nhánh đời ${targetBranch.generationLevel} (${_selectedMember!.generation} < ${targetBranch.generationLevel}).';
    }
    return null;
  }

  Future<void> _handleExecuteTransfer() async {
    setState(() {
      _isSubmitting = true;
      _backendErrorMessage = null;
    });

    final repo = ref.read(genealogyRepositoryProvider);

    try {
      if (_transferMode == 0) {
        // Điều chuyển chi nhánh
        final sourceNode = _findBranch(widget.rootTree, _selectedSourceBranchId);
        if (sourceNode == null) throw Exception('Không tìm thấy chi nhánh nguồn');
        if (_selectedTargetParentBranchId == null) {
          throw Exception('Vui lòng chọn nhánh cha đích');
        }

        await repo.updateBranch(
          _selectedSourceBranchId,
          UpdateBranchRequestDto(
            branchName: sourceNode.branchName,
            parentBranchId: _selectedTargetParentBranchId,
            description: null,
            representativeId: sourceNode.representativeId,
          ),
        );
      } else {
        // Điều chuyển thành viên
        if (_selectedMember == null) {
          throw Exception('Vui lòng chọn thành viên cần điều chuyển');
        }
        if (_selectedTargetBranchForMember == null) {
          throw Exception('Vui lòng chọn chi nhánh đích');
        }

        await repo.assignMemberToBranch(
          _selectedMember!.memberId,
          _selectedTargetBranchForMember!,
        );
      }

      // Làm mới dữ liệu cây phả hệ
      ref.invalidate(branchTreeProvider);
      ref.invalidate(clanMembersProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _transferMode == 0
                  ? 'Điều chuyển chi nhánh thành công!'
                  : 'Điều chuyển thành viên sang chi nhánh mới thành công!',
            ),
            backgroundColor: const Color(0xFF006E2A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backendErrorMessage = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF8F482F);
    final allBranches = _flattenBranches(widget.rootTree);
    final cycleError = _transferMode == 0 ? _checkBranchCycleError() : null;
    final generationError = _transferMode == 1 ? _checkMemberGenerationError() : null;
    final hasValidationError = cycleError != null || generationError != null;

    final canConfirm = !_isSubmitting &&
        !hasValidationError &&
        ((_transferMode == 0 && _selectedTargetParentBranchId != null) ||
            (_transferMode == 1 &&
                _selectedMember != null &&
                _selectedTargetBranchForMember != null));

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: kPrimaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điều Chuyển Phả Hệ',
                          style: TextStyle(
                            fontFamily: 'Merriweather',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1A),
                          ),
                        ),
                        Text(
                          'US-28: Chuyển một thành viên hoặc cả nhánh sang nhánh cha khác',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11.5,
                            color: Color(0xFF6B584E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Control: Chọn đối tượng điều chuyển
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Điều chuyển Chi Nhánh'),
                    icon: Icon(Icons.account_tree_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Điều chuyển Thành Viên'),
                    icon: Icon(Icons.person_outline, size: 18),
                  ),
                ],
                selected: {_transferMode},
                onSelectionChanged: (val) {
                  setState(() {
                    _transferMode = val.first;
                    _backendErrorMessage = null;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: kPrimaryColor.withValues(alpha: 0.12),
                  selectedForegroundColor: kPrimaryColor,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Nội dung form theo Mode
              if (_transferMode == 0) ...[
                // 1. Chọn Chi Nhánh Nguồn
                const Text(
                  '1. Chọn chi nhánh cần điều chuyển:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1C1C1A)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedSourceBranchId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: allBranches.map((b) {
                    final isRoot = b.parentBranchId == null || b.generationLevel == 1;
                    return DropdownMenuItem(
                      value: b.branchId,
                      child: Text(
                        '${b.branchName} (Đời ${b.generationLevel})${isRoot ? ' • [Nhánh Gốc]' : ''}',
                        style: TextStyle(fontWeight: isRoot ? FontWeight.bold : FontWeight.normal),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSourceBranchId = val;
                        _backendErrorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 2. Chọn Nhánh Cha Đích
                const Text(
                  '2. Chọn nhánh cha đích mới:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1C1C1A)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTargetParentBranchId,
                  hint: const Text('-- Chọn nhánh cha muốn kết nối vào --'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: allBranches.map((b) {
                    final isSource = b.branchId == _selectedSourceBranchId;
                    return DropdownMenuItem(
                      value: b.branchId,
                      enabled: !isSource,
                      child: Text(
                        '${b.branchName} (Đời ${b.generationLevel})${isSource ? ' [Nhánh hiện tại]' : ''}',
                        style: TextStyle(
                          color: isSource ? Colors.grey : Colors.black87,
                          fontWeight: isSource ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTargetParentBranchId = val;
                      _backendErrorMessage = null;
                    });
                  },
                ),
              ] else ...[
                // Mode 1: Điều chuyển thành viên
                const Text(
                  '1. Chọn thành viên cần điều chuyển:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1C1C1A)),
                ),
                const SizedBox(height: 6),
                Consumer(
                  builder: (context, ref, child) {
                    final membersAsync = ref.watch(clanMembersProvider);
                    return membersAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Lỗi tải thành viên: $e', style: const TextStyle(color: Colors.red)),
                      data: (members) {
                        return DropdownButtonFormField<String>(
                          value: _selectedMember?.memberId,
                          hint: const Text('-- Chọn thành viên dòng họ --'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: members.map((m) {
                            return DropdownMenuItem(
                              value: m.memberId,
                              child: Text('${m.fullName} • Mã: ${m.memberId} (Đời ${m.generation})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            final found = members.firstWhere((m) => m.memberId == val);
                            setState(() {
                              _selectedMember = found;
                              _backendErrorMessage = null;
                            });
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 2. Chọn Chi Nhánh Đích
                const Text(
                  '2. Chọn chi nhánh đích chuyển tới:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1C1C1A)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedTargetBranchForMember,
                  hint: const Text('-- Chọn chi nhánh chuyển tới --'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: allBranches.map((b) {
                    return DropdownMenuItem(
                      value: b.branchId,
                      child: Text('${b.branchName} • Đời ${b.generationLevel} (${b.memberCount} thành viên)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTargetBranchForMember = val;
                      _backendErrorMessage = null;
                    });
                  },
                ),
              ],

              // HIỂN THỊ CẢNH BÁO LỖI TRỰC QUAN NẾU VI PHẠM VÒNG LẶP ĐỆ QUY (US-28)
              if (cycleError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBA1A1A), width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cycleError,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12.5,
                            color: Color(0xFFBA1A1A),
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // CẢNH BÁO LỖI THẾ HỆ THÀNH VIÊN
              if (generationError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC2410C), width: 1.5),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFC2410C), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          generationError,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFC2410C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // LỖI PHẢN HỒI TỪ BACKEND
              if (_backendErrorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBA1A1A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Color(0xFFBA1A1A), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lỗi máy chủ: $_backendErrorMessage',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFFBA1A1A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: canConfirm ? _handleExecuteTransfer : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      _isSubmitting
                          ? 'Đang xử lý...'
                          : (_transferMode == 0 ? 'Xác Nhận Đổi Nhánh Cha' : 'Xác Nhận Đổi Chi Phái'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
