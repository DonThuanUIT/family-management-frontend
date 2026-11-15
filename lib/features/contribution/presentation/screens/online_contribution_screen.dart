import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../data/models/contribution_models.dart';
import '../../data/repositories/contribution_repository_impl.dart';
import '../../domain/repositories/contribution_repository.dart';
import '../providers/contribution_ui_provider.dart';

/// Màn hình 'Đóng góp trực tuyến' cho con cháu ở xa (US-53, Task #187).
/// Nhập số tiền -> hiển thị mã VietQR quét trực tiếp bằng App Ngân hàng -> nhận phiếu thu điện tử tự động.
/// Nối 100% Backend REST API (POST /api/v1/contributions/vietqr/generate).
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

  final List<double> _presetAmounts = [
    200000,
    500000,
    1000000,
    2000000,
    5000000,
    10000000,
  ];

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId ?? 'EVT-GIO-TO-2026';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateQr() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (amount < 1000) {
      setState(() => _errorMessage = 'Số tiền đóng góp tối thiểu là 1,000 VNĐ');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final session = ref.read(dualRbacSessionProvider);
      final userMemberId = authState.user?.memberId;
      final memberId = (userMemberId != null && userMemberId.isNotEmpty)
          ? userMemberId
          : session.memberId;

      final repo = ref.read(contributionRepositoryProvider);
      final qrResponse = await repo.generateVietQr(
        GenerateVietQrRequestDto(
          eventId: _selectedEventId,
          memberId: memberId.isNotEmpty ? memberId : null,
          amount: amount,
          note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
        ),
      );

      if (mounted) {
        setState(() {
          _generatedQr = qrResponse;
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

  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFF8B1E1E);
    const kBgColor = Color(0xFFFAF9F6);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: const HeritageNavBar(currentRoute: '/contributions/online'),
      bottomNavigationBar: const HeritageBottomNavBar(currentRoute: '/contributions/online'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
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
                      child: const Icon(Icons.qr_code_2, color: kPrimaryColor, size: 28),
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
                            'US-53: Dành cho con cháu ở xa dâng lễ & nhận phiếu thu điện tử tự động',
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
                const SizedBox(height: 24),

                // Hiển thị tài khoản ngân hàng chính thức của Dòng họ (Multi-tenant Clan Banking Info)
                ref.watch(clanBankingInfoProvider).when(
                  data: (banking) => Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFBF7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4A017).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A017).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance, color: Color(0xFF8B1E1E), size: 22),
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
                  error: (_, __) => const SizedBox.shrink(),
                ),

                if (_generatedQr == null) ...[
                  // BƯỚC 1: NHẬP SỐ TIỀN & THÔNG TIN ĐÓNG GÓP
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                            );
                          }).toList(),
                        ),
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
                            hintText: 'VD: Con cháu chi 2 kính cúng tiến ngày Đại lễ Giỗ Tổ...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                              border: Border.all(color: const Color(0xFFBA1A1A)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 13)),
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.qr_code_2, size: 20),
                          label: Text(
                            _isGenerating ? 'Đang tạo mã VietQR...' : 'Tạo Mã VietQR Thanh Toán Ngân Hàng',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: Border.all(color: const Color(0xFFD4A017), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006E2A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Color(0xFF006E2A), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Mã VietQR động đã sẵn sàng hạch toán',
                                style: TextStyle(
                                  color: Color(0xFF006E2A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Ảnh mã QR
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6DFD8)),
                          ),
                          child: Image.network(
                            _generatedQr!.qrCodeUrl,
                            width: 240,
                            height: 240,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 240,
                              height: 240,
                              color: const Color(0xFFF9F7F5),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code, size: 80, color: Color(0xFF8B1E1E)),
                                  SizedBox(height: 8),
                                  Text('Quét mã qua app ngân hàng', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
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
                              _copyableRow('Ngân hàng thụ hưởng', _generatedQr!.bankName),
                              const Divider(height: 16),
                              _copyableRow(
                                'Số tài khoản',
                                _generatedQr!.accountNumber,
                                canCopy: true,
                              ),
                              const Divider(height: 16),
                              _copyableRow('Tên chủ tài khoản', _generatedQr!.accountName),
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
                        const SizedBox(height: 24),

                        // Nút hành động
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
                                child: const Text('Nhập Lại Số Tiền'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Chuyển hướng sang màn hình lịch sử đóng góp để xem phiếu thu
                                  context.push('/contributions/my-history');
                                },
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('Xem Phiếu Thu Của Tôi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006E2A),
                                  foregroundColor: Colors.white,
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

  Widget _copyableRow(String label, String value, {bool canCopy = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF54433E))),
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
                    color: isBold ? const Color(0xFF8B1E1E) : const Color(0xFF2B1810),
                  ),
                ),
              ),
              if (canCopy) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _copyToClipboard(value, label),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 16, color: Color(0xFF8B1E1E)),
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
