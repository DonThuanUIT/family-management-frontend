import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../../data/repositories/ledger_repository_impl.dart';
import '../providers/ledger_adjustment_providers.dart';
import '../widgets/adjustment_amount_impact_section.dart';
import '../widgets/adjustment_confirm_dialog.dart';
import '../widgets/adjustment_evidence_section.dart';
import '../widgets/adjustment_history_sheet.dart';
import '../widgets/ledger_transaction_picker_sheet.dart';

class _ReasonSuggestion {
  final String label;
  final String text;
  const _ReasonSuggestion(this.label, this.text);
}

const List<_ReasonSuggestion> _kLedgerReasonSuggestions = [
  _ReasonSuggestion(
    'Sai sót số liệu đối soát',
    'Điều chỉnh sai lệch số liệu khi đối soát sao kê ngân hàng và sổ thu tiền mặt tại từ đường.',
  ),
  _ReasonSuggestion(
    'Bổ sung chứng từ chi phát sinh',
    'Bổ sung khoản chi phát sinh thực tế có hóa đơn hợp lệ đã được Ban Tổ Chức xác nhận.',
  ),
  _ReasonSuggestion(
    'Hoàn trả tiền thừa sự kiện',
    'Thu hồi và hoàn trả khoản tiền thừa sau khi quyết toán xong hạng mục sự kiện.',
  ),
  _ReasonSuggestion(
    'Chênh lệch kiểm kê quỹ',
    'Bù trừ phần chênh lệch giữa sổ cái hệ thống và biên bản kiểm kê quỹ thực tế.',
  ),
  _ReasonSuggestion(
    'Khác',
    'Giải trình điều chỉnh nghiệp vụ khác theo biên bản họp Ban Thường Trực dòng họ.',
  ),
];

/// Màn hình Lập Đề Xuất Bù Trừ Sổ Cái Quỹ Chung cho Thủ quỹ / Trưởng tộc (US-15).
class ProposeLedgerAdjustmentScreen extends ConsumerStatefulWidget {
  final String? initialTransactionId;

  const ProposeLedgerAdjustmentScreen({
    super.key,
    this.initialTransactionId,
  });

  @override
  ConsumerState<ProposeLedgerAdjustmentScreen> createState() =>
      _ProposeLedgerAdjustmentScreenState();
}

