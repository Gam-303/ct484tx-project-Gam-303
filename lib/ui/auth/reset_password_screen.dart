import 'package:ct484_project/ui/auth/widgets/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../services/cubits/auth_cubit.dart';

/// extra = {'email': String}
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _newPassword.text.length >= 8 &&
      _confirm.text == _newPassword.text &&
      !_loading;

  Future<void> _reset() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().resetPasswordWithOtp(_newPassword.text);
      if (!mounted) return;
      _showSuccess();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
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

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Thành công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mật khẩu đã được đặt lại.\nHãy đăng nhập lại để tiếp tục.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/login');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/forgot-password');
                }
              },
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textSecondary,
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
              title: 'Đặt lại mật khẩu',
              subtitle: 'Tạo mật khẩu mới an toàn cho tài khoản của bạn',
            ),

            const SizedBox(height: 36),

            AuthTextField(
              controller: _newPassword,
              label: 'Mật khẩu mới',
              hint: 'Tối thiểu 8 ký tự',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            AuthTextField(
              controller: _confirm,
              label: 'Xác nhận mật khẩu mới',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _canSubmit ? _reset() : null,
            ),

            const SizedBox(height: 12),

            // Match indicator
            ListenableBuilder(
              listenable: Listenable.merge([_newPassword, _confirm]),
              builder: (context, _) {
                if (_confirm.text.isEmpty) return const SizedBox.shrink();
                final match = _newPassword.text == _confirm.text;
                return Row(
                  children: [
                    Icon(
                      match
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 14,
                      color: match ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      match ? 'Mật khẩu khớp' : 'Mật khẩu không khớp',
                      style: TextStyle(
                        fontSize: 12,
                        color: match ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Requirements checklist
            _RequirementsCard(password: _newPassword),

            const SizedBox(height: 28),

            ListenableBuilder(
              listenable: Listenable.merge([_newPassword, _confirm]),
              builder: (context, _) => AuthPrimaryButton(
                label: 'Đặt lại mật khẩu',
                onPressed: _canSubmit ? _reset : null,
                isLoading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard({required this.password});
  final TextEditingController password;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: password,
      builder: (context, _) {
        final p = password.text;
        final checks = [
          (p.length >= 8, 'Ít nhất 8 ký tự'),
          (RegExp(r'[A-Z]').hasMatch(p), 'Có chữ hoa'),
          (RegExp(r'[0-9]').hasMatch(p), 'Có số'),
          (RegExp(r'[^a-zA-Z0-9]').hasMatch(p), 'Có ký tự đặc biệt'),
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: checks.map((item) {
              final (ok, label) = item;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                      size: 16,
                      color: ok ? AppColors.success : AppColors.textHint,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: ok ? AppColors.textPrimary : AppColors.textHint,
                        fontWeight: ok ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
