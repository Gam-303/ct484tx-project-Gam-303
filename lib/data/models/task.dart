enum TaskPriority { high, medium, low }

enum TaskStatus { todo, completed }

enum SyncState { synced, pendingUpsert, pendingDelete }

class Task {
  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.estimatedPomodoros,
    this.description = '',
    this.completedPomodoros = 0,
    this.status = TaskStatus.todo,
    this.remoteId,
    this.userId,
    this.updatedAtMs,
    this.deletedAtMs,
    this.syncState = SyncState.pendingUpsert,
  });

  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final TaskPriority priority;
  final int estimatedPomodoros;
  final int completedPomodoros;
  final TaskStatus status;
  final String? remoteId;
  final String? userId;
  final int? updatedAtMs;
  final int? deletedAtMs;
  final SyncState syncState;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    TaskPriority? priority,
    int? estimatedPomodoros,
    int? completedPomodoros,
    TaskStatus? status,
    String? remoteId,
    String? userId,
    int? updatedAtMs,
    int? deletedAtMs,
    SyncState? syncState,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      status: status ?? this.status,
      remoteId: remoteId ?? this.remoteId,
      userId: userId ?? this.userId,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, Object?> toSqlMap() {
    return <String, Object?>{
      'id': id,
      'remote_id': remoteId,
      'user_id': userId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'priority': priority.index,
      'estimated_pomodoros': estimatedPomodoros,
      'completed_pomodoros': completedPomodoros,
      'status': status.index,
      'sync_state': syncState.index,
      'updated_at_ms': updatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
      'deleted_at_ms': deletedAtMs,
    };
  }

  factory Task.fromSqlMap(Map<String, Object?> map) {
    return Task(
      id: map['id']! as String,
      remoteId: map['remote_id'] as String?,
      userId: map['user_id'] as String?,
      title: map['title']! as String,
      description: (map['description'] ?? '') as String,
      deadline: DateTime.parse(map['deadline']! as String),
      priority: TaskPriority.values[(map['priority']! as num).toInt()],
      estimatedPomodoros: (map['estimated_pomodoros']! as num).toInt(),
      completedPomodoros: (map['completed_pomodoros']! as num).toInt(),
      status: TaskStatus.values[(map['status']! as num).toInt()],
      syncState: SyncState.values[(map['sync_state']! as num).toInt()],
      updatedAtMs: (map['updated_at_ms'] as num?)?.toInt(),
      deletedAtMs: (map['deleted_at_ms'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toPocketBaseBody(String userId) {
    return <String, Object?>{
      'client_id': id,
      'user': userId,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'priority': priority.name,
      'estimated_pomodoros': estimatedPomodoros,
      'completed_pomodoros': completedPomodoros,
      'status': status.name,
      'updated_at_ms': updatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
      'deleted': deletedAtMs != null,
    };
  }

  factory Task.fromPocketBase(Map<String, dynamic> json) {
    final priority = (json['priority'] as String?) ?? 'medium';
    final status = (json['status'] as String?) ?? 'todo';

    return Task(
      id: (json['client_id'] as String?) ?? json['id'] as String,
      remoteId: json['id'] as String?,
      userId: json['user'] as String?,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      deadline:
          DateTime.tryParse((json['deadline'] ?? '').toString()) ??
          DateTime.now(),
      priority: TaskPriority.values.firstWhere(
        (value) => value.name == priority,
        orElse: () => TaskPriority.medium,
      ),
      estimatedPomodoros: (json['estimated_pomodoros'] as num?)?.toInt() ?? 1,
      completedPomodoros: (json['completed_pomodoros'] as num?)?.toInt() ?? 0,
      status: TaskStatus.values.firstWhere(
        (value) => value.name == status,
        orElse: () => TaskStatus.todo,
      ),
      syncState: SyncState.synced,
      updatedAtMs: (json['updated_at_ms'] as num?)?.toInt(),
      deletedAtMs: (json['deleted'] as bool? ?? false)
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    );
  }
}
