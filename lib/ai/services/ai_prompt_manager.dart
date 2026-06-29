import '../core/constants.dart';
import '../models/article_content.dart';
import '../../local/KV.dart';

class AIPromptProfile {
  final String channel;
  final String version;
  final String content;
  final bool isCustom;

  const AIPromptProfile({
    required this.channel,
    required this.version,
    required this.content,
    required this.isCustom,
  });
}

class AIPromptManager {
  AIPromptManager._();

  static const Map<String, String> _promptVersions = {
    kPromptChannelDailyReport: 'v1',
    kPromptChannelArticleChat: 'v1',
    kPromptChannelTodoAssistant: 'v1',
    kPromptChannelNoteContinue: 'v1',
    kPromptChannelNotePolish: 'v1',
    kPromptChannelQuestionExplain: 'v1',
  };

  static AIPromptProfile profile(String channel) {
    return AIPromptProfile(
      channel: channel,
      version: _promptVersions[channel] ?? 'v1',
      content: getEffectivePrompt(channel),
      isCustom: hasCustomPrompt(channel),
    );
  }

  static String buildSystemPrompt({
    required String channel,
    String? scene,
    List<String> sections = const [],
  }) {
    final prompt = profile(channel);
    final buffer = StringBuffer();
    buffer.writeln(prompt.content.trim());
    buffer.writeln();
    buffer.writeln('[prompt_channel=${prompt.channel}]');
    buffer.writeln('[prompt_version=${prompt.version}]');

    if (scene != null && scene.isNotEmpty) {
      buffer.writeln('[scene=$scene]');
    }

    for (final section in sections) {
      final trimmed = section.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      buffer.writeln();
      buffer.writeln(trimmed);
    }

    return buffer.toString().trim();
  }
}

class AIContextManager {
  AIContextManager._();

  static String compactText(
    String text, {
    int maxChars = 4000,
  }) {
    final normalized = text.trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars)}\n\n[truncated:${normalized.length - maxChars}]';
  }

  static String safeContext(
    String? text, {
    int maxChars = 1600,
  }) {
    if (text == null || text.trim().isEmpty) {
      return '';
    }
    return compactText(_redactSecrets(text), maxChars: maxChars);
  }

  static String buildArticleContext(
    ArticleContent article, {
    int maxChars = 5000,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('文章标题：${article.title}');

    if (article.author != null && article.author!.isNotEmpty) {
      buffer.writeln('作者：${article.author}');
    }

    buffer.writeln('来源：${article.platform}');
    buffer.writeln('链接：${article.url}');

    if (article.publishTime != null && article.publishTime!.isNotEmpty) {
      buffer.writeln('发布时间：${article.publishTime}');
    }

    buffer.writeln();
    buffer.writeln('正文内容：');
    buffer.writeln(compactText(article.content, maxChars: maxChars));

    return buffer.toString().trim();
  }

  static List<Map<String, String>> trimHistory(
    List<Map<String, String>> history, {
    int maxTokens = AIConstants.maxContextTokens ~/ 2,
    int maxMessages = 8,
  }) {
    if (history.isEmpty) {
      return const [];
    }

    final trimmed = history.length <= maxMessages
        ? List<Map<String, String>>.from(history)
        : List<Map<String, String>>.from(history.skip(history.length - maxMessages));

    var totalTokens = 0;
    final selected = <Map<String, String>>[];

    for (var i = trimmed.length - 1; i >= 0; i--) {
      final message = Map<String, String>.from(trimmed[i]);
      final tokens = estimateTokens(message['content'] ?? '');
      if (selected.isNotEmpty && totalTokens + tokens > maxTokens) {
        break;
      }
      selected.insert(0, message);
      totalTokens += tokens;
    }

    return selected;
  }

  static int estimateTokens(String text) {
    final chineseCount = text.runes.where((r) => r > 0x4E00 && r < 0x9FA5).length;
    final otherCount = text.length - chineseCount;
    return (chineseCount * 1.5 + otherCount / 4).ceil();
  }

  static String _redactSecrets(String value) {
    return value
        .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9._\-]+', caseSensitive: false), 'Bearer [redacted]')
        .replaceAll(RegExp(r'(sk|rk)-[A-Za-z0-9_\-]{8,}', caseSensitive: false), '[redacted-key]');
  }
}
