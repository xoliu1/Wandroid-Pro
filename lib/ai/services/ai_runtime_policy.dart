class AIStreamRuntimePolicy {
  final Duration firstTokenTimeout;
  final Duration completionTimeout;
  final int defaultMaxRetries;
  final bool cacheable;
  final Duration cacheTtl;

  const AIStreamRuntimePolicy({
    required this.firstTokenTimeout,
    required this.completionTimeout,
    this.defaultMaxRetries = 0,
    this.cacheable = false,
    this.cacheTtl = Duration.zero,
  });
}

class AIRuntimePolicyRegistry {
  AIRuntimePolicyRegistry._();

  static const AIStreamRuntimePolicy _defaultPolicy = AIStreamRuntimePolicy(
    firstTokenTimeout: Duration(seconds: 20),
    completionTimeout: Duration(minutes: 2),
    defaultMaxRetries: 1,
  );

  static const Map<String, AIStreamRuntimePolicy> _scenePolicies = {
    'article_chat': AIStreamRuntimePolicy(
      firstTokenTimeout: Duration(seconds: 15),
      completionTimeout: Duration(minutes: 2),
      defaultMaxRetries: 1,
    ),
    'plain_chat': AIStreamRuntimePolicy(
      firstTokenTimeout: Duration(seconds: 15),
      completionTimeout: Duration(minutes: 2),
      defaultMaxRetries: 1,
    ),
    'daily_question_explanation': AIStreamRuntimePolicy(
      firstTokenTimeout: Duration(seconds: 12),
      completionTimeout: Duration(minutes: 2),
      defaultMaxRetries: 1,
      cacheable: true,
      cacheTtl: Duration(minutes: 15),
    ),
    'daily_report': AIStreamRuntimePolicy(
      firstTokenTimeout: Duration(seconds: 12),
      completionTimeout: Duration(minutes: 2),
      defaultMaxRetries: 1,
    ),
    'weekly_report': AIStreamRuntimePolicy(
      firstTokenTimeout: Duration(seconds: 12),
      completionTimeout: Duration(minutes: 2),
      defaultMaxRetries: 1,
    ),
    'todo_daily_suggestion': AIStreamRuntimePolicy(
      firstTokenTimeout: Duration(seconds: 12),
      completionTimeout: Duration(minutes: 2),
      defaultMaxRetries: 1,
    ),
    'todo_breakdown': AIStreamRuntimePolicy(
      firstTokenTimeout: Duration(seconds: 12),
      completionTimeout: Duration(minutes: 2),
      defaultMaxRetries: 1,
    ),
  };

  static AIStreamRuntimePolicy forScene(String scene) {
    return _scenePolicies[scene] ?? _defaultPolicy;
  }
}
