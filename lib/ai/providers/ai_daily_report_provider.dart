import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wanandroid_pro/ai/core/constants.dart';
import 'package:wanandroid_pro/ai/core/diagnostics.dart';
import 'package:wanandroid_pro/ai/core/result.dart' as ai_result;
import 'package:wanandroid_pro/ai/models/ai_contract.dart';
import 'package:wanandroid_pro/ai/models/ai_request_status.dart';
import 'package:wanandroid_pro/ai/providers/ai_provider_manager.dart';
import 'package:wanandroid_pro/ai/providers/user_context_provider.dart';
import 'package:wanandroid_pro/ai/services/ai_client.dart';
import 'package:wanandroid_pro/ai/services/ai_message_composer.dart';
import 'package:wanandroid_pro/ai/services/ai_response_validator.dart';
import 'package:wanandroid_pro/ai/services/ai_schema_catalog.dart';
import 'package:wanandroid_pro/ai/services/browsing_history_db.dart';
import 'package:wanandroid_pro/local/KV.dart';
import 'package:wanandroid_pro/model/db/sqflite.dart';
import 'package:wanandroid_pro/remote/Api.dart';
import 'package:wanandroid_pro/remote/CgiTodo.dart';
import 'package:wanandroid_pro/remote/service/NerworkService.dart';

/// 日报阅读板块
class DailyReadingSection {
  final String? summary;
  final List<String> items;
  DailyReadingSection({this.summary, required this.items});
}

/// 日报任务板块
class DailyTodosSection {
  final String? completedSummary;
  final List<String> completed;
  final String? pendingSummary;
  final List<String> pending;
  DailyTodosSection({
    this.completedSummary,
    required this.completed,
    this.pendingSummary,
    required this.pending,
  });
}

/// 日报笔记板块
class DailyNotesSection {
  final String? summary;
  final List<String> items;
  DailyNotesSection({this.summary, required this.items});
}

/// 结构化日报数据
class DailyReport {
  final String overview;
  final DailyReadingSection? reading;
  final DailyTodosSection? todos;
  final DailyNotesSection? notes;
  final List<String> suggestions;

