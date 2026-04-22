import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_settings.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._prefs) : super(const AppSettings());

  final SharedPreferences _prefs;

  Future<void> load() async {
    emit(AppSettings(
      pomodoroMinutes: _prefs.getInt('pomodoro_minutes') ?? 25,
      shortBreakMinutes: _prefs.getInt('short_break_minutes') ?? 5,
      longBreakMinutes: _prefs.getInt('long_break_minutes') ?? 15,
      notificationsEnabled: _prefs.getBool('notifications_enabled') ?? true,
      darkMode: _prefs.getBool('dark_mode') ?? false,
      hapticFeedback: _prefs.getBool('haptic_feedback') ?? true,
      focusSound: _prefs.getBool('focus_sound') ?? false,
      displayName: _prefs.getString('display_name') ?? 'Người dùng',
      email: _prefs.getString('email') ?? 'user@email.com',
    ));
  }

  Future<void> update(AppSettings value) async {
    await _prefs.setInt('pomodoro_minutes', value.pomodoroMinutes);
    await _prefs.setInt('short_break_minutes', value.shortBreakMinutes);
    await _prefs.setInt('long_break_minutes', value.longBreakMinutes);
    await _prefs.setBool('notifications_enabled', value.notificationsEnabled);
    await _prefs.setBool('dark_mode', value.darkMode);
    await _prefs.setBool('haptic_feedback', value.hapticFeedback);
    await _prefs.setBool('focus_sound', value.focusSound);
    await _prefs.setString('display_name', value.displayName);
    await _prefs.setString('email', value.email);
    emit(value);
  }
}