class _ProposeLedgerAdjustmentScreenState
    extends ConsumerState<ProposeLedgerAdjustmentScreen> {
  final TextEditingController _reasonController = TextEditingController();

  LedgerHistoryItemModel? _selectedTransaction;
  bool _loadingInitialTx = false;
  String? _initialTxError;

  int _direction = 1; // 1 = Cộng vào Quỹ, -1 = Trừ khỏi Quỹ
  double _amount = 0;

  EvidenceInputMode _evidenceMode = EvidenceInputMode.file;
  SelectedEvidenceFile? _selectedFile;
  String _evidenceUrl = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTransactionId != null &&
        widget.initialTransactionId!.trim().isNotEmpty) {
      Future.microtask(
        () => _loadInitialTransaction(widget.initialTransactionId!.trim()),
      );
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialTransaction(String txId) async {
    setState(() {
      _loadingInitialTx = true;
      _initialTxError = null;
    });
    try {
      final tx =
          await ref.read(ledgerRepositoryProvider).getTransactionDetail(txId);
      if (!mounted) return;
      if (tx.isLockedByPendingAdjustment) {
        setState(() {
          _loadingInitialTx = false;
          _selectedTransaction = null;
          _initialTxError =
              'Giao dịch $txId đang có đề xuất bù trừ chờ Trưởng tộc phê duyệt nên tạm khóa lập thêm.';
        });
      } else {
        setState(() {
          _loadingInitialTx = false;
          _selectedTransaction = tx;
          _initialTxError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingInitialTx = false;
          _initialTxError =
              'Không thể tải sẵn giao dịch $txId: ${formatLedgerFailure(e)}';
        });
      }
    }
  }

  Future<void> _openTransactionPicker() async {
    final picked = await LedgerTransactionPickerSheet.show(
      context,
      selectedTransactionId: _selectedTransaction?.transactionId,
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTransaction = picked;
        _initialTxError = null;
      });
    }
  }

  void _appendReasonSuggestion(String snippet) {
    final current = _reasonController.text.trim();
    String next;
    if (current.isEmpty) {
      next = snippet;
    } else if (current.contains(snippet)) {
      return;
    } else {
      next = current.endsWith('.') ? '$current $snippet' : '$current. $snippet';
    }
    if (next.length > 2000) {
      next = next.substring(0, 2000);
    }
    setState(() {
      _reasonController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });
  }

  String? _computeBlockingReason(DualRbacSession session, double currentFund) {
    final tx = _selectedTransaction;
    if (!session.canProposeLedgerAdjustment(eventId: tx?.eventId)) {
      return 'Bạn không có quyền đề xuất điều chỉnh bút toán Sổ cái này.';
    }
    if (tx == null) {
      return 'Chưa chọn giao dịch gốc từ Sổ cái';
    }
    if (tx.isLockedByPendingAdjustment) {
      return 'Giao dịch gốc đang có đề xuất chờ duyệt';
    }
    if (_amount <= 0) {
      return 'Số tiền bù trừ phải lớn hơn 0 ₫';
    }
    final signed = _direction * _amount;
    if (currentFund + signed < 0) {
      return 'Số dư Quỹ chung sau bù trừ không được âm';
    }
    final trimmedReason = _reasonController.text.trim();
    if (trimmedReason.length < 5 || trimmedReason.length > 2000) {
      return 'Cần nhập lý do giải trình (5–2000 ký tự)';
    }
    if (_evidenceMode == EvidenceInputMode.url &&
        !AdjustmentEvidenceSection.isValidExternalUrl(_evidenceUrl)) {
      return 'Đường dẫn biên bản không hợp lệ';
    }
    return null;
  }

  Future<void> _onSubmitPressed(double currentFundBalance) async {
    final tx = _selectedTransaction;
    if (tx == null) return;
    final signed = _direction * _amount;
    final projected = currentFundBalance + signed;

    final created = await AdjustmentConfirmDialog.show(
      context,
      transaction: tx,
      signedAmount: signed,
      projectedFundBalance: projected,
      adjustmentReason: _reasonController.text.trim(),
      selectedFile:
          _evidenceMode == EvidenceInputMode.file ? _selectedFile : null,
      externalEvidenceUrl:
          _evidenceMode == EvidenceInputMode.url &&
                  _evidenceUrl.trim().isNotEmpty
              ? _evidenceUrl.trim()
              : null,
    );

    if (created == null || !mounted) return;

    ref
        .read(ledgerPickerProvider.notifier)
        .markTransactionPending(created.originalTransactionId);
    ref.read(ledgerAdjustmentHistoryProvider.notifier).prependRequest(created);

    await _showSuccessDialog(created);
  }

  Future<void> _showSuccessDialog(LedgerAdjustmentRequestModel created) async {
    final amtColor = created.proposedAdjustmentAmount >= 0
        ? AppTheme.immutableLedgerTeal
        : const Color(0xFFBA1A1A);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF99F6E4)),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.immutableLedgerTeal,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Đã Gửi Đề Xuất Bù Trừ Thành Công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Đề xuất đã được lưu ở trạng thái Chờ Trưởng tộc duyệt và thông báo đã được phát tới Trưởng tộc.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Color(0xFF58413F)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6DFD8)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mã đề xuất hệ thống cấp:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF58413F),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            created.requestId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryCrimson,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Giao dịch gốc:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF58413F),
                            ),
                          ),
                        ),
                        Text(
                          created.originalTransactionId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Số tiền bù trừ:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF58413F),
                            ),
                          ),
                        ),
                        Text(
                          formatSignedLedgerVnd(
                            created.proposedAdjustmentAmount,
                          ),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: amtColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dlgCtx).pop();
                        _resetForm();
                        AdjustmentHistorySheet.show(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: AppTheme.primaryCrimson,
                        side: const BorderSide(color: AppTheme.primaryCrimson),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xem Lịch Sử',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dlgCtx).pop();
                        _resetForm();
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: AppTheme.primaryCrimson,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lập Đề Xuất Mới',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  void _resetForm() {
    setState(() {
      _selectedTransaction = null;
      _direction = 1;
      _amount = 0;
      _reasonController.clear();
      _selectedFile = null;
      _evidenceUrl = '';
      _initialTxError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dualRbacSessionProvider);
    final pickerState = ref.watch(ledgerPickerProvider);
    final historyState = ref.watch(ledgerAdjustmentHistoryProvider);
    final currentFundBalance = pickerState.currentFundBalance;

    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    final signedAmount = _direction * _amount;
    final blockingReason = _computeBlockingReason(session, currentFundBalance);
    final canSubmit = blockingReason == null;
    final canProposeForSelection =
        session.canProposeLedgerAdjustment(eventId: _selectedTransaction?.eventId);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFE6DFD8)),
        ),
        leading: IconButton(
          tooltip: 'Quay lại',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF1A1C1A),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đề Xuất Bù Trừ Sổ Cái',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
              ),
            ),
            Text(
              'Quỹ chung dòng họ • Cần Trưởng tộc duyệt',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF58413F),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              key: const Key('open_adjustment_history_button'),
              onPressed: () => AdjustmentHistorySheet.show(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 42),
                foregroundColor: const Color(0xFF1A1C1A),
                backgroundColor: const Color(0xFFFAF9F6),
                side: const BorderSide(color: Color(0xFFE6DFD8)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.history_rounded,
                size: 18,
                color: AppTheme.primaryCrimson,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lịch sử',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  if (historyState.pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        '${historyState.pendingCount}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryGold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 16,
          20,
          isDesktop ? 24 : 16,
          isDesktop ? 40 : 28,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canProposeForSelection) ...[
                  _buildRbacWarningBanner(),
                  const SizedBox(height: 16),
                ],
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildFormStepsColumn(
                          currentFundBalance: currentFundBalance,
                          includeInlineImpact: false,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LedgerImpactPreviewCard(
                              selectedTransaction: _selectedTransaction,
                              currentFundBalance: currentFundBalance,
                              signedAdjustmentAmount: signedAmount,
                            ),
                            const SizedBox(height: 16),
                            _buildImmutableRuleInfoCard(),
                            const SizedBox(height: 16),
                            _buildDesktopSubmitCard(
                              canSubmit: canSubmit,
                              blockingReason: blockingReason,
                              currentFundBalance: currentFundBalance,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  _buildFormStepsColumn(
                    currentFundBalance: currentFundBalance,
                    includeInlineImpact: true,
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _buildMobileStickyFooter(
              canSubmit: canSubmit,
              currentFundBalance: currentFundBalance,
              signedAmount: signedAmount,
            ),
    );
  }

  Widget _buildRbacWarningBanner() {
    return Container(
      key: const Key('ledger_rbac_warning_banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.secondaryGold, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Phiên hiện tại chỉ có quyền xem. Chỉ Trưởng tộc, Quản trị viên, hoặc Thủ quỹ / Trưởng BTC của sự kiện gắn với giao dịch gốc mới có quyền lập đề xuất bù trừ Sổ cái.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF58413F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormStepsColumn({
    required double currentFundBalance,
    required bool includeInlineImpact,
  }) {
    final signedAmount = _direction * _amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStep1Card(),
        const SizedBox(height: 16),
        AdjustmentAmountInputCard(
          direction: _direction,
          amount: _amount,
          onDirectionChanged: (dir) => setState(() => _direction = dir),
          onAmountChanged: (val) => setState(() => _amount = val),
        ),
        if (includeInlineImpact) ...[
          const SizedBox(height: 16),
          LedgerImpactPreviewCard(
            selectedTransaction: _selectedTransaction,
            currentFundBalance: currentFundBalance,
            signedAdjustmentAmount: signedAmount,
          ),
        ],
        const SizedBox(height: 16),
        _buildStep3Card(),
      ],
    );
  }

  Widget _buildStep1Card() {
    final tx = _selectedTransaction;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _StepNumberBadge(number: 1),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giao Dịch Gốc (Sổ Cái)',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    Text(
                      'Chọn bút toán cần lập đề xuất điều chỉnh bù trừ',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_initialTxError != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                _initialTxError!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF93000A),
                ),
              ),
            ),
          ],

          if (_loadingInitialTx)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryCrimson),
              ),
            )
          else if (tx == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDFD8D0), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6DFD8)),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: AppTheme.primaryCrimson,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chưa chọn giao dịch gốc',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mở bảng Sổ cái Quỹ chung để tìm kiếm, lọc theo loại giao dịch và chọn bút toán cần bù trừ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF58413F)),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    key: const Key('open_ledger_picker_button'),
                    onPressed: _openTransactionPicker,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: AppTheme.primaryCrimson,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 19),
                    label: const Text(
                      'Mở Bảng Sổ Cái Chọn Giao Dịch',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              key: const Key('selected_original_transaction_card'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6DFD8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE6DFD8),
                              ),
                            ),
                            child: Text(
                              tx.transactionId,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tx.transactionType.badgeBackgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tx.transactionType.badgeBorderColor,
                              ),
                            ),
                            child: Text(
                              tx.transactionType.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tx.transactionType.badgeTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${tx.formattedSolarDate} • ${tx.formattedLunarDate}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF58413F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tx.description,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Số tiền bút toán gốc:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF58413F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatSignedLedgerVnd(tx.amount),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: tx.amount > 0
                                    ? AppTheme.immutableLedgerTeal
                                    : (tx.amount < 0
                                        ? const Color(0xFFBA1A1A)
                                        : const Color(0xFF58413F)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        key: const Key('reselect_ledger_transaction_button'),
                        onPressed: _openTransactionPicker,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          foregroundColor: AppTheme.primaryCrimson,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppTheme.primaryCrimson),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text(
                          'Chọn lại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tx.hasAdjustments) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        'Đã có ${tx.adjustmentCount} bù trừ trước đó • Hiệu lực ròng: ${formatSignedLedgerVnd(tx.netAdjustedAmount)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryGold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3Card() {
    final len = _reasonController.text.length;
    final trimmedLen = _reasonController.text.trim().length;
    final showLengthError = trimmedLen > 0 && trimmedLen < 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _StepNumberBadge(number: 3),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giải Trình & Biên Bản Đính Kèm',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    Text(
                      'Ghi rõ căn cứ đối soát để Trưởng tộc xem xét phê duyệt',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Gợi ý chèn nhanh lý do (không ghi đè nội dung đã nhập):',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF58413F),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kLedgerReasonSuggestions
                .map(
                  (item) => ActionChip(
                    label: Text(
                      '+ ${item.label}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF58413F),
                      ),
                    ),
                    backgroundColor: const Color(0xFFFAF9F6),
                    side: const BorderSide(color: Color(0xFFE6DFD8)),
                    onPressed: () => _appendReasonSuggestion(item.text),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nội dung giải trình *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),
              Text(
                '$len / 2000',
                key: const Key('reason_char_counter'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  fontWeight: len > 1900 ? FontWeight.bold : FontWeight.w500,
                  color: len > 1900
                      ? const Color(0xFFBA1A1A)
                      : const Color(0xFF58413F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('adjustment_reason_input'),
            controller: _reasonController,
            maxLines: 4,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Nhập chi tiết nguyên nhân sai lệch, số hóa đơn/biên bản đối chiếu hoặc quyết định của Ban Tổ Chức...',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8B716E),
              ),
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryCrimson,
                  width: 1.8,
                ),
              ),
            ),
          ),
          if (showLengthError) ...[
            const SizedBox(height: 6),
            const Text(
              'Vui lòng nhập nội dung giải trình tối thiểu 5 ký tự.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBA1A1A),
              ),
            ),
          ],

          AdjustmentEvidenceSection(
            mode: _evidenceMode,
            selectedFile: _selectedFile,
            evidenceUrl: _evidenceUrl,
            onModeChanged: (m) => setState(() => _evidenceMode = m),
            onFileChanged: (f) => setState(() => _selectedFile = f),
            onUrlChanged: (u) => setState(() => _evidenceUrl = u),
          ),
        ],
      ),
    );
  }

  Widget _buildImmutableRuleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppTheme.secondaryGold,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguyên tắc Sổ cái Bất biến (SHA-256)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hệ thống không sửa hay xóa giao dịch gốc. Sau khi Trưởng tộc phê duyệt, một bút toán bù trừ mới sẽ được nối vào chuỗi băm SHA-256 và cập nhật Số dư Quỹ chung.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF58413F),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSubmitCard({
    required bool canSubmit,
    required String? blockingReason,
    required double currentFundBalance,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            key: const Key('submit_adjustment_desktop_button'),
            onPressed:
                canSubmit ? () => _onSubmitPressed(currentFundBalance) : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppTheme.primaryCrimson,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE3E2E0),
              disabledForegroundColor: const Color(0xFF8B716E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text(
              'Gửi Đề Xuất Bù Trừ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canSubmit
                ? 'Bước tiếp theo: Mở bảng tóm tắt để xác nhận trước khi gửi'
                : (blockingReason ?? ''),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: canSubmit ? FontWeight.normal : FontWeight.w600,
              color: canSubmit
                  ? const Color(0xFF58413F)
                  : const Color(0xFFBA1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStickyFooter({
    required bool canSubmit,
    required double currentFundBalance,
    required double signedAmount,
  }) {
    final projected = currentFundBalance + signedAmount;
    final isNegative = projected < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6DFD8))),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Tác động Quỹ chung:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF58413F),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isNegative
                        ? '${formatSignedLedgerVnd(signedAmount)} → ${AppFormatters.formatVnd(projected)} (Âm quỹ!)'
                        : '${formatSignedLedgerVnd(signedAmount)} → ${AppFormatters.formatVnd(projected)}',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isNegative
                          ? const Color(0xFFBA1A1A)
                          : AppTheme.immutableLedgerTeal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              key: const Key('submit_adjustment_mobile_button'),
              onPressed:
                  canSubmit ? () => _onSubmitPressed(currentFundBalance) : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppTheme.primaryCrimson,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE3E2E0),
                disabledForegroundColor: const Color(0xFF8B716E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Gửi Đề Xuất Bù Trừ',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepNumberBadge extends StatelessWidget {
  final int number;
  const _StepNumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppTheme.primaryCrimson,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