  DailyReport({
    required this.overview,
    this.reading,
    this.todos,
    this.notes,
    required this.suggestions,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    // 解析阅读板块
    DailyReadingSection? reading;
    final readingJson = json['reading'];
    if (readingJson != null) {
      final items = (readingJson['items'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (items.isNotEmpty || readingJson['summary'] != null) {
        reading = DailyReadingSection(
          summary: readingJson['summary'] as String?,
          items: items,
        );
      }
    }

    // 解析任务板块
    DailyTodosSection? todos;
    final todosJson = json['todos'];
    if (todosJson != null) {
      final completed = (todosJson['completed'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final pending = (todosJson['pending'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (completed.isNotEmpty || pending.isNotEmpty) {
        todos = DailyTodosSection(
          completedSummary: todosJson['completed_summary'] as String?,
          completed: completed,
          pendingSummary: todosJson['pending_summary'] as String?,
          pending: pending,
        );
      }
    }

    // 解析笔记板块
    DailyNotesSection? notes;
    final notesJson = json['notes'];
    if (notesJson != null) {
      final items = (notesJson['items'] as List?)?.map((e) => e.toString()).toList() ?? [];
      if (items.isNotEmpty || notesJson['summary'] != null) {
        notes = DailyNotesSection(
          summary: notesJson['summary'] as String?,
          items: items,
        );
      }
    }

    // 解析建议
    final suggestions = (json['suggestions'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return DailyReport(
      overview: json['overview'] as String? ?? '今日活动已汇总',
      reading: reading,
      todos: todos,
      notes: notes,
      suggestions: suggestions,
    );
  }
}

/// AI 日报状态
class AIDailyReportState {
  final bool isLoading;
  final String rawContent; // 流式输出的原始内容（用于显示打字效果）
  final bool isCompleted;
  final DailyReport? report; // 解析后的结构化数据
  final String? error;
  final AIRequestStatus status;

  const AIDailyReportState({
    this.isLoading = false,
    this.rawContent = '',
    this.isCompleted = false,
    this.report,
    this.error,
    this.status = AIRequestStatus.idle,
  });

  AIDailyReportState copyWith({
    bool? isLoading,
    String? rawContent,
    bool? isCompleted,
    DailyReport? report,
    String? error,
    AIRequestStatus? status,
  }) {
    return AIDailyReportState(
      isLoading: isLoading ?? this.isLoading,
      rawContent: rawContent ?? this.rawContent,
      isCompleted: isCompleted ?? this.isCompleted,
      report: report ?? this.report,
      error: error ?? this.error,
      status: status ?? this.status,
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
  AIClient? _aiClient;

  AIDailyReportNotifier(this._ref) : super(const AIDailyReportState());

  /// 生成日报（forceRegenerate: 是否强制重新生成，忽略今日缓存）
  Future<void> generateReport({bool forceRegenerate = false}) async {
    if (state.isLoading) return;

    // 如果不是强制重新生成，先检查今日是否已有缓存
    if (!forceRegenerate) {
      final cached = getTodayDailyReport();
      if (cached != null) {
        final report = _parseReport(cached);
        state = state.copyWith(
          isLoading: false,
          isCompleted: true,
          rawContent: cached,
          report: report,
          status: AIRequestStatus.completed,
        );
        return;
      }
    }

    // 检查 AI 配置
    final activeProvider = _ref.read(activeAIProviderProvider);
    if (activeProvider == null) {
      state = state.copyWith(
        error: '请先配置 AI 服务',
        status: AIRequestStatus.error,
      );
      return;
    }

    state = const AIDailyReportState(
      isLoading: true,
      status: AIRequestStatus.loading,
    );

    try {
      // 1. 采集今日活动数据
      final dailyData = await _collectDailyData();
      if (dailyData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isCompleted: true,
          report: DailyReport(
            overview: '今天还没有浏览文章、完成任务或编辑笔记，去看看有什么有趣的文章吧！ 🚀',
            suggestions: ['去首页浏览今日推荐文章', '整理一下待办事项'],
          ),
          status: AIRequestStatus.completed,
        );
        return;
      }

      // 2. 获取用户上下文
      final userContext = _ref.read(userContextProvider.notifier).promptSummary;

      // 3. 构建消息
      final messages = AIMessageComposer.dailyReport(
        dailyData: dailyData,
        userContext: userContext,
      );

      // 4. 流式请求（收集完整 JSON 后解析）
      _aiClient = AIClient(activeProvider);
      final stream = _aiClient!.sendStream(
        scene: 'daily_report',
        messages: messages,
        maxRetries: 1,
      );

      final buffer = StringBuffer();
      await for (final event in stream) {
        switch (event.type) {
          case AIStreamEventType.deltaText:
            if (event.deltaText == null || event.deltaText!.isEmpty) {
              continue;
            }
            buffer.write(event.deltaText!);
            if (mounted) {
              state = state.copyWith(
                rawContent: buffer.toString(),
                status: AIRequestStatus.loading,
              );
            }
            break;
          case AIStreamEventType.retrying:
            if (mounted) {
              state = state.copyWith(
                isLoading: true,
                error: event.error?.message,
                status: AIRequestStatus.retrying,
              );
            }
            break;
          case AIStreamEventType.completed:
            if (mounted) {
              final rawJson = event.response?.content ?? buffer.toString();
              var report = _parseReport(rawJson);
              if (report.overview == '生成失败，请重试') {
                AIDiagnosticsStore.instance.record(
                  scene: 'daily_report',
                  level: 'warning',
                  message: 'structured validation failed',
                  metadata: {
                    'schemaVersion': AISchemaCatalog.dailyReport.fullName,
                  },
                );
                final repaired = await _aiClient!.repairStructuredJson<DailyReport>(
                  scene: 'daily_report',
                  originalMessages: messages,
                  invalidOutput: rawJson,
                  validator: _validateReportResult,
                  repairInstruction:
                      '返回格式必须为包含 ${AISchemaCatalog.dailyReport.requiredKeys.join('、')} 等字段的合法 JSON 对象。',
                );
                switch (repaired) {
                  case ai_result.Success(data: final repairedReport):
                    report = repairedReport;
                  case ai_result.Failure():
                    break;
                }
              }
              AIDiagnosticsStore.instance.record(
                scene: 'daily_report',
                level: report.overview != '生成失败，请重试' ? 'success' : 'error',
                message: report.overview != '生成失败，请重试'
                    ? 'structured validation succeeded'
                    : 'structured validation failed after repair',
                metadata: {
                  'schemaVersion': AISchemaCatalog.dailyReport.fullName,
                },
              );
              if (report.overview != '生成失败，请重试') {
                saveDailyReport(rawJson);
              }
              state = state.copyWith(
                isLoading: false,
                isCompleted: true,
                rawContent: rawJson,
                report: report,
                status: report.overview != '生成失败，请重试'
                    ? AIRequestStatus.completed
                    : AIRequestStatus.error,
              );
            }
            break;
          case AIStreamEventType.failed:
          case AIStreamEventType.cancelled:
            if (mounted) {
              state = state.copyWith(
                isLoading: false,
                error: event.error?.message ?? AIConstants.errorUnknown,
                status: _mapErrorToStatus(event.error),
              );
            }
            break;
          case AIStreamEventType.started:
          case AIStreamEventType.toolCallRequested:
          case AIStreamEventType.toolCallResult:
          case AIStreamEventType.usageUpdated:
            break;
        }
      }
    } catch (e) {
      debugPrint('📊 日报生成失败: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: '生成失败: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e}',
          status: AIRequestStatus.error,
        );
      }
    }
  }

  /// 解析 AI 返回的 JSON 为结构化日报
  DailyReport _parseReport(String raw) {
    final result = _validateReportResult(raw);
    switch (result) {
      case ai_result.Success(data: final report):
        return report;
      case ai_result.Failure():
        break;
    }
    final error = switch (result) {
      ai_result.Failure(error: final error) => error,
      ai_result.Success() => null,
    };
    debugPrint('📊 日报 JSON 解析失败: $error');
    return DailyReport(
      overview: raw.isNotEmpty ? '日报已生成（显示原始内容）' : '生成失败，请重试',
      suggestions: [],
    );
  }

  ai_result.Result<DailyReport> _validateReportResult(String raw) {
    try {
      return AIResponseValidator.validateJsonObject(
        raw: raw,
        parser: DailyReport.fromJson,
        schema: AISchemaCatalog.dailyReport,
      );
    } catch (e) {
      debugPrint('📊 日报 JSON 解析失败: $e, raw: $raw');
      return ai_result.Failure(
        ai_result.ParseException('日报校验失败: $e', originalError: e),
      );
    }
  }

  /// 重置状态
  void reset() {
    _aiClient?.cancelCurrentRequest();
    state = const AIDailyReportState();
  }

  AIRequestStatus _mapErrorToStatus(AIErrorInfo? error) {
    switch (error?.type) {
      case AIErrorType.timeout:
        return AIRequestStatus.timedOut;
      case AIErrorType.rateLimited:
        return AIRequestStatus.rateLimited;
      case AIErrorType.cancelled:
        return AIRequestStatus.cancelled;
      default:
        return AIRequestStatus.error;
    }
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
      _collectTodayCollects(),
    ]);

    final browsingData = results[0];
    final todoData = results[1];
    final noteData = results[2];
    final collectData = results[3];

    buffer.writeln('📅 日期：${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
    buffer.writeln('⏰ 当前时间段：${_getTimeOfDay(now)}');
    buffer.writeln();

    if (browsingData.isNotEmpty) {
      buffer.writeln('📖 今日浏览记录（仅今日，与历史偏好不同）：');
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

    if (collectData.isNotEmpty) {
      buffer.writeln('🔖 今日新增收藏：');
      buffer.writeln(collectData);
      buffer.writeln();
    }

    // 如果所有数据都为空
    if (browsingData.isEmpty && todoData.isEmpty && noteData.isEmpty && collectData.isEmpty) {
      return '';
    }

    return buffer.toString();
  }

  /// 获取当前时间段描述
  String _getTimeOfDay(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 9) return '清晨（${now.hour}:${now.minute.toString().padLeft(2, '0')}）';
    if (hour >= 9 && hour < 12) return '上午（${now.hour}:${now.minute.toString().padLeft(2, '0')}）';
    if (hour >= 12 && hour < 14) return '中午（${now.hour}:${now.minute.toString().padLeft(2, '0')}）';
    if (hour >= 14 && hour < 18) return '下午（${now.hour}:${now.minute.toString().padLeft(2, '0')}）';
    if (hour >= 18 && hour < 22) return '晚上（${now.hour}:${now.minute.toString().padLeft(2, '0')}）';
    return '深夜（${now.hour}:${now.minute.toString().padLeft(2, '0')}）';
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

  /// 采集今日新增收藏
  Future<String> _collectTodayCollects() async {
    try {
      final req = CollectListReq(page: 0, pageSize: 20);
      final resp = await NetworkService.get<CollectListResp>(
        url: req.path,
        fromJsonT: CollectListResp.fromJson,
      ).getData();

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 过滤今日收藏（niceDate 包含今日日期）
      final todayCollects = resp.datas.where((a) {
        return a.niceDate.contains(todayStr) ||
            a.niceDate.startsWith('${today.month}月${today.day}日') ||
            a.niceDate.contains('小时前') ||
            a.niceDate.contains('分钟前');
      }).toList();

      if (todayCollects.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('- 今日新增 ${todayCollects.length} 篇收藏：');
      for (final a in todayCollects) {
        buffer.writeln('  🔖 ${a.title}');
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集今日收藏失败: $e');
      return '';
    }
  }

  @override
  void dispose() {
    _aiClient?.cancelCurrentRequest();
    super.dispose();
  }
}
