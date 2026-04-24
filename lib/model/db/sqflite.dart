import 'package:flutter/cupertino.dart';
import "package:sqflite/sqflite.dart";
import 'package:path/path.dart';

import '../Todo.dart';

class Db {
  static late final Database db;
  static bool initialized = false;

  static Future<void> init() async {
    if (initialized) return;
    try {
      db = (await openDB())!;
      await _initDatabase();
      initialized = true; // 仅在全部成功后才标记为已初始化
      debugPrint('Database initialized successfully');
    } catch (e) {
      initialized = false; // 确保失败时可以重试
      debugPrint('Failed to initialize database: $e');
      rethrow;
    }
  }

  static Database get() {
    if (!initialized) throw Exception('Database not initialized');
    return db;
  }

  static Future<Database?> openDB() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'local.db');
      var db = await openDatabase(path, version: 3, onCreate: (db, version) {
        db.execute('''
        CREATE TABLE tasks(
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          completed INTEGER,
          date TEXT,
          priority INTEGER,
          important INTEGER,
          color INTEGER
        )
        ''');
        db.execute('''
        CREATE TABLE notes(
          id TEXT PRIMARY KEY,
          content TEXT,
          date TEXT,
          lastModified TEXT
        )
      ''');
        db.execute('''
        CREATE TABLE todos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL DEFAULT '',
          content TEXT NOT NULL DEFAULT '',
          date INTEGER NOT NULL DEFAULT 0,
          status INTEGER NOT NULL DEFAULT 0,
          type INTEGER NOT NULL DEFAULT 0,
          priority INTEGER NOT NULL DEFAULT 0,
          completeDate INTEGER,
          completeDateStr TEXT NOT NULL DEFAULT '',
          dateStr TEXT NOT NULL DEFAULT '',
          userId INTEGER NOT NULL DEFAULT 0
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS todos(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL DEFAULT '',
              content TEXT NOT NULL DEFAULT '',
              date INTEGER NOT NULL DEFAULT 0,
              status INTEGER NOT NULL DEFAULT 0,
              type INTEGER NOT NULL DEFAULT 0,
              priority INTEGER NOT NULL DEFAULT 0,
              completeDate INTEGER,
              completeDateStr TEXT NOT NULL DEFAULT '',
              dateStr TEXT NOT NULL DEFAULT '',
              userId INTEGER NOT NULL DEFAULT 0
            )
          ''');
        }
      });
      debugPrint('Database opened at: $path');
      return db;
    } catch (e) {
      debugPrint('Failed to open database: $e');
      return null;
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        completed INTEGER,
        date TEXT,
        priority INTEGER,
        important INTEGER,
        color INTEGER
      )
    ''');
  }

  static Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'task_keeper.db'),
      onCreate: (db, version) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE tasks ADD COLUMN priority INTEGER');
        }
      },
      version: 2,
    );
  }

  // ==================== 本地 Todo CRUD ====================

  /// 插入本地 Todo，返回自增 id
  static Future<Todo> insertTodo(Todo todo) async {
    if (!initialized) await init();
    final map = todo.toJson();
    map.remove('id'); // 让 SQLite 自增
    final newId = await db.insert('todos', map);
    return todo.copyWith(id: newId);
  }

  /// 更新本地 Todo
  static Future<void> updateTodo(Todo todo) async {
    if (!initialized) await init();
    await db.update('todos', todo.toJson(), where: 'id = ?', whereArgs: [todo.id]);
  }

  /// 删除本地 Todo
  static Future<void> deleteTodo(int todoId) async {
    if (!initialized) await init();
    await db.delete('todos', where: 'id = ?', whereArgs: [todoId]);
  }

  /// 查询本地 Todo 列表（分页）
  static Future<List<Todo>> queryTodos({int page = 1, int pageSize = 20}) async {
    if (!initialized) await init();
    try {
      final offset = (page - 1) * pageSize;
      final rows = await db.query(
        'todos',
        orderBy: 'date DESC',
        limit: pageSize,
        offset: offset,
      );
      return rows.map((row) => Todo.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Failed to query local todos: $e');
      return [];
    }
  }

  /// 查询所有本地 Todo（无分页）
  static Future<List<Todo>> getAllTodos() async {
    if (!initialized) await init();
    try {
      final rows = await db.query('todos', orderBy: 'date DESC');
      return rows.map((row) => Todo.fromJson(row)).toList();
    } catch (e) {
      debugPrint('Failed to get all local todos: $e');
      return [];
    }
  }

  static Future<void> insertTask(Map<String, dynamic> task) async {
    if (!initialized) await init();
    await db.insert('tasks', task);
  }

  static Future<void> updateTask(Map<String, dynamic> task) async {
    if (!initialized) await init();
    await db.update('tasks', task, where: 'id = ?', whereArgs: [task['id']]);
  }

  static Future<void> deleteTask(String taskId) async {
    if (!initialized) await init();
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  static Future<void> insertNote(Map<String, dynamic> note) async {
    if (!initialized) await init();
    await db.insert('notes', note);
  }

  static Future<void> updateNote(Map<String, dynamic> note) async {
    if (!initialized) await init();
    await db.update('notes', note, where: 'id = ?', whereArgs: [note['id']]);
  }

  static Future<void> deleteNote(String noteId) async {
    if (!initialized) await init();
    await db.delete('notes', where: 'id = ?', whereArgs: [noteId]);
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    if (!initialized) await init();
    try {
      final tasks = await db.query('tasks');
      debugPrint('Retrieved tasks: ${tasks.length}');
      return tasks;
    } catch (e) {
      debugPrint('Failed to retrieve tasks: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getNotes() async {
    if (!initialized) await init();
    try {
      final notes = await db.query('notes');
      debugPrint('Retrieved notes: ${notes.length}');
      return notes;
    } catch (e) {
      debugPrint('Failed to retrieve notes: $e');
      return [];
    }
  }
}
