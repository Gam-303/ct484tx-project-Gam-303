import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_colors.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/task.dart';
import '../../services/cubits/settings_cubit.dart';
import '../../services/cubits/tasks_cubit.dart';
import '../../services/cubits/timer_cubit.dart';

class PomodoroTimerScreen extends StatelessWidget {
  const PomodoroTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, AppSettings>(
      builder: (context, settings) {
        return BlocBuilder<TimerCubit, TimerState>(
          builder: (context, state) {
            final isBreak = state.isBreak;
            final bgColor = isBreak
                ? const Color(0xFFEBF8F9)
                : AppColors.background;

            return Scaffold(
              backgroundColor: bgColor,
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: bgColor,
                    elevation: 0,
                    pinned: true,
                    title: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isBreak ? 'Thời gian nghỉ' : 'Tập trung',
                        key: ValueKey(isBreak),
                        style: TextStyle(
                          color: isBreak
                              ? AppColors.secondary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _SessionChips(state: state),
                          const SizedBox(height: 48),
                          _CircularTimer(state: state, settings: settings),
                          const SizedBox(height: 48),
                          _Controls(state: state, settings: settings),
                          const SizedBox(height: 32),
                          _PomodoroCount(count: state.completedPomodoros),
                          const SizedBox(height: 24),
                          _CurrentTaskCard(state: state),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SessionChips extends StatelessWidget {
  const _SessionChips({required this.state});
  final TimerState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Chip(
          label: 'Tập trung',
          active: !state.isBreak,
          color: AppColors.primary,
          onTap: () => context.read<TimerCubit>().selectFocusSession(),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Nghỉ ngắn',
          active: state.isBreak && !state.isLongBreak,
          color: AppColors.secondary,
          onTap: () => context.read<TimerCubit>().selectShortBreak(),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'Nghỉ dài',
          active: state.isBreak && state.isLongBreak,
          color: AppColors.pomodoro,
          onTap: () => context.read<TimerCubit>().selectLongBreak(),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? color : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? color : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

class _CircularTimer extends StatelessWidget {
  const _CircularTimer({required this.state, required this.settings});
  final TimerState state;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final mm = (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (state.remainingSeconds % 60).toString().padLeft(2, '0');
    final totalSecs =
        (state.isBreak
            ? (state.isLongBreak
                  ? settings.longBreakMinutes
                  : settings.shortBreakMinutes)
            : settings.pomodoroMinutes) *
        60;
    final progress = 1.0 - (state.remainingSeconds / totalSecs).clamp(0.0, 1.0);
    final color = state.isBreak ? AppColors.secondary : AppColors.primary;

    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring glow
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // Track
          SizedBox(
            width: 240,
            height: 240,
            child: CustomPaint(
              painter: _ArcPainter(
                progress: progress,
                color: color,
                trackColor: AppColors.divider,
              ),
            ),
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.running)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Đang chạy',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '$mm:$ss',
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(progress * 100).toInt()}% hoàn thành',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Arc Painter ────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 12.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;

    // Shadow arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main arc
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: [color.withValues(alpha: 0.6), color],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Dot at end of arc
    final endAngle = -math.pi / 2 + sweepAngle;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);
    canvas.drawCircle(Offset(dotX, dotY), 7, Paint()..color = color);
    canvas.drawCircle(Offset(dotX, dotY), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Controls ───────────────────────────────────────────────────────
class _Controls extends StatelessWidget {
  const _Controls({required this.state, required this.settings});
  final TimerState state;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final color = state.isBreak ? AppColors.secondary : AppColors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        _CircleButton(
          icon: Icons.refresh_rounded,
          size: 52,
          color: AppColors.textHint,
          bgColor: AppColors.surfaceVariant,
          onTap: () {
            if (settings.hapticFeedback) HapticFeedback.mediumImpact();
            context.read<TimerCubit>().reset();
          },
        ),

        const SizedBox(width: 20),

        // Play / Pause
        _PlayButton(
          running: state.running,
          color: color,
          onTap: () {
            if (settings.hapticFeedback) HapticFeedback.mediumImpact();
            if (state.running) {
              context.read<TimerCubit>().pause();
            } else {
              context.read<TimerCubit>().start();
            }
          },
        ),

        const SizedBox(width: 20),

        // Skip
        _CircleButton(
          icon: Icons.skip_next_rounded,
          size: 52,
          color: AppColors.textHint,
          bgColor: AppColors.surfaceVariant,
          onTap: () {
            if (settings.hapticFeedback) HapticFeedback.mediumImpact();
            context.read<TimerCubit>().skip();
          },
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.running,
    required this.color,
    required this.onTap,
  });
  final bool running;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            running ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(running),
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
  final IconData icon;
  final double size;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }
}

// ── Pomodoro Count ─────────────────────────────────────────────────
class _PomodoroCount extends StatelessWidget {
  const _PomodoroCount({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timelapse_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            'Đã hoàn thành hôm nay',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count pomodoro',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Current Task Card ──────────────────────────────────────────────
class _CurrentTaskCard extends StatelessWidget {
  const _CurrentTaskCard({required this.state});

  final TimerState state;

  @override
  Widget build(BuildContext context) {
    final tasksState = context.watch<TasksCubit>().state;
    final availableTasks = tasksState.tasks
        .where((item) => item.status != TaskStatus.completed)
        .toList();
    Task? selectedTask;
    if (state.selectedTaskId != null) {
      final index = tasksState.tasks.indexWhere(
        (item) => item.id == state.selectedTaskId,
      );
      if (index != -1) {
        selectedTask = tasksState.tasks[index];
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Công việc hiện tại',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  selectedTask?.title ?? 'Chưa chọn task nào',
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedTask != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: availableTasks.isEmpty
                ? null
                : () => _showTaskPicker(
                    context,
                    tasks: availableTasks,
                    selectedTaskId: state.selectedTaskId,
                  ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Chọn',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTaskPicker(
    BuildContext context, {
    required List<Task> tasks,
    required String? selectedTaskId,
  }) async {
    final picked = await showModalBottomSheet<Task>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final selected = task.id == selectedTaskId;
              return ListTile(
                onTap: () => Navigator.of(context).pop(task),
                title: Text(task.title),
                subtitle: Text(
                  'Hạn: ${task.deadline.toLocal().toString().split(' ').first}',
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: tasks.length,
          ),
        );
      },
    );
    if (picked == null || !context.mounted) return;
    context.read<TimerCubit>().selectTask(picked.id);
  }
}
