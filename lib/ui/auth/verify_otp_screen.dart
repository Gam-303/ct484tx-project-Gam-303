import 'package:ct484_project/ui/auth/widgets/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../services/cubits/auth_cubit.dart';

/// extra = {'email': String}
class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpToken = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpToken.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpToken.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().verifyResetOtp(
        widget.email,
        _otpToken.text.trim(),
      );
      if (!mounted) return;
      context.go('/reset-password', extra: {'email': widget.email});
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

  Future<void> _resend() async {
    try {
      await context.read<AuthCubit>().resendResetOtp(widget.email);
      if (!mounted) return;
      _otpToken.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã gửi lại mã OTP'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
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
              title: 'Xác thực OTP',
              subtitle: 'Nhập mã xác thực được gửi đến email của bạn',
            ),

            const SizedBox(height: 12),

            // Email badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            AuthTextField(
              controller: _otpToken,
              label: 'Mã OTP',
              hint: 'Nhập 6 chữ số',
              prefixIcon: Icons.password_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verify(),
            ),

            const SizedBox(height: 32),

            ListenableBuilder(
              listenable: _otpToken,
              builder: (context, _) {
                return AuthPrimaryButton(
                  label: 'Xác nhận',
                  onPressed: _otpToken.text.trim().isNotEmpty ? _verify : null,
                  isLoading: _loading,
                );
              },
            ),

            const SizedBox(height: 24),

            Center(
              child: TextButton(
                onPressed: _resend,
                child: const Text(
                  'Gửi lại mã OTP',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
