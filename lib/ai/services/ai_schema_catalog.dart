enum AIJsonValueType {
  string,
  number,
  boolean,
  object,
  array,
}

class AIJsonFieldRule {
  final AIJsonValueType type;
  final bool nullable;

  const AIJsonFieldRule({
    required this.type,
    this.nullable = false,
  });
}

class AISchemaDefinition {
  final String id;
  final String version;
  final List<String> requiredKeys;
  final Map<String, AIJsonFieldRule> fieldRules;

  const AISchemaDefinition({
    required this.id,
    required this.version,
    required this.requiredKeys,
    this.fieldRules = const {},
  });

  String get fullName => '${id}_$version';
}

class AISchemaCatalog {
  AISchemaCatalog._();

  static const dailyReport = AISchemaDefinition(
    id: 'daily_report',
    version: 'v1',
    requiredKeys: ['overview', 'suggestions'],
    fieldRules: {
      'overview': AIJsonFieldRule(type: AIJsonValueType.string),
      'reading': AIJsonFieldRule(type: AIJsonValueType.object, nullable: true),
      'todos': AIJsonFieldRule(type: AIJsonValueType.object, nullable: true),
      'notes': AIJsonFieldRule(type: AIJsonValueType.object, nullable: true),
      'suggestions': AIJsonFieldRule(type: AIJsonValueType.array),
    },
  );

  static const weeklyReport = AISchemaDefinition(
    id: 'weekly_report',
    version: 'v1',
    requiredKeys: ['overview', 'week_range', 'next_week_goals'],
    fieldRules: {
      'overview': AIJsonFieldRule(type: AIJsonValueType.string),
      'week_range': AIJsonFieldRule(type: AIJsonValueType.string),
      'reading': AIJsonFieldRule(type: AIJsonValueType.object, nullable: true),
      'todos': AIJsonFieldRule(type: AIJsonValueType.object, nullable: true),
      'notes': AIJsonFieldRule(type: AIJsonValueType.object, nullable: true),
      'growth': AIJsonFieldRule(type: AIJsonValueType.object, nullable: true),
      'next_week_goals': AIJsonFieldRule(type: AIJsonValueType.array),
    },
  );

  static const todoSuggestion = AISchemaDefinition(
    id: 'todo_suggestion',
    version: 'v1',
    requiredKeys: ['type', 'summary', 'items'],
    fieldRules: {
      'type': AIJsonFieldRule(type: AIJsonValueType.string),
      'summary': AIJsonFieldRule(type: AIJsonValueType.string),
      'items': AIJsonFieldRule(type: AIJsonValueType.array),
    },
  );
}
