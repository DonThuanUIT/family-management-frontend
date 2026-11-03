import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/auth_models.dart';

class RegisterMemberScreen extends ConsumerStatefulWidget {
  final String? initialInviteCode;

  const RegisterMemberScreen({super.key, this.initialInviteCode});

  @override
  ConsumerState<RegisterMemberScreen> createState() =>
      _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends ConsumerState<RegisterMemberScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _inviteCodeController;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _generationController = TextEditingController(text: '1');
  final _proposedBranchNameController = TextEditingController();
  final _relationshipNoteController = TextEditingController();

  String _gender = 'Female';
  DateTime _dateOfBirth = DateTime(1996, 8, 15);
  bool _obscurePassword = true;
  bool _agreedToTerms = true;

  bool _isInitLoading = false;
  String? _initError;
  bool _isSubmitting = false;

  InviteCodePreviewDto? _invitePreview;
  OnboardingBranchTreeNodeDto? _treeRoot;
  final List<_BranchOption> _flattenedBranches = [];

  ProposalType _proposalType = ProposalType.existingBranchLeaf;
  String? _selectedTargetBranchId;
  bool _isTargetBranchLocked = false;

  @override
  void initState() {
    super.initState();
    _inviteCodeController = TextEditingController(
      text: widget.initialInviteCode ?? '',
    );
    if (_inviteCodeController.text.trim().isNotEmpty) {
      _loadInviteAndTree();
    }
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _generationController.dispose();
    _proposedBranchNameController.dispose();
    _relationshipNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadInviteAndTree() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      return;
    }

