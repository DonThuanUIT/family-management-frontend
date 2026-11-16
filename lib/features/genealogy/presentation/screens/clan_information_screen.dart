import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../contribution/data/models/contribution_models.dart';
import '../../../contribution/presentation/providers/contribution_ui_provider.dart';
import '../../../event/presentation/providers/event_providers.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';

/// Mục Thông Tin & Cấu Hình Dòng Họ (Clan Settings & Information)
/// Tách rời tài khoản ngân hàng thụ hưởng dòng họ khỏi hồ sơ cá nhân.
/// Tích hợp lưu trữ bảng định giá benchmark hiện vật cúng tiến (US-10).
/// Phân quyền Dual-RBAC rõ ràng:
/// - Trưởng Tộc / Admin: Toàn quyền cập nhật tài khoản ngân hàng, thông tin dòng họ, thêm/xóa benchmark.
/// - Thủ Quỹ: Có quyền thêm/xóa định mức benchmark hiện vật.
/// - Thành Viên / Trưởng Chi: Chỉ xem thông tin, quét mã VietQR và tra cứu định mức.
class ClanInformationScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ClanInformationScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ClanInformationScreen> createState() =>
      _ClanInformationScreenState();
}

class _ClanInformationScreenState extends ConsumerState<ClanInformationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String? _selectedEventId = 'EVT-GIO-TO-2026';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dualRbacSessionProvider);
    final authState = ref.watch(authStateProvider);
    final bankingAsync = ref.watch(clanBankingInfoProvider);
    final eventsState = ref.watch(eventListProvider);

    final isClanHead =
        session.isClanHead ||
        session.isAdmin ||
        authState.user?.roles.contains('ROLE_CLAN_HEAD') == true ||
        authState.user?.roles.contains('ROLE_ADMIN') == true;

    final canManageBenchmarks =
        isClanHead ||
        session.isBranchHead ||
        authState.user?.roles.any(
              (r) =>
                  r == 'ROLE_CLAN_HEAD' ||
                  r == 'ROLE_ADMIN' ||
                  r == 'ROLE_TREASURER',
            ) ==
            true;

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F6),
      appBar: const HeritageNavBar(currentRoute: '/clan-info'),
      bottomNavigationBar: const HeritageBottomNavBar(
        currentRoute: '/clan-info',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 40 : 16,
          vertical: 24,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                _buildHeaderBanner(context, isClanHead, isWide),
                const SizedBox(height: 20),

                // Tab Selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6DFD8)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF8B1E1E),
                    unselectedLabelColor: const Color(0xFF6B584E),
                    indicatorColor: const Color(0xFF8B1E1E),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.account_balance, size: 20),
                        text: 'Tài Khoản Ngân Hàng & VietQR',
                      ),
                      Tab(
                        icon: Icon(Icons.price_check, size: 20),
                        text: 'Định Giá Benchmark Hiện Vật',
                      ),
                      Tab(
                        icon: Icon(Icons.assured_workload, size: 20),
                        text: 'Hồ Sơ & Lược Sử Dòng Họ',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tab Content
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final index = _tabController.index;
                    if (index == 0) {
                      return _buildBankingTab(
                        context,
                        bankingAsync,
                        isClanHead,
                        isWide,
                      );
                    } else if (index == 1) {
                      return _buildBenchmarksTab(
                        context,
                        eventsState,
                        canManageBenchmarks,
                        isWide,
                      );
                    } else {
                      return _buildClanProfileTab(
                        context,
                        bankingAsync,
                        isClanHead,
                        isWide,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Header Banner
  Widget _buildHeaderBanner(
    BuildContext context,
    bool isClanHead,
    bool isWide,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1E1A), Color(0xFF4A342E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A017).withAlpha(40),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
            ),
            child: const Center(
              child: Icon(
                Icons.assured_workload,
                color: Color(0xFFD4A017),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Thông Tin & Cấu Hình Dòng Họ',
                        style: TextStyle(
                          fontFamily: 'Merriweather',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isClanHead
                            ? const Color(0xFF006E2A).withAlpha(40)
                            : Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isClanHead
                              ? const Color(0xFF4ADE80)
                              : Colors.white38,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isClanHead
                                ? Icons.verified_user
                                : Icons.visibility_outlined,
                            size: 13,
                            color: isClanHead
                                ? const Color(0xFF4ADE80)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isClanHead
                                ? 'Quyền Quản Trị: Trưởng Tộc'
                                : 'Chế Độ Xem: Thành Viên',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isClanHead
                                  ? const Color(0xFF4ADE80)
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Quản lý tài khoản ngân hàng thụ hưởng VietQR chính thức và bảng định mức giá tham chiếu quy đổi hiện vật cúng tiến của toàn Dòng họ.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFDAC1BA),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Tab 1: Tài Khoản Ngân Hàng & VietQR
  Widget _buildBankingTab(
    BuildContext context,
    AsyncValue<ClanBankingInfoDto> bankingAsync,
    bool isClanHead,
    bool isWide,
  ) {
    return bankingAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Lỗi tải thông tin tài khoản ngân hàng: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (banking) {
        final qrUrl =
            (banking.bankAccountNumber.isNotEmpty && banking.bankBin.isNotEmpty)
            ? 'https://img.vietqr.io/image/${banking.bankBin}-${banking.bankAccountNumber}-${banking.qrTemplate}.png?amount=0&addInfo=${Uri.encodeComponent("DONG HO NGUYEN DUNG LE")}&accountName=${Uri.encodeComponent(banking.bankAccountName)}'
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6DFD8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B1E1E).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          color: Color(0xFF8B1E1E),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tài Khoản Ngân Hàng Thụ Hưởng Chính Thức Của Dòng Họ',
                              style: TextStyle(
                                fontFamily: 'Merriweather',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B1810),
                              ),
                            ),
                            Text(
                              'Được dùng làm tài khoản thụ hưởng khi con cháu quét mã VietQR dâng lễ hoặc đóng góp trực tuyến.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7D6E66),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isClanHead)
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showEditClanBankingDialog(context, banking),
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('Cập Nhật Tài Khoản'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1E1E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 32),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildBankingDetailsColumn(banking)),
                        const SizedBox(width: 32),
                        _buildQrCodeCard(banking, qrUrl),
                      ],
                    )
                  else ...[
                    _buildBankingDetailsColumn(banking),
                    const SizedBox(height: 24),
                    Center(child: _buildQrCodeCard(banking, qrUrl)),
                  ],
                  const SizedBox(height: 20),
                  if (!isClanHead)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE6DFD8)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Color(0xFF006E2A),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tài khoản ngân hàng thụ hưởng này được xác thực và bảo mật 100%. Mọi biến động số dư từ chuyển khoản quét VietQR đều tự động đồng bộ vào Sổ Cái Gia Tộc.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF54433E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBankingDetailsColumn(ClanBankingInfoDto banking) {
    return Column(
      children: [
        _buildInfoTile(
          icon: Icons.account_balance,
          label: 'Ngân hàng thụ hưởng',
          value:
              '${banking.bankName ?? "Napas 247"} (Mã BIN: ${banking.bankBin})',
        ),
        const SizedBox(height: 10),
        _buildInfoTile(
          icon: Icons.numbers,
          label: 'Số tài khoản thụ hưởng',
          value: banking.bankAccountNumber.isNotEmpty
              ? banking.bankAccountNumber
              : 'Chưa cấu hình số tài khoản',
          isMonospace: true,
          copyable: banking.bankAccountNumber.isNotEmpty,
          onCopy: () {
            Clipboard.setData(ClipboardData(text: banking.bankAccountNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã sao chép số tài khoản vào bộ nhớ tạm!'),
                backgroundColor: Color(0xFF006E2A),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildInfoTile(
          icon: Icons.person_pin,
          label: 'Tên chủ tài khoản thụ hưởng',
          value: banking.bankAccountName.isNotEmpty
              ? banking.bankAccountName
              : 'HỘI ĐỒNG GIA TỘC DÒNG HỌ',
          isMonospace: true,
        ),
        const SizedBox(height: 10),
        _buildInfoTile(
          icon: Icons.qr_code,
          label: 'Mẫu hiển thị VietQR',
          value: banking.qrTemplate == 'compact2'
              ? 'Chuẩn VietQR Vector (Đầy đủ thông tin)'
              : banking.qrTemplate,
        ),
      ],
    );
  }

  Widget _buildQrCodeCard(ClanBankingInfoDto banking, String? qrUrl) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.qr_code_2, color: Color(0xFF8B1E1E), size: 18),
              SizedBox(width: 6),
              Text(
                'Mã VietQR Dòng Họ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: Color(0xFF2B1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (qrUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                qrUrl,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.white,
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Color(0xFF8B1E1E),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 200,
              height: 200,
              color: Colors.white,
              child: const Center(
                child: Text(
                  'Chưa có mã QR',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'Quét bằng App mọi ngân hàng\n(Napas 247 nhận tiền tức thì)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: Color(0xFF6B584E),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Tab 2: Định Giá Benchmark Hiện Vật
  Widget _buildBenchmarksTab(
    BuildContext context,
    EventListState eventsState,
    bool canManageBenchmarks,
    bool isWide,
  ) {
    final benchmarksAsync =
        _selectedEventId != null && _selectedEventId!.isNotEmpty
        ? ref.watch(eventBenchmarksProvider(_selectedEventId!))
        : ref.watch(clanBenchmarksProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A017).withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.price_check,
                  color: Color(0xFF8A5300),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bảng Định Mức Giá Tham Chiếu Quy Đổi Hiện Vật (US-10)',
                      style: TextStyle(
                        fontFamily: 'Merriweather',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B1810),
                      ),
                    ),
                    Text(
                      'Định mức do Ban Tổ Chức & Hội Đồng Gia Tộc ban hành để quy đổi hiện vật cúng tiến thành giá trị tương đương.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7D6E66)),
                    ),
                  ],
                ),
              ),
              if (canManageBenchmarks)
                ElevatedButton.icon(
                  onPressed: () => _showAddBenchmarkDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Thêm Định Mức Mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006E2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFECE6DF)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.celebration_outlined,
                  size: 18,
                  color: Color(0xFF8B1E1E),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sự kiện áp dụng:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Color(0xFF54433E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: eventsState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedEventId,
                            isDense: true,
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Tất cả định mức của Dòng họ',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              ...eventsState.events.map((e) {
                                return DropdownMenuItem<String?>(
                                  value: e.eventId,
                                  child: Text(
                                    e.eventName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2B1810),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedEventId = val);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Benchmarks List / Table
          benchmarksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Lỗi tải danh mục định mức benchmark: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
            data: (benchmarks) {
              if (benchmarks.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8DFD8)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 44,
                        color: Color(0xFFBCAAA4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Chưa có định mức hiện vật nào được ban hành cho sự kiện này.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF54433E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Các hiện vật cúng tiến chưa có trong định mức có thể quy đổi theo phương thức Hóa đơn thực tế (Invoice) hoặc Thỏa thuận (Agreement).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C7E77),
                        ),
                      ),
                      if (canManageBenchmarks) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddBenchmarkDialog(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Ban Hành Định Mức Đầu Tiên'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006E2A),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3ECE5),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'TÊN HIỆN VẬT CÚNG TIẾN',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'ĐƠN VỊ TÍNH',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'ĐƠN GIÁ ĐỊNH MỨC',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'QUY CHUẨN & GHI CHÚ',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B1E1E),
                            ),
                          ),
                        ),
                        SizedBox(width: 48), // Action space
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: benchmarks.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFECE6DF)),
                    itemBuilder: (ctx, idx) {
                      final item = benchmarks[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: idx % 2 == 0
                              ? Colors.white
                              : const Color(0xFFFCFBF9),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B1E1E)
                                          .withAlpha(12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.egg_alt_outlined,
                                      size: 16,
                                      color: Color(0xFF8B1E1E),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: Color(0xFF2B1810),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDE9E5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.unit,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF54433E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                currencyFormatter.format(item.unitPrice),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006E2A),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                item.note?.isNotEmpty == true
                                    ? item.note!
                                    : 'Định mức tiêu chuẩn lễ giỗ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B584E),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              child: canManageBenchmarks
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Color(0xFFBA1A1A),
                                      ),
                                      tooltip: 'Xóa định mức này',
                                      onPressed: () => _confirmDeleteBenchmark(
                                        context,
                                        item,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // 4. Tab 3: Hồ Sơ & Lược Sử Dòng Họ
  Widget _buildClanProfileTab(
    BuildContext context,
    AsyncValue<ClanBankingInfoDto> bankingAsync,
    bool isClanHead,
    bool isWide,
  ) {
    return bankingAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Lỗi tải hồ sơ dòng họ: $e')),
      data: (clan) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6DFD8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1E1E).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.history_edu,
                      color: Color(0xFF8B1E1E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hồ Sơ Danh Tính & Lược Sử Dòng Họ',
                          style: TextStyle(
                            fontFamily: 'Merriweather',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        Text(
                          'Thông tin khởi tổ, từ đường tổ, niên hiệu thành lập và tộc ước truyền đời.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7D6E66),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isClanHead)
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showEditClanBankingDialog(context, clan),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Chỉnh Sửa Hồ Sơ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E1E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const Divider(height: 32),
              _buildInfoTile(
                icon: Icons.shield,
                label: 'Tên dòng họ chính thức',
                value: clan.clanName ?? 'Dòng họ Nguyễn Tộc (Đại Tôn)',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.person_outline,
                label: 'Khởi tổ / Thủy tổ dòng họ',
                value: clan.ancestorName ?? 'Nguyễn Khởi Tổ',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ Từ Đường tổ / Nơi phát tích',
                value:
                    clan.originLocation ??
                    'Từ Đường Dòng Họ Nguyễn (Đại Tôn), Bắc Ninh',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.calendar_month_outlined,
                label: 'Năm khởi lập dòng họ',
                value: clan.establishedYear != null
                    ? '${clan.establishedYear} (Niên hiệu Triều Nguyễn)'
                    : '1845 (Niên hiệu Triều Nguyễn)',
              ),
              const SizedBox(height: 12),
              _buildInfoTile(
                icon: Icons.menu_book_outlined,
                label: 'Lược sử & Tộc ước dòng họ',
                value: clan.description?.isNotEmpty == true
                    ? clan.description!
                    : 'Dòng họ Nguyễn Tộc khởi lập từ đường lưu truyền gia phong, gìn giữ cội nguồn muôn đời thịnh vượng. Mọi con cháu đồng tâm hiệp lực phụng sự tổ tiên và phát triển dòng tộc.',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
    bool copyable = false,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE6DF)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF8B1E1E)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8C7E77),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: isMonospace ? 'monospace' : null,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2B1810),
                  ),
                ),
              ],
            ),
          ),
          if (copyable) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.copy, size: 16, color: Color(0xFF8B1E1E)),
              onPressed: onCopy,
              tooltip: 'Sao chép',
            ),
          ],
        ],
      ),
    );
  }

  // DIALOG 1: Cập nhật tài khoản ngân hàng & thông tin dòng họ (Trưởng tộc only)
  void _showEditClanBankingDialog(
    BuildContext context,
    ClanBankingInfoDto current,
  ) {
    final binCtrl = TextEditingController(text: current.bankBin);
    final accNumCtrl = TextEditingController(text: current.bankAccountNumber);
    final accNameCtrl = TextEditingController(text: current.bankAccountName);
    final clanNameCtrl = TextEditingController(text: current.clanName ?? '');
    final ancestorCtrl = TextEditingController(
      text: current.ancestorName ?? '',
    );
    final originCtrl = TextEditingController(
      text: current.originLocation ?? '',
    );
    final yearCtrl = TextEditingController(
      text: current.establishedYear?.toString() ?? '',
    );
    final descCtrl = TextEditingController(text: current.description ?? '');

    String selectedTemplate = current.qrTemplate;
    bool isSubmitting = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1E1E).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_suggest,
                  color: Color(0xFF8B1E1E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Cập Nhật Thông Tin & Tài Khoản Dòng Họ',
                  style: TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. THÔNG TIN TÀI KHOẢN NGÂN HÀNG THỤ HƯỞNG:',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B1E1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: binCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mã BIN ngân hàng (6 chữ số chuẩn Napas) *',
                      hintText: 'Ví dụ: 970415 (VietinBank), 970436 (VCB)...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accNumCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản ngân hàng thụ hưởng *',
                      hintText: 'Nhập số tài khoản dòng họ...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: accNameCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản thụ hưởng (In hoa) *',
                      hintText: 'Ví dụ: NGUYEN TRONG HOANG HOAC DONG HO NGUYEN',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '2. THÔNG TIN HỒ SƠ & LƯỢC SỬ DÒNG HỌ:',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B1E1E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: clanNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên Dòng Họ Chính Thức',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ancestorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Khởi Tổ / Thủy Tổ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: originCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ Từ Đường tổ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: yearCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Năm thành lập / Khởi lập',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Lược sử & Tộc ước dòng họ',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final bin = binCtrl.text.trim();
                      final accNum = accNumCtrl.text.trim();
                      final accName = accNameCtrl.text.trim();

                      if (bin.length != 6 || int.tryParse(bin) == null) {
                        setDialogState(
                          () => errorText =
                              'Mã BIN phải gồm đúng 6 chữ số theo chuẩn Napas!',
                        );
                        return;
                      }
                      if (accNum.isEmpty) {
                        setDialogState(
                          () => errorText =
                              'Vui lòng nhập số tài khoản ngân hàng!',
                        );
                        return;
                      }
                      if (accName.isEmpty) {
                        setDialogState(
                          () => errorText =
                              'Vui lòng nhập tên chủ tài khoản ngân hàng!',
                        );
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        errorText = null;
                      });

                      try {
                        final req = UpdateClanBankingRequestDto(
                          bankBin: bin,
                          bankAccountNumber: accNum,
                          bankAccountName: accName,
                          qrTemplate: selectedTemplate,
                          clanName: clanNameCtrl.text.trim(),
                          ancestorName: ancestorCtrl.text.trim(),
                          originLocation: originCtrl.text.trim(),
                          establishedYear: int.tryParse(yearCtrl.text.trim()),
                          description: descCtrl.text.trim(),
                        );

                        await ref
                            .read(contributionUiProvider.notifier)
                            .updateClanBankingInfo(req);

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cập nhật thông tin dòng họ & tài khoản ngân hàng thành công!',
                              ),
                              backgroundColor: Color(0xFF006E2A),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                          errorText = 'Lỗi cập nhật: $e';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1E1E),
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Lưu Thay Đổi'),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG 2: Thêm định mức hiện vật cúng tiến mới (Trưởng tộc / Thủ quỹ only)
  void _showAddBenchmarkDialog(BuildContext context) {
    final itemCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'con');
    final priceCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    bool isSubmitting = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006E2A).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_task,
                  color: Color(0xFF006E2A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ban Hành Định Mức Hiện Vật Cúng Tiến',
                  style: TextStyle(
                    fontFamily: 'Merriweather',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Định mức này sẽ được hệ thống áp dụng tự động khi tiếp nhận hiện vật cúng tiến theo chuẩn BTC (US-10).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B584E)),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: itemCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên hiện vật / đồ lễ cúng *',
                      hintText: 'Ví dụ: Heo quay nguyên con, Mâm xôi gà...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Đơn vị tính *',
                            hintText: 'Ví dụ: con, mâm, bộ, bức...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Đơn giá định mức (VNĐ) *',
                            hintText: 'Ví dụ: 4000000',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Quy chuẩn & Ghi chú định mức',
                      hintText: 'Ví dụ: Heo quay từ 15-20kg loại 1 dâng cúng tế tổ...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = itemCtrl.text.trim();
                      final unit = unitCtrl.text.trim();
                      final price = double.tryParse(
                        priceCtrl.text.replaceAll('.', '').trim(),
                      );

                      if (name.isEmpty) {
                        setDialogState(
                          () => errorText =
                              'Vui lòng nhập tên hiện vật cúng tiến!',
                        );
                        return;
                      }
                      if (unit.isEmpty) {
                        setDialogState(
                          () => errorText = 'Vui lòng nhập đơn vị tính!',
                        );
                        return;
                      }
                      if (price == null || price <= 0) {
                        setDialogState(
                          () => errorText =
                              'Đơn giá định mức phải lớn hơn 0 VNĐ!',
                        );
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        errorText = null;
                      });

                      try {
                        final eventIdToUse =
                            _selectedEventId?.isNotEmpty == true
                            ? _selectedEventId!
                            : 'EVT-GIO-TO-2026';

                        await ref
                            .read(contributionUiProvider.notifier)
                            .createEventItemBenchmark(
                              eventId: eventIdToUse,
                              request: CreateEventItemBenchmarkRequestDto(
                                itemName: name,
                                unit: unit,
                                unitPrice: price,
                                note: noteCtrl.text.trim(),
                              ),
                            );

                        if (context.mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã ban hành định mức cho "$name" thành công!',
                              ),
                              backgroundColor: const Color(0xFF006E2A),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                          errorText = 'Lỗi tạo định mức: $e';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006E2A),
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Ban Hành Định Mức'),
            ),
          ],
        ),
      ),
    );
  }

  // DIALOG 3: Xác nhận xóa định mức hiện vật
  void _confirmDeleteBenchmark(
    BuildContext context,
    EventItemBenchmarkDto item,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xác Nhận Xóa Định Mức'),
        content: Text(
          'Bạn có chắc chắn muốn xóa định mức giá của "${item.itemName}" (${currencyFormatter.format(item.unitPrice)}/${item.unit}) không?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(contributionUiProvider.notifier)
                    .deleteEventItemBenchmark(
                      eventId: item.eventId,
                      benchmarkId: item.benchmarkId,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa định mức "${item.itemName}"!'),
                      backgroundColor: const Color(0xFF8B1E1E),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi xóa định mức: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa Định Mức'),
          ),
        ],
      ),
    );
  }
}
