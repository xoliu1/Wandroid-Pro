import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_context.dart';

/// 用户上下文数据库服务
/// 
/// 负责将用户画像数据持久化到 sqflite，支持过期策略。
/// 采用单例模式，与 ChatHistoryDatabase 保持一致。
class UserContextDatabase {
  static final UserContextDatabase _instance = UserContextDatabase._internal();
  factory UserContextDatabase() => _instance;
  UserContextDatabase._internal();

  Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'user_context.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_context (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        context_json TEXT NOT NULL,
        prompt_summary TEXT NOT NULL,
        collected_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');
  }

  /// 保存用户上下文
  /// 
  /// 会先删除该用户的旧数据，再插入新数据。
  /// 默认过期时间为 24 小时。
  Future<void> saveContext(UserContext context, {Duration expiry = const Duration(hours: 24)}) async {
    final db = await database;
    final now = DateTime.now();
    final expiresAt = now.add(expiry);

    // 删除该用户的旧数据
    await db.delete(
      'user_context',
      where: 'user_id = ?',
      whereArgs: [context.userId],
    );

    // 插入新数据
    await db.insert('user_context', {
      'user_id': context.userId,
      'context_json': context.toJsonString(),
      'prompt_summary': context.toPromptSummary(),
      'collected_at': now.millisecondsSinceEpoch,
      'expires_at': expiresAt.millisecondsSinceEpoch,
    });

    debugPrint('📋 用户上下文已保存 (userId: ${context.userId}, 过期时间: $expiresAt)');
  }

  /// 获取最新的用户上下文
  Future<UserContext?> getLatestContext(int userId) async {
    final db = await database;
    final maps = await db.query(
      'user_context',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'collected_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;

    try {
      return UserContext.fromJsonString(maps.first['context_json'] as String);
    } catch (e) {
      debugPrint('📋 解析用户上下文失败: $e');
      return null;
    }
  }

  /// 检查用户上下文是否已过期
  Future<bool> isExpired(int userId) async {
    final db = await database;
    final maps = await db.query(
      'user_context',
      columns: ['expires_at'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'collected_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return true;

    final expiresAt = maps.first['expires_at'] as int;
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  /// 快速获取 prompt 摘要文本（给 AI 用）
  Future<String?> getPromptSummary(int userId) async {
    final db = await database;
    final maps = await db.query(
      'user_context',
      columns: ['prompt_summary'],
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'collected_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return maps.first['prompt_summary'] as String?;
  }

  /// 清除过期数据
  Future<void> clearExpired() async {
    final db = await database;
    await db.delete(
      'user_context',
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// 强制清除指定用户的上下文（用于强制刷新）
  Future<void> clearForUser(int userId) async {
    final db = await database;
    await db.delete(
      'user_context',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
