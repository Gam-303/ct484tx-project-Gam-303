import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../config/app_env.dart';
import '../notification/local_notification_service.dart';

class AppBootstrap {
  AppBootstrap({
    required this.prefs,
    required this.pocketBase,
    required this.database,
    required this.notificationsPlugin,
  });

  final SharedPreferences prefs;
  final PocketBase pocketBase;
  final Database database;
  final FlutterLocalNotificationsPlugin notificationsPlugin;

  static Future<AppBootstrap> create() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final prefs = await SharedPreferences.getInstance();
    final pb = PocketBase(AppEnv.pocketBaseUrl);
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'pomodoro_cache.db'),
      version: 2,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE IF NOT EXISTS tasks(
            id TEXT PRIMARY KEY,
            remote_id TEXT,
            user_id TEXT,
            title TEXT NOT NULL,
            description TEXT,
            deadline TEXT NOT NULL,
            priority INTEGER NOT NULL DEFAULT 1,
            estimated_pomodoros INTEGER NOT NULL DEFAULT 1,
            completed_pomodoros INTEGER NOT NULL DEFAULT 0,
            status INTEGER NOT NULL DEFAULT 0,
            sync_state INTEGER NOT NULL DEFAULT 1,
            updated_at_ms INTEGER NOT NULL,
            deleted_at_ms INTEGER
          )
        ''');
        await database.execute('''
          CREATE TABLE IF NOT EXISTS pomodoro_sessions(
            id TEXT PRIMARY KEY,
            remote_id TEXT,
            user_id TEXT,
            task_id TEXT,
            phase TEXT NOT NULL,
            duration_seconds INTEGER NOT NULL,
            started_at_ms INTEGER NOT NULL,
            ended_at_ms INTEGER NOT NULL,
            sync_state INTEGER NOT NULL DEFAULT 1,
            updated_at_ms INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            CREATE TABLE IF NOT EXISTS tasks_v2(
              id TEXT PRIMARY KEY,
              remote_id TEXT,
              user_id TEXT,
              title TEXT NOT NULL,
              description TEXT,
              deadline TEXT NOT NULL,
              priority INTEGER NOT NULL DEFAULT 1,
              estimated_pomodoros INTEGER NOT NULL DEFAULT 1,
              completed_pomodoros INTEGER NOT NULL DEFAULT 0,
              status INTEGER NOT NULL DEFAULT 0,
              sync_state INTEGER NOT NULL DEFAULT 1,
              updated_at_ms INTEGER NOT NULL,
              deleted_at_ms INTEGER
            )
          ''');
          await database.execute('''
            INSERT OR REPLACE INTO tasks_v2(
              id, title, description, deadline, priority, estimated_pomodoros, completed_pomodoros, status, sync_state, updated_at_ms
            )
            SELECT
              id, title, description, deadline, priority, estimatedPomodoros, completedPomodoros, status, 1, CAST(strftime('%s','now') AS INTEGER) * 1000
            FROM tasks
          ''');
          await database.execute('DROP TABLE IF EXISTS tasks');
          await database.execute('ALTER TABLE tasks_v2 RENAME TO tasks');
          await database.execute('''
            CREATE TABLE IF NOT EXISTS pomodoro_sessions(
              id TEXT PRIMARY KEY,
              remote_id TEXT,
              user_id TEXT,
              task_id TEXT,
              phase TEXT NOT NULL,
              duration_seconds INTEGER NOT NULL,
              started_at_ms INTEGER NOT NULL,
              ended_at_ms INTEGER NOT NULL,
              sync_state INTEGER NOT NULL DEFAULT 1,
              updated_at_ms INTEGER NOT NULL
            )
          ''');
        }
      },
    );

    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    LocalNotificationService.instance.configure(notifications);

    return AppBootstrap(
      prefs: prefs,
      pocketBase: pb,
      database: db,
      notificationsPlugin: notifications,
    );
  }
}
