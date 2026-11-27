import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/common_fund_disbursement_models.dart';
import '../providers/common_fund_disbursement_providers.dart';
import '../widgets/disbursement_review_detail_panel.dart';
import '../widgets/disbursement_review_dialogs.dart';

/// Màn hình Ký Duyệt Chi Quỹ Chung dành cho Trưởng tộc / Admin kèm xác thực Mật khẩu (US-60).
class ReviewCommonFundDisbursementScreen extends ConsumerStatefulWidget {
  final String? initialRequestId;

  const ReviewCommonFundDisbursementScreen({
    super.key,
    this.initialRequestId,
  });

  @override
  ConsumerState<ReviewCommonFundDisbursementScreen> createState() =>
      _ReviewCommonFundDisbursementScreenState();
}

class _ReviewCommonFundDisbursementScreenState
    extends ConsumerState<ReviewCommonFundDisbursementScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _mobileShowingDetail = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRequestId != null &&
        widget.initialRequestId!.trim().isNotEmpty) {
      _mobileShowingDetail = true;
    }
    Future.microtask(
      () => ref.read(disbursementReviewQueueProvider.notifier).loadQueue(
            showLoading: true,
            preferredRequestId: widget.initialRequestId,
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openApproveDialog(
    CommonFundDisbursementModel req,
    double availableBalance,
  ) async {
    final notifier = ref.read(disbursementReviewQueueProvider.notifier);
    final result = await ApproveDisbursementPasswordDialog.show(
      context,
      request: req,
      availableBalance: availableBalance,
      onConfirm: ({
        String? confirmPassword,
        String? rejectionReason,
        String? description,
      }) {
        return notifier.submitReview(
          requestId: req.requestId,
          approved: true,
          confirmPassword: confirmPassword,
          description: description,
        );
      },
    );

    if (result != null && mounted) {
      final txId = result.ledgerEntry?.transactionId ??
          result.disbursementRequest.ledgerTransactionId ??
          '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            txId.isNotEmpty
                ? 'Đã ký duyệt ${req.requestId} và ghi bút toán $txId vào Sổ cái!'
                : 'Đã ký duyệt đề xuất chi ${req.requestId} thành công!',
          ),
          backgroundColor: AppTheme.immutableLedgerTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openRejectDialog(CommonFundDisbursementModel req) async {
    final notifier = ref.read(disbursementReviewQueueProvider.notifier);
    final result = await RejectDisbursementDialog.show(
      context,
      request: req,
      onConfirm: ({
        String? confirmPassword,
        String? rejectionReason,
        String? description,
      }) {
        return notifier.submitReview(
          requestId: req.requestId,
          approved: false,
          rejectionReason: rejectionReason,
        );
      },
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối đề xuất chi ${req.requestId}.'),
          backgroundColor: const Color(0xFF1A1C1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(dualRbacSessionProvider);
    final state = ref.watch(disbursementReviewQueueProvider);
    final canReview = session.canReviewCommonFundDisbursement;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final showHeaderBalancePill = screenWidth >= 720;

    final selected = state.selectedRequest;
    final isPendingSelected = selected != null &&
        selected.approvalStatus == CommonFundDisbursementStatusEnum.pending;
    final isOverdraftSelected =
        isPendingSelected && (selected.amount > state.availableBalance);

    final mobileSubtitle = _mobileShowingDetail
        ? 'Thẩm định & ký duyệt mật khẩu'
        : 'Chọn phiếu chi cần thẩm định';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE6DFD8))),
        leading: IconButton(
          key: const Key('disbursement_review_back_button'),
          tooltip: 'Quay lại',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF1A1C1A),
          ),
          onPressed: () {
            if (!isDesktop && _mobileShowingDetail) {
              setState(() => _mobileShowingDetail = false);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ký Duyệt Chi Quỹ Chung',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
              ),
            ),
            Text(
              isDesktop
                  ? 'Trưởng tộc thẩm định, xác thực mật khẩu & niêm phong Sổ cái'
                  : mobileSubtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF58413F),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (showHeaderBalancePill)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  key: const Key('disbursement_header_balance_pill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Quỹ khả dụng: ',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.immutableLedgerTeal,
                        ),
                      ),
                      Text(
                        AppFormatters.formatVnd(state.availableBalance),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.immutableLedgerTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              key: const Key('disbursement_refresh_button'),
              tooltip: 'Làm mới danh sách',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFAF9F6),
                side: const BorderSide(color: Color(0xFFE6DFD8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: state.isLoading
                  ? null
                  : () => ref
                      .read(disbursementReviewQueueProvider.notifier)
                      .loadQueue(showLoading: true),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 20,
                color: Color(0xFF58413F),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktopLayout = constraints.maxWidth >= 1024;
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryCrimson),
            );
          }

          if (state.errorMessage != null && state.items.isEmpty) {
            return _buildFullErrorState(state.errorMessage!);
          }

          if (desktopLayout) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!canReview) ...[
                        _buildRbacGuardBanner(),
                        const SizedBox(height: 14),
                      ],
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth >= 1200 ? 372 : 340,
                              child: _buildQueuePanel(
                                state: state,
                                isDesktop: true,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: selected == null
                                        ? _buildEmptyDetailCard()
                                        : SingleChildScrollView(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: DisbursementReviewDetailPanel(
                                              request: selected,
                                              balance: state.balance,
                                              sealedEntry:
                                                  state.selectedSealedEntry,
                                              isLoadingLedgerDetail:
                                                  state.isLoadingLedgerDetail,
                                            ),
                                          ),
                                  ),
                                  if (isPendingSelected) ...[
                                    const SizedBox(height: 12),
                                    _buildDesktopDecisionBar(
                                      selected: selected,
                                      availableBalance: state.availableBalance,
                                      canReview: canReview,
                                      isOverdraft: isOverdraftSelected,
                                      isSubmitting: state.isSubmittingReview,
                                    ),
                                  ],
                                ],
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
          }

          // MOBILE: List <-> Detail
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canReview) ...[
                  _buildRbacGuardBanner(),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: !_mobileShowingDetail
                      ? _buildQueuePanel(state: state, isDesktop: false)
                      : (selected == null
                          ? _buildEmptyDetailCard()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: DisbursementReviewDetailPanel(
                                request: selected,
                                balance: state.balance,
                                sealedEntry: state.selectedSealedEntry,
                                isLoadingLedgerDetail:
                                    state.isLoadingLedgerDetail,
                              ),
                            )),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: (!isDesktop &&
              _mobileShowingDetail &&
              isPendingSelected &&
              !state.isLoading)
          ? _buildMobileStickyDecisionBar(
              selected: selected,
              availableBalance: state.availableBalance,
              canReview: canReview,
              isOverdraft: isOverdraftSelected,
              isSubmitting: state.isSubmittingReview,
            )
          : null,
    );
  }

  Widget _buildRbacGuardBanner() {
    return Container(
      key: const Key('disbursement_review_rbac_banner'),
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
              'Phiên hiện tại chỉ có quyền xem. Chỉ Trưởng tộc (ROLE_CLAN_HEAD) hoặc Quản trị viên (ROLE_ADMIN) mới có quyền ký duyệt hoặc từ chối phiếu chi Quỹ chung.',
              style: TextStyle(
                fontSize: 13.5,
                color: Color(0xFF58413F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullErrorState(String message) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFBA1A1A),
                  size: 38,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Không thể tải danh sách đề xuất chi Quỹ chung',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1C1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF58413F),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(disbursementReviewQueueProvider.notifier)
                      .loadQueue(showLoading: true),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppTheme.primaryCrimson,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Thử tải lại',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueuePanel({
    required DisbursementReviewQueueState state,
    required bool isDesktop,
  }) {
    final notifier = ref.read(disbursementReviewQueueProvider.notifier);
    final filtered = state.filteredItems;

    return Container(
      key: const Key('disbursement_review_queue_panel'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hàng Chờ Ký Duyệt Chi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1A),
                        ),
                      ),
                    ),
                    if (!isDesktop)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF99F6E4)),
                        ),
                        child: Text(
                          'Quỹ: ${AppFormatters.formatVnd(state.availableBalance)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.immutableLedgerTeal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('disbursement_queue_search_input'),
                  controller: _searchController,
                  onChanged: notifier.setKeyword,
                  decoration: InputDecoration(
                    hintText: 'Tìm mã CFD..., tiêu đề, thụ hưởng...',
                    hintStyle: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF8B716E),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 19,
                      color: Color(0xFF58413F),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Xóa từ khóa',
                            onPressed: () {
                              _searchController.clear();
                              notifier.setKeyword('');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CommonFundExpenseCategoryEnum?>(
                  key: const Key('disbursement_queue_category_dropdown'),
                  initialValue: state.categoryFilter,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFDFD8D0)),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<CommonFundExpenseCategoryEnum?>(
                      value: null,
                      child: Text(
                        'Tất cả danh mục chi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    ...CommonFundExpenseCategoryEnum.values.map(
                      (c) => DropdownMenuItem<CommonFundExpenseCategoryEnum?>(
                        value: c,
                        child: Text(
                          c.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                  onChanged: notifier.setCategoryFilter,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: DisbursementReviewStatusFilter.values.map((filter) {
                    final selected = state.statusFilter == filter;
                    final count = state.countForFilter(filter);
                    return ChoiceChip(
                      key: Key('disbursement_filter_${filter.name}'),
                      label: Text(
                        '${filter.shortLabel} ($count)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF58413F),
                        ),
                      ),
                      selected: selected,
                      showCheckmark: false,
                      selectedColor: AppTheme.primaryCrimson,
                      backgroundColor: const Color(0xFFFAF9F6),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.primaryCrimson
                            : const Color(0xFFE6DFD8),
                      ),
                      onSelected: (_) => notifier.setStatusFilter(filter),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEFECE6)),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không có phiếu chi nào khớp bộ lọc hiện tại.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF58413F),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = filtered[index];
                      final isSelected =
                          item.requestId == state.selectedRequestId;
                      final isOver = item.approvalStatus ==
                              CommonFundDisbursementStatusEnum.pending &&
                          item.amount > state.availableBalance;
                      return _DisbursementQueueCard(
                        item: item,
                        isSelected: isSelected,
                        isOverdraft: isOver,
                        onTap: () {
                          notifier.selectRequest(item.requestId);
                          if (!isDesktop) {
                            setState(() => _mobileShowingDetail = true);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6DFD8)),
      ),
      child: const Center(
        child: Text(
          'Chọn một phiếu đề xuất chi trong hàng chờ để bắt đầu thẩm định.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.5, color: Color(0xFF58413F)),
        ),
      ),
    );
  }

  Widget _buildDesktopDecisionBar({
    required CommonFundDisbursementModel selected,
    required double availableBalance,
    required bool canReview,
    required bool isOverdraft,
    required bool isSubmitting,
  }) {
    final helperText = !canReview
        ? 'Phiên chỉ xem — Không có quyền ký duyệt hoặc từ chối.'
        : isOverdraft
            ? 'Số dư Quỹ khả dụng không đủ; hệ thống khóa nút Ký duyệt.'
            : 'Trưởng tộc kiểm tra chứng từ và nhập Mật khẩu tài khoản để ký duyệt.';

    return Container(
      key: const Key('disbursement_desktop_decision_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6DFD8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x121A1C1A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              helperText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isOverdraft ? FontWeight.bold : FontWeight.normal,
                color: isOverdraft
                    ? const Color(0xFFBA1A1A)
                    : const Color(0xFF58413F),
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('reject_disbursement_button'),
                onPressed: (canReview && !isSubmitting)
                    ? () => _openRejectDialog(selected)
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFFBA1A1A),
                  side: BorderSide(
                    color: canReview
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFFDFD8D0),
                    width: 1.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  'Từ Chối',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('approve_disbursement_button'),
                onPressed: (canReview && !isOverdraft && !isSubmitting)
                    ? () => _openApproveDialog(selected, availableBalance)
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppTheme.primaryCrimson,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE3E2E0),
                  disabledForegroundColor: const Color(0xFF8B716E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.lock_outline_rounded, size: 18),
                label: const Text(
                  'Ký Duyệt (Mật Khẩu)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStickyDecisionBar({
    required CommonFundDisbursementModel selected,
    required double availableBalance,
    required bool canReview,
    required bool isOverdraft,
    required bool isSubmitting,
  }) {
    return Container(
      key: const Key('disbursement_mobile_decision_bar'),
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
        child: Row(
          children: [
            OutlinedButton(
              key: const Key('reject_disbursement_button'),
              onPressed: (canReview && !isSubmitting)
                  ? () => _openRejectDialog(selected)
                  : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: const Color(0xFFBA1A1A),
                side: BorderSide(
                  color: canReview
                      ? const Color(0xFFBA1A1A)
                      : const Color(0xFFDFD8D0),
                  width: 1.8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Từ Chối',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('approve_disbursement_button'),
                onPressed: (canReview && !isOverdraft && !isSubmitting)
                    ? () => _openApproveDialog(selected, availableBalance)
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppTheme.primaryCrimson,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE3E2E0),
                  disabledForegroundColor: const Color(0xFF8B716E),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.lock_outline_rounded, size: 17),
                label: const Text(
                  'Ký Duyệt (Mật Khẩu)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisbursementQueueCard extends StatelessWidget {
  final CommonFundDisbursementModel item;
  final bool isSelected;
  final bool isOverdraft;
  final VoidCallback onTap;

  const _DisbursementQueueCard({
    required this.item,
    required this.isSelected,
    required this.isOverdraft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortStatus = switch (item.approvalStatus) {
      CommonFundDisbursementStatusEnum.pending => 'Chờ duyệt',
      CommonFundDisbursementStatusEnum.approved => 'Đã duyệt',
      CommonFundDisbursementStatusEnum.rejected => 'Từ chối',
    };

    return InkWell(
      key: Key('disbursement_queue_item_${item.requestId}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDF2F2) : const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryCrimson : const Color(0xFFE6DFD8),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.requestId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1C1A),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.approvalStatus.badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: item.approvalStatus.badgeBorderColor),
                  ),
                  child: Text(
                    shortStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: item.approvalStatus.badgeTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.category.badgeBackgroundColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: item.category.badgeBorderColor),
                    ),
                    child: Text(
                      item.category.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.category.badgeTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '−${AppFormatters.formatVnd(item.amount)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.beneficiaryName ?? item.proposedByAccountId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF58413F),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (isOverdraft)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Text(
                      'Vượt số dư',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBA1A1A),
                      ),
                    ),
                  )
                else
                  Text(
                    AppFormatters.formatDate(item.createdAt.toLocal()),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF58413F),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
