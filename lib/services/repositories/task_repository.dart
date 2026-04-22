import 'package:pocketbase/pocketbase.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/models/task.dart';

class TaskRepository {
  TaskRepository({required this.database, required this.pocketBase});

  final Database database;
  final PocketBase pocketBase;
  static const _phaseFocus = 'focus';

  Future<List<Task>> getTasks({
    TaskPriority? priority,
    TaskStatus? status,
    bool includeDeleted = false,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];
    if (!includeDeleted) {
      clauses.add('deleted_at_ms IS NULL');
    }
    if (priority != null) {
      clauses.add('priority = ?');
      args.add(priority.index);
    }
    if (status != null) {
      clauses.add('status = ?');
      args.add(status.index);
    }

    final rows = await database.query(
      'tasks',
      where: clauses.isEmpty ? null : clauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'deadline ASC, updated_at_ms DESC',
    );

    return rows.map(Task.fromSqlMap).toList();
  }

  Future<void> upsertTask(Task task, {String? userId}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final taskToSave = task.copyWith(
      userId: userId ?? task.userId ?? _currentUserId(),
      updatedAtMs: nowMs,
      syncState: SyncState.pendingUpsert,
      deletedAtMs: null,
    );
    await database.insert(
      'tasks',
      taskToSave.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markCompleted(String taskId) async {
    final rows = await database.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final task = Task.fromSqlMap(rows.first).copyWith(
      status: TaskStatus.completed,
      syncState: SyncState.pendingUpsert,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await database.update(
      'tasks',
      task.toSqlMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String taskId) async {
    final rows = await database.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final task = Task.fromSqlMap(rows.first).copyWith(
      deletedAtMs: nowMs,
      syncState: SyncState.pendingDelete,
      updatedAtMs: nowMs,
    );
    await database.update(
      'tasks',
      task.toSqlMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> syncPending() async {
    final userId = _currentUserId();
    if (userId == null) return;

    final pendingRows = await database.query(
      'tasks',
      where: 'sync_state != ?',
      whereArgs: [SyncState.synced.index],
      orderBy: 'updated_at_ms ASC',
    );

    for (final row in pendingRows) {
      final task = Task.fromSqlMap(row);
      try {
        if (task.syncState == SyncState.pendingDelete) {
          await _pushDelete(task, userId);
        } else {
          await _pushUpsert(task, userId);
        }
      } catch (_) {
        // Keep pending for next sync round.
      }
    }

    await _syncPendingSessions(userId);

    await pullFromRemote();
  }

  Future<void> pullFromRemote() async {
    final userId = _currentUserId();
    if (userId == null) return;

    try {
      final records = await pocketBase
          .collection('tasks')
          .getFullList(filter: 'user = "$userId"', sort: '-updated_at_ms');
      for (final record in records) {
        final remoteTask = Task.fromPocketBase(
          record.toJson(),
        ).copyWith(syncState: SyncState.synced);
        await database.insert(
          'tasks',
          remoteTask.toSqlMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final sessionRecords = await pocketBase
          .collection('pomodoro_sessions')
          .getFullList(filter: 'user = "$userId"', sort: '-updated_at_ms');
      for (final record in sessionRecords) {
        final json = record.toJson();
        final deleted = json['deleted'] as bool? ?? false;
        if (deleted) {
          await database.delete(
            'pomodoro_sessions',
            where: 'id = ?',
            whereArgs: [(json['client_id'] as String?) ?? record.id],
          );
          continue;
        }
        await database.insert('pomodoro_sessions', <String, Object?>{
          'id': (json['client_id'] as String?) ?? record.id,
          'remote_id': record.id,
          'user_id': json['user'] as String?,
          'task_id': json['task'] as String?,
          'phase': (json['phase'] ?? _phaseFocus) as String,
          'duration_seconds': (json['duration_seconds'] as num?)?.toInt() ?? 0,
          'started_at_ms': (json['started_at_ms'] as num?)?.toInt() ?? 0,
          'ended_at_ms': (json['ended_at_ms'] as num?)?.toInt() ?? 0,
          'sync_state': SyncState.synced.index,
          'updated_at_ms':
              (json['updated_at_ms'] as num?)?.toInt() ??
              DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (_) {
      // Offline or collection not ready yet.
    }
  }

  String? _currentUserId() {
    if (!pocketBase.authStore.isValid) return null;
    return pocketBase.authStore.record?.id;
  }

  Future<void> _pushUpsert(Task task, String userId) async {
    final body = task.toPocketBaseBody(userId);
    String? remoteId = task.remoteId;

    if (remoteId != null && remoteId.isNotEmpty) {
      await pocketBase.collection('tasks').update(remoteId, body: body);
    } else {
      try {
        final found = await pocketBase
            .collection('tasks')
            .getFirstListItem('client_id = "${task.id}" && user = "$userId"');
        remoteId = found.id;
        await pocketBase.collection('tasks').update(remoteId, body: body);
      } on ClientException {
        final created = await pocketBase.collection('tasks').create(body: body);
        remoteId = created.id;
      }
    }

    await database.update(
      'tasks',
      task
          .copyWith(
            remoteId: remoteId,
            userId: userId,
            syncState: SyncState.synced,
            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          )
          .toSqlMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> _pushDelete(Task task, String userId) async {
    if (task.remoteId != null && task.remoteId!.isNotEmpty) {
      await pocketBase.collection('tasks').delete(task.remoteId!);
    } else {
      final found = await pocketBase
          .collection('tasks')
          .getFirstListItem('client_id = "${task.id}" && user = "$userId"');
      await pocketBase.collection('tasks').delete(found.id);
    }

    await database.delete('tasks', where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> logPomodoroSession({
    required String phase,
    required int durationSeconds,
    required int startedAtMs,
    required int endedAtMs,
    String? taskId,
  }) async {
    final sessionId = endedAtMs.toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert('pomodoro_sessions', <String, Object?>{
      'id': sessionId,
      'remote_id': null,
      'user_id': _currentUserId(),
      'task_id': taskId,
      'phase': phase,
      'duration_seconds': durationSeconds,
      'started_at_ms': startedAtMs,
      'ended_at_ms': endedAtMs,
      'sync_state': SyncState.pendingUpsert.index,
      'updated_at_ms': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> incrementTaskPomodoro(String taskId) async {
    final rows = await database.query(
      'tasks',
      where: 'id = ? AND deleted_at_ms IS NULL',
      whereArgs: [taskId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final current = Task.fromSqlMap(rows.first);
    await database.update(
      'tasks',
      current
          .copyWith(
            completedPomodoros: current.completedPomodoros + 1,
            syncState: SyncState.pendingUpsert,
            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          )
          .toSqlMap(),
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> getTodayFocusCount() async {
    final now = DateTime.now();
    final dayStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).millisecondsSinceEpoch;
    final dayEnd = dayStart + const Duration(days: 1).inMilliseconds;
    final rows = await database.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM pomodoro_sessions
      WHERE phase = ? AND ended_at_ms >= ? AND ended_at_ms < ?
      ''',
      [_phaseFocus, dayStart, dayEnd],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> getCurrentStreakDays() async {
    final rows = await database.rawQuery(
      '''
      SELECT DISTINCT date(ended_at_ms / 1000, 'unixepoch', 'localtime') AS day
      FROM pomodoro_sessions
      WHERE phase = ?
      ORDER BY day DESC
      ''',
      [_phaseFocus],
    );
    if (rows.isEmpty) return 0;

    final days = rows.map((row) => row['day'] as String).toSet();
    var streak = 0;
    var cursor = DateTime.now();
    while (true) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      if (!days.contains(key)) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<Map<String, int>> getLast7DaysFocusCount() async {
    final now = DateTime.now();
    final from = DateTime(
      now.year,
      now.month,
      now.day - 6,
    ).millisecondsSinceEpoch;
    final rows = await database.rawQuery(
      '''
      SELECT date(ended_at_ms / 1000, 'unixepoch', 'localtime') AS day, COUNT(*) AS total
      FROM pomodoro_sessions
      WHERE phase = ? AND ended_at_ms >= ?
      GROUP BY day
      ''',
      [_phaseFocus, from],
    );
    final result = <String, int>{};
    for (final row in rows) {
      result[(row['day'] ?? '') as String] =
          (row['total'] as num?)?.toInt() ?? 0;
    }
    return result;
  }

  Future<Map<String, int>> getLast4WeeksFocusCount() async {
    final now = DateTime.now();
    final from = DateTime(
      now.year,
      now.month,
      now.day - 27,
    ).millisecondsSinceEpoch;
    final rows = await database.rawQuery(
      '''
      SELECT CAST((julianday('now', 'localtime') - julianday(date(ended_at_ms / 1000, 'unixepoch', 'localtime'))) / 7 AS INTEGER) AS week_offset,
             COUNT(*) AS total
      FROM pomodoro_sessions
      WHERE phase = ? AND ended_at_ms >= ?
      GROUP BY week_offset
      ''',
      [_phaseFocus, from],
    );
    final result = <String, int>{};
    for (final row in rows) {
      final offset = (row['week_offset'] as num?)?.toInt() ?? 0;
      final key = 'W${(4 - offset).clamp(1, 4)}';
      result[key] = (row['total'] as num?)?.toInt() ?? 0;
    }
    return result;
  }

  Future<Map<String, int>> getLast6MonthsFocusCount() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 5, 1).millisecondsSinceEpoch;
    final rows = await database.rawQuery(
      '''
      SELECT strftime('%Y-%m', ended_at_ms / 1000, 'unixepoch', 'localtime') AS ym, COUNT(*) AS total
      FROM pomodoro_sessions
      WHERE phase = ? AND ended_at_ms >= ?
      GROUP BY ym
      ''',
      [_phaseFocus, from],
    );
    final result = <String, int>{};
    for (final row in rows) {
      result[(row['ym'] ?? '') as String] =
          (row['total'] as num?)?.toInt() ?? 0;
    }
    return result;
  }

  Future<void> _syncPendingSessions(String userId) async {
    final pendingRows = await database.query(
      'pomodoro_sessions',
      where: 'sync_state != ?',
      whereArgs: [SyncState.synced.index],
      orderBy: 'updated_at_ms ASC',
    );
    for (final row in pendingRows) {
      try {
        final remoteId = row['remote_id'] as String?;
        final id = row['id'] as String;
        final body = <String, Object?>{
          'client_id': id,
          'user': userId,
          'task': row['task_id'],
          'phase': row['phase'],
          'duration_seconds': row['duration_seconds'],
          'started_at_ms': row['started_at_ms'],
          'ended_at_ms': row['ended_at_ms'],
          'updated_at_ms': row['updated_at_ms'],
          'deleted': false,
        };
        String nextRemoteId = remoteId ?? '';
        if (remoteId != null && remoteId.isNotEmpty) {
          await pocketBase
              .collection('pomodoro_sessions')
              .update(remoteId, body: body);
          nextRemoteId = remoteId;
        } else {
          final created = await pocketBase
              .collection('pomodoro_sessions')
              .create(body: body);
          nextRemoteId = created.id;
        }
        await database.update(
          'pomodoro_sessions',
          <String, Object?>{
            ...row,
            'remote_id': nextRemoteId,
            'user_id': userId,
            'sync_state': SyncState.synced.index,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {
        // keep pending
      }
    }
  }
}
