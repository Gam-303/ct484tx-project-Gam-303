import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/task.dart';
import '../repositories/task_repository.dart';

class TasksState {
  const TasksState({
    this.tasks = const <Task>[],
    this.filterPriority,
    this.filterStatus,
  });

  final List<Task> tasks;
  final TaskPriority? filterPriority;
  final TaskStatus? filterStatus;

  List<Task> get filteredTasks => tasks.where((task) {
    final byPriority =
        filterPriority == null || task.priority == filterPriority;
    final byStatus = filterStatus == null || task.status == filterStatus;
    return byPriority && byStatus;
  }).toList();
}

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(this._repository) : super(const TasksState());

  final TaskRepository _repository;
  TaskRepository get repository => _repository;

  Future<void> load() async {
    final tasks = await _repository.getTasks();
    emit(
      TasksState(
        tasks: tasks,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
    await _repository.syncPending();
    final refreshed = await _repository.getTasks();
    emit(
      TasksState(
        tasks: refreshed,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
  }

  Future<void> addOrUpdate(Task task) async {
    final next = [...state.tasks];
    final index = next.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      next.add(task);
    } else {
      next[index] = task;
    }
    emit(
      TasksState(
        tasks: next,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
    await _repository.upsertTask(task);
    await _repository.syncPending();
    final refreshed = await _repository.getTasks(
      priority: state.filterPriority,
      status: state.filterStatus,
    );
    emit(
      TasksState(
        tasks: refreshed,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
  }

  Future<void> complete(String taskId) async {
    final next = state.tasks
        .map(
          (item) => item.id == taskId
              ? item.copyWith(status: TaskStatus.completed)
              : item,
        )
        .toList();
    emit(
      TasksState(
        tasks: next,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
    await _repository.markCompleted(taskId);
    await _repository.syncPending();
    final refreshed = await _repository.getTasks(
      priority: state.filterPriority,
      status: state.filterStatus,
    );
    emit(
      TasksState(
        tasks: refreshed,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
  }

  Future<void> delete(String taskId) async {
    final next = state.tasks.where((item) => item.id != taskId).toList();
    emit(
      TasksState(
        tasks: next,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
    await _repository.deleteTask(taskId);
    await _repository.syncPending();
    final refreshed = await _repository.getTasks(
      priority: state.filterPriority,
      status: state.filterStatus,
    );
    emit(
      TasksState(
        tasks: refreshed,
        filterPriority: state.filterPriority,
        filterStatus: state.filterStatus,
      ),
    );
  }

  void setPriorityFilter(TaskPriority? value) {
    emit(
      TasksState(
        tasks: state.tasks,
        filterPriority: value,
        filterStatus: state.filterStatus,
      ),
    );
  }

  void setStatusFilter(TaskStatus? value) {
    emit(
      TasksState(
        tasks: state.tasks,
        filterPriority: state.filterPriority,
        filterStatus: value,
      ),
    );
  }
}
