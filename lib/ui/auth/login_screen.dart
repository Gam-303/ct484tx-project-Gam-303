import 'package:ct484_project/ui/auth/widgets/auth_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../services/cubits/auth_cubit.dart';
import '../../services/cubits/tasks_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().login(_email.text.trim(), _password.text);
      if (!mounted) return;
      await context.read<TasksCubit>().load();
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email hoặc mật khẩu không đúng'),
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
            const SizedBox(height: 48),

            const AuthHeader(
              title: 'Chào mừng trở lại!',
              subtitle: 'Đăng nhập để bắt đầu phiên tập trung hôm nay',
            ),

            const SizedBox(height: 36),

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
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 8),

            AuthPrimaryButton(
              label: 'Đăng nhập',
              onPressed: _loading ? null : _login,
              isLoading: _loading,
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 32),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa có tài khoản? ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text(
                      'Đăng ký ngay',
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
