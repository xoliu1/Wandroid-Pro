import 'package:flutter_test/flutter_test.dart';
import 'package:wanandroid_pro/ai/services/ai_prompt_manager.dart';
import 'package:wanandroid_pro/ai/services/ai_service.dart';
import 'package:wanandroid_pro/ai/models/article_content.dart';
import 'package:wanandroid_pro/local/KV.dart';

void main() {
  group('AIPromptManager', () {
    test('应该包含 prompt channel 和 version 元信息', () {
      final prompt = AIPromptManager.buildSystemPrompt(
        channel: kPromptChannelDailyReport,
        scene: 'daily_report',
        sections: const ['规则区块'],
      );

      expect(prompt, contains('[prompt_channel=prompt_daily_report]'));
      expect(prompt, contains('[prompt_version=v1]'));
      expect(prompt, contains('[scene=daily_report]'));
      expect(prompt, contains('规则区块'));
    });
  });

  group('AIContextManager', () {
    test('应该裁剪超长文本并标记 truncated', () {
      final compacted = AIContextManager.compactText('a' * 20, maxChars: 8);

      expect(compacted, startsWith('aaaaaaaa'));
      expect(compacted, contains('[truncated:12]'));
    });

    test('应该保留最近历史并控制 token 预算', () {
      final history = List.generate(6, (index) {
        return {
          'role': index.isEven ? 'user' : 'assistant',
          'content': '消息$index ' * 30,
        };
      });

      final trimmed = AIContextManager.trimHistory(
        history,
        maxMessages: 4,
        maxTokens: 80,
      );

      expect(trimmed.length, lessThanOrEqualTo(4));
      expect(trimmed.last['content'], contains('消息5'));
      expect(trimmed.any((message) => message['content']!.contains('消息0')), false);
    });
  });

  group('AIService message builders', () {
    test('文章聊天消息应该使用统一 prompt 和裁剪后的历史', () {
      final article = ArticleContent.create(
        title: 'Flutter Riverpod 实战',
        content: '正文' * 3000,
        url: 'https://example.com/flutter',
        platform: 'WanAndroid',
      );

      final history = List.generate(12, (index) {
        return {
          'role': index.isEven ? 'user' : 'assistant',
          'content': '历史消息$index ' * 50,
        };
      });

      final messages = AIService.buildMessagesWithArticle(
        article: article,
        userQuestion: '帮我总结这篇文章',
        history: history,
      );

      expect(messages.first['role'], 'system');
      expect(messages.first['content'], contains('[prompt_channel=prompt_article_chat]'));
      expect(messages.first['content'], contains('Flutter Riverpod 实战'));
      expect(messages.first['content'], contains('[truncated:'));
      expect(messages.last['content'], '帮我总结这篇文章');
      expect(messages.length, lessThan(history.length + 2));
    });

    test('日报消息应该使用安全上下文和版本化 prompt', () {
      final messages = AIService.buildDailyReportMessages(
        dailyData: '今天阅读了 3 篇文章，完成了 2 个 TODO。',
        userContext: 'token=sk-1234567890abcdef Bearer abcdefghijklmnop',
      );

      expect(messages.first['content'], contains('[prompt_channel=prompt_daily_report]'));
      expect(messages.first['content'], contains('[redacted-key]'));
      expect(messages.first['content'], contains('Bearer [redacted]'));
      expect(messages.last['content'], contains('今天阅读了 3 篇文章'));
    });
  });
}
