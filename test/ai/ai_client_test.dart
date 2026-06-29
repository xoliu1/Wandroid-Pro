import 'dart:collection';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wanandroid_pro/ai/core/result.dart';
import 'package:wanandroid_pro/ai/core/response_cache.dart';
import 'package:wanandroid_pro/ai/models/ai_contract.dart';
import 'package:wanandroid_pro/ai/models/ai_provider_config.dart';
import 'package:wanandroid_pro/ai/services/ai_client.dart';
import 'package:wanandroid_pro/ai/services/ai_service.dart';

class _FakeAIService extends AIService {
  _FakeAIService(
    AIProviderConfig config, {
    required this.streamFactories,
  }) : super(config);

  final Queue<Stream<AIStreamEvent> Function(AIRequest request)> streamFactories;
  int streamCallCount = 0;

  @override
  Stream<AIStreamEvent> sendRequestStream({
    required AIRequest request,
  }) {
    streamCallCount++;
    return streamFactories.removeFirst()(request);
  }

  @override
  Future<Result<AIResponse>> sendRequest({
    required AIRequest request,
  }) async {
    return Success(
      AIResponse(
        requestId: request.requestId,
        scene: request.scene,
        content: '{"ok": true}',
      ),
    );
  }
}

void main() {
  late AIProviderConfig config;

  setUp(() {
    AIResponseCacheStore.instance.clear();
    config = AIProviderConfig(
      id: 'test-provider',
      name: 'Test Provider',
      apiUrl: 'https://example.com/v1',
      modelId: 'test-model',
      apiKey: 'sk-test',
    );
  });

  test('AIClient 应该对可缓存场景复用缓存响应', () async {
    final fakeService = _FakeAIService(
      config,
      streamFactories: Queue.of([
        (request) => Stream.fromIterable([
              AIStreamEvent.started(
                requestId: request.requestId,
                scene: request.scene,
              ),
              AIStreamEvent.deltaText(
                requestId: request.requestId,
                scene: request.scene,
                deltaText: '回答内容',
              ),
              AIStreamEvent.completed(
                requestId: request.requestId,
                scene: request.scene,
                response: AIResponse(
                  requestId: request.requestId,
                  scene: request.scene,
                  content: '回答内容',
                ),
              ),
            ]),
      ]),
    );
    final client = AIClient(config, service: fakeService);
    final messages = [
      {'role': 'user', 'content': '解释 Riverpod'},
    ];

    final firstEvents = await client
        .sendStream(
          scene: 'daily_question_explanation',
          messages: messages,
        )
        .toList();
    final secondEvents = await client
        .sendStream(
          scene: 'daily_question_explanation',
          messages: messages,
        )
        .toList();

    expect(fakeService.streamCallCount, 1);
    expect(
      firstEvents.where((event) => event.type == AIStreamEventType.completed).single.response?.content,
      '回答内容',
    );
    final cachedCompleted =
        secondEvents.where((event) => event.type == AIStreamEventType.completed).single;
    expect(cachedCompleted.response?.content, '回答内容');
    expect(cachedCompleted.response?.metadata['cacheHit'], true);
  });

  test('AIClient 应该只对可重试错误重试一次', () async {
    final fakeService = _FakeAIService(
      config,
      streamFactories: Queue.of([
        (request) => Stream.fromIterable([
              AIStreamEvent.started(
                requestId: request.requestId,
                scene: request.scene,
              ),
              AIStreamEvent.failed(
                requestId: request.requestId,
                scene: request.scene,
                error: const AIErrorInfo(
                  type: AIErrorType.network,
                  message: '网络错误',
                  retryable: true,
                ),
              ),
            ]),
        (request) => Stream.fromIterable([
              AIStreamEvent.started(
                requestId: request.requestId,
                scene: request.scene,
              ),
              AIStreamEvent.completed(
                requestId: request.requestId,
                scene: request.scene,
                response: AIResponse(
                  requestId: request.requestId,
                  scene: request.scene,
                  content: '重试成功',
                ),
              ),
            ]),
      ]),
    );
    final client = AIClient(config, service: fakeService);

    final events = await client
        .sendStream(
          scene: 'article_chat',
          messages: const [
            {'role': 'user', 'content': '你好'},
          ],
          maxRetries: 1,
        )
        .toList();

    expect(fakeService.streamCallCount, 2);
    expect(events.where((event) => event.type == AIStreamEventType.retrying).length, 1);
    expect(events.where((event) => event.type == AIStreamEventType.completed).length, 1);
    expect(
      events.where((event) => event.type == AIStreamEventType.completed).single.response?.content,
      '重试成功',
    );
  });

  test('AIClient 遇到取消事件时不应重试', () async {
    final fakeService = _FakeAIService(
      config,
      streamFactories: Queue.of([
        (request) => Stream.fromIterable([
              AIStreamEvent.started(
                requestId: request.requestId,
                scene: request.scene,
              ),
              AIStreamEvent.cancelled(
                requestId: request.requestId,
                scene: request.scene,
                error: const AIErrorInfo(
                  type: AIErrorType.cancelled,
                  message: '请求已取消',
                ),
              ),
            ]),
      ]),
    );
    final client = AIClient(config, service: fakeService);

    final events = await client
        .sendStream(
          scene: 'plain_chat',
          messages: const [
            {'role': 'user', 'content': '取消一下'},
          ],
          maxRetries: 2,
        )
        .toList();

    expect(fakeService.streamCallCount, 1);
    expect(events.where((event) => event.type == AIStreamEventType.cancelled).length, 1);
    expect(events.where((event) => event.type == AIStreamEventType.completed), isEmpty);
  });

  test('AIClient 在未允许重试时应直接透出限流错误', () async {
    final fakeService = _FakeAIService(
      config,
      streamFactories: Queue.of([
        (request) => Stream.fromIterable([
              AIStreamEvent.started(
                requestId: request.requestId,
                scene: request.scene,
              ),
              AIStreamEvent.failed(
                requestId: request.requestId,
                scene: request.scene,
                error: const AIErrorInfo(
                  type: AIErrorType.rateLimited,
                  message: '请求频率过高',
                  retryable: true,
                ),
              ),
            ]),
      ]),
    );
    final client = AIClient(config, service: fakeService);

    final events = await client
        .sendStream(
          scene: 'article_chat',
          messages: const [
            {'role': 'user', 'content': '限流测试'},
          ],
          maxRetries: 0,
        )
        .toList();

    expect(fakeService.streamCallCount, 1);
    expect(events.where((event) => event.type == AIStreamEventType.retrying), isEmpty);
    final failed = events.where((event) => event.type == AIStreamEventType.failed).single;
    expect(failed.error?.type, AIErrorType.rateLimited);
  });
}
