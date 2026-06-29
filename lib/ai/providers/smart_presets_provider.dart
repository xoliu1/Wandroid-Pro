import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/ai/models/chat_message.dart';
import 'package:wanandroid_pro/ai/services/browsing_history_db.dart';
import 'package:wanandroid_pro/model/db/sqflite.dart';
import 'package:wanandroid_pro/model/Todo.dart';
import 'package:wanandroid_pro/remote/CgiTodo.dart';

/// 预设问题分类
class PresetCategory {
  final String id;
  final String title;
  final String description;
  final List<PresetQuestion> questions;

  PresetCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });
}

/// 智能预设问题 Provider（带缓存和自动释放）
/// 根据用户的学习记录、浏览历史、待办任务等生成个性化的对话预设
/// 
/// 使用 autoDispose 自动释放资源
/// 使用 keepAlive 保持 5 分钟缓存，避免频繁重新计算
final smartPresetsProvider = FutureProvider.autoDispose<List<PresetCategory>>((ref) async {
  // 保持缓存 5 分钟
  final link = ref.keepAlive();
  Future.delayed(const Duration(minutes: 5), () {
    link.close();
  });

  return await SmartPresetsService().generateSmartPresets();
});

/// 智能预设生成服务
class SmartPresetsService {
  List<PresetQuestion> getDefaultPresetsForTest() {
    return _getDefaultCategories()
        .expand((category) => category.questions)
        .toList();
  }

  List<PresetQuestion> generatePresetsFromContextForTest(
    Map<String, dynamic> context,
  ) {
    return _generatePersonalizedCategory(context).questions;
  }

  /// 生成智能预设分类
  Future<List<PresetCategory>> generateSmartPresets() async {
    final categories = <PresetCategory>[];

    try {
      // 1. 采集用户上下文数据
      final context = await _collectUserContext();

      // 2. 生成个性化学习类（基于用户行为）
      final personalizedCategory = _generatePersonalizedCategory(context);
      if (personalizedCategory.questions.isNotEmpty) {
        categories.add(personalizedCategory);
      }

      // 3. 生成通用学习类
      categories.add(_generateGeneralLearningCategory());

      // 4. 生成效率工具类
      categories.add(_generateProductivityCategory());

      // 5. 生成创意灵感类
      categories.add(_generateCreativityCategory());

    } catch (e) {
      debugPrint('🤖 生成智能预设失败: $e');
      // 失败时返回默认分类
      return _getDefaultCategories();
    }

    return categories;
  }

  /// 采集用户上下文数据
  Future<Map<String, dynamic>> _collectUserContext() async {
    final context = <String, dynamic>{};

    // 并行采集
    final results = await Future.wait([
      _getRecentBrowsing(),
      _getTodoStatus(),
      _getRecentNotes(),
      _getBrowsingCategories(),
    ]);

    context['recentBrowsing'] = results[0];
    context['todos'] = results[1];
    context['recentNotes'] = results[2];
    context['categories'] = results[3];

    return context;
  }

  /// 获取最近浏览记录
  Future<Map<String, dynamic>> _getRecentBrowsing() async {
    try {
      final db = BrowsingHistoryDatabase();
      final records = await db.getRecentRecords(limit: 10);
      final todayCount = (await db.getTodayStats())['count'] as int;

      // 提供更详细的浏览记录数据
      final detailedRecords = records.map((r) => {
        'title': r.title,
        'url': r.url,
        'visitedAt': DateTime.fromMillisecondsSinceEpoch(r.visitedAt).toIso8601String(),
        'duration': r.duration,
        'category': r.category,
      }).toList();

      return {
        'count': records.length,
        'todayCount': todayCount,
        'detailedRecords': detailedRecords,
        'hasData': records.isNotEmpty,
      };
    } catch (e) {
      debugPrint('🤖 获取浏览记录失败: $e');
      return {'hasData': false};
    }
  }

