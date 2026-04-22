import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  FlutterLocalNotificationsPlugin? _plugin;

  void configure(FlutterLocalNotificationsPlugin plugin) {
    _plugin = plugin;
  }

  Future<void> showPhaseCompleted({
    required String phaseEnded,
  }) async {
    final plugin = _plugin;
    if (plugin == null) return;

    final title = switch (phaseEnded) {
      'focus' => 'Phiên tập trung kết thúc',
      'short_break' => 'Phiên nghỉ ngắn kết thúc',
      'long_break' => 'Phiên nghỉ dài kết thúc',
      _ => 'Phiên làm việc kết thúc',
    };
    final body = switch (phaseEnded) {
      'focus' => 'Đã hoàn thành 1 phiên tập trung. Đến giờ nghỉ ngắn.',
      'short_break' => 'Hết giờ nghỉ ngắn. Hãy quay lại tập trung.',
      'long_break' => 'Hết giờ nghỉ dài. Sẵn sàng cho phiên mới.',
      _ => 'Đến giờ chuyển sang phiên tiếp theo.',
    };

    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_channel',
          'Pomodoro Notifications',
          channelDescription: 'Thông báo nhắc pomodoro',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 200, 120, 240, 120, 280]),
        ),
      ),
    );
  }
}
