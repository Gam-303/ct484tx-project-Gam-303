import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../notification/local_notification_service.dart';
import '../repositories/task_repository.dart';
import 'settings_cubit.dart';

class TimerState {
  const TimerState({
    required this.remainingSeconds,
    required this.running,
    required this.isBreak,
    this.isLongBreak = false,
    this.completedPomodoros = 0,
    this.selectedTaskId,
  });

  final int remainingSeconds;
  final bool running;
  final bool isBreak;
  final bool isLongBreak;
  final int completedPomodoros;
  final String? selectedTaskId;

  TimerState copyWith({
    int? remainingSeconds,
    bool? running,
    bool? isBreak,
    bool? isLongBreak,
    int? completedPomodoros,
    String? selectedTaskId,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      running: running ?? this.running,
      isBreak: isBreak ?? this.isBreak,
      isLongBreak: isLongBreak ?? this.isLongBreak,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      selectedTaskId: selectedTaskId ?? this.selectedTaskId,
    );
  }
}

class TimerCubit extends Cubit<TimerState> {
  TimerCubit(this._settingsCubit, this._prefs, this._taskRepository)
    : super(
        TimerState(
          remainingSeconds: _settingsCubit.state.pomodoroMinutes * 60,
          running: false,
          isBreak: false,
        ),
      ) {
    _settingsSubscription = _settingsCubit.stream.listen((_) {
      if (!state.running) {
        emit(state.copyWith(remainingSeconds: _minutesForCurrentPhase() * 60));
      }
    });
  }

  final SettingsCubit _settingsCubit;
  final SharedPreferences _prefs;
  final TaskRepository _taskRepository;
  Timer? _ticker;
  late final StreamSubscription<dynamic> _settingsSubscription;
  int? _focusStartedAtMs;
  static const _selectedTaskKey = 'timer_selected_task_id';

  void start() {
    _ticker?.cancel();
    _focusStartedAtMs ??= DateTime.now().millisecondsSinceEpoch;
    emit(state.copyWith(running: true));
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        _switchPhase();
      } else {
        emit(state.copyWith(remainingSeconds: next, running: true));
      }
    });
  }

  void pause() {
    _ticker?.cancel();
    emit(state.copyWith(running: false));
  }

  void reset() {
    _ticker?.cancel();
    _focusStartedAtMs = null;
    final minutes = _minutesForCurrentPhase();
    emit(state.copyWith(remainingSeconds: minutes * 60, running: false));
  }

  void skip() {
    _ticker?.cancel();
    _switchPhase();
  }

  void selectFocusSession() {
    _ticker?.cancel();
    emit(
      state.copyWith(
        isBreak: false,
        isLongBreak: false,
        running: false,
        remainingSeconds: _settingsCubit.state.pomodoroMinutes * 60,
      ),
    );
    _focusStartedAtMs = null;
  }

  void selectShortBreak() {
    _ticker?.cancel();
    emit(
      state.copyWith(
        isBreak: true,
        isLongBreak: false,
        running: false,
        remainingSeconds: _settingsCubit.state.shortBreakMinutes * 60,
      ),
    );
    _focusStartedAtMs = null;
  }

  void selectLongBreak() {
    _ticker?.cancel();
    emit(
      state.copyWith(
        isBreak: true,
        isLongBreak: true,
        running: false,
        remainingSeconds: _settingsCubit.state.longBreakMinutes * 60,
      ),
    );
    _focusStartedAtMs = null;
  }

  void selectTask(String taskId) {
    _prefs.setString(_selectedTaskKey, taskId);
    emit(state.copyWith(selectedTaskId: taskId));
  }

  Future<void> restorePersistedState() async {
    final taskId = _prefs.getString(_selectedTaskKey);
    final todayCount = await _taskRepository.getTodayFocusCount();
    emit(
      state.copyWith(selectedTaskId: taskId, completedPomodoros: todayCount),
    );
  }

  void _switchPhase() {
    final endedPhase = !state.isBreak
        ? 'focus'
        : (state.isLongBreak ? 'long_break' : 'short_break');
    final finishingFocusSession = !state.isBreak;
    final completed = finishingFocusSession
        ? state.completedPomodoros + 1
        : state.completedPomodoros;

    final nextIsBreak = !state.isBreak;
    final nextIsLongBreak = nextIsBreak && completed > 0 && completed % 4 == 0;
    final minutes = nextIsBreak
        ? (nextIsLongBreak
              ? _settingsCubit.state.longBreakMinutes
              : _settingsCubit.state.shortBreakMinutes)
        : _settingsCubit.state.pomodoroMinutes;

    emit(
      state.copyWith(
        remainingSeconds: minutes * 60,
        running: false,
        isBreak: nextIsBreak,
        isLongBreak: nextIsLongBreak,
        completedPomodoros: completed,
      ),
    );
    if (finishingFocusSession) {
      unawaited(_logFocusSession());
    }
    _notifyPhaseTransition(endedPhase);
    _ticker?.cancel();
    _focusStartedAtMs = null;
  }

  Future<void> _logFocusSession() async {
    final endedAtMs = DateTime.now().millisecondsSinceEpoch;
    final startedAtMs =
        _focusStartedAtMs ??
        (endedAtMs - (_settingsCubit.state.pomodoroMinutes * 60 * 1000));
    await _taskRepository.logPomodoroSession(
      phase: 'focus',
      taskId: state.selectedTaskId,
      durationSeconds: ((endedAtMs - startedAtMs) ~/ 1000).clamp(1, 7200),
      startedAtMs: startedAtMs,
      endedAtMs: endedAtMs,
    );
    if (state.selectedTaskId != null) {
      await _taskRepository.incrementTaskPomodoro(state.selectedTaskId!);
    }
    await _taskRepository.syncPending();
  }

  int _minutesForCurrentPhase() {
    if (!state.isBreak) return _settingsCubit.state.pomodoroMinutes;
    if (state.isLongBreak) return _settingsCubit.state.longBreakMinutes;
    return _settingsCubit.state.shortBreakMinutes;
  }

  Future<void> _notifyPhaseTransition(String endedPhase) async {
    final settings = _settingsCubit.state;

    if (settings.notificationsEnabled) {
      await LocalNotificationService.instance.showPhaseCompleted(
        phaseEnded: endedPhase,
      );
    }

    if (settings.hapticFeedback) {
      await _vibratePattern();
    }
    if (settings.focusSound) {
      await _playSoundPattern();
    }
  }

  Future<void> _vibratePattern() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 140));
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 170));
    await HapticFeedback.mediumImpact();
  }

  Future<void> _playSoundPattern() async {
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    await SystemSound.play(SystemSoundType.alert);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    await SystemSound.play(SystemSoundType.alert);
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _settingsSubscription.cancel();
    return super.close();
  }
}
