class ChatMessage {
  final String id;
  final String content;
  final ChatRole role;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isLiked;
  
  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.status = MessageStatus.completed,
    this.isLiked = false,
  });

  factory ChatMessage.user(String content) {
    final now = DateTime.now();
    return ChatMessage(
      id: 'user_${now.millisecondsSinceEpoch}_${now.microsecond}',
      content: content,
      role: ChatRole.user,
      timestamp: now,
      status: MessageStatus.completed,
    );
  }

  factory ChatMessage.assistantPlaceholder() {
    final now = DateTime.now();
    return ChatMessage(
      id: 'ai_${now.millisecondsSinceEpoch}_${now.microsecond}',
      content: '',
      role: ChatRole.assistant,
      timestamp: now,
      status: MessageStatus.thinking,
    );
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      role: ChatRole.system,
      timestamp: DateTime.now(),
      status: MessageStatus.completed,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    ChatRole? role,
    DateTime? timestamp,
    MessageStatus? status,
    bool? isLiked,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'isLiked': isLiked,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      role: ChatRole.values.byName(json['role'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.byName(json['status'] as String),
      isLiked: (json['isLiked'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChatMessage(id: $id, role: $role, status: $status)';
}

enum ChatRole {
  user,      // 用户消息
  assistant, // AI 回复
  system,    // 系统消息（用于传递上下文）
}

/// 消息状态
enum MessageStatus {
  sending,    // 发送中
  thinking,   // AI 思考中
  streaming,  // 流式输出中
  completed,  // 完成
  error,      // 错误
}

class PresetQuestion {
  final String title;
  final String prompt;
  final String icon;

  const PresetQuestion({
    required this.title,
    required this.prompt,
    required this.icon,
  });

  static const List<PresetQuestion> defaults = [
    PresetQuestion(
      title: '总结要点',
      prompt: '请总结这篇文章的核心要点，用简洁的列表形式呈现。',
      icon: '📝',
    ),
    PresetQuestion(
      title: '深入解析',
      prompt: '请深入分析这篇文章的技术细节，解释其实现原理和关键概念。',
      icon: '🔍',
    ),
    PresetQuestion(
      title: '优缺点分析',
      prompt: '请分析文章中提到的技术方案的优缺点，以及适用场景。',
      icon: '⚖️',
    ),
    PresetQuestion(
      title: '实践建议',
      prompt: '基于这篇文章的内容，给出实际项目中的应用建议和最佳实践。',
      icon: '💡',
    ),
    PresetQuestion(
      title: '相关技术',
      prompt: '介绍与文章主题相关的其他技术和解决方案，进行对比分析。',
      icon: '🔗',
    ),
  ];
}
