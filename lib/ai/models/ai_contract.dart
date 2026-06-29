import '../core/result.dart';
import 'ai_provider_config.dart';

enum AIMessageRole {
  system,
  user,
  assistant,
  tool,
}

class AIMessage {
  final AIMessageRole role;
  final String content;

  const AIMessage({
    required this.role,
    required this.content,
  });

  Map<String, String> toWire() {
    return {
      'role': role.name,
      'content': content,
    };
  }

  factory AIMessage.fromWire(Map<String, String> wire) {
    return AIMessage(
      role: AIMessageRole.values.byName(wire['role'] ?? 'user'),
      content: wire['content'] ?? '',
    );
  }
}

class AIToolCall {
  final String id;
  final String name;
  final String argumentsJson;

  const AIToolCall({
    required this.id,
    required this.name,
    required this.argumentsJson,
  });
}

class AIUsage {
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  const AIUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
  });
}

enum AIErrorType {
  config,
  network,
  api,
  timeout,
  cancelled,
  parse,
  rateLimited,
  server,
  unknown,
}

class AIErrorInfo {
  final AIErrorType type;
  final String message;
  final int? code;
  final bool retryable;
  final Object? originalError;

  const AIErrorInfo({
    required this.type,
    required this.message,
    this.code,
    this.retryable = false,
    this.originalError,
  });

  factory AIErrorInfo.fromException(AIException error) {
    if (error is ConfigException) {
      return AIErrorInfo(
        type: AIErrorType.config,
        message: error.message,
        code: error.code,
        originalError: error.originalError,
      );
    }

    if (error is CancelledException) {
      return AIErrorInfo(
        type: AIErrorType.cancelled,
        message: error.message,
        code: error.code,
        originalError: error.originalError,
      );
    }

    if (error is TimeoutException) {
      return AIErrorInfo(
        type: AIErrorType.timeout,
        message: error.message,
        code: error.code,
        retryable: true,
        originalError: error.originalError,
      );
    }

    if (error is ParseException) {
      return AIErrorInfo(
        type: AIErrorType.parse,
        message: error.message,
        code: error.code,
        originalError: error.originalError,
      );
    }

    if (error is APIException) {
      final isRateLimited = error.code == 429;
      final isServerError = (error.code ?? 0) >= 500;
      return AIErrorInfo(
        type: isRateLimited
            ? AIErrorType.rateLimited
            : (isServerError ? AIErrorType.server : AIErrorType.api),
        message: error.message,
        code: error.code,
        retryable: isRateLimited || isServerError,
        originalError: error.originalError,
      );
    }

    if (error is NetworkException) {
      return AIErrorInfo(
        type: AIErrorType.network,
        message: error.message,
        code: error.code,
        retryable: true,
        originalError: error.originalError,
      );
    }

    return AIErrorInfo(
      type: AIErrorType.unknown,
      message: error.message,
      code: error.code,
      originalError: error.originalError,
    );
  }
}

class AIRequest {
  final String requestId;
  final String scene;
  final List<AIMessage> messages;
  final int? maxTokens;
  final double? temperature;
  final bool stream;
  final DateTime createdAt;
  final AIProviderConfig? provider;
  final Map<String, Object?> metadata;

  const AIRequest({
    required this.requestId,
    required this.scene,
    required this.messages,
    this.maxTokens,
    this.temperature,
    this.stream = true,
    required this.createdAt,
    this.provider,
    this.metadata = const {},
  });

  List<Map<String, String>> toWireMessages() {
    return messages.map((message) => message.toWire()).toList();
  }

  factory AIRequest.fromWire({
    required String requestId,
    required String scene,
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
    bool stream = true,
    AIProviderConfig? provider,
    Map<String, Object?> metadata = const {},
  }) {
    return AIRequest(
      requestId: requestId,
      scene: scene,
      messages: messages.map(AIMessage.fromWire).toList(),
      maxTokens: maxTokens,
      temperature: temperature,
      stream: stream,
      createdAt: DateTime.now(),
      provider: provider,
      metadata: metadata,
    );
  }
}

class AIResponse {
  final String requestId;
  final String scene;
  final String content;
  final AIUsage? usage;
  final String? finishReason;
  final Map<String, Object?> metadata;

  const AIResponse({
    required this.requestId,
    required this.scene,
    required this.content,
    this.usage,
    this.finishReason,
    this.metadata = const {},
  });
}

enum AIStreamEventType {
  started,
  deltaText,
  toolCallRequested,
  toolCallResult,
  usageUpdated,
  retrying,
  completed,
  failed,
  cancelled,
}

class AIStreamEvent {
  final AIStreamEventType type;
  final String requestId;
  final String scene;
  final String? deltaText;
  final AIToolCall? toolCall;
  final AIUsage? usage;
  final AIResponse? response;
  final AIErrorInfo? error;

  const AIStreamEvent({
    required this.type,
    required this.requestId,
    required this.scene,
    this.deltaText,
    this.toolCall,
    this.usage,
    this.response,
    this.error,
  });

  const AIStreamEvent.started({
    required String requestId,
    required String scene,
  }) : this(
          type: AIStreamEventType.started,
          requestId: requestId,
          scene: scene,
        );

  const AIStreamEvent.deltaText({
    required String requestId,
    required String scene,
    required String deltaText,
  }) : this(
          type: AIStreamEventType.deltaText,
          requestId: requestId,
          scene: scene,
          deltaText: deltaText,
        );

  const AIStreamEvent.retrying({
    required String requestId,
    required String scene,
    required AIErrorInfo error,
  }) : this(
          type: AIStreamEventType.retrying,
          requestId: requestId,
          scene: scene,
          error: error,
        );

  const AIStreamEvent.completed({
    required String requestId,
    required String scene,
    required AIResponse response,
  }) : this(
          type: AIStreamEventType.completed,
          requestId: requestId,
          scene: scene,
          response: response,
        );

  const AIStreamEvent.failed({
    required String requestId,
    required String scene,
    required AIErrorInfo error,
  }) : this(
          type: AIStreamEventType.failed,
          requestId: requestId,
          scene: scene,
          error: error,
        );

  const AIStreamEvent.cancelled({
    required String requestId,
    required String scene,
    required AIErrorInfo error,
  }) : this(
          type: AIStreamEventType.cancelled,
          requestId: requestId,
          scene: scene,
          error: error,
        );
}
