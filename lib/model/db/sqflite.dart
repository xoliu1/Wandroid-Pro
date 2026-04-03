import 'package:flutter/cupertino.dart';
import "package:sqflite/sqflite.dart";
import 'package:path/path.dart';


class Db {
  static late final Database db;
  static bool initialized = false;

  static Future<void> init() async {
    if (initialized) return;
    try {
      initialized = true;
      db = (await openDB())!;
      await _initDatabase();
      debugPrint('Database initialized successfully');
    } catch (e) {
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
      var db = await openDatabase(path, version: 2, onCreate: (db, version) {
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
