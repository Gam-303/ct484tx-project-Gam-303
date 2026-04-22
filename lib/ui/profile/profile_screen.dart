import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../data/models/app_settings.dart';
import '../../services/cubits/auth_cubit.dart';
import '../../services/cubits/settings_cubit.dart';
import '../../services/cubits/tasks_cubit.dart';

Future<void> showEditProfileSheet(
  BuildContext context,
  AppSettings settings,
  AuthState auth,
) async {
  final nameController = TextEditingController(
    text: auth.displayName.isEmpty ? settings.displayName : auth.displayName,
  );
  final emailController = TextEditingController(
    text: auth.email.isEmpty ? settings.email : auth.email,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chỉnh sửa thông tin cá nhân',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final authCubit = context.read<AuthCubit>();
                  final settingsCubit = context.read<SettingsCubit>();
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await authCubit.updateProfile(
                      displayName: name.isEmpty ? auth.displayName : name,
                    );
                    await settingsCubit.update(
                      settings.copyWith(
                        displayName: name.isEmpty ? settings.displayName : name,
                        email: auth.email.isEmpty ? settings.email : auth.email,
                      ),
                    );
                  } catch (error) {
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            error.toString().replaceFirst('Exception: ', ''),
                          ),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, auth) => _ProfileHeader(auth: auth),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: BlocBuilder<SettingsCubit, AppSettings>(
                builder: (context, settings) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── Pomodoro settings ────────────────────
                      _SectionLabel('Cài đặt Pomodoro'),
                      const SizedBox(height: 10),
                      _PomodoroSettingsCard(settings: settings),

                      const SizedBox(height: 20),

                      // ── App preferences ──────────────────────
                      _SectionLabel('Tùy chọn ứng dụng'),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        children: [
                          _ToggleRow(
                            icon: Icons.notifications_outlined,
                            iconColor: AppColors.warning,
                            iconBg: const Color(0xFFFFF5E6),
                            label: 'Thông báo',
                            value: settings.notificationsEnabled,
                            onChanged: (v) =>
                                context.read<SettingsCubit>().update(
                                  settings.copyWith(notificationsEnabled: v),
                                ),
                          ),
                          _Divider(),
                          _ToggleRow(
                            icon: Icons.vibration_rounded,
                            iconColor: AppColors.primary,
                            iconBg: AppColors.primarySurface,
                            label: 'Rung khi hết giờ',
                            value: settings.hapticFeedback,
                            onChanged: (v) => context
                                .read<SettingsCubit>()
                                .update(settings.copyWith(hapticFeedback: v)),
                          ),
                          _Divider(),
                          _ToggleRow(
                            icon: Icons.music_note_outlined,
                            iconColor: AppColors.secondary,
                            iconBg: const Color(0xFFE6F8F9),
                            label: 'Âm thanh tập trung',
                            value: settings.focusSound,
                            onChanged: (v) => context
                                .read<SettingsCubit>()
                                .update(settings.copyWith(focusSound: v)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Account ──────────────────────────────
                      _SectionLabel('Tài khoản'),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        children: [
                          _NavRow(
                            icon: Icons.lock_outline_rounded,
                            iconColor: AppColors.primary,
                            iconBg: AppColors.primarySurface,
                            label: 'Đổi mật khẩu',
                            onTap: () => context.go('/change-password'),
                          ),
                          _Divider(),
                          _NavRow(
                            icon: Icons.edit_outlined,
                            iconColor: const Color(0xFF4CAF50),
                            iconBg: const Color(0xFFEDF7EE),
                            label: 'Chỉnh sửa hồ sơ',
                            onTap: () => showEditProfileSheet(
                              context,
                              settings,
                              context.read<AuthCubit>().state,
                            ),
                          ),
                          _Divider(),
                          _NavRow(
                            icon: Icons.cloud_sync_outlined,
                            iconColor: AppColors.secondary,
                            iconBg: const Color(0xFFE6F8F9),
                            label: 'Đồng bộ dữ liệu',
                            onTap: () async {
                              await context.read<TasksCubit>().load();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Đã đồng bộ dữ liệu'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Support ──────────────────────────────
                      _SectionLabel('Hỗ trợ'),
                      const SizedBox(height: 10),
                      _SettingsGroup(
                        children: [
                          _NavRow(
                            icon: Icons.help_outline_rounded,
                            iconColor: AppColors.warning,
                            iconBg: const Color(0xFFFFF5E6),
                            label: 'Trung tâm trợ giúp',
                            onTap: () {},
                          ),
                          _Divider(),
                          _NavRow(
                            icon: Icons.star_outline_rounded,
                            iconColor: const Color(0xFFFFB800),
                            iconBg: const Color(0xFFFFF8E0),
                            label: 'Đánh giá ứng dụng',
                            onTap: () {},
                          ),
                          _Divider(),
                          _NavRow(
                            icon: Icons.info_outline_rounded,
                            iconColor: AppColors.textHint,
                            iconBg: AppColors.surfaceVariant,
                            label: 'Về ứng dụng',
                            subtitle: 'v1.0.0',
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Logout ───────────────────────────────
                      _LogoutButton(),

                      const SizedBox(height: 100),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.auth});

  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3A7DBF), Color(0xFF6EC6CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          auth.displayName.isEmpty
                              ? 'Người dùng'
                              : auth.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  IconButton(
                    onPressed: () {
                      final settings = context.read<SettingsCubit>().state;
                      final auth = context.read<AuthCubit>().state;
                      showEditProfileSheet(context, settings, auth);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: Colors.white70,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
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
}

// ── Helpers ────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      color: AppColors.divider,
    );
  }
}

// ── Toggle Row ─────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Nav Row ────────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 13, color: AppColors.textHint),
              ),
            if (subtitle != null) const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pomodoro Settings Card ─────────────────────────────────────────
class _PomodoroSettingsCard extends StatelessWidget {
  const _PomodoroSettingsCard({required this.settings});
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _TimerRow(
            label: 'Thời gian tập trung',
            icon: Icons.track_changes_rounded,
            minutes: settings.pomodoroMinutes,
            onDecrement: settings.pomodoroMinutes > 1
                ? () => context.read<SettingsCubit>().update(
                    settings.copyWith(
                      pomodoroMinutes: settings.pomodoroMinutes - 1,
                    ),
                  )
                : null,
            onIncrement: () => context.read<SettingsCubit>().update(
              settings.copyWith(pomodoroMinutes: settings.pomodoroMinutes + 1),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _TimerRow(
            label: 'Nghỉ ngắn',
            icon: Icons.free_breakfast_rounded,
            minutes: settings.shortBreakMinutes,
            onDecrement: settings.shortBreakMinutes > 1
                ? () => context.read<SettingsCubit>().update(
                    settings.copyWith(
                      shortBreakMinutes: settings.shortBreakMinutes - 1,
                    ),
                  )
                : null,
            onIncrement: () => context.read<SettingsCubit>().update(
              settings.copyWith(
                shortBreakMinutes: settings.shortBreakMinutes + 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          _TimerRow(
            label: 'Nghỉ dài',
            icon: Icons.nightlight_round,
            minutes: settings.longBreakMinutes,
            onDecrement: settings.longBreakMinutes > 1
                ? () => context.read<SettingsCubit>().update(
                    settings.copyWith(
                      longBreakMinutes: settings.longBreakMinutes - 1,
                    ),
                  )
                : null,
            onIncrement: () => context.read<SettingsCubit>().update(
              settings.copyWith(
                longBreakMinutes: settings.longBreakMinutes + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRow extends StatelessWidget {
  const _TimerRow({
    required this.label,
    required this.icon,
    required this.minutes,
    required this.onIncrement,
    this.onDecrement,
  });

  final String label;
  final IconData icon;
  final int minutes;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Stepper
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _StepBtn(icon: Icons.remove, onTap: onDecrement),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$minutes\'',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StepBtn(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? Colors.white : AppColors.textHint,
        ),
      ),
    );
  }
}

// ── Logout Button ──────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Đăng xuất?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: const Text(
                'Bạn có chắc muốn đăng xuất khỏi tài khoản này không?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'Huỷ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          );
          if (confirm == true && context.mounted) {
            await context.read<AuthCubit>().logout();
            if (context.mounted) context.go('/login');
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
