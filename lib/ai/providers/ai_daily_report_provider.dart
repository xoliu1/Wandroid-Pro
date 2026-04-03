import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/ai/models/user_context.dart';
import 'package:notes_app/ai/providers/ai_provider_manager.dart';
import 'package:notes_app/ai/providers/user_context_provider.dart';
import 'package:notes_app/ai/services/ai_service.dart';
import 'package:notes_app/ai/services/browsing_history_db.dart';
import 'package:notes_app/model/db/sqflite.dart';
import 'package:notes_app/remote/CgiTodo.dart';

/// AI 日报状态
class AIDailyReportState {
  final bool isLoading;
  final String content; // 流式输出的 Markdown 内容
  final bool isCompleted;
  final String? error;

  const AIDailyReportState({
    this.isLoading = false,
    this.content = '',
    this.isCompleted = false,
    this.error,
  });

  AIDailyReportState copyWith({
    bool? isLoading,
    String? content,
    bool? isCompleted,
    String? error,
  }) {
    return AIDailyReportState(
      isLoading: isLoading ?? this.isLoading,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
    );
  }
}

/// AI 日报 Provider
final aiDailyReportProvider =
    StateNotifierProvider<AIDailyReportNotifier, AIDailyReportState>((ref) {
  return AIDailyReportNotifier(ref);
});

class AIDailyReportNotifier extends StateNotifier<AIDailyReportState> {
  final Ref _ref;
  AIService? _aiService;

  AIDailyReportNotifier(this._ref) : super(const AIDailyReportState());

  /// 生成日报
  Future<void> generateReport() async {
    if (state.isLoading) return;

    // 检查 AI 配置
    final activeProvider = _ref.read(activeAIProviderProvider);
    if (activeProvider == null) {
      state = state.copyWith(error: '请先配置 AI 服务');
      return;
    }

    state = const AIDailyReportState(isLoading: true);

    try {
      // 1. 采集今日活动数据
      final dailyData = await _collectDailyData();
      if (dailyData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isCompleted: true,
          content: '## 📋 今日暂无活动记录\n\n今天还没有浏览文章、完成任务或编辑笔记。\n\n去看看有什么有趣的文章吧！ 🚀',
        );
        return;
      }

      // 2. 获取用户上下文
      final userContext = _ref.read(userContextProvider.notifier).promptSummary;

      // 3. 构建消息
      final messages = AIService.buildDailyReportMessages(
        dailyData: dailyData,
        userContext: userContext,
      );

      // 4. 流式请求
      _aiService = AIService(activeProvider);
      final stream = _aiService!.sendChatStream(messages: messages);

      final buffer = StringBuffer();
      await for (final chunk in stream) {
        buffer.write(chunk);
        if (mounted) {
          state = state.copyWith(content: buffer.toString());
        }
      }

      if (mounted) {
        state = state.copyWith(isLoading: false, isCompleted: true);
      }
    } catch (e) {
      debugPrint('📊 日报生成失败: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: '生成失败: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e}',
        );
      }
    }
  }

  /// 重置状态
  void reset() {
    _aiService?.cancelCurrentRequest();
    state = const AIDailyReportState();
  }

  /// 采集今日活动数据
  Future<String> _collectDailyData() async {
    final buffer = StringBuffer();
    final now = DateTime.now();

    // 并行采集
    final results = await Future.wait([
      _collectTodayBrowsing(),
      _collectTodayTodos(),
      _collectTodayNotes(),
    ]);

    final browsingData = results[0] as String;
    final todoData = results[1] as String;
    final noteData = results[2] as String;

    buffer.writeln('📅 日期：${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    buffer.writeln();

    if (browsingData.isNotEmpty) {
      buffer.writeln('📖 今日浏览记录：');
      buffer.writeln(browsingData);
      buffer.writeln();
    }

    if (todoData.isNotEmpty) {
      buffer.writeln('✅ 待办事项情况：');
      buffer.writeln(todoData);
      buffer.writeln();
    }

    if (noteData.isNotEmpty) {
      buffer.writeln('📝 笔记动态：');
      buffer.writeln(noteData);
      buffer.writeln();
    }

    // 如果所有数据都为空
    if (browsingData.isEmpty && todoData.isEmpty && noteData.isEmpty) {
      return '';
    }

    return buffer.toString();
  }

  /// 采集今日浏览记录
  Future<String> _collectTodayBrowsing() async {
    try {
      final db = BrowsingHistoryDatabase();
      final records = await db.getRecordsByDate(DateTime.now());
      if (records.isEmpty) return '';

      final stats = await db.getTodayStats();
      final buffer = StringBuffer();
      buffer.writeln('- 共浏览 ${stats['count']} 篇文章');
      
      final totalMinutes = (stats['totalDuration'] as int) ~/ 60;
      if (totalMinutes > 0) {
        buffer.writeln('- 总阅读时长约 $totalMinutes 分钟');
      }

      buffer.writeln('- 浏览的文章：');
      // 去重显示
      final seen = <String>{};
      for (final r in records) {
        if (r.title.isNotEmpty && seen.add(r.title)) {
          final durationMin = r.duration > 0 ? '（${r.duration ~/ 60}分钟）' : '';
          buffer.writeln('  · ${r.title}$durationMin');
        }
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集今日浏览记录失败: $e');
      return '';
    }
  }

  /// 采集今日待办情况
  Future<String> _collectTodayTodos() async {
    try {
      // 获取所有待办（已完成 + 未完成）
      final pending = await CgiTodo().queryTodo(1, status: 0);
      final completed = await CgiTodo().queryTodo(1, status: 1);

      final buffer = StringBuffer();

      // 今日完成的
      final todayCompleted = completed.where((t) {
        if (t.completeDateStr.isEmpty) return false;
        final today = DateTime.now();
        return t.completeDateStr.contains(
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
      }).toList();

      if (todayCompleted.isNotEmpty) {
        buffer.writeln('- 今日完成 ${todayCompleted.length} 项：');
        for (final t in todayCompleted) {
          buffer.writeln('  ✅ ${t.title}');
        }
      }

      if (pending.isNotEmpty) {
        buffer.writeln('- 待完成 ${pending.length} 项：');
        for (final t in pending.take(5)) {
          final priority = t.priority >= 2 ? '🔴' : t.priority == 1 ? '🟡' : '🔵';
          buffer.writeln('  $priority ${t.title}');
        }
        if (pending.length > 5) {
          buffer.writeln('  ... 还有 ${pending.length - 5} 项');
        }
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集今日待办失败: $e');
      return '';
    }
  }

  /// 采集今日笔记动态
  Future<String> _collectTodayNotes() async {
    try {
      await Db.init();
      final notes = await Db.getNotes();
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final todayNotes = notes.where((n) {
        final lastModified = n['lastModified'] as String? ?? '';
        return lastModified.startsWith(todayStr);
      }).toList();

      if (todayNotes.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('- 今日编辑 ${todayNotes.length} 条笔记：');
      for (final n in todayNotes.take(5)) {
        final content = n['content'] as String? ?? '';
        final preview = content.length > 30 ? '${content.substring(0, 30)}...' : content;
        buffer.writeln('  · $preview');
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集今日笔记失败: $e');
      return '';
    }
  }

  @override
  void dispose() {
    _aiService?.cancelCurrentRequest();
    super.dispose();
  }
}
