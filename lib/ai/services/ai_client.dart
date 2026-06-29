import 'dart:convert';

import '../core/constants.dart';
import '../core/diagnostics.dart';
import '../core/logger.dart';
import '../core/response_cache.dart';
import '../core/result.dart';
import '../models/ai_contract.dart';
import '../models/ai_provider_config.dart';
import 'ai_response_validator.dart';
import 'ai_runtime_policy.dart';
import 'ai_service.dart';

class AIClient {
  AIClient(
    this.config, {
    AIService? service,
  }) : _service = service ?? AIService(config);

  final AIProviderConfig config;
  final AIService _service;

  Stream<AIStreamEvent> sendStream({
    required String scene,
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
    int? maxRetries,
    Map<String, Object?> metadata = const {},
  }) async* {
    final policy = AIRuntimePolicyRegistry.forScene(scene);
    final effectiveMaxRetries = maxRetries ?? policy.defaultMaxRetries;
    final cacheKey = policy.cacheable
        ? _buildCacheKey(
            scene: scene,
            messages: messages,
            maxTokens: maxTokens,
            temperature: temperature,
          )
        : null;
    final cachedResponse = cacheKey == null
        ? null
        : AIResponseCacheStore.instance.get(cacheKey);

    if (cachedResponse != null) {
      final requestId = AIService.createRequestId(scene);
      AIDiagnosticsStore.instance.record(
        scene: scene,
        level: 'info',
        message: 'cache hit',
        metadata: {
          ...metadata,
          'providerId': config.id,
          'modelId': config.modelId,
          'cacheHit': true,
        },
      );
      yield AIStreamEvent.started(
        requestId: requestId,
        scene: scene,
      );
      yield AIStreamEvent.completed(
        requestId: requestId,
        scene: scene,
        response: AIResponse(
          requestId: requestId,
          scene: scene,
          content: cachedResponse.content,
          usage: cachedResponse.usage,
          finishReason: cachedResponse.finishReason,
          metadata: {
            ...cachedResponse.metadata,
            'cacheHit': true,
          },
        ),
      );
      return;
    }

    var attempt = 0;

    while (true) {
      final startedAt = DateTime.now();
      var receivedContent = false;
      var firstTokenLatencyMs = 0;
      final request = AIRequest.fromWire(
        requestId: AIService.createRequestId(scene),
        scene: scene,
        messages: messages,
        maxTokens: maxTokens,
        temperature: temperature,
        provider: config,
        metadata: {
          ...metadata,
          'attempt': attempt + 1,
          'providerId': config.id,
          'modelId': config.modelId,
          'startedAt': startedAt.toIso8601String(),
          'firstTokenTimeoutMs': policy.firstTokenTimeout.inMilliseconds,
          'completionTimeoutMs': policy.completionTimeout.inMilliseconds,
        },
      );

      AIDiagnosticsStore.instance.record(
        scene: scene,
        level: 'info',
        message: 'start request',
        metadata: request.metadata,
      );

      AIStreamEvent? terminalEvent;

      final sourceStream = _service.sendRequestStream(request: request).timeout(
        policy.firstTokenTimeout,
        onTimeout: (sink) {
          if (!receivedContent) {
            sink.add(
              AIStreamEvent.failed(
                requestId: request.requestId,
                scene: request.scene,
                error: const AIErrorInfo(
                  type: AIErrorType.timeout,
                  message: '首个响应超时，请稍后重试',
                  retryable: true,
                ),
              ),
            );
            sink.close();
          }
        },
      );

      await for (final event in sourceStream) {
        final elapsed = DateTime.now().difference(startedAt);
        if (elapsed > policy.completionTimeout &&
            event.type != AIStreamEventType.completed &&
            event.type != AIStreamEventType.failed &&
            event.type != AIStreamEventType.cancelled) {
          terminalEvent = AIStreamEvent.failed(
            requestId: request.requestId,
            scene: request.scene,
            error: const AIErrorInfo(
              type: AIErrorType.timeout,
              message: '响应超时，请稍后重试',
              retryable: true,
            ),
          );
          break;
        }

        if (!receivedContent &&
            (event.type == AIStreamEventType.deltaText ||
                event.type == AIStreamEventType.completed)) {
          receivedContent = true;
          firstTokenLatencyMs = elapsed.inMilliseconds;
        }

        if (event.type == AIStreamEventType.failed ||
            event.type == AIStreamEventType.cancelled) {
          terminalEvent = event;
          break;
        }

        if (event.type == AIStreamEventType.completed) {
          if (cacheKey != null) {
            AIResponseCacheStore.instance.put(
              cacheKey,
              event.response!,
              ttl: policy.cacheTtl,
            );
          }

          AIDiagnosticsStore.instance.record(
            scene: scene,
            level: 'success',
            message: 'request completed',
            metadata: {
              ...request.metadata,
              'responseLength': event.response?.content.length ?? 0,
              'latencyMs': elapsed.inMilliseconds,
              'firstTokenLatencyMs': firstTokenLatencyMs,
              'retryCount': attempt,
              'cacheHit': false,
            },
          );
        }

        yield event;
      }

      if (terminalEvent == null) {
        return;
      }

      if (terminalEvent.type == AIStreamEventType.cancelled) {
        AIDiagnosticsStore.instance.record(
          scene: scene,
          level: 'warning',
          message: 'request cancelled',
          metadata: {
            ...request.metadata,
            'latencyMs': DateTime.now().difference(startedAt).inMilliseconds,
            'retryCount': attempt,
          },
        );
        yield terminalEvent;
        return;
      }

      final error = terminalEvent.error;
      final canRetry = error?.retryable == true && attempt < effectiveMaxRetries;
      if (canRetry) {
        attempt++;
        AILogger.warning(
          '请求失败，准备重试 scene=$scene attempt=${attempt + 1}',
          tag: AIConstants.tagService,
        );
        AIDiagnosticsStore.instance.record(
          scene: scene,
          level: 'warning',
          message: 'retry request',
          metadata: {
            ...request.metadata,
            'reason': error?.message,
            'nextAttempt': attempt + 1,
            'latencyMs': DateTime.now().difference(startedAt).inMilliseconds,
          },
        );
        yield AIStreamEvent.retrying(
          requestId: request.requestId,
          scene: request.scene,
          error: error!,
        );
        continue;
      }

      AIDiagnosticsStore.instance.record(
        scene: scene,
        level: 'error',
        message: error?.message ?? AIConstants.errorUnknown,
        metadata: {
          ...request.metadata,
          'latencyMs': DateTime.now().difference(startedAt).inMilliseconds,
          'retryCount': attempt,
          'errorType': error?.type.name,
          'errorCode': error?.code,
        },
      );
      yield terminalEvent;
      return;
    }
  }

