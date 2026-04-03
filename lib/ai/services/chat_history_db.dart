import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_history.dart';
import '../models/chat_message.dart';

/// AI 对话历史数据库服务
class ChatHistoryDatabase {
  static final ChatHistoryDatabase _instance = ChatHistoryDatabase._internal();
  factory ChatHistoryDatabase() => _instance;
  ChatHistoryDatabase._internal();

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
    final path = join(databasesPath, 'chat_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  /// 创建表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        article_url TEXT UNIQUE NOT NULL,
        article_title TEXT NOT NULL,
        article_author TEXT,
        messages TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  /// 保存或更新对话历史
  Future<int> saveChatHistory(ChatHistory history) async {
    final db = await database;
    final map = history.toMap();
    map['messages'] = jsonEncode(history.messages.map((m) => m.toJson()).toList());
    
    // 检查是否已存在
    final existing = await getChatHistoryByUrl(history.articleUrl);
    if (existing != null) {
      // 更新
      await db.update(
        'chat_history',
        map,
        where: 'article_url = ?',
        whereArgs: [history.articleUrl],
      );
      return existing.id!;
    } else {
      // 插入
      return await db.insert('chat_history', map);
    }
  }

  /// 根据文章URL获取对话历史
  Future<ChatHistory?> getChatHistoryByUrl(String url) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_history',
      where: 'article_url = ?',
      whereArgs: [url],
    );

    if (maps.isEmpty) return null;
    
    final map = maps.first;
    final messagesJson = map['messages'] as String;
    final messagesList = (jsonDecode(messagesJson) as List)
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList();
    
    return ChatHistory(
      id: map['id'] as int?,
      articleUrl: map['article_url'] as String,
      articleTitle: map['article_title'] as String,
      articleAuthor: map['article_author'] as String?,
      messages: messagesList,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 获取所有对话历史（按更新时间降序）
  Future<List<ChatHistory>> getAllChatHistories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_history',
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) {
      final messagesJson = map['messages'] as String;
      final messagesList = (jsonDecode(messagesJson) as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      
      return ChatHistory(
        id: map['id'] as int?,
        articleUrl: map['article_url'] as String,
        articleTitle: map['article_title'] as String,
        articleAuthor: map['article_author'] as String?,
        messages: messagesList,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );
    }).toList();
  }

  /// 删除指定的对话历史
  Future<int> deleteChatHistory(String url) async {
    final db = await database;
    return await db.delete(
      'chat_history',
      where: 'article_url = ?',
      whereArgs: [url],
    );
  }

  /// 清空所有对话历史
  Future<int> clearAllHistory() async {
    final db = await database;
    return await db.delete('chat_history');
  }

  /// 添加消息到现有对话
  Future<void> addMessage(String articleUrl, ChatMessage message) async {
    final history = await getChatHistoryByUrl(articleUrl);
    if (history != null) {
      final updatedMessages = [...history.messages, message];
      final updatedHistory = history.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );
      await saveChatHistory(updatedHistory);
    }
  }

  /// 更新对话标题
  Future<int> updateChatTitle(String articleUrl, String newTitle) async {
    final db = await database;
    return await db.update(
      'chat_history',
      {
        'article_title': newTitle,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'article_url = ?',
      whereArgs: [articleUrl],
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
