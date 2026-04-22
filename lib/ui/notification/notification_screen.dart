import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationTile(
            title: 'Nhắc nhở Pomodoro',
            message: 'Đã đến lúc bắt đầu phiên tập trung tiếp theo.',
            time: 'Vừa xong',
          ),
          SizedBox(height: 12),
          _NotificationTile(
            title: 'Hoàn thành mục tiêu',
            message: 'Bạn đã hoàn thành 4 phiên tập trung hôm nay.',
            time: '2 giờ trước',
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.message,
    required this.time,
  });

  final String title;
  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
