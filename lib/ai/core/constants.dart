class AIConstants {
  AIConstants._();

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 2);
  static const Duration sendTimeout = Duration(seconds: 15);

  static const int defaultMaxTokens = 2000;
  static const int maxContextTokens = 8000;

  static const Duration contentCacheDuration = Duration(hours: 24);
  static const Duration configCacheDuration = Duration(days: 7);

  static const double defaultTemperature = 0.7;
  static const int maxRetryCount = 3;

  static const String chatCompletionsPath = '/chat/completions';

  static const String errorInvalidApiKey = 'API Key 无效或已过期';
  static const String errorRateLimited = '请求频率过高，请稍后再试';
  static const String errorServerError = 'AI 服务暂时不可用';
  static const String errorNetworkFailed = '网络连接失败，请检查网络或 API 地址';
  static const String errorTimeout = '请求超时，请检查网络连接';
  static const String errorCancelled = '请求已取消';
  static const String errorUnknown = '未知错误';

  static const String tagService = 'AIService';
  static const String tagProvider = 'AIProvider';
  static const String tagRepository = 'AIRepository';
  static const String tagExtractor = 'ContentExtractor';
}

enum AIProviderType {
  openai('OpenAI', 'openai.com'),
  anthropic('Claude', 'anthropic.com'),
  gemini('Gemini', 'generativelanguage.googleapis.com'),
  zhipu('智谱AI', 'bigmodel.cn'),
  qwen('通义千问', 'dashscope.aliyuncs.com'),
  deepseek('DeepSeek', 'deepseek.com'),
  moonshot('Kimi/Moonshot', 'moonshot.cn'),
  minimax('MiniMax', 'minimax.chat'),
  doubao('豆包', 'volces.com'),
  siliconflow('硅基流动', 'siliconflow.cn'),
  grok('Grok', 'x.ai'),
  custom('自定义', '');

  final String displayName;
  final String urlPattern;

  const AIProviderType(this.displayName, this.urlPattern);

  static AIProviderType fromUrl(String url) {
    for (final type in AIProviderType.values) {
      if (type.urlPattern.isNotEmpty && url.contains(type.urlPattern)) {
        return type;
      }
    }
    return AIProviderType.custom;
  }
}

enum CachePolicy {
  noCache,
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
}
