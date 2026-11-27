import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/vietnamese_money_converter.dart';
import '../../../genealogy/data/models/branch_models.dart';
import '../../../genealogy/presentation/providers/genealogy_providers.dart';
import '../../data/models/common_fund_disbursement_models.dart';
import '../../data/models/ledger_adjustment_models.dart';
import '../providers/common_fund_disbursement_providers.dart';
import '../widgets/adjustment_evidence_section.dart';
import '../widgets/disbursement_propose_widgets.dart';

enum _BeneficiaryInputMode { external, member }

/// Màn hình Đề Xuất Chi Quỹ Chung Cho Việc Lớn (`POST /api/v1/ledger/disbursements`, US-60).
class ProposeCommonFundDisbursementScreen extends ConsumerStatefulWidget {
  const ProposeCommonFundDisbursementScreen({super.key});

  @override
  ConsumerState<ProposeCommonFundDisbursementScreen> createState() =>
      _ProposeCommonFundDisbursementScreenState();
}

class _ProposeCommonFundDisbursementScreenState
    extends ConsumerState<ProposeCommonFundDisbursementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _beneficiaryNameController =
      TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  CommonFundExpenseCategoryEnum _category =
      CommonFundExpenseCategoryEnum.templeMaintenance;
  double _amount = 0;

  _BeneficiaryInputMode _beneficiaryMode = _BeneficiaryInputMode.external;
  String? _selectedMemberId;

  EvidenceInputMode _evidenceMode = EvidenceInputMode.file;
  SelectedEvidenceFile? _selectedFile;
  String _evidenceUrl = '';

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _beneficiaryNameController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  static String _formatRawDigits(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(s[i]);
    }
    return buf.toString();
  }

  void _onAmountChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _amountController.value = const TextEditingValue(text: '');
      setState(() => _amount = 0);
      return;
    }
    final clamped = digits.length > 15 ? digits.substring(0, 15) : digits;
    final parsed = int.tryParse(clamped) ?? 0;
    final formatted = parsed > 0 ? _formatRawDigits(parsed) : '';
    if (_amountController.text != formatted) {
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() => _amount = parsed.toDouble());
  }

  void _setAmountValue(double nextAmount) {
    final rounded = nextAmount < 0 ? 0 : nextAmount.round();
    final formatted = rounded > 0 ? _formatRawDigits(rounded) : '';
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() => _amount = rounded.toDouble());
  }

  void _appendCategorySuggestion() {
    final snippet = _category.purposeSuggestion;
    final current = _purposeController.text.trim();
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
      _purposeController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });
  }

  BranchMemberItem? _findSelectedMember(List<BranchMemberItem> members) {
    if (_selectedMemberId == null) return null;
    for (final m in members) {
      if (m.memberId == _selectedMemberId) return m;
    }
    return null;
  }

  String? _computeBlockingReason(
    DualRbacSession session,
    CommonFundBalanceModel balance,
    List<BranchMemberItem> members,
  ) {
    if (!session.canProposeCommonFundDisbursement) {
      return 'Phiên hiện tại chỉ có quyền xem.';
    }
    if (_titleController.text.trim().isEmpty) {
      return 'Chưa nhập tiêu đề khoản chi Quỹ chung';
    }
    if (_amount <= 0) {
      return 'Số tiền đề xuất chi phải lớn hơn 0 ₫';
    }
    if (_amount > balance.availableBalance) {
      return 'Số tiền vượt quá Số dư Quỹ khả dụng hiện tại';
    }
    if (_beneficiaryMode == _BeneficiaryInputMode.external) {
      if (_beneficiaryNameController.text.trim().isEmpty) {
        return 'Cần nhập tên đơn vị hoặc người thụ hưởng';
      }
    } else {
      if (_findSelectedMember(members) == null) {
        return 'Cần chọn thành viên thụ hưởng trong Gia phả';
      }
    }
    final purpose = _purposeController.text.trim();
    if (purpose.length < 5 || purpose.length > 2000) {
      return 'Mục đích / lý do chi phải từ 5 đến 2000 ký tự';
    }
    if (_evidenceMode == EvidenceInputMode.url &&
        !AdjustmentEvidenceSection.isValidExternalUrl(_evidenceUrl)) {
      return 'Đường dẫn chứng từ không hợp lệ';
    }
    return null;
  }

  Future<void> _onSubmitPressed(
    CommonFundBalanceModel balance,
    List<BranchMemberItem> members,
  ) async {
    final selectedMember = _beneficiaryMode == _BeneficiaryInputMode.member
        ? _findSelectedMember(members)
        : null;
    final externalName = _beneficiaryMode == _BeneficiaryInputMode.external
        ? _beneficiaryNameController.text.trim()
        : selectedMember?.fullName;
    final displayBeneficiary = selectedMember != null
        ? '${selectedMember.fullName} (${selectedMember.memberId})'
        : (externalName ?? '—');

    final created = await ProposeDisbursementConfirmDialog.show(
      context,
      title: _titleController.text.trim(),
      category: _category,
      amount: _amount,
      beneficiaryName: externalName,
      beneficiaryMemberId: selectedMember?.memberId,
      beneficiaryDisplay: displayBeneficiary,
      purpose: _purposeController.text.trim(),
      projectedBalance: balance.availableBalance - _amount,
      selectedFile:
          _evidenceMode == EvidenceInputMode.file ? _selectedFile : null,
      externalAttachmentUrl:
          _evidenceMode == EvidenceInputMode.url &&
                  _evidenceUrl.trim().isNotEmpty
              ? _evidenceUrl.trim()
              : null,
    );

    if (created == null || !mounted) return;
    ref.read(commonFundOverviewProvider.notifier).prependCreated(created);
    await _showSuccessDialog(created);
  }

  Future<void> _showSuccessDialog(CommonFundDisbursementModel created) async {
    final canReview =
        ref.read(dualRbacSessionProvider).canReviewCommonFundDisbursement;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
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
                'Đã Gửi Đề Xuất Chi Quỹ Thành Công',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Phiếu đề xuất đang ở trạng thái Chờ Trưởng tộc duyệt và thông báo in-app đã được gửi tới Trưởng tộc.',
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
                            'Mã phiếu chi:',
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
                            'Số tiền đề xuất:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF58413F),
                            ),
                          ),
                        ),
                        Text(
                          '−${AppFormatters.formatVnd(created.amount)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(dlgCtx).pop();
                      _resetForm();
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
                      'Lập Phiếu Mới',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (canReview)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dlgCtx).pop();
                        _resetForm();
                        context.push(
                          '/finance/disbursements/review?requestId=${created.requestId}',
                        );
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
                        'Sang Màn Trưởng Tộc Duyệt',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(dlgCtx).pop();
                        _resetForm();
                        DisbursementHistorySheet.show(context);
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
                        'Xem Lịch Sử',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
      _category = CommonFundExpenseCategoryEnum.templeMaintenance;
      _titleController.clear();
      _amountController.clear();
      _amount = 0;
      _beneficiaryNameController.clear();
      _selectedMemberId = null;
      _purposeController.clear();
      _selectedFile = null;
      _evidenceUrl = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dualRbacSessionProvider);
    final overviewState = ref.watch(commonFundOverviewProvider);
    final membersAsync = ref.watch(genealogyMemberListProvider);
    final members = membersAsync.asData?.value ?? const <BranchMemberItem>[];

    final isDesktop = MediaQuery.sizeOf(context).width >= 960;
    final balance = overviewState.balance;
    final blockingReason = _computeBlockingReason(session, balance, members);
    final canSubmit = blockingReason == null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
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
              'Đề Xuất Chi Quỹ Chung',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
              ),
            ),
            Text(
              'Khoản chi việc lớn • Trưởng tộc ký duyệt mật khẩu',
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
              key: const Key('open_disbursement_history_button'),
              onPressed: () => DisbursementHistorySheet.show(context),
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
                  if (overviewState.pendingCount > 0) ...[
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
                        '${overviewState.pendingCount}',
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
      body: overviewState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryCrimson),
            )
          : SingleChildScrollView(
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
                      if (!session.canProposeCommonFundDisbursement) ...[
                        _buildRbacWarningBanner(),
                        const SizedBox(height: 16),
                      ],
                      if (overviewState.errorMessage != null) ...[
                        _buildBalanceErrorBanner(overviewState.errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _buildFormColumn(
                                balance: balance,
                                members: members,
                                includeInlineBalance: false,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  DisbursementBalanceImpactCard(
                                    balance: balance,
                                    proposedAmount: _amount,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGovernanceRuleCard(),
                                  const SizedBox(height: 16),
                                  _buildDesktopSubmitCard(
                                    canSubmit: canSubmit,
                                    blockingReason: blockingReason,
                                    balance: balance,
                                    members: members,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        _buildFormColumn(
                          balance: balance,
                          members: members,
                          includeInlineBalance: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: (isDesktop || overviewState.isLoading)
          ? null
          : _buildMobileStickyFooter(
              canSubmit: canSubmit,
              balance: balance,
              members: members,
            ),
    );
  }

  Widget _buildRbacWarningBanner() {
    return Container(
      key: const Key('disbursement_propose_rbac_banner'),
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
              'Phiên hiện tại chỉ có quyền xem. Chỉ Trưởng tộc, Trưởng chi, Thủ quỹ sự kiện hoặc Quản trị viên mới có quyền lập đề xuất chi Quỹ chung.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF58413F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceErrorBanner(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFBA1A1A), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF93000A)),
            ),
          ),
          TextButton(
            onPressed: () => ref
                .read(commonFundOverviewProvider.notifier)
                .loadOverview(showLoading: true),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormColumn({
    required CommonFundBalanceModel balance,
    required List<BranchMemberItem> members,
    required bool includeInlineBalance,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStep1CategoryAndTitle(),
        const SizedBox(height: 16),
        _buildStep2AmountAndBeneficiary(balance, members),
        if (includeInlineBalance) ...[
          const SizedBox(height: 16),
          DisbursementBalanceImpactCard(
            balance: balance,
            proposedAmount: _amount,
          ),
        ],
        const SizedBox(height: 16),
        _buildStep3PurposeAndEvidence(),
      ],
    );
  }

  Widget _buildStep1CategoryAndTitle() {
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
              _StepBadge(number: 1),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạng Mục & Tiêu Đề Khoản Chi',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    Text(
                      'Chọn đúng 1 trong 5 danh mục chuẩn Quỹ chung dòng họ',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth >= 460;
              final itemWidth = twoCols
                  ? (constraints.maxWidth - 10) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: CommonFundExpenseCategoryEnum.values.map((cat) {
                  final selected = _category == cat;
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      key: Key('category_card_${cat.code}'),
                      onTap: () => setState(() => _category = cat),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 68),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFDF2F2)
                              : const Color(0xFFFAF9F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryCrimson
                                : const Color(0xFFE6DFD8),
                            width: selected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              cat.iconData,
                              size: 20,
                              color: selected
                                  ? AppTheme.primaryCrimson
                                  : const Color(0xFF58413F),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    cat.displayName,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: selected
                                          ? AppTheme.primaryCrimson
                                          : const Color(0xFF1A1C1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cat.shortDescription,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF58413F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tiêu đề khoản chi *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),
              Text(
                '${_titleController.text.length} / 255',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF58413F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('disbursement_title_input'),
            controller: _titleController,
            maxLength: 255,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Ví dụ: Trùng tu mái ngói Tiền Đường & thay xà gồ gỗ lim',
              hintStyle: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF8B716E),
              ),
              filled: true,
              fillColor: Colors.white,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2AmountAndBeneficiary(
    CommonFundBalanceModel balance,
    List<BranchMemberItem> members,
  ) {
    final available = balance.availableBalance;
    final ratioPercent = available > 0
        ? ((_amount / available) * 100).clamp(0.0, 100.0)
        : 0.0;
    final isOver = _amount > available;

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
              _StepBadge(number: 2),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số Tiền Chi & Đơn Vị Thụ Hưởng',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    Text(
                      'Đọc số tiền bằng chữ tiếng Việt và chọn người nhận',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Số tiền đề xuất chi (VNĐ) *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1A),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const Key('disbursement_amount_input'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: _onAmountChanged,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1A),
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 22,
                color: Color(0xFFB5A9A2),
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 6),
                child: Text(
                  '−',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 32),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 14, left: 6),
                child: Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF58413F),
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 32),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isOver
                      ? const Color(0xFFBA1A1A)
                      : const Color(0xFFFECACA),
                  width: 1.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryCrimson,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickIncrementChip(
                label: '+5.000.000',
                onTap: () => _setAmountValue(_amount + 5000000),
              ),
              _QuickIncrementChip(
                label: '+10.000.000',
                onTap: () => _setAmountValue(_amount + 10000000),
              ),
              _QuickIncrementChip(
                label: '+50.000.000',
                onTap: () => _setAmountValue(_amount + 50000000),
              ),
              if (_amount > 0)
                _QuickIncrementChip(
                  label: 'Xóa số tiền',
                  isDanger: true,
                  onTap: () => _setAmountValue(0),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Vietnamese Words & Ratio Progress Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOver ? const Color(0xFFFEF2F2) : const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOver
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFE6DFD8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bằng chữ: ${VietnameseMoneyConverter.toWords(_amount)}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isOver
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF1A1C1A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tỷ trọng trên Quỹ khả dụng hiện tại',
                        style: TextStyle(fontSize: 12, color: Color(0xFF58413F)),
                      ),
                    ),
                    Text(
                      '${ratioPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isOver
                            ? const Color(0xFFBA1A1A)
                            : AppTheme.primaryCrimson,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratioPercent / 100.0,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE6DFD8),
                    color: isOver
                        ? const Color(0xFFBA1A1A)
                        : AppTheme.primaryCrimson,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 28, color: Color(0xFFEFECE6)),

          const Text(
            'Người / Đơn vị thụ hưởng *',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6DFD8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SegmentModeButton(
                    key: const Key('beneficiary_mode_external'),
                    label: 'Đơn vị / Nhà thầu ngoài',
                    selected:
                        _beneficiaryMode == _BeneficiaryInputMode.external,
                    onTap: () => setState(
                      () => _beneficiaryMode = _BeneficiaryInputMode.external,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _SegmentModeButton(
                    key: const Key('beneficiary_mode_member'),
                    label: 'Thành viên Gia phả',
                    selected: _beneficiaryMode == _BeneficiaryInputMode.member,
                    onTap: () => setState(() {
                      _beneficiaryMode = _BeneficiaryInputMode.member;
                      if (_selectedMemberId == null && members.isNotEmpty) {
                        _selectedMemberId = members.first.memberId;
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_beneficiaryMode == _BeneficiaryInputMode.external)
            TextField(
              key: const Key('beneficiary_name_input'),
              controller: _beneficiaryNameController,
              maxLength: 255,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    'Ví dụ: CTCP Tu bổ Di tích & Mỹ nghệ Cố Đô hoặc Ông Nguyễn Văn C',
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF8B716E),
                ),
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                ),
              ),
            )
          else if (members.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Đang tải hoặc chưa có danh sách thành viên Gia phả khả dụng.',
                style: TextStyle(fontSize: 13, color: Color(0xFF58413F)),
              ),
            )
          else
            DropdownButtonFormField<String>(
              key: const Key('beneficiary_member_dropdown'),
              initialValue: _findSelectedMember(members) != null
                  ? _selectedMemberId
                  : null,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Chọn thành viên dòng họ nhận chi hỗ trợ...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                ),
              ),
              items: members
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.memberId,
                      child: Text(
                        '${m.fullName} (${m.memberId})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedMemberId = val),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3PurposeAndEvidence() {
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
              _StepBadge(number: 3),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mục Đích Chi & 01 Chứng Từ Đính Kèm',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1C1A),
                      ),
                    ),
                    Text(
                      'Giải trình rõ căn cứ chi và đính kèm 01 tài liệu chính',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mục đích / Lý do chi Quỹ chung *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
              ),
              Text(
                '${_purposeController.text.length} / 2000',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF58413F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ActionChip(
            label: Text(
              '+ Gợi ý mẫu (${_category.displayName})',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryCrimson,
              ),
            ),
            backgroundColor: const Color(0xFFFDF2F2),
            side: const BorderSide(color: Color(0xFFFECACA)),
            onPressed: _appendCategorySuggestion,
          ),
          const SizedBox(height: 8),

          TextField(
            key: const Key('disbursement_purpose_input'),
            controller: _purposeController,
            maxLines: 4,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Ghi rõ hiện trạng, căn cứ dự toán và phạm vi sử dụng khoản chi (tối thiểu 5 ký tự)...',
              hintStyle: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF8B716E),
              ),
              filled: true,
              fillColor: Colors.white,
              counterText: '',
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
              ),
            ),
          ),

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

  Widget _buildGovernanceRuleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quy trình kiểm soát chi Quỹ chung (US-60)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1C1A),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '1. Khoản chi phải nhỏ hơn hoặc bằng Số dư khả dụng hiện tại.\n'
            '2. Chỉ Trưởng tộc hoặc Quản trị viên mới có quyền ký duyệt kèm xác thực mật khẩu tài khoản.\n'
            '3. Sau khi ký duyệt, Sổ cái bất biến (SHA-256) sẽ tự động ghi nhận bút toán chi.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF58413F),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSubmitCard({
    required bool canSubmit,
    required String? blockingReason,
    required CommonFundBalanceModel balance,
    required List<BranchMemberItem> members,
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
          Text(
            blockingReason != null
                ? '• $blockingReason'
                : '✓ Đủ điều kiện trình Trưởng tộc ký duyệt',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: blockingReason != null
                  ? const Color(0xFFBA1A1A)
                  : AppTheme.immutableLedgerTeal,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('submit_disbursement_desktop_button'),
            onPressed:
                canSubmit ? () => _onSubmitPressed(balance, members) : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: AppTheme.primaryCrimson,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE3E2E0),
              disabledForegroundColor: const Color(0xFF8B716E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.send_rounded, size: 19),
            label: const Text(
              'Gửi Đề Xuất Chi Quỹ',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStickyFooter({
    required bool canSubmit,
    required CommonFundBalanceModel balance,
    required List<BranchMemberItem> members,
  }) {
    final projected = balance.availableBalance - _amount;
    final isOver = projected < 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6DFD8))),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
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
                const Expanded(
                  child: Text(
                    'Sau chi dự kiến:',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF58413F)),
                  ),
                ),
                Text(
                  AppFormatters.formatVnd(projected),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isOver
                        ? const Color(0xFFBA1A1A)
                        : AppTheme.immutableLedgerTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              key: const Key('submit_disbursement_mobile_button'),
              onPressed:
                  canSubmit ? () => _onSubmitPressed(balance, members) : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(48, 48),
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
                'Gửi Đề Xuất Chi Quỹ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int number;
  const _StepBadge({required this.number});

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

class _QuickIncrementChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _QuickIncrementChip({
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: isDanger ? null : 'monospace',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: isDanger ? const Color(0xFFBA1A1A) : const Color(0xFF1A1C1A),
        ),
      ),
      backgroundColor: isDanger ? Colors.white : const Color(0xFFFAF9F6),
      side: BorderSide(
        color: isDanger ? const Color(0xFFFECACA) : const Color(0xFFE6DFD8),
      ),
      onPressed: onTap,
    );
  }
}

class _SegmentModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  selected ? AppTheme.primaryCrimson : const Color(0xFF58413F),
            ),
          ),
        ),
      ),
    );
  }
}
