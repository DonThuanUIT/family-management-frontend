import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../genealogy/data/models/branch_models.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../data/models/contribution_models.dart';
import '../../data/repositories/contribution_repository_impl.dart';
import '../providers/contribution_ui_provider.dart';
import '../widgets/electronic_receipt_dialog.dart';

/// Hình thức đóng góp trực tuyến
enum ContributionScope {
  individual,
  jointGroup,
}

/// Trạng thái của từng dòng thành viên khi đóng góp theo Hộ gia đình / Nhóm con cháu
class AllocationItemState {
  String? memberId;
  String? memberName;
  String? generation;
  final TextEditingController amountController;

  AllocationItemState({
    this.memberId,
    this.memberName,
    this.generation,
    String initialAmount = '',
  }) : amountController = TextEditingController(text: initialAmount);

  double get amount =>
      double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

  void dispose() {
    amountController.dispose();
  }
}

/// Màn hình 'Đóng góp trực tuyến' cho con cháu ở xa (US-53, Task #187).
/// Hỗ trợ cả Đóng góp cá nhân (đơn lẻ) & Đóng góp theo Hộ Gia Đình / Nhóm Con Cháu.
/// Nhập số tiền -> hiển thị mã VietQR quét trực tiếp bằng App Ngân hàng -> nhận phiếu thu điện tử tự động.
/// Nối 100% Backend REST API (POST /api/v1/contributions/vietqr/generate & POST /api/v1/contributions/vietqr/webhook).
class OnlineContributionScreen extends ConsumerStatefulWidget {
  final String? initialEventId;

  const OnlineContributionScreen({super.key, this.initialEventId});

  @override
  ConsumerState<OnlineContributionScreen> createState() =>
      _OnlineContributionScreenState();
}

