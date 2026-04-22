import 'package:ct484_project/ui/auth/widgets/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../services/cubits/auth_cubit.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _current.text.isNotEmpty &&
      _new.text.length >= 8 &&
      _confirm.text == _new.text &&
      !_loading;

  Future<void> _change() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().changePassword(_current.text, _new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đổi mật khẩu thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textSecondary,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            _InfoBanner(),

            const SizedBox(height: 28),

            AuthTextField(
              controller: _current,
              label: 'Mật khẩu hiện tại',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 30),
                ),
                child: const Text(
                  'Quên mật khẩu hiện tại?',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            const _SectionDivider(label: 'Mật khẩu mới'),

            const SizedBox(height: 16),

            AuthTextField(
              controller: _new,
              label: 'Mật khẩu mới',
              hint: 'Tối thiểu 8 ký tự',
              prefixIcon: Icons.lock_reset_rounded,
              obscure: true,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            AuthTextField(
              controller: _confirm,
              label: 'Xác nhận mật khẩu mới',
              hint: '••••••••',
              prefixIcon: Icons.lock_reset_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _canSubmit ? _change() : null,
            ),

            const SizedBox(height: 12),

            // Match indicator
            ListenableBuilder(
              listenable: Listenable.merge([_new, _confirm]),
              builder: (context, _) {
                if (_confirm.text.isEmpty || _new.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                final match = _new.text == _confirm.text;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: match
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: match
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.danger.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        match
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        size: 15,
                        color: match ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        match ? 'Mật khẩu khớp' : 'Mật khẩu không khớp',
                        style: TextStyle(
                          fontSize: 12,
                          color: match ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            ListenableBuilder(
              listenable: Listenable.merge([_current, _new, _confirm]),
              builder: (context, _) => AuthPrimaryButton(
                label: 'Cập nhật mật khẩu',
                onPressed: _canSubmit ? _change : null,
                isLoading: _loading,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Info Banner ────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nên đổi mật khẩu định kỳ để bảo vệ tài khoản',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
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

// ── Section Divider ────────────────────────────────────────────────
class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}
