import 'package:ct484_project/ui/auth/widgets/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../services/cubits/auth_cubit.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().sendResetOtp(_email.text.trim());
      if (mounted) {
        setState(() {
          _loading = false;
          _sent = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _loading = false);
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
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/login');
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
              title: 'Quên mật khẩu?',
              subtitle: 'Nhập email để nhận mã OTP đặt lại mật khẩu',
            ),

            const SizedBox(height: 36),

            if (!_sent) ...[
              AuthTextField(
                controller: _email,
                label: 'Email đã đăng ký',
                hint: 'example@email.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _send(),
              ),

              const SizedBox(height: 24),

              ListenableBuilder(
                listenable: _email,
                builder: (context, _) => AuthPrimaryButton(
                  label: 'Gửi mã OTP',
                  onPressed: _email.text.trim().isNotEmpty ? _send : null,
                  isLoading: _loading,
                ),
              ),
            ] else ...[
              // ── Success state ──────────────────────────────────
              _SentSuccessCard(email: _email.text.trim()),

              const SizedBox(height: 24),

              AuthPrimaryButton(
                label: 'Nhập mã OTP',
                onPressed: () => context.go(
                  '/verify-otp',
                  extra: {'email': _email.text.trim()},
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => setState(() => _sent = false),
                  child: const Text(
                    'Gửi lại email khác',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Tips card
            _TipCard(),
          ],
        ),
      ),
    );
  }
}

class _SentSuccessCard extends StatelessWidget {
  const _SentSuccessCard({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email đã được gửi!',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Kiểm tra hộp thư của $email',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Kiểm tra cả thư mục Spam nếu không thấy email trong hộp thư đến. Mã OTP có hiệu lực trong 5 phút.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