class _OnlineContributionScreenState
    extends ConsumerState<OnlineContributionScreen> {
  final _amountCtrl = TextEditingController(text: '500000');
  final _noteCtrl = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  late String _selectedEventId;
  bool _isGenerating = false;
  String? _errorMessage;
  VietQrResponseDto? _generatedQr;

  ContributionScope _scope = ContributionScope.individual;
  final List<AllocationItemState> _groupAllocations = [];
  List<MemberAllocationDto> _committedAllocations = [];

  double get _totalGroupAmount =>
      _groupAllocations.fold(0.0, (sum, item) => sum + item.amount);

  final List<double> _presetAmounts = [
    200000,
    500000,
    1000000,
    2000000,
    5000000,
    10000000,
  ];

  bool _isVerifyingPayment = false;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId ?? 'EVT-GIO-TO-2026';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    for (final item in _groupAllocations) {
      item.dispose();
    }
    super.dispose();
  }

  void _initializeDefaultGroupAllocations(List<BranchMemberItem> members) {
    if (_groupAllocations.isNotEmpty) return;

    final authState = ref.read(authStateProvider);
    final session = ref.read(dualRbacSessionProvider);
    final userMemberId = (authState.user?.memberId != null && authState.user!.memberId!.isNotEmpty)
        ? authState.user!.memberId!
        : session.memberId;

    BranchMemberItem? primaryMember;
    if (members.isNotEmpty) {
      primaryMember = members.firstWhere(
        (m) => m.memberId == userMemberId,
        orElse: () => members.first,
      );
    }

    if (primaryMember != null) {
      _groupAllocations.add(
        AllocationItemState(
          memberId: primaryMember.memberId,
          memberName: primaryMember.fullName,
          generation: primaryMember.roleInBranch,
          initialAmount: '500000',
        ),
      );
    }

    // Thêm ô thứ 2 cho thành viên tiếp theo trong gia đình nếu có
    final remaining = members.where((m) => m.memberId != primaryMember?.memberId).toList();
    if (remaining.isNotEmpty) {
      final secondMember = remaining.first;
      _groupAllocations.add(
        AllocationItemState(
          memberId: secondMember.memberId,
          memberName: secondMember.fullName,
          generation: secondMember.roleInBranch,
          initialAmount: '500000',
        ),
      );
    } else {
      _groupAllocations.add(
        AllocationItemState(initialAmount: '500000'),
      );
    }
  }

  void _addGroupAllocationRow(List<BranchMemberItem> members) {
    final selectedIds =
        _groupAllocations.map((a) => a.memberId).whereType<String>().toSet();
    final candidate = members.firstWhere(
      (m) => !selectedIds.contains(m.memberId),
      orElse: () => members.isNotEmpty
          ? members.first
          : const BranchMemberItem(
              memberId: '',
              fullName: '',
              generation: 1,
              roleInBranch: '',
            ),
    );

    setState(() {
      _groupAllocations.add(
        AllocationItemState(
          memberId: candidate.memberId.isNotEmpty ? candidate.memberId : null,
          memberName: candidate.fullName.isNotEmpty ? candidate.fullName : null,
          generation: candidate.roleInBranch.isNotEmpty ? candidate.roleInBranch : null,
          initialAmount: '500000',
        ),
      );
    });
  }

  void _removeGroupAllocationRow(int index) {
    if (_groupAllocations.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cần ít nhất 1 thành viên trong danh sách đóng góp nhóm.'),
          backgroundColor: Color(0xFFC64545),
        ),
      );
      return;
    }
    setState(() {
      final removed = _groupAllocations.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _handleGenerateQr() async {
    double totalAmount = 0;
    List<MemberAllocationDto> allocationsToCommit = [];

    if (_scope == ContributionScope.individual) {
      totalAmount =
          double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (totalAmount < 1000) {
        setState(() => _errorMessage = 'Số tiền đóng góp tối thiểu là 1,000 VNĐ');
        return;
      }
      allocationsToCommit = [];
    } else {
      if (_groupAllocations.isEmpty) {
        setState(() => _errorMessage =
            'Vui lòng thêm ít nhất một thành viên trong nhóm đóng góp');
        return;
      }

      final Set<String> seenIds = {};
      for (int i = 0; i < _groupAllocations.length; i++) {
        final item = _groupAllocations[i];
        if (item.memberId == null || item.memberId!.trim().isEmpty) {
          setState(() =>
              _errorMessage = 'Vui lòng chọn thành viên cho dòng thứ ${i + 1}');
          return;
        }
        if (item.amount < 1000) {
          setState(() => _errorMessage =
              'Số tiền cho ${item.memberName ?? "thành viên"} phải từ 1,000 VNĐ trở lên');
          return;
        }
        if (seenIds.contains(item.memberId)) {
          setState(() => _errorMessage =
              'Thành viên "${item.memberName}" bị trùng lặp. Mỗi thành viên chỉ chọn 1 lần.');
          return;
        }
        seenIds.add(item.memberId!);
      }

      totalAmount = _totalGroupAmount;
      if (totalAmount < 1000) {
        setState(
            () => _errorMessage = 'Tổng số tiền đóng góp tối thiểu là 1,000 VNĐ');
        return;
      }

      allocationsToCommit = _groupAllocations.map((item) {
        final pct = totalAmount > 0 ? (item.amount / totalAmount * 100) : 0.0;
        return MemberAllocationDto(
          memberId: item.memberId!,
          memberName: item.memberName ?? item.memberId!,
          generation: item.generation ?? 'Thành viên',
          amount: item.amount,
          percentage: pct,
        );
      }).toList();
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final session = ref.read(dualRbacSessionProvider);
      final userMemberId = authState.user?.memberId;
      String memberId = (userMemberId != null && userMemberId.isNotEmpty)
          ? userMemberId
          : session.memberId;

      if (memberId.isEmpty && allocationsToCommit.isNotEmpty) {
        memberId = allocationsToCommit.first.memberId;
      }

      final repo = ref.read(contributionRepositoryProvider);
      final qrResponse = await repo.generateVietQr(
        GenerateVietQrRequestDto(
          eventId: _selectedEventId,
          memberId: memberId.isNotEmpty ? memberId : null,
          amount: totalAmount,
          note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
        ),
      );

      if (mounted) {
        setState(() {
          _generatedQr = qrResponse;
          _committedAllocations = allocationsToCommit;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tạo mã VietQR: $e';
          _isGenerating = false;
        });
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        backgroundColor: const Color(0xFF006E2A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Xây dựng chuỗi VietQR EMVCo tiêu chuẩn Napas 247 cho ứng dụng ngân hàng quét trực tiếp
  String _buildVietQrPayload(VietQrResponseDto qr) {
    if (qr.bankBin.isEmpty || qr.accountNumber.isEmpty) {
      return qr.qrPayload.isNotEmpty ? qr.qrPayload : qr.qrCodeUrl;
    }

    String tlv(String tag, String value) {
      final len = value.length.toString().padLeft(2, '0');
      return '$tag$len$value';
    }

    String calcCrc16(String str) {
      int crc = 0xFFFF;
      for (int i = 0; i < str.length; i++) {
        int c = str.codeUnitAt(i);
        crc ^= (c << 8);
        for (int j = 0; j < 8; j++) {
          if ((crc & 0x8000) != 0) {
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
          } else {
            crc = (crc << 1) & 0xFFFF;
          }
        }
      }
      return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
    }

    // Tiêu chuẩn VietQR Napas EMVCo
    final f00 = tlv('00', '01');
    final f01 = tlv('01', '12'); // 12 = Dynamic QR (có số tiền)

    // Tag 38: Thông tin ngân hàng thụ hưởng (Merchant Info)
    final guid = tlv('00', 'A000000727');
    final beneficiary = tlv('00', qr.bankBin) + tlv('01', qr.accountNumber);
    final sub38_01 = tlv('01', beneficiary);
    final serviceCode = tlv('02', 'QRIBFTTA');
    final f38 = tlv('38', guid + sub38_01 + serviceCode);

    final f53 = tlv('53', '704'); // VND
    final f54 = tlv('54', qr.amount.toInt().toString());
    final f58 = tlv('58', 'VN');

    // Tag 62: Nội dung chuyển khoản
    final sub62_08 = tlv('08', qr.transferContent);
    final f62 = tlv('62', sub62_08);

    final rawWithoutCrc = '$f00$f01$f38$f53$f54$f58$f62' '6304';
    final crc = calcCrc16(rawWithoutCrc);
    return '$rawWithoutCrc$crc';
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF8B1E1E);
    const kBgColor = Color(0xFFFAF9F6);

    final membersAsync = ref.watch(genealogyMemberListProvider);
    final memberList = membersAsync.value ?? const <BranchMemberItem>[];

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: const HeritageNavBar(currentRoute: '/contributions/online'),
      bottomNavigationBar:
          const HeritageBottomNavBar(currentRoute: '/contributions/online'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4A017)),
                      ),
                      child: const Icon(Icons.qr_code_2,
                          color: kPrimaryColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đóng Góp Trực Tuyến Qua VietQR',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                          Text(
                            'Hỗ trợ cúng tiến đơn lẻ hoặc theo Hộ gia đình / Nhóm con cháu & nhận phiếu thu điện tử',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12.5,
                              color: Color(0xFF6B584E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hiển thị tài khoản ngân hàng chính thức của Dòng họ (Multi-tenant Clan Banking Info)
                ref.watch(clanBankingInfoProvider).when(
                      data: (banking) => Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFD4A017)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4A017)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance,
                                  color: Color(0xFF8B1E1E), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TÀI KHOẢN QUỸ DÒNG HỌ TIẾP NHẬN: ${banking.clanName ?? 'Gia tộc'}',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8B1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${banking.bankName ?? 'Ngân hàng'} • STK: ${banking.bankAccountNumber} • Chủ TK: ${banking.bankAccountName}',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2B1810),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),

                if (_generatedQr == null) ...[
                  // BƯỚC 1: LỰA CHỌN PHƯƠNG THỨC & NHẬP THÔNG TIN ĐÓNG GÓP
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle chọn hình thức: Đơn lẻ vs Hộ gia đình / Nhóm con cháu
                        Container(
                          margin: const EdgeInsets.only(bottom: 22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F2EC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5DDD3)),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _scope = ContributionScope.individual;
                                      _errorMessage = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(9),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _scope == ContributionScope.individual
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow:
                                          _scope == ContributionScope.individual
                                              ? const [
                                                  BoxShadow(
                                                    color: Color(0x14000000),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  )
                                                ]
                                              : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 18,
                                          color: _scope ==
                                                  ContributionScope.individual
                                              ? kPrimaryColor
                                              : const Color(0xFF6B584E),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Cá Nhân (Đơn lẻ)',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 13.5,
                                            fontWeight: _scope ==
                                                    ContributionScope.individual
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: _scope ==
                                                    ContributionScope.individual
                                                ? kPrimaryColor
                                                : const Color(0xFF6B584E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _scope = ContributionScope.jointGroup;
                                      _errorMessage = null;
                                      if (_groupAllocations.isEmpty) {
                                        _initializeDefaultGroupAllocations(
                                            memberList);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(9),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: _scope == ContributionScope.jointGroup
                                          ? Colors.white
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow:
                                          _scope == ContributionScope.jointGroup
                                              ? const [
                                                  BoxShadow(
                                                    color: Color(0x14000000),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 2),
                                                  )
                                                ]
                                              : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.family_restroom,
                                          size: 18,
                                          color: _scope ==
                                                  ContributionScope.jointGroup
                                              ? kPrimaryColor
                                              : const Color(0xFF6B584E),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Hộ Gia Đình / Nhóm Con Cháu',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 13.5,
                                            fontWeight: _scope ==
                                                    ContributionScope.jointGroup
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color: _scope ==
                                                    ContributionScope.jointGroup
                                                ? kPrimaryColor
                                                : const Color(0xFF6B584E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_scope == ContributionScope.individual) ...[
                          // MODE 1: CÁ NHÂN (ĐƠN LẺ)
                          const Text(
                            '1. Nhập số tiền công đức cúng tiến (VNĐ) *',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B1810),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Input số tiền
                          TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                            decoration: InputDecoration(
                              suffixText: 'VNĐ',
                              suffixStyle: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Các mức tiền gợi ý
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _presetAmounts.map((amt) {
                              return ActionChip(
                                label: Text(_currencyFormat.format(amt)),
                                onPressed: () {
                                  setState(() {
                                    _amountCtrl.text = amt.toInt().toString();
                                  });
                                },
                                backgroundColor: const Color(0xFFF9F7F5),
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ] else ...[
                          // MODE 2: HỘ GIA ĐÌNH / NHÓM CON CHÁU
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDFBF7),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE8DFD8)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.diversity_3,
                                            color: Color(0xFF8B1E1E), size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Phân bổ thành viên trong gia đình',
                                          style: TextStyle(
                                            fontFamily: 'Merriweather',
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2B1810),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B1E1E)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_groupAllocations.length} thành viên',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8B1E1E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Một người đứng ra quét VietQR thanh toán tổng tiền. Sổ Cái sẽ ghi danh và xuất phiếu thu phân bổ chi tiết cho từng người.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF755B53),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                ...List.generate(_groupAllocations.length, (index) {
                                  final item = _groupAllocations[index];
                                  return _buildAllocationRow(
                                      index, item, memberList);
                                }),

                                const SizedBox(height: 4),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _addGroupAllocationRow(memberList),
                                  icon: const Icon(Icons.person_add_alt_1,
                                      size: 18),
                                  label: const Text(
                                      '＋ Thêm Thành Viên Trong Gia Đình / Nhóm'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF8B1E1E),
                                    side: const BorderSide(
                                        color: Color(0xFFD4A017)),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Bảng tổng cộng
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B1E1E)
                                        .withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFF8B1E1E)
                                            .withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Tổng số tiền chuyển khoản (Cả nhà):',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2B1810),
                                        ),
                                      ),
                                      Text(
                                        _currencyFormat
                                            .format(_totalGroupAmount),
                                        style: const TextStyle(
                                          fontFamily: 'Merriweather',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF8B1E1E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Lời chúc / Lời cúng tiến
                        const Text(
                          '2. Lời cúng tiến / Lời chúc mừng dòng họ',
                          style: TextStyle(
                            fontFamily: 'Merriweather',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2B1810),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: _scope == ContributionScope.jointGroup
                                ? 'VD: Gia đình con cháu anh Tuấn kính cúng tiến ngày Đại lễ Giỗ Tổ...'
                                : 'VD: Con cháu chi 2 kính cúng tiến ngày Đại lễ Giỗ Tổ...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFBA1A1A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFBA1A1A), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage!,
                                      style: const TextStyle(
                                          color: Color(0xFFBA1A1A),
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Nút tạo VietQR
                        ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _handleGenerateQr,
                          icon: _isGenerating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.qr_code_2, size: 20),
                          label: Text(
                            _isGenerating
                                ? 'Đang tạo mã VietQR...'
                                : _scope == ContributionScope.jointGroup
                                    ? 'Tạo Mã VietQR Cúng Tiến Cho Cả Gia Đình'
                                    : 'Tạo Mã VietQR Thanh Toán Ngân Hàng',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // BƯỚC 2: HIỂN THỊ MÃ VIETQR ĐỘNG & THÔNG TIN CHUYỂN KHOẢN
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFD4A017), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 16,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF006E2A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF006E2A), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _committedAllocations.isNotEmpty
                                    ? 'Mã VietQR cúng tiến Hộ gia đình (${_committedAllocations.length} người) đã sẵn sàng'
                                    : 'Mã VietQR động đã sẵn sàng hạch toán',
                                style: const TextStyle(
                                  color: Color(0xFF006E2A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Khung mã VietQR chuẩn xác
                        Container(
                          width: 280,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFD4AF37), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header chuẩn VietQR & Napas 247
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFAF6EE),
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(14)),
                                  border: Border(
                                      bottom:
                                          BorderSide(color: Color(0xFFE6DFD8))),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF005BAA),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'VietQR',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFED1C24),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'napas 247',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _generatedQr!.bankName.split('-').first.trim(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF58413F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: QrImageView(
                                  data: _buildVietQrPayload(_generatedQr!),
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Color(0xFF8B1E1E),
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Color(0xFF2B1810),
                                  ),
                                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: const Text(
                                  'Quét bằng ứng dụng Ngân hàng bất kỳ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF755B53),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          _currencyFormat.format(_generatedQr!.amount),
                          style: const TextStyle(
                            fontFamily: 'Merriweather',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B1E1E),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bảng danh sách phân bổ hộ gia đình nếu có
                        if (_committedAllocations.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFD4A017)
                                      .withValues(alpha: 0.6)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.group,
                                        color: Color(0xFF8B1E1E), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Phân bổ công đức theo Hộ Gia Đình (${_committedAllocations.length} người):',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2B1810),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ..._committedAllocations.map(
                                  (alloc) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '• ${alloc.memberName} (${alloc.generation})',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF422E28),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${_currencyFormat.format(alloc.amount)} (${alloc.percentage.toStringAsFixed(0)}%)',
                                          style: const TextStyle(
                                            fontFamily: 'JetBrains Mono',
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF8B1E1E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Bảng thông tin chuyển khoản có nút copy
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF9F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6DFD8)),
                          ),
                          child: Column(
                            children: [
                              _copyableRow(
                                  'Ngân hàng thụ hưởng', _generatedQr!.bankName),
                              const Divider(height: 16),
                              _copyableRow(
                                'Số tài khoản',
                                _generatedQr!.accountNumber,
                                canCopy: true,
                              ),
                              const Divider(height: 16),
                              _copyableRow(
                                  'Tên chủ tài khoản', _generatedQr!.accountName),
                              const Divider(height: 16),
                              _copyableRow(
                                'Nội dung chuyển khoản (bắt buộc)',
                                _generatedQr!.transferContent,
                                canCopy: true,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Hướng dẫn Webhook tự động trong sản xuất & Giả lập môi trường Test
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F7F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6DFD8)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.bolt,
                                      color: Color(0xFF006E2A), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12.5,
                                            color: Color(0xFF2B1810),
                                            height: 1.4),
                                        children: [
                                          TextSpan(
                                            text: 'Cơ chế tự động thực tế: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF006E2A)),
                                          ),
                                          TextSpan(
                                            text:
                                                'Khi bạn quét mã QR và chuyển khoản thành công qua App ngân hàng, cổng Napas/VietQR sẽ tự động bắn Webhook ngầm đến máy chủ để khớp lệnh và cấp phiếu thu ngay tức thì mà không cần bấm xác nhận.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFDE68A)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.science,
                                            color: Color(0xFFB45309), size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Công Cụ Giả Lập Webhook (Dành Cho Dev / Localhost)',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Do máy chủ đang chạy localhost chưa mở tunnel đón Webhook thật từ ngân hàng, bạn có thể bấm nút dưới đây để giả lập tín hiệu ngân hàng báo về backend để test quy trình cấp phiếu thu.',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF92400E),
                                          height: 1.35),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton.icon(
                                      onPressed: _isVerifyingPayment
                                          ? null
                                          : () async {
                                              setState(() =>
                                                  _isVerifyingPayment = true);
                                              try {
                                                final repo = ref.read(
                                                    contributionRepositoryProvider);
                                                final res = await repo
                                                    .simulatePaymentWebhook(
                                                  amount: _generatedQr!.amount,
                                                  content: _generatedQr!
                                                      .transferContent,
                                                  allocations:
                                                      _committedAllocations,
                                                );
                                                ref.invalidate(
                                                    contributionUiProvider);

                                                final isSuccess =
                                                    res['success'] == true ||
                                                        (res['data']?['success'] ==
                                                            true);
                                                final responseMsg =
                                                    res['data']?['message'] ??
                                                        res['message'] ??
                                                        '';

                                                if (!isSuccess) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Lỗi đối soát: $responseMsg'),
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF9B1C1C),
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                      ),
                                                    );
                                                  }
                                                  return;
                                                }

                                                if (context.mounted) {
                                                  final receiptData =
                                                      res['data'];
                                                  final receiptObj =
                                                      (receiptData
                                                                  is Map<
                                                                      String,
                                                                      dynamic> &&
                                                              receiptData[
                                                                      'receipt']
                                                                  is Map<
                                                                      String,
                                                                      dynamic>)
                                                          ? receiptData['receipt']
                                                              as Map<String,
                                                                  dynamic>
                                                          : null;

                                                  ElectronicReceiptDto
                                                      receiptDto;
                                                  if (receiptObj != null) {
                                                    receiptDto =
                                                        ElectronicReceiptDto
                                                            .fromJson(
                                                                receiptObj);
                                                  } else {
                                                    final receiptNo =
                                                        receiptData?[
                                                                'receiptNumber'] ??
                                                            'PT-${DateFormat('yyyyMMdd').format(DateTime.now())}-${(1000 + DateTime.now().millisecond).toString()}';
                                                    final contributionId =
                                                        receiptData?[
                                                                'contributionId'] ??
                                                            '';
                                                    receiptDto =
                                                        ElectronicReceiptDto(
                                                      receiptNumber:
                                                          receiptNo.toString(),
                                                      contributionId:
                                                          contributionId
                                                              .toString(),
                                                      eventId: _selectedEventId,
                                                      eventName: _generatedQr
                                                              ?.eventName ??
                                                          'Đại Lễ Giỗ Tổ Thủy Tộc Xuân Bính Ngọ 2026',
                                                      payerMemberId:
                                                          _generatedQr
                                                                  ?.memberId ??
                                                              '',
                                                      payerMemberName:
                                                          _generatedQr
                                                                  ?.memberName ??
                                                              'Nguyễn Trọng Hoàng',
                                                      receiverAccountId:
                                                          _generatedQr
                                                                  ?.accountNumber ??
                                                              '',
                                                      amount:
                                                          _generatedQr!.amount,
                                                      amountInWords:
                                                          VietnameseMoneyConverter
                                                              .toWords(
                                                                  _generatedQr!
                                                                      .amount),
                                                      paymentMethod:
                                                          PaymentMethod
                                                              .BankTransfer,
                                                      contributionDate:
                                                          DateTime.now(),
                                                      allocations:
                                                          _committedAllocations,
                                                    );
                                                  }

                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: true,
                                                    builder: (_) =>
                                                        ElectronicReceiptDialog(
                                                      cashReceipt: receiptDto,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Lỗi khi đối soát chuyển khoản: $e'),
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF9B1C1C),
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                    ),
                                                  );
                                                }
                                              } finally {
                                                if (mounted) {
                                                  setState(() =>
                                                      _isVerifyingPayment =
                                                          false);
                                                }
                                              }
                                            },
                                      icon: _isVerifyingPayment
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(Icons.science, size: 16),
                                      label: Text(
                                        _isVerifyingPayment
                                            ? 'Đang giả lập đối soát webhook...'
                                            : '🧪 Giả Lập Webhook Ngân Hàng Xác Nhận (Dev Test)',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF006E2A),
                                        foregroundColor: Colors.white,
                                        minimumSize:
                                            const Size.fromHeight(44),
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Nút hành động phụ
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _generatedQr = null);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  side: const BorderSide(color: kPrimaryColor),
                                ),
                                child: const Text('Nhập Lại / Chọn Lại'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.push('/contributions/my-history');
                                },
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('Xem Sổ Phiếu Thu Của Tôi'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF006E2A),
                                  side: const BorderSide(
                                      color: Color(0xFF006E2A)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationRow(
      int index, AllocationItemState item, List<BranchMemberItem> members) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8DFD8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF8B1E1E).withValues(alpha: 0.1),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1E1E),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: (item.memberId != null &&
                      members.any((m) => m.memberId == item.memberId))
                  ? item.memberId
                  : null,
              decoration: InputDecoration(
                labelText: 'Chọn con cháu / thành viên *',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: members.map((m) {
                return DropdownMenuItem<String>(
                  value: m.memberId,
                  child: Text(
                    '${m.fullName} (${m.roleInBranch})',
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId == null) return;
                final found = members.firstWhere((m) => m.memberId == newId);
                setState(() {
                  item.memberId = found.memberId;
                  item.memberName = found.fullName;
                  item.generation = found.roleInBranch;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: TextField(
              controller: item.amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B1E1E),
              ),
              decoration: InputDecoration(
                labelText: 'Số tiền (VNĐ) *',
                suffixText: 'đ',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
          ),
          if (_groupAllocations.length > 1) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _removeGroupAllocationRow(index),
              icon: const Icon(Icons.remove_circle_outline,
                  color: Color(0xFFBA1A1A), size: 20),
              tooltip: 'Xóa người này',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _copyableRow(String label, String value,
      {bool canCopy = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF54433E))),
        const SizedBox(width: 8),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontFamily: isBold ? 'JetBrains Mono' : null,
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: isBold
                        ? const Color(0xFF8B1E1E)
                        : const Color(0xFF2B1810),
                  ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _copyToClipboard(value, label),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child:
                        Icon(Icons.copy, size: 16, color: Color(0xFF8B1E1E)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
