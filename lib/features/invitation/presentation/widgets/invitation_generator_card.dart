import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/position_link_providers.dart';

class InvitationGeneratorCard extends ConsumerStatefulWidget {
  const InvitationGeneratorCard({super.key});

  @override
  ConsumerState<InvitationGeneratorCard> createState() =>
      _InvitationGeneratorCardState();
}

class _InvitationGeneratorCardState
    extends ConsumerState<InvitationGeneratorCard> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(clanInvitesProvider);
    _nameController = TextEditingController(text: state.memberName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clanInvitesProvider);
    final notifier = ref.read(clanInvitesProvider.notifier);

    if (_nameController.text != state.memberName && !state.isSubmitting) {
      _nameController.text = state.memberName;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;
        final stackActions = constraints.maxWidth < 800;

        return Container(
          padding: EdgeInsets.all(isNarrow ? 16 : 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6DFD8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card with Wrap to prevent overflow
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF0EBE5)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.key_outlined,
                          color: Color(0xFF8F482F),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Tạo Mã Liên Kết Thành Viên Mới',
                            style: TextStyle(
                              fontFamily: 'Merriweather',
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1C1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDBD0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CHUẨN HÓA CHI PHÁI',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Color(0xFF8F482F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Form Grid (Stacked on narrow, Row on wide)
              if (isNarrow)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBranchField(state, notifier),
                    const SizedBox(height: 14),
                    _buildNameField(notifier),
                    const SizedBox(height: 14),
                    _buildGenerationField(state, notifier),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildBranchField(state, notifier)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildNameField(notifier)),
                    const SizedBox(width: 14),
                    Expanded(child: _buildGenerationField(state, notifier)),
                  ],
                ),
              const SizedBox(height: 18),

              // 3. Action Row & Generated Link Container
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEBE6E0)),
                ),
                child: stackActions
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildGenerateButton(state, notifier),
                          const SizedBox(height: 8),
                          _buildCopyableLinkBox(state, notifier),
                        ],
                      )
                    : Row(
                        children: [
                          _buildGenerateButton(state, notifier),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _buildCopyableLinkBox(state, notifier)),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchField(ClanInvitesState state, ClanInvitesNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1A),
              fontFamily: 'Plus Jakarta Sans',
            ),
            children: [
              TextSpan(text: 'Nhánh Gia Đình Tiếp Nhận '),
              TextSpan(text: '*', style: TextStyle(color: Color(0xFF8F482F))),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3F1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E0DA)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: state.selectedBranchId,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF54433E)),
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF1C1C1A),
                fontWeight: FontWeight.w500,
              ),
              items: state.availableBranches.map((branch) {
                return DropdownMenuItem<String>(
                  value: branch.id,
                  child: Text(
                    branch.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  notifier.setSelectedBranch(val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Chi phái định vị nhánh phụ',
          style: TextStyle(fontSize: 11, color: Color(0xFF756864)),
        ),
      ],
    );
  }

  Widget _buildNameField(ClanInvitesNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1A),
              fontFamily: 'Plus Jakarta Sans',
            ),
            children: [
              TextSpan(text: 'Tên Thành Viên Dự Kiến '),
              TextSpan(text: '*', style: TextStyle(color: Color(0xFF8F482F))),
            ],
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _nameController,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1C1A),
            ),
            decoration: InputDecoration(
              hintText: 'Họ và tên chữ đầy đủ...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9E928E)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: const Color(0xFFF6F3F1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E0DA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF8F482F), width: 1.5),
              ),
            ),
            onChanged: (val) => notifier.setMemberName(val),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Tên định danh khai sinh',
          style: TextStyle(fontSize: 11, color: Color(0xFF756864)),
        ),
      ],
    );
  }

  Widget _buildGenerationField(
      ClanInvitesState state, ClanInvitesNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1A),
              fontFamily: 'Plus Jakarta Sans',
            ),
            children: [
              TextSpan(text: 'Thế Hệ (Đời thứ) '),
              TextSpan(text: '*', style: TextStyle(color: Color(0xFF8F482F))),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3F1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E0DA)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: state.generation,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF54433E)),
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF1C1C1A),
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem<int>(
                  value: 3,
                  child: Text('Đời thứ 3 (Tam thế)'),
                ),
                DropdownMenuItem<int>(
                  value: 4,
                  child: Text('Đời thứ 4 (Tứ thế)'),
                ),
                DropdownMenuItem<int>(
                  value: 5,
                  child: Text('Đời thứ 5 (Ngũ thế tử tôn)'),
                ),
                DropdownMenuItem<int>(
                  value: 6,
                  child: Text('Đời thứ 6 (Lục thế hậu duệ)'),
                ),
                DropdownMenuItem<int>(
                  value: 7,
                  child: Text('Đời thứ 7 (Thất thế)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  notifier.setGeneration(val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Bậc thứ tính từ thủy tổ',
          style: TextStyle(fontSize: 11, color: Color(0xFF756864)),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(
      ClanInvitesState state, ClanInvitesNotifier notifier) {
    return ElevatedButton.icon(
      onPressed: state.isSubmitting
          ? null
          : () async {
              await notifier.createVirtualMemberAndGenerateCode();
            },
      icon: state.isSubmitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.add_link, size: 18, color: Colors.white),
      label: Text(
        state.isSubmitting
            ? 'Đang khởi tạo...'
            : '+ Tạo Hồ Sơ & Sinh Mã Liên Kết',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8F482F),
        disabledBackgroundColor: const Color(0xFFB58E81),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildCopyableLinkBox(
      ClanInvitesState state, ClanInvitesNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E0DA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 16, color: Color(0xFF8F482F)),
          const SizedBox(width: 6),
          Expanded(
            child: SelectableText(
              state.currentShareableUrl,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8F482F),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => notifier.copyShareableLink(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: state.hasCopied
                    ? const Color(0xFF99F8A2)
                    : const Color(0xFFF0EDEB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.hasCopied ? Icons.check : Icons.copy,
                    size: 13,
                    color: state.hasCopied
                        ? const Color(0xFF00531E)
                        : const Color(0xFF54433E),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.hasCopied ? '✓ Đã Sao Chép' : '📋 Sao Chép Link',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: state.hasCopied
                          ? const Color(0xFF00531E)
                          : const Color(0xFF1C1C1A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
