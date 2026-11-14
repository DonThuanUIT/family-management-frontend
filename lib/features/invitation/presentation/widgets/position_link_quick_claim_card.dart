import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/claim_position_provider.dart';

class PositionLinkQuickClaimCard extends ConsumerStatefulWidget {
  final String? initialCode;
  final VoidCallback? onSuccess;

  const PositionLinkQuickClaimCard({
    super.key,
    this.initialCode,
    this.onSuccess,
  });

  @override
  ConsumerState<PositionLinkQuickClaimCard> createState() =>
      _PositionLinkQuickClaimCardState();
}

class _PositionLinkQuickClaimCardState
    extends ConsumerState<PositionLinkQuickClaimCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _emailController;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _emailController = TextEditingController();

    if (widget.initialCode != null && widget.initialCode!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(claimPositionProvider.notifier)
              .lookupCode(widget.initialCode!.trim());
        }
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(claimPositionProvider.notifier);
    final success = await notifier.claim(
      inviteCode: _codeController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    if (success && mounted) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Đã liên kết vị trí gia phả thành công! Chào mừng bạn.'),
              ],
            ),
            backgroundColor: Color(0xFF006E2A),
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(claimPositionProvider);
    final notifier = ref.read(claimPositionProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Generation Key / Position Link Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Mã liên kết vị trí gia phả',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F482F).withAlpha(15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BẮT BUỘC',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8F482F),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.previewError != null
                        ? const Color(0xFFBA1A1A)
                        : (state.preview != null
                            ? const Color(0xFF006E2A)
                            : const Color(0xFFDAC1BA)),
                    width: state.preview != null ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8F482F),
                          letterSpacing: 0.8,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'NHẬP-MÃ-VỊ-TRÍ',
                          hintStyle: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: Color(0xFF9E8E87),
                            letterSpacing: 0.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (val) => notifier.onCodeChanged(val),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Vui lòng nhập mã vị trí gia phả';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (state.isLoadingPreview)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8F482F),
                        ),
                      )
                    else if (state.preview != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF99F8A2).withAlpha(120),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF006E2A).withAlpha(80),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                size: 14, color: Color(0xFF006E2A)),
                            const SizedBox(width: 4),
                            Text(
                              'Khớp ${state.preview!.branchName}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00531E),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (state.preview != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 15, color: Color(0xFF874E00)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Cấp bởi: ${state.preview!.issuedBy ?? "Trưởng Chi"} • Tự động gắn vào ${state.preview!.branchName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B584E),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (state.previewError != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 15, color: Color(0xFFBA1A1A)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        state.previewError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // 2. Pre-assigned Profile Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Họ và tên con cháu (Đã định vị)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F3F1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E0DA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person,
                        size: 18, color: Color(0xFF8F482F)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.preview?.fullName.isNotEmpty == true
                            ? state.preview!.fullName
                            : 'Đang tải thông tin vị trí...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: state.preview != null
                              ? const Color(0xFF1C1C1A)
                              : const Color(0xFF9E8E87),
                        ),
                      ),
                    ),
                    const Tooltip(
                      message: 'Hồ sơ đã được Trưởng chi tạo sẵn trên phả hệ',
                      child: Icon(Icons.lock_outline,
                          size: 16, color: Color(0xFF87736D)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Phone Number & Password Inputs
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Số điện thoại',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.call,
                      size: 18, color: Color(0xFF87736D)),
                  filled: true,
                  fillColor: const Color(0xFFF6F3F1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E0DA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E0DA)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nhập số điện thoại';
                  }
                  if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(val.trim())) {
                    return 'SĐT không hợp lệ';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mật khẩu tài khoản',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1A),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.lock,
                      size: 18, color: Color(0xFF87736D)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18,
                      color: const Color(0xFF87736D),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F3F1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E0DA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFFE5E0DA)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nhập mật khẩu';
                  }
                  if (val.trim().length < 6) {
                    return 'Tối thiểu 6 ký tự';
                  }
                  return null;
                },
              ),
            ],
          ),

          if (state.claimError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBA1A1A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFBA1A1A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.claimError!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF93000A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 4. Submit CTA Button
          ElevatedButton(
            onPressed: state.isClaiming ? null : _submitClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8F482F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: state.isClaiming
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Đang kết nối phả hệ...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Xác Nhận & Gia Nhập Cây Phả Hệ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
