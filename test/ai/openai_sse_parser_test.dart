import 'package:flutter_test/flutter_test.dart';
import 'package:wanandroid_pro/ai/repositories/openai_sse_parser.dart';

void main() {
  group('OpenAISSEParser', () {
    test('应该忽略 malformed SSE chunk 并继续提取合法 delta', () {
      final raw = [
        'data: {"choices":[{"delta":{"content":"你"}}]}',
        'data: {bad json',
        'data: {"choices":[{"delta":{"content":"好"}}]}',
        '',
      ].join('\n');

      final result = OpenAISSEParser.parse(raw);

      expect(result.deltas, ['你', '好']);
      expect(result.remainingBuffer, '');
      expect(result.sawDone, false);
    });

    test('应该忽略 empty delta 并保留剩余 buffer', () {
      final raw = [
        'data: {"choices":[{"delta":{"content":""}}]}',
        'data: {"choices":[{"delta":{}}]}',
        'data: {"choices":[{"delta":{"content":"A"}}]}',
        'data: {"choices":[{"delta":{"content":"partial"}}]}',
      ].join('\n');

      final result = OpenAISSEParser.parse(raw);

      expect(result.deltas, ['A']);
      expect(
        result.remainingBuffer,
        'data: {"choices":[{"delta":{"content":"partial"}}]}',
      );
    });

    test('应该识别 DONE 标记', () {
      const raw = 'data: [DONE]\n';

      final result = OpenAISSEParser.parse(raw);

      expect(result.sawDone, true);
      expect(result.deltas, isEmpty);
      expect(result.remainingBuffer, '');
    });
  });
}
