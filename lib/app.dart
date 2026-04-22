import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'config/app_theme.dart';
import 'data/models/app_settings.dart';
import 'router/app_router.dart';
import 'services/bootstrap/app_bootstrap.dart';
import 'services/cubits/auth_cubit.dart';
import 'services/cubits/settings_cubit.dart';
import 'services/cubits/tasks_cubit.dart';
import 'services/cubits/timer_cubit.dart';
import 'services/repositories/task_repository.dart';

class PomodoroApp extends StatefulWidget {
  const PomodoroApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends State<PomodoroApp> {
  late final AuthCubit _authCubit;
  late final SettingsCubit _settingsCubit;
  late final TasksCubit _tasksCubit;
  late final TimerCubit _timerCubit;
  late final GoRouter _router;
  late final TaskRepository _taskRepository;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(widget.bootstrap.prefs, widget.bootstrap.pocketBase)
      ..restore();
    _settingsCubit = SettingsCubit(widget.bootstrap.prefs)..load();
    _taskRepository = TaskRepository(
      database: widget.bootstrap.database,
      pocketBase: widget.bootstrap.pocketBase,
    );
    _tasksCubit = TasksCubit(_taskRepository)..load();
    _timerCubit = TimerCubit(
      _settingsCubit,
      widget.bootstrap.prefs,
      _taskRepository,
    );
    unawaited(_timerCubit.restorePersistedState());
    _router = buildRouter(_authCubit);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _settingsCubit),
        BlocProvider.value(value: _tasksCubit),
        BlocProvider.value(value: _timerCubit),
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, _) {
          return MaterialApp.router(
            title: 'Pomodoro Focus',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