  /// 获取待办任务状态（添加超时保护）
  Future<Map<String, dynamic>> _getTodoStatus() async {
    try {
      // 添加 3 秒超时保护，避免网络慢导致加载卡顿
      final results = await Future.wait(
        [
          CgiTodo().queryTodo(1, status: 0),
          CgiTodo().queryTodo(1, status: 1),
        ],
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('🤖 待办任务查询超时，返回空数据');
          return [<Todo>[], <Todo>[]];
        },
      );

      final pending = results[0];
      final completed = results[1];

      // 获取今日完成的任务
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayCompleted = completed.where((t) {
        return t.completeDateStr.contains(todayStr);
      }).toList();

      // 提供详细的任务列表（标题、优先级、截止日期等）
      final pendingDetails = pending.take(10).map((t) => {
        'title': t.title,
        'priority': t.priority,
        'date': t.dateStr,
        'status': '待完成',
      }).toList();

      final completedDetails = todayCompleted.take(10).map((t) => {
        'title': t.title,
        'priority': t.priority,
        'completedDate': t.completeDateStr,
        'status': '已完成',
      }).toList();

      return {
        'pendingCount': pending.length,
        'todayCompletedCount': todayCompleted.length,
        'pendingTasks': pendingDetails,
        'completedTasks': completedDetails,
        'hasData': pending.isNotEmpty || completed.isNotEmpty,
      };
    } catch (e) {
      debugPrint('🤖 获取待办任务失败: $e');
      return {'hasData': false};
    }
  }

  /// 获取最近笔记（避免重复初始化）
  Future<Map<String, dynamic>> _getRecentNotes() async {
    try {
      // 检查数据库是否已初始化，避免重复初始化
      if (!Db.initialized) {
        await Db.init();
      }
      
      final notes = await Db.getNotes();
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final todayNotes = notes.where((n) {
        final lastModified = n['lastModified'] as String? ?? '';
        return lastModified.startsWith(todayStr);
      }).toList();

      return {
        'totalCount': notes.length,
        'todayCount': todayNotes.length,
        'hasData': notes.isNotEmpty,
      };
    } catch (e) {
      debugPrint('🤖 获取笔记失败: $e');
      return {'hasData': false};
    }
  }

  /// 获取浏览分类统计
  Future<Map<String, dynamic>> _getBrowsingCategories() async {
    try {
      final db = BrowsingHistoryDatabase();
      final categories = await db.getTopDomains(limit: 3);
      return {
        'topCategories': categories,
        'hasData': categories.isNotEmpty,
      };
    } catch (e) {
      debugPrint('🤖 获取分类统计失败: $e');
      return {'hasData': false};
    }
  }

  /// 生成个性化学习类（基于用户行为）
  /// 直接将原始数据作为上下文传递给 AI，让 AI 自己分析
  PresetCategory _generatePersonalizedCategory(Map<String, dynamic> context) {
    final questions = <PresetQuestion>[];

    // 构建完整的上下文信息字符串
    final contextInfo = _buildContextInfo(context);

    // 如果有有效的用户数据，生成个性化预设
    if (contextInfo.isNotEmpty) {
      questions.addAll([
        PresetQuestion(
          icon: '',
          title: '总结今天的学习',
          prompt: '根据我的浏览记录、待办任务等数据，帮我总结一下今天的学习情况和收获。',
          context: contextInfo, // 上下文数据不显示在用户消息中
        ),
        PresetQuestion(
          icon: '',
          title: '学习建议',
          prompt: '根据我的学习数据，给我一些针对性的学习建议和改进方向。',
          context: contextInfo,
        ),
        PresetQuestion(
          icon: '',
          title: '知识盲点分析',
          prompt: '分析一下我的学习数据，看看有哪些知识盲点或需要加强的地方。',
          context: contextInfo,
        ),
        PresetQuestion(
          icon: '',
          title: '学习效率分析',
          prompt: '分析一下我的学习效率，给出提升建议。',
          context: contextInfo,
        ),
        PresetQuestion(
          icon: '',
          title: '任务优先级建议',
          prompt: '根据我的待办任务和学习情况，帮我规划任务优先级。',
          context: contextInfo,
        ),
        PresetQuestion(
          icon: '',
          title: '学习路线规划',
          prompt: '根据我最近的学习方向，帮我规划后续的学习路线。',
          context: contextInfo,
        ),
      ]);
    }

    return PresetCategory(
      id: 'personalized',
      title: '个性化学习',
      description: '基于你的浏览记录和学习行为',
      questions: questions,
    );
  }

  /// 构建上下文信息字符串，将原始数据格式化后传递给 AI
  String _buildContextInfo(Map<String, dynamic> context) {
    final sections = <String>[];
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. 浏览记录 - 提供详细的文章列表
    final browsing = context['recentBrowsing'] as Map<String, dynamic>?;
    if (browsing != null && browsing['hasData'] == true) {
      final section = StringBuffer();
      final todayCount = browsing['todayCount'] as int? ?? 0;
      final records = browsing['detailedRecords'] as List<dynamic>? ?? [];
      final recentTitles = browsing['recentTitles'] as List<dynamic>? ?? [];
      
      section.writeln('📚 浏览记录：');
      section.writeln('- 今日浏览：$todayCount 篇文章');

      if (records.isNotEmpty) {
        section.writeln('- 最近浏览记录（含时间）：');

        for (var i = 0; i < records.length && i < 5; i++) {
          final record = records[i] as Map<String, dynamic>;
          final title = record['title'] as String;
          final visitedAt = record['visitedAt'] as String;
          final duration = record['duration'] as int?;
          final category = record['category'] as String? ?? '';

          final time = DateTime.parse(visitedAt);
          final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

          section.write('  ${i + 1}. $title ($timeStr');
          if (duration != null && duration > 0) {
            section.write(', 停留${duration}秒');
          }
          if (category.isNotEmpty) {
            section.write(', 分类:$category');
          }
          section.writeln(')');
        }
      } else if (recentTitles.isNotEmpty) {
        section.writeln('- 最近浏览标题：');
        for (var i = 0; i < recentTitles.length && i < 5; i++) {
          section.writeln('  ${i + 1}. ${recentTitles[i]}');
        }
      }

      if (section.toString().trim().isNotEmpty) {
        sections.add(section.toString().trim());
      }
    }

    // 2. 待办任务 - 提供详细的任务列表
    final todos = context['todos'] as Map<String, dynamic>?;
    if (todos != null && todos['hasData'] == true) {
      final section = StringBuffer();
      final pendingCount = todos['pendingCount'] as int? ?? 0;
      final todayCompleted = todos['todayCompletedCount'] as int? ?? 0;
      final pendingTasks = todos['pendingTasks'] as List<dynamic>? ?? [];
      final completedTasks = todos['completedTasks'] as List<dynamic>? ?? [];
      
      section.writeln('✅ 待办任务：');
      section.writeln('- 待完成：$pendingCount 个');
      section.writeln('- 今日已完成：$todayCompleted 个');
      
      if (pendingTasks.isNotEmpty) {
        section.writeln('- 待办事项列表：');
        for (var i = 0; i < pendingTasks.length && i < 5; i++) {
          final task = pendingTasks[i] as Map<String, dynamic>;
          final title = task['title'] as String;
          final priority = task['priority'] as int? ?? 0;
          final date = task['date'] as String? ?? '';
          
          section.write('  ${i + 1}. $title');
          if (priority > 0) {
            section.write(' [优先级: $priority]');
          }
          if (date.isNotEmpty) {
            section.write(' (截止: $date)');
          }
          section.writeln();
        }
      }
      
      if (completedTasks.isNotEmpty) {
        section.writeln('- 今日已完成任务：');
        for (var i = 0; i < completedTasks.length && i < 3; i++) {
          final task = completedTasks[i] as Map<String, dynamic>;
          final title = task['title'] as String;
          section.writeln('  ${i + 1}. $title');
        }
      }

      sections.add(section.toString().trim());
    }

    // 3. 笔记记录
    final notes = context['recentNotes'] as Map<String, dynamic>?;
    if (notes != null && notes['hasData'] == true) {
      final section = StringBuffer();
      final totalCount = notes['totalCount'] as int? ?? 0;
      final todayCount = notes['todayCount'] as int? ?? 0;
      
      section.writeln('📝 笔记记录：');
      section.writeln('- 总笔记数：$totalCount 条');
      section.writeln('- 今日新增：$todayCount 条');
      sections.add(section.toString().trim());
    }

    // 4. 浏览分类统计
    final categories = context['categories'] as Map<String, dynamic>?;
    if (categories != null && categories['hasData'] == true) {
      final topCategories = categories['topCategories'] as List<dynamic>? ?? [];
      
      if (topCategories.isNotEmpty) {
        final section = StringBuffer();
        section.writeln('🔖 学习方向统计：');
        for (var i = 0; i < topCategories.length && i < 5; i++) {
          final cat = topCategories[i];
          final category = cat['category'] as String;
          final count = cat['count'] as int;
          section.writeln('  ${i + 1}. $category - 浏览了 $count 次');
        }
        sections.add(section.toString().trim());
      }
    }

    if (sections.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('【我的学习数据】');
    buffer.writeln('当前日期：$dateStr ${_getWeekday(now.weekday)}');
    buffer.writeln();
    buffer.write(sections.join('\n\n'));
    return buffer.toString().trim();
  }

  /// 获取星期几的中文名称
  String _getWeekday(int weekday) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${weekdays[weekday - 1]}';
  }

  /// 生成通用学习类
  PresetCategory _generateGeneralLearningCategory() {
    return PresetCategory(
      id: 'general_learning',
      title: '通用学习',
      description: '技术学习与知识积累',
      questions: [
        PresetQuestion(
          icon: '',
          title: '学习方法优化',
          prompt: '能给我一些提升学习效率的方法和建议吗？',
        ),
        PresetQuestion(
          icon: '',
          title: '技术难点解答',
          prompt: '我在学习中遇到了一些技术难点，需要你的帮助',
        ),
        PresetQuestion(
          icon: '',
          title: '知识点串联',
          prompt: '帮我梳理一下相关的知识点，建立系统的知识体系',
        ),
        PresetQuestion(
          icon: '',
          title: '实战项目建议',
          prompt: '推荐一些实战项目来巩固我学到的知识',
        ),
        PresetQuestion(
          icon: '',
          title: '学习资源推荐',
          prompt: '推荐一些优质的学习资源和教程',
        ),
        PresetQuestion(
          icon: '',
          title: '技术趋势分析',
          prompt: '帮我分析一下当前的技术趋势和发展方向',
        ),
      ],
    );
  }

  /// 生成效率工具类
  PresetCategory _generateProductivityCategory() {
    return PresetCategory(
      id: 'productivity',
      title: '效率工具',
      description: '提升工作和学习效率',
      questions: [
        PresetQuestion(
          icon: '',
          title: '代码优化建议',
          prompt: '帮我分析这段代码，提供优化建议',
        ),
        PresetQuestion(
          icon: '',
          title: '问题排查思路',
          prompt: '我遇到了一个 bug，帮我理清排查思路',
        ),
        PresetQuestion(
          icon: '',
          title: '文档快速总结',
          prompt: '帮我快速总结这篇技术文档的核心内容',
        ),
        PresetQuestion(
          icon: '',
          title: '任务优先级规划',
          prompt: '帮我分析任务优先级，制定高效的执行计划',
        ),
        PresetQuestion(
          icon: '',
          title: '技术选型建议',
          prompt: '我需要做技术选型，能帮我分析各方案的优劣吗？',
        ),
      ],
    );
  }

  /// 生成创意灵感类
  PresetCategory _generateCreativityCategory() {
    return PresetCategory(
      id: 'creativity',
      title: '创意灵感',
      description: '激发创意和新想法',
      questions: [
        PresetQuestion(
          icon: '',
          title: '项目创意启发',
          prompt: '我想做一个有趣的项目，给我一些创意灵感',
        ),
        PresetQuestion(
          icon: '',
          title: '功能设计建议',
          prompt: '帮我设计一个功能的实现方案和交互流程',
        ),
        PresetQuestion(
          icon: '',
          title: '技术文章写作',
          prompt: '我想写一篇技术文章，帮我理清思路和结构',
        ),
        PresetQuestion(
          icon: '',
          title: '开源项目推荐',
          prompt: '推荐一些值得学习和贡献的开源项目',
        ),
        PresetQuestion(
          icon: '',
          title: '技术演讲准备',
          prompt: '我要做技术分享，帮我准备演讲内容和大纲',
        ),
      ],
    );
  }

  /// 获取默认分类（当数据采集失败时使用）
  List<PresetCategory> _getDefaultCategories() {
    return [
      _generateGeneralLearningCategory(),
      _generateProductivityCategory(),
      _generateCreativityCategory(),
    ];
  }
}
