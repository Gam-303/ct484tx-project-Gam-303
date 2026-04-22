class AppSettings {
  const AppSettings({
    this.pomodoroMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.notificationsEnabled = true,
    this.darkMode = false,
    this.hapticFeedback = true,
    this.focusSound = false,
    this.displayName = 'Người dùng',
    this.email = 'user@email.com',
  });

  final int pomodoroMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final bool notificationsEnabled;
  final bool darkMode;
  final bool hapticFeedback;
  final bool focusSound;
  final String displayName;
  final String email;

  AppSettings copyWith({
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    bool? notificationsEnabled,
    bool? darkMode,
    bool? hapticFeedback,
    bool? focusSound,
    String? displayName,
    String? email,
  }) {
    return AppSettings(
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      focusSound: focusSound ?? this.focusSound,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
    );
  }
}
