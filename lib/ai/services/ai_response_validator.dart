import 'dart:convert';

import '../core/result.dart';
import 'ai_schema_catalog.dart';

class AIResponseValidator {
  AIResponseValidator._();

  static String cleanJsonEnvelope(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z0-9_-]*\n?'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
    }
    return cleaned.trim();
  }

  static Result<T> validateJsonObject<T>({
    required String raw,
    required T Function(Map<String, dynamic> json) parser,
    List<String> requiredKeys = const [],
    AISchemaDefinition? schema,
  }) {
    try {
      final cleaned = cleanJsonEnvelope(raw);
      final decoded = _decodeMap(cleaned);

      final effectiveRequiredKeys = schema?.requiredKeys ?? requiredKeys;
      for (final key in effectiveRequiredKeys) {
        if (!decoded.containsKey(key)) {
          return Failure(
            ParseException('缺少必要字段: $key'),
          );
        }
      }

      if (schema != null) {
        final schemaValidation = _validateSchema(decoded, schema);
        if (schemaValidation != null) {
          return Failure(schemaValidation);
        }
      }

      return Success(parser(decoded));
    } catch (e) {
      if (e is AIException) {
        return Failure(e);
      }
      return Failure(ParseException('JSON 解析失败: $e', originalError: e));
    }
  }

  static Map<String, dynamic> _decodeMap(String cleaned) {
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map<String, dynamic>) {
      throw const ParseException('返回结果不是 JSON 对象');
    }
    return decoded;
  }

  static ParseException? _validateSchema(
    Map<String, dynamic> decoded,
    AISchemaDefinition schema,
  ) {
    for (final entry in schema.fieldRules.entries) {
      final key = entry.key;
      final rule = entry.value;
      if (!decoded.containsKey(key)) {
        continue;
      }

      final value = decoded[key];
      if (value == null) {
        if (!rule.nullable) {
          return ParseException('字段 $key 不允许为 null');
        }
        continue;
      }

      if (!_matchesType(value, rule.type)) {
        return ParseException('字段 $key 类型不匹配，期望 ${rule.type.name}');
      }
    }
    return null;
  }

  static bool _matchesType(dynamic value, AIJsonValueType type) {
    return switch (type) {
      AIJsonValueType.string => value is String,
      AIJsonValueType.number => value is num,
      AIJsonValueType.boolean => value is bool,
      AIJsonValueType.object => value is Map<String, dynamic>,
      AIJsonValueType.array => value is List,
    };
  }
}