    setState(() {
      _isInitLoading = true;
      _initError = null;
    });

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);
      final preview = await dataSource.previewInvite(code);
      final tree = await dataSource.getOnboardingBranchTree(code);

      _flattenedBranches.clear();
      _flattenTree(tree, 0);

      String? targetBranchId;
      bool isLocked = false;

      if (preview.targetBranchId != null &&
          preview.targetBranchId!.trim().isNotEmpty) {
        targetBranchId = preview.targetBranchId!.trim();
        isLocked = true;
      } else if (_flattenedBranches.isNotEmpty) {
        targetBranchId = _flattenedBranches.first.branchId;
      }

      final initialBranch = _flattenedBranches.firstWhere(
        (b) => b.branchId == targetBranchId,
        orElse: () => _flattenedBranches.isNotEmpty
            ? _flattenedBranches.first
            : _BranchOption(
                branchId: targetBranchId ?? '',
                branchName: preview.targetBranchName ?? 'Nhánh chính',
                depth: 0,
                memberCount: 0,
              ),
      );

      final suggestedGen = (initialBranch.generationLevel != null)
          ? initialBranch.generationLevel! + 1
          : 1;

      if (mounted) {
        setState(() {
          _invitePreview = preview;
          _treeRoot = tree;
          _selectedTargetBranchId = targetBranchId;
          _isTargetBranchLocked = isLocked;
          _generationController.text = suggestedGen.toString();
          _isInitLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitLoading = false;
          _initError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _flattenTree(OnboardingBranchTreeNodeDto node, int depth) {
    _flattenedBranches.add(
      _BranchOption(
        branchId: node.branchId,
        branchName: node.branchName,
        generationLevel: node.generationLevel,
        representativeName: node.representativeName,
        memberCount: node.memberCount,
        depth: depth,
      ),
    );
    for (final child in node.children) {
      _flattenTree(child, depth + 1);
    }
  }

  String _formatDateVietnamese(DateTime dt) {
    return '${dt.day} tháng ${dt.month}, ${dt.year}';
  }

  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với cam kết gia phong'),
          backgroundColor: Color(0xFF9B1C1C),
        ),
      );
      return;
    }

    final targetBranchId = _selectedTargetBranchId ??
        _invitePreview?.targetBranchId ??
        (_flattenedBranches.isNotEmpty ? _flattenedBranches.first.branchId : '');

    if (targetBranchId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn chi nhánh muốn gia nhập'),
          backgroundColor: Color(0xFF9B1C1C),
        ),
      );
      return;
    }

    final generation = int.tryParse(_generationController.text.trim());
    if (generation == null || generation < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đời thứ đề xuất phải là số nguyên lớn hơn hoặc bằng 1'),
          backgroundColor: Color(0xFF9B1C1C),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dobStr =
        "${_dateOfBirth.year.toString().padLeft(4, '0')}-${_dateOfBirth.month.toString().padLeft(2, '0')}-${_dateOfBirth.day.toString().padLeft(2, '0')}";

    final request = RegisterMemberRequestDto(
      inviteCode: _inviteCodeController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      gender: _gender,
      proposalType: _proposalType,
      targetBranchId: targetBranchId.trim(),
      proposedGeneration: generation,
      proposedNewBranchName: _proposalType == ProposalType.newChildBranch
          ? _proposedBranchNameController.text.trim()
          : null,
      relationshipNote: _relationshipNoteController.text.trim().isNotEmpty
          ? _relationshipNoteController.text.trim()
          : null,
      dateOfBirth: dobStr,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);
      final response = await dataSource.registerMember(request);

      if (mounted) {
        context.push('/pending-approval', extra: response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFF9B1C1C),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        title: const Text(
          'Ghi Tên Vào Gia Phả',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF7A1518),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF7A1518)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(),
                    if (_isInitLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(
                        color: Color(0xFF7A1518),
                        backgroundColor: Color(0xFFFAF6F0),
                      ),
                    ],
                    if (_initError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF8B4B4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFF9B1C1C), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _initError!,
                                style: const TextStyle(
                                  color: Color(0xFF9B1C1C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _buildPlacementCard(),
                    const SizedBox(height: 18),
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 14),
                    _buildCommitmentAndSubmit(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final clanDisplayName = _invitePreview?.clanName ??
        _treeRoot?.clanName ??
        _invitePreview?.clanId ??
        'Gia Tộc';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7A1518),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A1518).withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A0E10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories,
                        color: Color(0xFFE2AA36), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'SỔ VÀNG GIA TỘC',
                      style: TextStyle(
                        color: Color(0xFFE2AA36),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_inviteCodeController.text.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withAlpha(200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _inviteCodeController.text.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            clanDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nối tiếp tiền nhân • Giữ gìn gia phong muôn thuở',
            style: TextStyle(
              color: Color(0xFFE5D5D0),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8DFD8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_tree_outlined,
                    color: Color(0xFF7A1518), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vị Trí Trong Tộc Phả',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B1810),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Mã mời input
            const Text(
              'Mã Gia Tộc (Bắt buộc) *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _inviteCodeController,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF9F6F0),
                hintText: 'Nhập mã mời',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.sync, color: Color(0xFF7A1518)),
                  onPressed: _loadInviteAndTree,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng có mã gia tộc'
                  : null,
            ),
            const SizedBox(height: 14),

            if (_isTargetBranchLocked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2AA36)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Color(0xFF8B6B23), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi nhánh được chỉ định theo mã mời:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8B6B23),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _invitePreview?.targetBranchName ??
                                _selectedTargetBranchId ??
                                'Chi nhánh cố định',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ] else ...[
              // Proposal type tab
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _proposalType = ProposalType.existingBranchLeaf;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _proposalType ==
                                    ProposalType.existingBranchLeaf
                                ? const Color(0xFF7A1518)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Nhánh hiện có',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _proposalType ==
                                        ProposalType.existingBranchLeaf
                                    ? Colors.white
                                    : const Color(0xFF6B584E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _proposalType = ProposalType.newChildBranch;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _proposalType == ProposalType.newChildBranch
                                ? const Color(0xFF7A1518)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Đề xuất nhánh mới',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color:
                                    _proposalType == ProposalType.newChildBranch
                                        ? Colors.white
                                        : const Color(0xFF6B584E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                _proposalType == ProposalType.existingBranchLeaf
                    ? 'Chọn chi nhánh muốn gia nhập *'
                    : 'Chọn chi nhánh cha trực thuộc *',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              if (_flattenedBranches.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedTargetBranchId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF9F6F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: _flattenedBranches.map((b) {
                    final indent = '　' * b.depth;
                    final prefix = b.depth > 0 ? '└ ' : '';
                    final rep = (b.representativeName != null &&
                            b.representativeName!.isNotEmpty)
                        ? ' (${b.representativeName})'
                        : '';
                    return DropdownMenuItem<String>(
                      value: b.branchId,
                      child: Text(
                        '$indent$prefix${b.branchName}$rep',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: b.depth == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: const Color(0xFF2B1810),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedTargetBranchId = val;
                        final branch = _flattenedBranches.firstWhere(
                          (b) => b.branchId == val,
                          orElse: () => _flattenedBranches.first,
                        );
                        if (branch.generationLevel != null) {
                          _generationController.text =
                              (branch.generationLevel! + 1).toString();
                        }
                      });
                    }
                  },
                ),
              ] else ...[
                TextFormField(
                  initialValue: _selectedTargetBranchId ?? 'Nhánh chính',
                  decoration: InputDecoration(
                    hintText: 'Nhập tên hoặc mã chi nhánh',
                    filled: true,
                    fillColor: const Color(0xFFF9F6F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) => _selectedTargetBranchId = val,
                ),
              ],
              const SizedBox(height: 14),

              if (_proposalType == ProposalType.newChildBranch) ...[
                const Text(
                  'Tên chi nhánh mới đề xuất *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _proposedBranchNameController,
                  decoration: InputDecoration(
                    hintText: 'VD: Chi 3 - Nhánh Giáp Ất',
                    prefixIcon: const Icon(Icons.add_business_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (_proposalType == ProposalType.newChildBranch &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Vui lòng nhập tên chi nhánh mới đề xuất';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],
            ],

            // Đời thứ đề xuất
            const Text(
              'Đời thứ đề xuất (Thế hệ trong gia phả) *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _generationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'VD: 5',
                prefixIcon: const Icon(Icons.format_list_numbered),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập đời thứ đề xuất';
                }
                final num = int.tryParse(v.trim());
                if (num == null || num < 1) {
                  return 'Đời thứ phải lớn hơn hoặc bằng 1';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Ghi chú mối quan hệ
            const Text(
              'Ghi chú mối quan hệ / Nguồn gốc (tùy chọn)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _relationshipNoteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText:
                    'VD: Con trai thứ 2 của ông Lê Văn Nam, thuộc dòng dõi cụ Lê Hữu Hưng...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8DFD8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_add_alt_1,
                    color: Color(0xFF7A1518), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thông Tin Thành Viên & Tài Khoản',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B1810),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),

            // Họ và tên khai sinh *
            const Text(
              'Họ và tên khai sinh *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: 'VD: Nguyễn Thị Mai Anh',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng nhập họ và tên'
                  : null,
            ),
            const SizedBox(height: 14),

            // Số điện thoại liên lạc *
            const Text(
              'Số điện thoại liên lạc *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'VD: 0912345678',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                final cleaned = v.trim();
                final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
                if (!phoneRegex.hasMatch(cleaned)) {
                  return 'Số điện thoại không đúng định dạng (VD: 0912345678)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Giới tính
            const Text(
              'Giới tính *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGenderButton('Male', 'Nam', Icons.male),
                const SizedBox(width: 10),
                _buildGenderButton('Female', 'Nữ', Icons.female),
                const SizedBox(width: 10),
                _buildGenderButton('Other', 'Khác', Icons.transgender),
              ],
            ),
            const SizedBox(height: 14),

            // Ngày tháng năm sinh (Dương lịch) *
            const Text(
              'Ngày tháng năm sinh (Dương lịch) *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth,
                  firstDate: DateTime(1900),
                  lastDate: now,
                );
                if (picked != null) {
                  setState(() => _dateOfBirth = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F1EB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8DFD8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF7A1518), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatDateVietnamese(_dateOfBirth),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B1810),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Email
            const Text(
              'Email nhận tin dòng họ (tùy chọn)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'VD: maianh@domain.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Mật khẩu bảo vệ tài khoản *
            const Text(
              'Mật khẩu bảo vệ tài khoản *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A1518),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Tối thiểu 6 ký tự để đăng nhập sau này',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                if (v.trim().length < 6 || v.trim().length > 50) {
                  return 'Mật khẩu phải từ 6 đến 50 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Nhập lại mật khẩu *
            const Text(
              'Nhập lại mật khẩu *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Nhập lại chính xác mật khẩu trên',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Mật khẩu nhập lại không khớp';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7A1518) : const Color(0xFFF7F1EB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF2B1810),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : const Color(0xFF2B1810),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommitmentAndSubmit() {
    return Column(
      children: [
        CheckboxListTile(
          value: _agreedToTerms,
          activeColor: const Color(0xFF7A1518),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Tôi cam kết thông tin khai báo là chính xác và đồng ý tuân thủ Tộc ước dòng họ.',
            style: TextStyle(fontSize: 12.5),
          ),
          onChanged: (val) => setState(() => _agreedToTerms = val ?? true),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitRegistration,
          icon: _isSubmitting
              ? const SizedBox.shrink()
              : const Icon(Icons.how_to_reg, color: Colors.white),
          label: _isSubmitting
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Đang gửi hồ sơ gia nhập...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Hoàn tất đăng ký & Vào dòng họ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7A1518),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Color(0xFFD4A017)),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'Quyền bảo vệ danh dự & sự minh bạch của dòng họ được đảm bảo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7D6E66),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BranchOption {
  final String branchId;
  final String branchName;
  final int? generationLevel;
  final String? representativeName;
  final int memberCount;
  final int depth;

  const _BranchOption({
    required this.branchId,
    required this.branchName,
    this.generationLevel,
    this.representativeName,
    required this.memberCount,
    required this.depth,
  });
}
