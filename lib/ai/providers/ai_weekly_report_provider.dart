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

// ─── 周报数据模型 ─────────────────────────────────────────────────────────────

/// 周报阅读板块
class WeeklyReadingSection {
  final String? summary;
  final List<String> items;
  final int totalCount;
  final int totalMinutes;

  WeeklyReadingSection({
    this.summary,
    required this.items,
    this.totalCount = 0,
    this.totalMinutes = 0,
  });

  factory WeeklyReadingSection.fromJson(Map<String, dynamic> json) {
    return WeeklyReadingSection(
      summary: json['summary'] as String?,
      items: (json['items'] as List?)?.map((e) => e.toString()).toList() ?? [],
      totalCount: json['total_count'] as int? ?? 0,
      totalMinutes: json['total_minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'items': items,
    'total_count': totalCount,
    'total_minutes': totalMinutes,
  };
}

/// 周报任务板块
class WeeklyTodosSection {
  final String? summary;
  final int completedCount;
  final int pendingCount;
  final List<String> highlights;

  WeeklyTodosSection({
    this.summary,
    this.completedCount = 0,
    this.pendingCount = 0,
    required this.highlights,
  });

  factory WeeklyTodosSection.fromJson(Map<String, dynamic> json) {
    return WeeklyTodosSection(
      summary: json['summary'] as String?,
      completedCount: json['completed_count'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
      highlights: (json['highlights'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'completed_count': completedCount,
    'pending_count': pendingCount,
    'highlights': highlights,
  };
}

/// 周报笔记板块
class WeeklyNotesSection {
  final String? summary;
  final int totalCount;
  final List<String> topics;

  WeeklyNotesSection({
    this.summary,
    this.totalCount = 0,
    required this.topics,
  });

  factory WeeklyNotesSection.fromJson(Map<String, dynamic> json) {
    return WeeklyNotesSection(
      summary: json['summary'] as String?,
      totalCount: json['total_count'] as int? ?? 0,
      topics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'total_count': totalCount,
    'topics': topics,
  };
}

/// 成长评估
class WeeklyGrowthSection {
  final String? assessment;
  final int score; // 1-10 分
  final List<String> strengths;
  final List<String> improvements;

  WeeklyGrowthSection({
    this.assessment,
    this.score = 0,
    required this.strengths,
    required this.improvements,
  });

  factory WeeklyGrowthSection.fromJson(Map<String, dynamic> json) {
    return WeeklyGrowthSection(
      assessment: json['assessment'] as String?,
      score: json['score'] as int? ?? 0,
      strengths: (json['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [],
      improvements: (json['improvements'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'assessment': assessment,
    'score': score,
    'strengths': strengths,
    'improvements': improvements,
  };
}

/// 结构化周报数据
class WeeklyReport {
  final String overview;
  final String weekRange; // 如 "2026-04-07 ~ 2026-04-13"
  final WeeklyReadingSection? reading;
  final WeeklyTodosSection? todos;
  final WeeklyNotesSection? notes;
  final WeeklyGrowthSection? growth;
  final List<String> nextWeekGoals;

  WeeklyReport({
    required this.overview,
    required this.weekRange,
    this.reading,
    this.todos,
    this.notes,
    this.growth,
    required this.nextWeekGoals,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    WeeklyReadingSection? reading;
    if (json['reading'] != null) {
      reading = WeeklyReadingSection.fromJson(json['reading']);
    }

    WeeklyTodosSection? todos;
    if (json['todos'] != null) {
      todos = WeeklyTodosSection.fromJson(json['todos']);
    }

    WeeklyNotesSection? notes;
    if (json['notes'] != null) {
      notes = WeeklyNotesSection.fromJson(json['notes']);
    }

    WeeklyGrowthSection? growth;
    if (json['growth'] != null) {
      growth = WeeklyGrowthSection.fromJson(json['growth']);
    }

    return WeeklyReport(
      overview: json['overview'] as String? ?? '本周活动已汇总',
      weekRange: json['week_range'] as String? ?? '',
      reading: reading,
      todos: todos,
      notes: notes,
      growth: growth,
      nextWeekGoals: (json['next_week_goals'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'overview': overview,
    'week_range': weekRange,
    'reading': reading?.toJson(),
    'todos': todos?.toJson(),
    'notes': notes?.toJson(),
    'growth': growth?.toJson(),
    'next_week_goals': nextWeekGoals,
  };
}

// ─── 周报历史持久化 ──────────────────────────────────────────────────────────

/// 周报历史记录项
class WeeklyReportRecord {
  final String weekKey; // 如 "2026-W15"
  final String weekRange;
  final String generatedAt; // ISO 日期
  final String rawJson;
  final WeeklyReport report;

  WeeklyReportRecord({
    required this.weekKey,
    required this.weekRange,
    required this.generatedAt,
    required this.rawJson,
    required this.report,
  });

  factory WeeklyReportRecord.fromJson(Map<String, dynamic> json) {
    final rawJson = json['raw_json'] as String? ?? '{}';
    WeeklyReport report;
    try {
      report = WeeklyReport.fromJson(jsonDecode(rawJson));
    } catch (_) {
      report = WeeklyReport(overview: '解析失败', weekRange: '', nextWeekGoals: []);
    }
    return WeeklyReportRecord(
      weekKey: json['week_key'] as String? ?? '',
      weekRange: json['week_range'] as String? ?? '',
      generatedAt: json['generated_at'] as String? ?? '',
      rawJson: rawJson,
      report: report,
    );
  }

  Map<String, dynamic> toJson() => {
    'week_key': weekKey,
    'week_range': weekRange,
    'generated_at': generatedAt,
    'raw_json': rawJson,
  };
}

/// 周报历史管理（MMKV 持久化）
const KEY_WEEKLY_REPORTS = 'weekly_reports_history';

/// 获取所有周报历史记录
List<WeeklyReportRecord> getWeeklyReportHistory() {
  final jsonStr = Kv.decodeString(KEY_WEEKLY_REPORTS);
  if (jsonStr == null || jsonStr.isEmpty) return [];
  try {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => WeeklyReportRecord.fromJson(e)).toList();
  } catch (e) {
    debugPrint('📊 周报历史解析失败: $e');
    return [];
  }
}

/// 保存周报到历史记录
void saveWeeklyReport(WeeklyReportRecord record) {
  final history = getWeeklyReportHistory();
  // 如果同一周已有记录，替换
  history.removeWhere((r) => r.weekKey == record.weekKey);
  history.insert(0, record); // 最新的在前面
  // 最多保留 52 条（一年）
  if (history.length > 52) {
    history.removeRange(52, history.length);
  }
  Kv.encodeString(KEY_WEEKLY_REPORTS, jsonEncode(history.map((e) => e.toJson()).toList()));
}

/// 删除指定周报
void deleteWeeklyReport(String weekKey) {
  final history = getWeeklyReportHistory();
  history.removeWhere((r) => r.weekKey == weekKey);
  Kv.encodeString(KEY_WEEKLY_REPORTS, jsonEncode(history.map((e) => e.toJson()).toList()));
}

/// 获取当前周的 key（如 "2026-W15"）
String getCurrentWeekKey() {
  final now = DateTime.now();
  final weekNumber = _weekNumber(now);
  return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
}

/// 获取当前周的日期范围
String getCurrentWeekRange() {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return '${_fmtDate(monday)} ~ ${_fmtDate(sunday)}';
}

int _weekNumber(DateTime date) {
  final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
  return ((dayOfYear - date.weekday + 10) / 7).floor();
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ─── AI 周报状态管理 ─────────────────────────────────────────────────────────

class AIWeeklyReportState {
  final bool isLoading;
  final String rawContent;
  final bool isCompleted;
  final WeeklyReport? report;
  final String? error;
  final AIRequestStatus status;

  const AIWeeklyReportState({
    this.isLoading = false,
    this.rawContent = '',
    this.isCompleted = false,
    this.report,
    this.error,
    this.status = AIRequestStatus.idle,
  });

  AIWeeklyReportState copyWith({
    bool? isLoading,
    String? rawContent,
    bool? isCompleted,
    WeeklyReport? report,
    String? error,
    bool clearError = false,
    AIRequestStatus? status,
  }) {
    return AIWeeklyReportState(
      isLoading: isLoading ?? this.isLoading,
      rawContent: rawContent ?? this.rawContent,
      isCompleted: isCompleted ?? this.isCompleted,
      report: report ?? this.report,
      error: clearError ? null : (error ?? this.error),
      status: status ?? this.status,
    );
  }
}

/// AI 周报 Provider
final aiWeeklyReportProvider =
    StateNotifierProvider<AIWeeklyReportNotifier, AIWeeklyReportState>((ref) {
  return AIWeeklyReportNotifier(ref);
});

/// 周报历史列表 Provider
final weeklyReportHistoryProvider = StateProvider<List<WeeklyReportRecord>>((ref) {
  return getWeeklyReportHistory();
});

class AIWeeklyReportNotifier extends StateNotifier<AIWeeklyReportState> {
  final Ref _ref;
  AIClient? _aiClient;

  AIWeeklyReportNotifier(this._ref) : super(const AIWeeklyReportState());

  /// 生成周报
  Future<void> generateReport({bool forceRegenerate = false}) async {
    if (state.isLoading) return;

    final weekKey = getCurrentWeekKey();

    // 检查缓存
    if (!forceRegenerate) {
      final history = getWeeklyReportHistory();
      final cached = history.where((r) => r.weekKey == weekKey).firstOrNull;
      if (cached != null) {
        state = state.copyWith(
          isLoading: false,
          isCompleted: true,
          rawContent: cached.rawJson,
          report: cached.report,
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

    state = const AIWeeklyReportState(
      isLoading: true,
      status: AIRequestStatus.loading,
    );

    try {
      // 1. 采集本周活动数据
      final weeklyData = await _collectWeeklyData();
      if (weeklyData.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isCompleted: true,
          report: WeeklyReport(
            overview: '本周还没有浏览文章、完成任务或编辑笔记，下周加油！ 🚀',
            weekRange: getCurrentWeekRange(),
            nextWeekGoals: ['去首页浏览推荐文章', '整理一下待办事项'],
          ),
          status: AIRequestStatus.completed,
        );
        return;
      }

      // 2. 获取用户上下文
      final userContext = _ref.read(userContextProvider.notifier).promptSummary;

      // 3. 构建消息
      final messages = AIMessageComposer.weeklyReport(
        weeklyData: weeklyData,
        weekRange: getCurrentWeekRange(),
        userContext: userContext,
      );

      // 4. 流式请求
      _aiClient = AIClient(activeProvider);
      final stream = _aiClient!.sendStream(
        scene: 'weekly_report',
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
                  scene: 'weekly_report',
                  level: 'warning',
                  message: 'structured validation failed',
                  metadata: {
                    'schemaVersion': AISchemaCatalog.weeklyReport.fullName,
                  },
                );
                final repaired = await _aiClient!.repairStructuredJson<WeeklyReport>(
                  scene: 'weekly_report',
                  originalMessages: messages,
                  invalidOutput: rawJson,
                  validator: _validateReportResult,
                  repairInstruction:
                      '返回格式必须为包含 ${AISchemaCatalog.weeklyReport.requiredKeys.join('、')} 字段的合法 JSON 对象。',
                );
                switch (repaired) {
                  case ai_result.Success(data: final repairedReport):
                    report = repairedReport;
                  case ai_result.Failure():
                    break;
                }
              }

              AIDiagnosticsStore.instance.record(
                scene: 'weekly_report',
                level: report.overview != '生成失败，请重试' ? 'success' : 'error',
                message: report.overview != '生成失败，请重试'
                    ? 'structured validation succeeded'
                    : 'structured validation failed after repair',
                metadata: {
                  'schemaVersion': AISchemaCatalog.weeklyReport.fullName,
                },
              );

              if (report.overview != '生成失败，请重试') {
                final record = WeeklyReportRecord(
                  weekKey: weekKey,
                  weekRange: getCurrentWeekRange(),
                  generatedAt: DateTime.now().toIso8601String(),
                  rawJson: rawJson,
                  report: report,
                );
                saveWeeklyReport(record);
                _ref.read(weeklyReportHistoryProvider.notifier).state = getWeeklyReportHistory();
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
      debugPrint('📊 周报生成失败: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: '生成失败: ${e.toString().length > 100 ? '${e.toString().substring(0, 100)}...' : e}',
          status: AIRequestStatus.error,
        );
      }
    }
  }

  /// 解析 AI 返回的 JSON
  WeeklyReport _parseReport(String raw) {
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
    debugPrint('📊 周报 JSON 解析失败: $error');
    return WeeklyReport(
      overview: raw.isNotEmpty ? '周报已生成（显示原始内容）' : '生成失败，请重试',
      weekRange: getCurrentWeekRange(),
      nextWeekGoals: [],
    );
  }

  ai_result.Result<WeeklyReport> _validateReportResult(String raw) {
    try {
      return AIResponseValidator.validateJsonObject(
        raw: raw,
        parser: WeeklyReport.fromJson,
        schema: AISchemaCatalog.weeklyReport,
      );
    } catch (e) {
      debugPrint('📊 周报 JSON 解析失败: $e');
      return ai_result.Failure(
        ai_result.ParseException('周报校验失败: $e', originalError: e),
      );
    }
  }

  void reset() {
    _aiClient?.cancelCurrentRequest();
    state = const AIWeeklyReportState();
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

  /// 采集本周活动数据
  Future<String> _collectWeeklyData() async {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekRange = getCurrentWeekRange();

    final results = await Future.wait([
      _collectWeekBrowsing(monday, now),
      _collectWeekTodos(),
      _collectWeekNotes(monday, now),
      _collectWeekCollects(),
    ]);

    final browsingData = results[0];
    final todoData = results[1];
    final noteData = results[2];
    final collectData = results[3];

    buffer.writeln('📅 周报范围：$weekRange');
    buffer.writeln('📆 当前周：${getCurrentWeekKey()}');
    buffer.writeln();

    if (browsingData.isNotEmpty) {
      buffer.writeln('📖 本周浏览记录：');
      buffer.writeln(browsingData);
      buffer.writeln();
    }

    if (todoData.isNotEmpty) {
      buffer.writeln('✅ 本周待办情况：');
      buffer.writeln(todoData);
      buffer.writeln();
    }

    if (noteData.isNotEmpty) {
      buffer.writeln('📝 本周笔记动态：');
      buffer.writeln(noteData);
      buffer.writeln();
    }

    if (collectData.isNotEmpty) {
      buffer.writeln('🔖 本周新增收藏：');
      buffer.writeln(collectData);
      buffer.writeln();
    }

    if (browsingData.isEmpty && todoData.isEmpty && noteData.isEmpty && collectData.isEmpty) {
      return '';
    }

    return buffer.toString();
  }

  /// 采集本周浏览记录
  Future<String> _collectWeekBrowsing(DateTime from, DateTime to) async {
    try {
      final db = BrowsingHistoryDatabase();
      final dailyCounts = await db.getDailyReadCount(from: from, to: to);
      final totalCount = dailyCounts.values.fold<int>(0, (a, b) => a + b);
      if (totalCount == 0) return '';

      // 获取本周所有记录
      final buffer = StringBuffer();
      buffer.writeln('- 本周共浏览 $totalCount 篇文章');

      // 每日分布
      buffer.writeln('- 每日阅读量：');
      for (final entry in dailyCounts.entries) {
        if (entry.value > 0) {
          buffer.writeln('  · ${entry.key}: ${entry.value} 篇');
        }
      }

      // 获取本周浏览的文章标题（去重）
      final records = <BrowsingRecord>[];
      var current = DateTime(from.year, from.month, from.day);
      final end = DateTime(to.year, to.month, to.day);
      while (!current.isAfter(end)) {
        final dayRecords = await db.getRecordsByDate(current);
        records.addAll(dayRecords);
        current = current.add(const Duration(days: 1));
      }

      final seen = <String>{};
      final titles = <String>[];
      for (final r in records) {
        if (r.title.isNotEmpty && seen.add(r.title)) {
          titles.add(r.title);
        }
      }

      if (titles.isNotEmpty) {
        buffer.writeln('- 浏览的文章（去重后 ${titles.length} 篇）：');
        for (final t in titles.take(15)) {
          buffer.writeln('  · $t');
        }
        if (titles.length > 15) {
          buffer.writeln('  ... 还有 ${titles.length - 15} 篇');
        }
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集本周浏览记录失败: $e');
      return '';
    }
  }

  /// 采集本周待办情况
  Future<String> _collectWeekTodos() async {
    try {
      final pending = await CgiTodo().queryTodo(1, status: 0);
      final completed = await CgiTodo().queryTodo(1, status: 1);

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayStr = _fmtDate(monday);

      final buffer = StringBuffer();

      // 本周完成的
      final weekCompleted = completed.where((t) {
        return t.completeDateStr.compareTo(mondayStr) >= 0;
      }).toList();

      if (weekCompleted.isNotEmpty) {
        buffer.writeln('- 本周完成 ${weekCompleted.length} 项：');
        for (final t in weekCompleted.take(10)) {
          buffer.writeln('  ✅ ${t.title}');
        }
      }

      if (pending.isNotEmpty) {
        buffer.writeln('- 当前待完成 ${pending.length} 项：');
        for (final t in pending.take(5)) {
          final priority = t.priority >= 2 ? '🔴' : t.priority == 1 ? '🟡' : '🔵';
          buffer.writeln('  $priority ${t.title}');
        }
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集本周待办失败: $e');
      return '';
    }
  }

  /// 采集本周笔记动态
  Future<String> _collectWeekNotes(DateTime from, DateTime to) async {
    try {
      await Db.init();
      final notes = await Db.getNotes();
      final fromStr = _fmtDate(from);

      final weekNotes = notes.where((n) {
        final lastModified = n['lastModified'] as String? ?? '';
        return lastModified.compareTo(fromStr) >= 0;
      }).toList();

      if (weekNotes.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('- 本周编辑 ${weekNotes.length} 条笔记：');
      for (final n in weekNotes.take(8)) {
        final content = n['content'] as String? ?? '';
        final preview = content.length > 40 ? '${content.substring(0, 40)}...' : content;
        buffer.writeln('  · $preview');
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集本周笔记失败: $e');
      return '';
    }
  }

  /// 采集本周新增收藏
  Future<String> _collectWeekCollects() async {
    try {
      final req = CollectListReq(page: 0, pageSize: 40);
      final resp = await NetworkService.get<CollectListResp>(
        url: req.path,
        fromJsonT: CollectListResp.fromJson,
      ).getData();

      // 简单过滤（收藏列表没有精确时间戳，只能粗略判断）
      if (resp.datas.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('- 最近收藏的文章（最多显示 10 篇）：');
      for (final a in resp.datas.take(10)) {
        buffer.writeln('  🔖 ${a.title}');
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('📊 采集本周收藏失败: $e');
      return '';
    }
  }

  @override
  void dispose() {
    _aiClient?.cancelCurrentRequest();
    super.dispose();
  }
}
