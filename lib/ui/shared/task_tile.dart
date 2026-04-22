import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import '../../config/app_colors.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return AppColors.primary;
      case TaskPriority.medium:
        return AppColors.secondary;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 44,
              decoration: BoxDecoration(
                color: _priorityColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Hạn chót ${task.deadline.toLocal().toString().split(' ').first}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(task.status == TaskStatus.completed ? 'Hoàn thành' : 'Đang làm'),
          ],
        ),
      ),
    );
  }
}
