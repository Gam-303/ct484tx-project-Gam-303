import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../data/models/task.dart';
import '../../services/cubits/tasks_cubit.dart';

class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  int _estimate = 2;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));
  Task? _editingTask;

  @override
  void initState() {
    super.initState();
    if (widget.taskId == null) return;
    final tasks = context.read<TasksCubit>().state.tasks;
    final index = tasks.indexWhere((item) => item.id == widget.taskId);
    if (index == -1) return;
    _editingTask = tasks[index];
    _title.text = _editingTask!.title;
    _description.text = _editingTask!.description;
    _priority = _editingTask!.priority;
    _estimate = _editingTask!.estimatedPomodoros;
    _deadline = _editingTask!.deadline;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          _editingTask == null ? 'Công việc mới' : 'Chỉnh sửa công việc',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ── Title ─────────────────────────────────────────────
          _SectionLabel('Tiêu đề *'),
          const SizedBox(height: 8),
          _StyledTextField(
            controller: _title,
            hint: 'Nhập tiêu đề task...',
            maxLines: 1,
          ),

          const SizedBox(height: 20),

          // ── Description ───────────────────────────────────────
          _SectionLabel('Mô tả'),
          const SizedBox(height: 8),
          _StyledTextField(
            controller: _description,
            hint: 'Thêm mô tả chi tiết...',
            maxLines: 4,
          ),

          const SizedBox(height: 20),

          // ── Priority ──────────────────────────────────────────
          _SectionLabel('Độ ưu tiên'),
          const SizedBox(height: 10),
          _PrioritySelector(
            selected: _priority,
            onChanged: (p) => setState(() => _priority = p),
          ),

          const SizedBox(height: 20),

          // ── Deadline ──────────────────────────────────────────
          _SectionLabel('Hạn chót'),
          const SizedBox(height: 8),
          _DeadlinePicker(
            deadline: _deadline,
            onChanged: (d) => setState(() => _deadline = d),
          ),

          const SizedBox(height: 20),

          // ── Pomodoro estimate ─────────────────────────────────
          _SectionLabel('Ước tính Pomodoro'),
          const SizedBox(height: 10),
          _PomodoroEstimator(
            value: _estimate,
            onChanged: (v) => setState(() => _estimate = v),
          ),

          const SizedBox(height: 32),

          // ── Save button ───────────────────────────────────────
          ListenableBuilder(
            listenable: _title,
            builder: (context, _) {
              return _SaveButton(
                onPressed: _title.text.trim().isEmpty ? null : _save,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _save() {
    final source = _editingTask;
    context.read<TasksCubit>().addOrUpdate(
      Task(
        id: source?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        deadline: _deadline,
        priority: _priority,
        estimatedPomodoros: _estimate,
        completedPomodoros: source?.completedPomodoros ?? 0,
        status: source?.status ?? TaskStatus.todo,
        remoteId: source?.remoteId,
        userId: source?.userId,
        updatedAtMs: source?.updatedAtMs,
        deletedAtMs: source?.deletedAtMs,
        syncState: source?.syncState ?? SyncState.pendingUpsert,
      ),
    );
    context.go('/home');
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
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ── Styled Text Field ──────────────────────────────────────────────
class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ── Priority Selector ─────────────────────────────────────────────
class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.selected, required this.onChanged});
  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (TaskPriority.high, Icons.priority_high_rounded, 'Cao', AppColors.danger),
      (TaskPriority.medium, Icons.flag_outlined, 'Vừa', AppColors.primary),
      (TaskPriority.low, Icons.low_priority_rounded, 'Thấp', AppColors.success),
    ];

    return Row(
      children: options.map((opt) {
        final (priority, icon, label, color) = opt;
        final isSelected = selected == priority;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(priority),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? color : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Deadline Picker ────────────────────────────────────────────────
class _DeadlinePicker extends StatelessWidget {
  const _DeadlinePicker({required this.deadline, required this.onChanged});
  final DateTime deadline;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final isToday = deadline.day == DateTime.now().day;
    final label = isToday
        ? 'Hôm nay'
        : deadline.toLocal().toString().split(' ').first;

    return GestureDetector(
      onTap: () async {
        final pick = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          initialDate: deadline,
          builder: (context, child) => Theme(
            data: Theme.of(
              context,
            ).copyWith(colorScheme: AppColors.colorScheme),
            child: child!,
          ),
        );
        if (pick != null) onChanged(pick);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

// ── Pomodoro Estimator ────────────────────────────────────────────
class _PomodoroEstimator extends StatelessWidget {
  const _PomodoroEstimator({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0ECFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  size: 18,
                  color: AppColors.pomodoro,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$value pomodoro (~${value * 25} phút)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (v) => onChanged(v.toInt()),
            ),
          ),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(12, (i) {
              final active = i < value;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryLight
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Save Button ────────────────────────────────────────────────────
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.divider,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Lưu task',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
