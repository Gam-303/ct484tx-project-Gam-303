import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_colors.dart';
import '../../data/models/task.dart';
import '../../services/cubits/tasks_cubit.dart';

// ── Chart period enum ──────────────────────────────────────────────
enum ChartPeriod { week, month, year }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  ChartPeriod _period = ChartPeriod.week;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final repository = context.read<TasksCubit>().repository;
        final tasks = state.tasks;
        final total = tasks.length;
        final completed = tasks
            .where((e) => e.status == TaskStatus.completed)
            .length;
        final todo = total - completed;
        final progress = total == 0 ? 0.0 : completed / total;
        final highPriority = tasks
            .where((e) => e.priority == TaskPriority.high)
            .length;
        final estimatedPomodoros = tasks.fold<int>(
          0,
          (sum, t) => sum + t.estimatedPomodoros,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────
              SliverAppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                pinned: true,
                title: const Text(
                  'Thống kê',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      // ── Overall Progress ─────────────────────
                      _OverallProgressCard(
                        completed: completed,
                        total: total,
                        progress: progress,
                      ),

                      const SizedBox(height: 20),

                      // ── Summary Cards ────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.success,
                              bgColor: AppColors.success.withValues(alpha: 0.1),
                              value: '$completed',
                              label: 'Đã xong',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.pending_rounded,
                              iconColor: AppColors.primary,
                              bgColor: AppColors.primarySurface,
                              value: '$todo',
                              label: 'Đang làm',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: AppColors.danger,
                              bgColor: AppColors.danger.withValues(alpha: 0.1),
                              value: '$highPriority',
                              label: 'Ưu tiên cao',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Chart with period tabs ────────────────
                      const _SectionLabel('Biểu đồ hoàn thành'),
                      const SizedBox(height: 12),
                      _TaskChartCard(
                        tasks: tasks,
                        period: _period,
                        onPeriodChanged: (p) => setState(() => _period = p),
                      ),

                      const SizedBox(height: 28),

                      // ── Pomodoro ──────────────────────────────
                      const _SectionLabel('Pomodoro ước tính'),
                      const SizedBox(height: 12),
                      FutureBuilder<int>(
                        future: repository.getTodayFocusCount(),
                        builder: (context, snapshot) {
                          return _PomodoroCard(
                            totalPomodoros: estimatedPomodoros,
                            completedToday: snapshot.data ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Chuỗi tập trung'),
                      const SizedBox(height: 12),
                      FutureBuilder<int>(
                        future: repository.getCurrentStreakDays(),
                        builder: (context, snapshot) {
                          final streak = snapshot.data ?? 0;
                          return _StreakCard(streakDays: streak);
                        },
                      ),

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
  }
}

// ── Task Chart Card ────────────────────────────────────────────────
class _TaskChartCard extends StatelessWidget {
  const _TaskChartCard({
    required this.tasks,
    required this.period,
    required this.onPeriodChanged,
  });

  final List<Task> tasks;
  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onPeriodChanged;

  List<_Bucket> _buildBuckets() {
    final now = DateTime.now();

    switch (period) {
      case ChartPeriod.week:
        return List.generate(7, (i) {
          final day = now.subtract(Duration(days: 6 - i));
          final dayStart = DateTime(day.year, day.month, day.day);
          final dayEnd = dayStart.add(const Duration(days: 1));
          const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
          final weekday = day.weekday;
          final inRange = tasks.where(
            (task) =>
                !_taskMoment(task).isBefore(dayStart) &&
                _taskMoment(task).isBefore(dayEnd),
          );
          final done = inRange
              .where((task) => task.status == TaskStatus.completed)
              .length;
          final pending = inRange.length - done;
          return _Bucket(
            label: labels[weekday - 1],
            completed: done,
            pending: pending,
          );
        });

      case ChartPeriod.month:
        return List.generate(4, (i) {
          final weekEnd = DateTime(
            now.year,
            now.month,
            now.day + 1,
          ).subtract(Duration(days: (3 - i) * 7));
          final weekStart = weekEnd.subtract(const Duration(days: 7));
          final inRange = tasks.where(
            (task) =>
                !_taskMoment(task).isBefore(weekStart) &&
                _taskMoment(task).isBefore(weekEnd),
          );
          final done = inRange
              .where((task) => task.status == TaskStatus.completed)
              .length;
          final pending = inRange.length - done;
          return _Bucket(
            label: 'Tuần ${i + 1}',
            completed: done,
            pending: pending,
          );
        });

      case ChartPeriod.year:
        return List.generate(6, (i) {
          final monthOffset = 5 - i;
          final monthDate = DateTime(now.year, now.month - monthOffset, 1);
          final monthStart = DateTime(monthDate.year, monthDate.month, 1);
          final monthEnd = DateTime(monthDate.year, monthDate.month + 1, 1);
          const monthLabels = [
            'T1',
            'T2',
            'T3',
            'T4',
            'T5',
            'T6',
            'T7',
            'T8',
            'T9',
            'T10',
            'T11',
            'T12',
          ];
          final inRange = tasks.where(
            (task) =>
                !_taskMoment(task).isBefore(monthStart) &&
                _taskMoment(task).isBefore(monthEnd),
          );
          final done = inRange
              .where((task) => task.status == TaskStatus.completed)
              .length;
          final pending = inRange.length - done;
          return _Bucket(
            label: monthLabels[(monthDate.month - 1) % 12],
            completed: done,
            pending: pending,
          );
        });
    }
  }

  DateTime _taskMoment(Task task) {
    if (task.updatedAtMs != null && task.updatedAtMs! > 0) {
      return DateTime.fromMillisecondsSinceEpoch(task.updatedAtMs!);
    }
    final parsedId = int.tryParse(task.id);
    if (parsedId != null && parsedId > 0) {
      return DateTime.fromMillisecondsSinceEpoch(parsedId);
    }
    return task.deadline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Period tabs ───────────────────────────────────
          Row(
            children: [
              _PeriodTab(
                label: '7 ngày',
                active: period == ChartPeriod.week,
                onTap: () => onPeriodChanged(ChartPeriod.week),
              ),
              const SizedBox(width: 8),
              _PeriodTab(
                label: '4 tuần',
                active: period == ChartPeriod.month,
                onTap: () => onPeriodChanged(ChartPeriod.month),
              ),
              const SizedBox(width: 8),
              _PeriodTab(
                label: '6 tháng',
                active: period == ChartPeriod.year,
                onTap: () => onPeriodChanged(ChartPeriod.year),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Builder(
            builder: (context) {
              final buckets = _buildBuckets();
              final maxY = buckets
                  .map((b) => b.total)
                  .fold(0, (a, b) => a > b ? a : b)
                  .toDouble()
                  .clamp(3.0, double.infinity);
              return SizedBox(
                height: 190,
                child: BarChart(
                  BarChartData(
                    maxY: maxY * 1.35,
                    groupsSpace: period == ChartPeriod.week ? 10 : 12,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.divider,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: (maxY / 3).ceilToDouble(),
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == meta.max) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= buckets.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                buckets[idx].label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(buckets.length, (i) {
                      final b = buckets[i];
                      final barWidth = period == ChartPeriod.week ? 8.0 : 10.0;
                      return BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          BarChartRodData(
                            toY: b.completed.toDouble(),
                            width: barWidth,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            color: AppColors.success,
                          ),
                          BarChartRodData(
                            toY: b.pending.toDouble(),
                            width: barWidth,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            color: AppColors.warning,
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // ── Legend ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.success, label: 'Đã hoàn thành'),
              const SizedBox(width: 20),
              _LegendDot(color: AppColors.warning, label: 'Chưa hoàn thành'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bucket data class ──────────────────────────────────────────────
class _Bucket {
  const _Bucket({
    required this.label,
    required this.completed,
    required this.pending,
  });
  final String label;
  final int completed;
  final int pending;
  int get total => completed + pending;
}

// ── Period Tab ─────────────────────────────────────────────────────
class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

// ── Legend Dot ─────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Overall Progress Card ──────────────────────────────────────────
class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? 'Chưa có task nào'
                      : '$completed / $total task hoàn thành',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'Nhấn + để thêm task đầu tiên'
                      : 'Còn ${total - completed} task cần hoàn thành',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pomodoro Card ──────────────────────────────────────────────────
class _PomodoroCard extends StatelessWidget {
  const _PomodoroCard({
    required this.totalPomodoros,
    required this.completedToday,
  });
  final int totalPomodoros;
  final int completedToday;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = totalPomodoros * 25;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final timeLabel = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              color: const Color(0xFFF0ECFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.timer_rounded,
              color: AppColors.pomodoro,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng thời gian ước tính',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hôm nay hoàn thành: $completedToday phiên',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0ECFF),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$totalPomodoros 🍅',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.pomodoro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});

  final int streakDays;

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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              streakDays == 0
                  ? 'Bắt đầu một phiên tập trung để tạo streak'
                  : 'Bạn đang có chuỗi $streakDays ngày tập trung liên tiếp',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
      ),
    );
  }
}
