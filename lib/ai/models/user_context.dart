import 'dart:convert';

/// 待办摘要（用于 AI 上下文）
class TodoSummary {
  final String title;
  final String content;
  final int priority;
  final String dateStr;

  TodoSummary({
    required this.title,
    required this.content,
    required this.priority,
    required this.dateStr,
  });

  String get priorityLabel => priority >= 2 ? '高' : priority == 1 ? '中' : '低';

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'priority': priority,
    'dateStr': dateStr,
  };

  factory TodoSummary.fromJson(Map<String, dynamic> json) => TodoSummary(
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    priority: json['priority'] ?? 0,
    dateStr: json['dateStr'] ?? '',
  );
}

/// 用户上下文数据模型
/// 
/// 用于 AI 功能的用户画像数据，包含收藏文章、笔记、待办、对话主题等信息。
/// 在 App 启动时后台采集，全局可用。
class UserContext {
  /// 用户名
  final String username;
  /// 用户 ID
  final int userId;
  /// 用户等级
  final int level;
  /// 积分
  final int coinCount;
  
  /// 收藏文章标题（最近 20 篇）
  final List<String> collectTitles;
  
  /// 笔记摘要（最近 10 条，取前 50 字）
  final List<String> noteSummaries;
  
  /// 待办列表（当前未完成的）
  final List<TodoSummary> pendingTodos;
  
  /// AI 对话主题（最近 10 个对话标题）
  final List<String> chatTopics;
  
  /// 最近浏览的文章标题（最近 15 篇，去重）
  final List<String> browsingTitles;
  
  /// 采集时间
  final DateTime collectedAt;

  UserContext({
    required this.username,
    required this.userId,
    required this.level,
    required this.coinCount,
    required this.collectTitles,
    required this.noteSummaries,
    required this.pendingTodos,
    required this.chatTopics,
    required this.browsingTitles,
    required this.collectedAt,
  });

  /// 转为 AI prompt 可用的文本摘要
  /// 
  /// 注意：browsingTitles 是历史浏览偏好（非今日），
  /// 今日浏览记录由 _collectDailyData() 单独采集传入 dailyData。
  String toPromptSummary() {
    final buffer = StringBuffer();
    buffer.writeln('用户: $username (等级$level, 积分$coinCount)');
    
    if (collectTitles.isNotEmpty) {
      buffer.writeln('\n【历史收藏偏好】（反映长期兴趣方向）:');
      for (final t in collectTitles.take(10)) {
        buffer.writeln('- $t');
      }
    }
    
    if (noteSummaries.isNotEmpty) {
      buffer.writeln('\n【笔记知识库】（反映用户的知识积累）:');
      for (final n in noteSummaries.take(5)) {
        buffer.writeln('- $n');
      }
    }
    
    if (pendingTodos.isNotEmpty) {
      buffer.writeln('\n【当前待办】:');
      for (final t in pendingTodos) {
        buffer.writeln('- [${t.priorityLabel}] ${t.title}${t.content.isNotEmpty ? ": ${t.content}" : ""}');
      }
    }
    
    if (chatTopics.isNotEmpty) {
      buffer.writeln('\n【近期 AI 对话主题】（反映近期关注点）:');
      for (final c in chatTopics.take(5)) {
        buffer.writeln('- $c');
      }
    }
    
    if (browsingTitles.isNotEmpty) {
      // 注意：这是历史浏览偏好，不含今日浏览（今日浏览在 dailyData 中单独列出）
      buffer.writeln('\n【历史浏览偏好】（近期阅读倾向，不含今日）:');
      for (final b in browsingTitles.take(10)) {
        buffer.writeln('- $b');
      }
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'userId': userId,
    'level': level,
    'coinCount': coinCount,
    'collectTitles': collectTitles,
    'noteSummaries': noteSummaries,
    'pendingTodos': pendingTodos.map((t) => t.toJson()).toList(),
    'chatTopics': chatTopics,
    'browsingTitles': browsingTitles,
    'collectedAt': collectedAt.millisecondsSinceEpoch,
  };

  factory UserContext.fromJson(Map<String, dynamic> json) => UserContext(
    username: json['username'] ?? '',
    userId: json['userId'] ?? 0,
    level: json['level'] ?? 0,
    coinCount: json['coinCount'] ?? 0,
    collectTitles: List<String>.from(json['collectTitles'] ?? []),
    noteSummaries: List<String>.from(json['noteSummaries'] ?? []),
    pendingTodos: (json['pendingTodos'] as List<dynamic>?)
        ?.map((e) => TodoSummary.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    chatTopics: List<String>.from(json['chatTopics'] ?? []),
    browsingTitles: List<String>.from(json['browsingTitles'] ?? []),
    collectedAt: DateTime.fromMillisecondsSinceEpoch(json['collectedAt'] ?? 0),
  );

  String toJsonString() => jsonEncode(toJson());

  factory UserContext.fromJsonString(String jsonStr) =>
      UserContext.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  /// 空的上下文（用于降级场景）
  factory UserContext.empty() => UserContext(
    username: '',
    userId: 0,
    level: 0,
    coinCount: 0,
    collectTitles: [],
    noteSummaries: [],
    pendingTodos: [],
    chatTopics: [],
    browsingTitles: [],
    collectedAt: DateTime.now(),
  );

  bool get isEmpty => collectTitles.isEmpty && noteSummaries.isEmpty && pendingTodos.isEmpty && chatTopics.isEmpty && browsingTitles.isEmpty;
}
