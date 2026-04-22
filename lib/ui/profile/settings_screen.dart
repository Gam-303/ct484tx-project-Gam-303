import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/app_settings.dart';
import '../../services/cubits/auth_cubit.dart';
import '../../services/cubits/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, state) {
          return ListView(
            children: [
              SwitchListTile(
                value: state.notificationsEnabled,
                onChanged: (value) =>
                    context.read<SettingsCubit>().update(state.copyWith(notificationsEnabled: value)),
                title: const Text('Thông báo'),
              ),
              ListTile(
                title: const Text('Số phút Pomodoro'),
                subtitle: Text('${state.pomodoroMinutes} phút'),
                trailing: IconButton(
                  onPressed: () => context
                      .read<SettingsCubit>()
                      .update(state.copyWith(pomodoroMinutes: state.pomodoroMinutes + 1)),
                  icon: const Icon(Icons.add),
                ),
              ),
              ListTile(
                title: const Text('Đăng xuất'),
                onTap: () async {
                  await context.read<AuthCubit>().logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
