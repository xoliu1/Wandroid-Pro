import 'chat_message.dart';

class ChatHistory {
  final int? id;
  final String articleUrl;      // 文章URL（作为唯一标识）
  final String articleTitle;    // 文章标题
  final String? articleAuthor;  // 文章作者
  final List<ChatMessage> messages; // 对话消息列表
  final DateTime createdAt;     // 创建时间
  final DateTime updatedAt;     // 更新时间

  ChatHistory({
    this.id,
    required this.articleUrl,
    required this.articleTitle,
    this.articleAuthor,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'article_url': articleUrl,
      'article_title': articleTitle,
      'article_author': articleAuthor,
      'messages': messages.map((m) => m.toJson()).toList(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  ChatHistory copyWith({
    int? id,
    String? articleUrl,
    String? articleTitle,
    String? articleAuthor,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatHistory(
      id: id ?? this.id,
      articleUrl: articleUrl ?? this.articleUrl,
      articleTitle: articleTitle ?? this.articleTitle,
      articleAuthor: articleAuthor ?? this.articleAuthor,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
