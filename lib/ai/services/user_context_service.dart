import 'package:flutter/cupertino.dart';
import 'package:notes_app/ai/models/user_context.dart';
import 'package:notes_app/ai/services/browsing_history_db.dart';
import 'package:notes_app/ai/services/chat_history_db.dart';
import 'package:notes_app/ai/services/user_context_db.dart';
import 'package:notes_app/local/KV.dart';
import 'package:notes_app/model/db/sqflite.dart';
import 'package:notes_app/remote/Api.dart';
import 'package:notes_app/remote/CgiTodo.dart';
import 'package:notes_app/remote/service/NerworkService.dart';

/// 用户上下文采集服务
/// 
/// 在 App 启动时后台执行，从多个数据源并行采集用户画像数据。
/// 采集结果存入 sqflite，供全局 AI 功能使用。
/// 
/// 数据源：
/// - 收藏文章标题（API）
/// - 笔记摘要（本地 DB）
/// - 待办列表（API）
/// - AI 对话主题（本地 DB）
/// - 用户基本信息（本地 KV）
class UserContextService {
  
  /// 采集并保存用户上下文（App 启动时调用）
  /// 
  /// 策略：
  /// 1. 先检查 DB 中是否有未过期的快照 → 有则跳过
  /// 2. 并行采集各数据源
  /// 3. 组装 UserContext 并存入 DB
  static Future<UserContext?> collectAndSave() async {
    // 0. 检查登录状态
    if (!isLogin()) {
      debugPrint('📋 用户未登录，跳过上下文采集');
      return null;
    }

    final userInfo = getUserProfile();
    final userId = userInfo.userInfo.id;

    // 1. 检查是否有未过期的缓存
    final db = UserContextDatabase();
    if (!await db.isExpired(userId)) {
      debugPrint('📋 用户上下文未过期，使用缓存');
      return await db.getLatestContext(userId);
    }

    debugPrint('📋 开始采集用户上下文...');

    // 2. 并行采集（各自 try-catch，互不影响）
    final results = await Future.wait([
      _collectCollectTitles(),
      _collectNoteSummaries(),
      _collectPendingTodos(),
      _collectChatTopics(),
      _collectBrowsingTitles(),
    ]);

    // 3. 组装
    final context = UserContext(
      username: userInfo.userInfo.nickname,
      userId: userId,
      level: userInfo.coinInfo.level,
      coinCount: userInfo.coinInfo.coinCount,
      collectTitles: results[0] as List<String>,
      noteSummaries: results[1] as List<String>,
      pendingTodos: results[2] as List<TodoSummary>,
      chatTopics: results[3] as List<String>,
      browsingTitles: results[4] as List<String>,
      collectedAt: DateTime.now(),
    );

    // 4. 存入 DB
    await db.saveContext(context);

    debugPrint('📋 用户上下文采集完成: '
        '收藏${context.collectTitles.length}篇, '
        '笔记${context.noteSummaries.length}条, '
        '待办${context.pendingTodos.length}项, '
        '对话${context.chatTopics.length}个, '
        '浏览${context.browsingTitles.length}篇');

    return context;
  }

  /// 强制刷新用户上下文（清除缓存后重新采集）
  static Future<UserContext?> forceRefresh() async {
    if (!isLogin()) return null;

    final userInfo = getUserProfile();
    final userId = userInfo.userInfo.id;

    // 清除旧缓存
    final db = UserContextDatabase();
    await db.clearForUser(userId);

    // 重新采集
    return await collectAndSave();
  }

  /// 采集收藏文章标题（走 API，最近 20 篇）
  static Future<List<String>> _collectCollectTitles() async {
    try {
      final req = CollectListReq(page: 0, pageSize: 20);
      final resp = await NetworkService.get<CollectListResp>(
        url: req.path,
        fromJsonT: CollectListResp.fromJson,
      ).getData();
      return resp.datas.map((a) => a.title).toList();
    } catch (e) {
      debugPrint('📋 采集收藏文章失败: $e');
      return [];
    }
  }

  /// 采集笔记摘要（本地 DB，最近 10 条，取前 50 字）
  static Future<List<String>> _collectNoteSummaries() async {
    try {
      await Db.init();
      final notes = await Db.getNotes();
      return notes
          .take(10)
          .map((n) {
            final content = n['content'] as String? ?? '';
            return content.length > 50 ? content.substring(0, 50) : content;
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('📋 采集笔记摘要失败: $e');
      return [];
    }
  }

  /// 采集待办列表（走 API，未完成的）
  static Future<List<TodoSummary>> _collectPendingTodos() async {
    try {
      final todos = await CgiTodo().queryTodo(1, status: 0);
      return todos.map((t) => TodoSummary(
        title: t.title,
        content: t.content,
        priority: t.priority,
        dateStr: t.dateStr,
      )).toList();
    } catch (e) {
      debugPrint('📋 采集待办列表失败: $e');
      return [];
    }
  }

  /// 采集 AI 对话主题（本地 DB，最近 10 个）
  static Future<List<String>> _collectChatTopics() async {
    try {
      final db = ChatHistoryDatabase();
      final histories = await db.getAllChatHistories();
      return histories
          .take(10)
          .map((h) => h.articleTitle)
          .where((t) => t.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('📋 采集 AI 对话主题失败: $e');
      return [];
    }
  }

  /// 采集浏览历史标题（本地 DB，最近 15 篇，去重）
  static Future<List<String>> _collectBrowsingTitles() async {
    try {
      final db = BrowsingHistoryDatabase();
      return await db.getRecentTitles(limit: 15);
    } catch (e) {
      debugPrint('📋 采集浏览历史失败: $e');
      return [];
    }
  }
}
