import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../data/models/task.dart';
import '../../services/cubits/tasks_cubit.dart';
import '../../services/cubits/timer_cubit.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final task = context.read<TasksCubit>().state.tasks.firstWhere(
      (e) => e.id == taskId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go('/home/task/${task.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => _confirmDelete(context, task),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF8C42), Color(0xFFFFAB6E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _PriorityBadge(priority: task.priority),
                        const SizedBox(height: 8),
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards row
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.calendar_today_rounded,
                          label: 'Hạn chót',
                          value: task.deadline
                              .toLocal()
                              .toString()
                              .split(' ')
                              .first,
                          iconColor: AppColors.danger,
                          bgColor: const Color(0xFFFFEEEE),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.timer_rounded,
                          label: 'Pomodoro',
                          value: '${task.estimatedPomodoros} phiên',
                          iconColor: AppColors.pomodoro,
                          bgColor: const Color(0xFFF0ECFF),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Status chip
                  _StatusChip(status: task.status),

                  const SizedBox(height: 20),

                  // Description
                  if (task.description.isNotEmpty) ...[
                    _SectionLabel('Mô tả'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Pomodoro progress (visual)
                  _SectionLabel('Tiến độ Pomodoro'),
                  const SizedBox(height: 12),
                  _PomodoroGrid(total: task.estimatedPomodoros),

                  const SizedBox(height: 32),

                  // Action buttons
                  _StartPomodoroButton(
                    onPressed: () {
                      context.read<TimerCubit>().selectTask(task.id);
                      context.go('/timer');
                    },
                  ),

                  const SizedBox(height: 12),

                  if (task.status != TaskStatus.completed)
                    _MarkDoneButton(
                      onPressed: () {
                        context.read<TasksCubit>().complete(task.id);
                        context.pop();
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, Task task) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa công việc?'),
      content: Text('Bạn có chắc muốn xóa "${task.title}" không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );

  if (shouldDelete != true || !context.mounted) return;
  await context.read<TasksCubit>().delete(task.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Đã xóa công việc')),
  );
  context.go('/home');
}

// ── Priority Badge ─────────────────────────────────────────────────
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final label = switch (priority) {
      TaskPriority.high => 'Ưu tiên cao',
      TaskPriority.medium => 'Ưu tiên vừa',
      TaskPriority.low => 'Ưu tiên thấp',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Info Card ──────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Chip ────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final isDone = status == TaskStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: isDone ? AppColors.success : AppColors.primaryLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isDone ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            isDone ? 'Đã hoàn thành' : 'Đang thực hiện',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDone ? AppColors.success : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pomodoro Grid ──────────────────────────────────────────────────
class _PomodoroGrid extends StatelessWidget {
  const _PomodoroGrid({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(total, (i) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: AppColors.primaryLight,
          ),
        );
      }),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ── Start Pomodoro Button ──────────────────────────────────────────
class _StartPomodoroButton extends StatelessWidget {
  const _StartPomodoroButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 22),
        label: const Text(
          'Bắt đầu Pomodoro',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Mark Done Button ───────────────────────────────────────────────
class _MarkDoneButton extends StatelessWidget {
  const _MarkDoneButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.success,
          side: const BorderSide(color: AppColors.success),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.check_rounded, size: 20),
        label: const Text(
          'Đánh dấu hoàn thành',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
