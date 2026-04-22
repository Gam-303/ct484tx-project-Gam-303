import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../data/models/task.dart';
import '../../services/cubits/tasks_cubit.dart';
import '../shared/task_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          final tasks = state.filteredTasks;
          final total = tasks.length;
          final done = tasks.where((e) => e.status == TaskStatus.completed).length;
          final remaining = total - done;
          final progress = total == 0 ? 0.0 : done / total;
          final isCompletedFilter = state.filterStatus == TaskStatus.completed;
          final emptyTitle =
              isCompletedFilter ? 'Chưa có công việc nào hoàn thành' : 'Chưa có công việc nào';
          final emptySubtitle = isCompletedFilter
              ? 'Hãy hoàn thành một công việc để hiển thị tại đây.'
              : 'Nhấn nút + để thêm công việc đầu tiên.';

          return CustomScrollView(
            slivers: [
              // ── Header SliverAppBar ──────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeaderBanner(
                    remaining: remaining,
                    done: done,
                    total: total,
                    progress: progress,
                  ),
                  collapseMode: CollapseMode.pin,
                ),
                title: const Text(
                  'Công việc của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),

              // ── Filter chips ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Ưu tiên cao',
                        selected: state.filterPriority == TaskPriority.high,
                        onTap: () => context.read<TasksCubit>().setPriorityFilter(
                              state.filterPriority == TaskPriority.high
                                  ? null
                                  : TaskPriority.high,
                            ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Đã hoàn thành',
                        selected: state.filterStatus == TaskStatus.completed,
                        onTap: () => context.read<TasksCubit>().setStatusFilter(
                              state.filterStatus == TaskStatus.completed
                                  ? null
                                  : TaskStatus.completed,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section label ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    tasks.isEmpty
                        ? (isCompletedFilter
                            ? 'Chưa có công việc hoàn thành'
                            : 'Chưa có công việc nào')
                        : '${tasks.length} công việc',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              // ── Task list ────────────────────────────────────
              tasks.isEmpty
                  ? SliverFillRemaining(
                      child: _EmptyState(title: emptyTitle, subtitle: emptySubtitle),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = tasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TaskTile(
                                task: task,
                                onTap: () => context.go('/home/task/${task.id}'),
                              ),
                            );
                          },
                          childCount: tasks.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
      floatingActionButton: _AddTaskFAB(
        onPressed: () => context.go('/home/task/new'),
      ),
    );
  }
}

// ── Header Banner ──────────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({
    required this.remaining,
    required this.done,
    required this.total,
    required this.progress,
  });

  final int remaining;
  final int done;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6EC6CA), Color(0xFF85B9E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remaining == 0
                              ? 'Bạn đã hoàn thành tất cả công việc'
                              : 'Còn $remaining công việc hôm nay',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatBadge(value: '$done/$total', label: 'hoàn thành'),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

// ── Stat Badge ─────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Custom Filter Chip ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Add Task FAB ───────────────────────────────────────────────────
class _AddTaskFAB extends StatelessWidget {
  const _AddTaskFAB({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'Công việc mới',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}