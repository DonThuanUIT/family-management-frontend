import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/branch_models.dart';
import '../providers/genealogy_providers.dart';

/// Màn hình biểu mẫu chỉnh sửa thông tin Nhánh Gốc (Root Branch)
/// Đáp ứng yêu cầu Task #16 & Tuân thủ thiết kế Stitch Warm Editorial Heritage.
class EditRootBranchScreen extends ConsumerStatefulWidget {
  const EditRootBranchScreen({super.key});

  @override
  ConsumerState<EditRootBranchScreen> createState() => _EditRootBranchScreenState();
}

class _EditRootBranchScreenState extends ConsumerState<EditRootBranchScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _branchNameController;
  late TextEditingController _representativeIdController;
  late TextEditingController _descriptionController;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _branchNameController = TextEditingController();
    _representativeIdController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _representativeIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncControllersWithData(RootBranchState state) {
    if (state.branch != null && !_isInitialized) {
      _branchNameController.text = state.branch!.branchName;
      _representativeIdController.text = state.branch!.representativeId ?? '';
      _descriptionController.text = state.branch!.description ?? '';
      _isInitialized = true;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final notifier = ref.read(rootBranchProvider.notifier);
    final request = UpdateRootBranchRequestDto(
      branchName: _branchNameController.text.trim(),
      representativeId: _representativeIdController.text.trim().isEmpty
          ? null
          : _representativeIdController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    final success = await notifier.updateRootBranch(request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cập nhật nhánh gốc thành công lên máy chủ!',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF006E2A), // secondary green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      final error = ref.read(rootBranchProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lưu cục bộ: ${error ?? "Đã lưu tạm thời vào bộ nhớ giao diện."}',
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF8F482F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchState = ref.watch(rootBranchProvider);
    _syncControllersWithData(branchState);

    const kPrimaryColor = Color(0xFF8F482F); // Nâu đất / Đỏ son gia phả
    const kBgColor = Color(0xFFFCF9F6);      // Nền ngà ấm
    const kSurfaceColor = Color(0xFFFFFFFF); // Card trắng
    const kBorderColor = Color(0xFFDAC1BA);  // Viền ấm
    const kTextColor = Color(0xFF1C1C1A);    // Chữ đậm
    const kSubtextColor = Color(0xFF54433E); // Chữ phụ

    final branch = branchState.branch;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kSurfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: kTextColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biểu Mẫu Chỉnh Sửa Nhánh Gốc',
              style: TextStyle(
                fontFamily: 'Merriweather',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            Text(
              branch?.clanName.isNotEmpty == true
                  ? branch!.clanName
                  : 'DÒNG HỌ LÊ VIỆT NAM • Nam Trung, Thái Bình',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: kSubtextColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu từ máy chủ',
            icon: const Icon(Icons.refresh, color: kPrimaryColor),
            onPressed: () => ref.read(rootBranchProvider.notifier).loadRootBranch(),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: kBorderColor.withValues(alpha: 0.6), height: 1),
        ),
      ),
      body: branchState.isLoading && branch == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: kPrimaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Đang kết nối API và đồng bộ nhánh gốc...',
                    style: TextStyle(color: kSubtextColor, fontFamily: 'Plus Jakarta Sans'),
                  ),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Archival Root Banner (Phong cách lưu trữ di sản)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF31302F), // inverse-surface espresso
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.military_tech, size: 14, color: Color(0xFFFFB59D)),
                                        SizedBox(width: 6),
                                        Text(
                                          'CỤ KHỞI TỔ • ĐỜI 1',
                                          style: TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFFB59D),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'MÃ: ${branch?.branchId ?? "BR_ROOT"}',
                                    style: const TextStyle(
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 11,
                                      color: Color(0xFFE5E2E0),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                branch?.branchName.isNotEmpty == true
                                    ? branch!.branchName
                                    : 'Chi Gốc Dòng Họ',
                                style: const TextStyle(
                                  fontFamily: 'Merriweather',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFCF9F6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.person_pin, size: 15, color: Color(0xFFFFB59D)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Đại diện: ${branch?.representativeName ?? branch?.representativeId ?? "Cụ Thủy Tổ"}',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      color: Color(0xFFE5E2E0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF99F8A2)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        branchState.isFallback
                                            ? 'Chế độ Demo / Offline (Sẵn sàng kết nối khi Backend khởi động)'
                                            : 'Dữ liệu được đồng bộ trực tiếp từ máy chủ Spring Boot',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: branchState.isFallback
                                              ? const Color(0xFFFFDCBE)
                                              : const Color(0xFF99F8A2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. Thông tin quy tắc cấu trúc bất biến (System Invariant Metadata)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorderColor.withValues(alpha: 0.8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 18, color: kPrimaryColor),
                                  SizedBox(width: 8),
                                  Text(
                                    'Đặc Tính Cấu Trúc Bất Biến',
                                    style: TextStyle(
                                      fontFamily: 'Merriweather',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildMetadataRow('Dòng tộc:', branch?.clanName ?? 'Mặc định'),
                              _buildMetadataRow('Cấp bậc thế hệ:', 'Đời 1 (Khởi tổ phả hệ - Cố định)'),
                              _buildMetadataRow('Nhánh trực thuộc (Cha):', 'Không có (Cội nguồn tối cao)'),
                              _buildMetadataRow('Mã định danh nhánh:', branch?.branchId ?? 'BR_ROOT'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 3. Biểu mẫu chỉnh sửa (Editable Fields)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kBorderColor.withValues(alpha: 0.8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.edit_note, size: 20, color: kPrimaryColor),
                                  SizedBox(width: 8),
                                  Text(
                                    'Thông Tin Có Thể Hiệu Chỉnh',
                                    style: TextStyle(
                                      fontFamily: 'Merriweather',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: kTextColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Các trường sau có thể cập nhật thông qua API PUT /api/v1/branches/root.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: kSubtextColor,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Trường 1: Tên nhánh gốc
                              const Row(
                                children: [
                                  Text(
                                    'Tên Nhánh Gốc',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                      color: kTextColor,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text('*', style: TextStyle(color: Color(0xFFBA1A1A), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _branchNameController,
                                maxLength: 100,
                                decoration: InputDecoration(
                                  hintText: 'Nhập tên nhánh gốc, ví dụ: Chi Gốc Đại Tôn Nam Trung',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.account_tree_outlined, color: kPrimaryColor, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFFBF8F5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kBorderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kBorderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Tên nhánh gốc không được để trống';
                                  }
                                  if (value.trim().length > 100) {
                                    return 'Tên nhánh gốc không được vượt quá 100 ký tự';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Trường 2: Mã thành viên đại diện / Khởi tổ
                              const Text(
                                'Mã Khởi Tổ / Người Đại Diện',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: kTextColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _representativeIdController,
                                decoration: InputDecoration(
                                  hintText: 'Nhập mã thành viên khởi tổ (ví dụ: MEM_001 hoặc để trống)',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                  prefixIcon: const Icon(Icons.person_outline, color: kPrimaryColor, size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFFBF8F5),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kBorderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kBorderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Trường 3: Lược sử & Ghi chú từ đường
                              const Text(
                                'Lược Sử & Ghi Chú Từ Đường',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                  color: kTextColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _descriptionController,
                                maxLines: 4,
                                maxLength: 1000,
                                decoration: InputDecoration(
                                  hintText: 'Ghi chép nguồn gốc, xuất xứ, nhà thờ tổ, ngày giỗ hoặc chỉ dẫn cho con cháu...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
                                  filled: true,
                                  fillColor: const Color(0xFFFBF8F5),
                                  contentPadding: const EdgeInsets.all(14),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kBorderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kBorderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 4. Các nút hành động (Actions)
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: branchState.isSaving
                                    ? null
                                    : () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go('/home');
                                        }
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: kBorderColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text(
                                  'Hủy Bỏ',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: kSubtextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: branchState.isSaving ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: branchState.isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save_outlined, size: 18, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Lưu Thay Đổi Nhánh Gốc',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12.5,
                color: Color(0xFF54433E),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
