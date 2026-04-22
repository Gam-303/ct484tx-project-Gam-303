import 'package:ct484_project/ui/auth/widgets/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../services/cubits/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _loading = false;
  bool _agreed = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty &&
      _confirmPassword.text.isNotEmpty &&
      _agreed &&
      !_loading;

  Future<void> _register() async {
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mật khẩu xác nhận không khớp'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Đăng ký thành công. Hãy đăng nhập để tiếp tục.',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.go('/login');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đăng ký thất bại. Vui lòng thử lại.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Back button
            IconButton(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const AuthHeader(
              title: 'Tạo tài khoản mới',
              subtitle: 'Bắt đầu hành trình tập trung của bạn',
            ),

            const SizedBox(height: 32),

            AuthTextField(
              controller: _name,
              label: 'Họ và tên',
              hint: 'Nguyễn Văn A',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            AuthTextField(
              controller: _email,
              label: 'Email',
              hint: 'example@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            AuthTextField(
              controller: _password,
              label: 'Mật khẩu',
              hint: 'Tối thiểu 8 ký tự',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            AuthTextField(
              controller: _confirmPassword,
              label: 'Xác nhận mật khẩu',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _canSubmit ? _register() : null,
            ),

            const SizedBox(height: 20),

            // Password strength indicator
            _PasswordStrength(password: _password),

            const SizedBox(height: 16),

            // Terms agreement
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: _agreed ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _agreed ? AppColors.primary : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: _agreed
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: 'Tôi đồng ý với '),
                          TextSpan(
                            text: 'Điều khoản dịch vụ',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' và '),
                          TextSpan(
                            text: 'Chính sách bảo mật',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ListenableBuilder(
              listenable: Listenable.merge([
                _name,
                _email,
                _password,
                _confirmPassword,
              ]),
              builder: (context, _) {
                return AuthPrimaryButton(
                  label: 'Đăng ký',
                  onPressed: _canSubmit ? _register : null,
                  isLoading: _loading,
                );
              },
            ),

            const SizedBox(height: 24),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Password Strength ──────────────────────────────────────────────
class _PasswordStrength extends StatefulWidget {
  const _PasswordStrength({required this.password});
  final TextEditingController password;

  @override
  State<_PasswordStrength> createState() => _PasswordStrengthState();
}

class _PasswordStrengthState extends State<_PasswordStrength> {
  @override
  void initState() {
    super.initState();
    widget.password.addListener(() => setState(() {}));
  }

  int get _strength {
    final p = widget.password.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.password.text.isEmpty) return const SizedBox.shrink();

    final labels = ['Yếu', 'Trung bình', 'Khá', 'Mạnh'];
    final colors = [
      AppColors.danger,
      AppColors.warning,
      AppColors.primaryLight,
      AppColors.success,
    ];
    final s = _strength.clamp(1, 4) - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= s ? colors[s] : AppColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Độ mạnh: ${labels[s]}',
          style: TextStyle(
            fontSize: 12,
            color: colors[s],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