  Future<Result<T>> repairStructuredJson<T>({
    required String scene,
    required List<Map<String, String>> originalMessages,
    required String invalidOutput,
    required Result<T> Function(String raw) validator,
    required String repairInstruction,
  }) async {
    AIDiagnosticsStore.instance.record(
      scene: scene,
      level: 'warning',
      message: 'structured output repair requested',
      metadata: {
        'providerId': config.id,
        'modelId': config.modelId,
        'invalidPreview': AILogger.previewText(invalidOutput, maxChars: 120),
      },
    );

    final repairMessages = <Map<String, String>>[
      ...originalMessages,
      {
        'role': 'system',
        'content': '你上一次的输出不符合要求。请只返回合法 JSON，不要输出解释文字或 Markdown 代码块。',
      },
      {
        'role': 'user',
        'content': '以下是上一次的输出，请按要求修复：\n\n$invalidOutput\n\n修复要求：$repairInstruction',
      },
    ];

    final result = await _service.sendRequest(
      request: AIRequest.fromWire(
        requestId: AIService.createRequestId('${scene}_repair'),
        scene: '${scene}_repair',
        messages: repairMessages,
        provider: config,
        stream: false,
      ),
    );

    if (result.isFailure) {
      AIDiagnosticsStore.instance.record(
        scene: scene,
        level: 'error',
        message: 'structured output repair failed',
        metadata: {
          'providerId': config.id,
          'modelId': config.modelId,
          'error': result.errorOrNull?.message,
        },
      );
      return Failure(result.errorOrNull!);
    }

    final raw = result.dataOrNull!.content;
    final repaired = validator(raw);
    AIDiagnosticsStore.instance.record(
      scene: scene,
      level: repaired.isSuccess ? 'success' : 'error',
      message: repaired.isSuccess
          ? 'structured output repair succeeded'
          : 'structured output repair validation failed',
      metadata: {
        'providerId': config.id,
        'modelId': config.modelId,
      },
    );
    return repaired;
  }

  Result<T> validateJson<T>({
    required String raw,
    required T Function(Map<String, dynamic> json) parser,
    List<String> requiredKeys = const [],
  }) {
    return AIResponseValidator.validateJsonObject(
      raw: raw,
      parser: parser,
      requiredKeys: requiredKeys,
    );
  }

  void cancelCurrentRequest() {
    _service.cancelCurrentRequest();
  }

  String _buildCacheKey({
    required String scene,
    required List<Map<String, String>> messages,
    required int? maxTokens,
    required double? temperature,
  }) {
    return jsonEncode({
      'scene': scene,
      'providerId': config.id,
      'modelId': config.modelId,
      'messages': messages,
      'maxTokens': maxTokens,
      'temperature': temperature,
    });
  }
}
