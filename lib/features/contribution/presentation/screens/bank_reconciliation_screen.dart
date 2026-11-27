import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/presentation/widgets/heritage_nav_bar.dart';
import '../../../../core/widgets/error_message_box.dart';
import '../../data/models/contribution_models.dart';
import '../providers/contribution_ui_provider.dart';

/// Màn hình Đối soát Chuyển khoản cho Thủ quỹ (US-50, Task #178).
/// Cho phép tải ảnh chụp màn hình chuyển khoản/sao kê, nhập mã giao dịch ngân hàng và bấm xác nhận khớp số liệu.
/// Nối 100% Backend REST API (GET /api/v1/contributions/cash/unreconciled, PUT /api/v1/contributions/cash/{id}/reconcile).
class BankReconciliationScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const BankReconciliationScreen({super.key, this.eventId});

  @override
  ConsumerState<BankReconciliationScreen> createState() =>
      _BankReconciliationScreenState();
}

class _BankReconciliationScreenState
    extends ConsumerState<BankReconciliationScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  void _showReconcileDialog(UnreconciledContributionDto item) {
    final codeCtrl = TextEditingController(
      text: item.bankTransactionCode ?? '',
    );
    final proofCtrl = TextEditingController(text: item.transferProofUrl ?? '');
    final noteCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Color(0xFF3F51B5),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đối Soát Khoản Chuyển Khoản',
                        style: TextStyle(
                          fontFamily: 'Merriweather',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C1C1A),
                        ),
                      ),
                      Text(
                        'Thủ quỹ đối soát với sao kê ngân hàng & đính kèm ảnh',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B584E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thông tin giao dịch
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F7F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE6DFD8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.receiptNumber,
                                style: const TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B1E1E),
                                ),
                              ),
                              Text(
                                _currencyFormat.format(item.amount),
                                style: const TextStyle(
                                  fontFamily: 'Merriweather',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E8B43),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Người chuyển: ${item.payerMemberName ?? item.payerMemberId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (item.eventName != null)
                            Text(
                              'Sự kiện: ${item.eventName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B584E),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nhập mã giao dịch ngân hàng (bắt buộc)
                    const Text(
                      'Mã giao dịch ngân hàng (FT / Ref Code) *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: codeCtrl,
                      decoration: InputDecoration(
                        hintText: 'VD: FT240987654321 hoặc 992834',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Ảnh chụp màn hình chuyển khoản / sao kê
                    const Text(
                      'Đường dẫn ảnh sao kê / ảnh chụp màn hình biên lai',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: proofCtrl,
                      decoration: InputDecoration(
                        hintText: 'https://... hoặc link ảnh sao kê đối soát',
                        prefixIcon: const Icon(Icons.image, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Ghi chú đối soát
                    const Text(
                      'Ghi chú đối soát (tùy chọn)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Đã kiểm tra khớp lệnh tài khoản Vietcombank...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim();
                        if (code.isEmpty) {
                          showWarningMessageBox(
                            context: ctx,
                            title: 'Thiếu Thông Tin Đối Soát',
                            message: 'Vui lòng nhập mã giao dịch ngân hàng (FT / Ref Code) từ sao kê!',
                          );
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                        });

                        try {
                          await ref
                              .read(contributionUiProvider.notifier)
                              .reconcileContribution(
                                contributionId: item.contributionId,
                                bankTransactionCode: code,
                                transferProofUrl: proofCtrl.text.trim(),
                                note: noteCtrl.text.trim(),
                              );

                          ref.invalidate(
                            unreconciledContributionsProvider(widget.eventId),
                          );

                          if (mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã xác nhận khớp số liệu thành công cho mã ${item.receiptNumber}!',
                                ),
                                backgroundColor: const Color(0xFF006E2A),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                          });
                          if (ctx.mounted) {
                            showErrorMessageBox(
                              context: ctx,
                              title: 'Lỗi Đối Soát Ngân Hàng',
                              error: e,
                            );
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 16),
                label: const Text('Xác Nhận Khớp Số Liệu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreconciledAsync = ref.watch(
      unreconciledContributionsProvider(widget.eventId),
    );

    const kPrimaryColor = Color(0xFF8B1E1E);
    const kBgColor = Color(0xFFFAF9F6);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: const HeritageNavBar(currentRoute: '/contributions'),
      body: unreconciledAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: kPrimaryColor),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFBA1A1A),
                ),
                const SizedBox(height: 12),
                Text(
                  'Lỗi tải danh sách đối soát: $err',
                  style: const TextStyle(color: Color(0xFFBA1A1A)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.refresh(
                    unreconciledContributionsProvider(widget.eventId),
                  ),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (unreconciledList) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3F51B5)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: Color(0xFF3F51B5),
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Đối Soát Chuyển Khoản Ngân Hàng',
                                  style: TextStyle(
                                    fontFamily: 'Merriweather',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2B1810),
                                  ),
                                ),
                                Text(
                                  'Đối soát khoản chuyển khoản với sao kê và đính kèm ảnh biên lai',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => ref.refresh(
                            unreconciledContributionsProvider(widget.eventId),
                          ),
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Làm mới'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF3F51B5),
                            side: const BorderSide(color: Color(0xFF3F51B5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Thẻ thống kê
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE6DFD8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.pending_actions,
                            color: Color(0xFFE65100),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GIAO DỊCH CHỜ THỦ QUỸ ĐỐI SOÁT KHỚP SỐ',
                                  style: TextStyle(
                                    fontFamily: 'JetBrains Mono',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B584E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${unreconciledList.length} khoản chuyển khoản cần xác nhận',
                                  style: const TextStyle(
                                    fontFamily: 'Merriweather',
                                    fontSize: 17,
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
                    const SizedBox(height: 24),

                    // Danh sách
                    if (unreconciledList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE6DFD8)),
                        ),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF006E2A),
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tất cả các khoản chuyển khoản ngân hàng đã được đối soát khớp số 100%!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: unreconciledList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final item = unreconciledList[idx];
                          final dateStr = item.contributionDate != null
                              ? _dateFormat.format(item.contributionDate!)
                              : 'Chưa cập nhật';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE6DFD8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3F51B5)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2,
                                    color: Color(0xFF3F51B5),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.receiptNumber,
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: Color(0xFF8B1E1E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.payerMemberName ??
                                            item.payerMemberId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Ngày: $dateStr • Sự kiện: ${item.eventName ?? item.eventId}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF6B584E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _currencyFormat.format(item.amount),
                                        style: const TextStyle(
                                          fontFamily: 'Merriweather',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF2E8B43),
                                        ),
                                      ),
                                      const Text(
                                        'Chờ đối soát sao kê',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFE65100),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _showReconcileDialog(item),
                                  icon: const Icon(Icons.rule, size: 16),
                                  label: const Text('Đối Soát Khớp Số'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3F51B5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
