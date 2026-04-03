class ArticleContent {
  String get id => url;

  final String title;
  final String content;
  final String? author;
  final String? publishTime;
  final String url;
  final String platform;
  final DateTime extractTime;
  
  const ArticleContent({
    required this.title,
    required this.content,
    this.author,
    this.publishTime,
    required this.url,
    required this.platform,
    required this.extractTime,
  });

  factory ArticleContent.create({
    required String title,
    required String content,
    String? author,
    String? publishTime,
    required String url,
    required String platform,
  }) {
    return ArticleContent(
      title: title,
      content: content,
      author: author,
      publishTime: publishTime,
      url: url,
      platform: platform,
      extractTime: DateTime.now(),
    );
  }

  bool get isValid => title.isNotEmpty && content.isNotEmpty;

  String get summary {
    if (content.length <= 200) return content;
    return '${content.substring(0, 200)}...';
  }

  int get wordCount => content.length;

  int get estimatedTokens {
    final chineseChars = content.split('').where((c) {
      final code = c.codeUnitAt(0);
      return code >= 0x4E00 && code <= 0x9FFF;
    }).length;
    
    final otherChars = content.length - chineseChars;
    
    return chineseChars + (otherChars / 2).ceil();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'author': author,
      'publishTime': publishTime,
      'url': url,
      'platform': platform,
      'extractTime': extractTime.toIso8601String(),
    };
  }
  
  /// 从 JSON 创建
  factory ArticleContent.fromJson(Map<String, dynamic> json) {
    return ArticleContent(
      title: json['title'] as String,
      content: json['content'] as String,
      author: json['author'] as String?,
      publishTime: json['publishTime'] as String?,
      url: json['url'] as String,
      platform: json['platform'] as String,
      extractTime: DateTime.parse(json['extractTime'] as String),
    );
  }

  ArticleContent copyWith({
    String? title,
    String? content,
    String? author,
    String? publishTime,
    String? url,
    String? platform,
    DateTime? extractTime,
  }) {
    return ArticleContent(
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      publishTime: publishTime ?? this.publishTime,
      url: url ?? this.url,
      platform: platform ?? this.platform,
      extractTime: extractTime ?? this.extractTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleContent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ArticleContent(title: $title, platform: $platform, wordCount: $wordCount)';
  }
}
