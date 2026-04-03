import 'dart:convert';

/// AI TODO 建议项
class AISuggestionItem {
  /// 建议的任务标题
  final String title;
  /// 任务详细描述
  final String content;
  /// 优先级：0=低, 1=中, 2=高
  final int priority;
  /// 推荐理由
  final String reason;

  AISuggestionItem({
    required this.title,
    required this.content,
    required this.priority,
    required this.reason,
  });

  String get priorityLabel {
    switch (priority) {
      case 2: return '高';
      case 1: return '中';
      default: return '低';
    }
  }

  factory AISuggestionItem.fromJson(Map<String, dynamic> json) => AISuggestionItem(
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    priority: json['priority'] ?? 0,
    reason: json['reason'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'priority': priority,
    'reason': reason,
  };
}

/// AI TODO 建议响应
class AITodoSuggestion {
  /// 类型：goal_breakdown / daily_suggestions
  final String type;
  /// 概述
  final String summary;
  /// 建议项列表
  final List<AISuggestionItem> items;

  AITodoSuggestion({
    required this.type,
    required this.summary,
    required this.items,
  });

  factory AITodoSuggestion.fromJson(Map<String, dynamic> json) => AITodoSuggestion(
    type: json['type'] ?? '',
    summary: json['summary'] ?? '',
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => AISuggestionItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );

  /// 从 AI 返回的原始文本中解析 JSON
  /// AI 可能返回带有 markdown 代码块标记的 JSON，需要清理
  static AITodoSuggestion? tryParse(String rawText) {
    try {
      // 尝试清理 markdown 代码块标记
      var cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return AITodoSuggestion.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'summary': summary,
    'items': items.map((e) => e.toJson()).toList(),
  };
}
