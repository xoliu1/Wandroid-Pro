import 'package:flutter_test/flutter_test.dart';
import 'package:wanandroid_pro/ai/core/result.dart';
import 'package:wanandroid_pro/ai/services/ai_response_validator.dart';
import 'package:wanandroid_pro/ai/services/ai_schema_catalog.dart';

void main() {
  group('AIResponseValidator', () {
    test('应该清理 markdown code fence', () {
      final cleaned = AIResponseValidator.cleanJsonEnvelope('''```json
{"overview":"ok"}
```''');

      expect(cleaned, '{"overview":"ok"}');
    });

    test('有效 JSON 应该解析成功', () {
      final result = AIResponseValidator.validateJsonObject<Map<String, dynamic>>(
        raw: '{"overview":"今天不错","suggestions":["继续保持"]}',
        requiredKeys: const ['overview', 'suggestions'],
        parser: (json) => json,
      );

      expect(result, isA<Success<Map<String, dynamic>>>());
      expect(result.dataOrNull?['overview'], '今天不错');
    });

    test('缺少必要字段应该返回 Failure', () {
      final result = AIResponseValidator.validateJsonObject<Map<String, dynamic>>(
        raw: '{"overview":"今天不错"}',
        requiredKeys: const ['overview', 'suggestions'],
        parser: (json) => json,
      );

      expect(result, isA<Failure<Map<String, dynamic>>>());
      expect(result.errorOrNull?.message, contains('缺少必要字段'));
    });

    test('schema 类型不匹配应该返回 Failure', () {
      final result = AIResponseValidator.validateJsonObject<Map<String, dynamic>>(
        raw: '{"overview":"今天不错","suggestions":"继续保持"}',
        parser: (json) => json,
        schema: AISchemaCatalog.dailyReport,
      );

      expect(result, isA<Failure<Map<String, dynamic>>>());
      expect(result.errorOrNull?.message, contains('类型不匹配'));
    });

    test('非对象 JSON 应该返回 Failure', () {
      final result = AIResponseValidator.validateJsonObject<List<dynamic>>(
        raw: '["a", "b"]',
        parser: (json) => json.values.toList(),
      );

      expect(result, isA<Failure<List<dynamic>>>());
      expect(result.errorOrNull?.message, contains('不是 JSON 对象'));
    });
  });
}
