import 'dart:async';
import '../core/logger.dart';
import '../core/constants.dart';
import '../core/result.dart';
import '../models/ai_provider_config.dart';
import '../models/ai_contract.dart';
import '../models/article_content.dart';
import '../repositories/ai_repository.dart';
import 'ai_message_composer.dart';
import 'ai_prompt_manager.dart';

/// AI 服务 - 业务逻辑层
/// 
/// 职责：
/// - 构建消息上下文
/// - 管理对话历史
/// - Token 估算
/// - 委托具体请求给 Repository
class AIService {
  final AIProviderConfig config;
  final AIRepository _repository;

  AIService(this.config) : _repository = AIRepositoryFactory.create(config) {
    AILogger.info('初始化 AI 服务: ${config.name}', tag: AIConstants.tagService);
  }

  static String createRequestId([String prefix = 'ai']) {
    final now = DateTime.now();
    return '${prefix}_${now.microsecondsSinceEpoch}';
  }

  /// 发送聊天消息（事件流响应）
  Stream<AIStreamEvent> sendRequestStream({
    required AIRequest request,
  }) async* {
    AILogger.info('发送事件流请求: ${request.scene}', tag: AIConstants.tagService);
    AILogger.debug(
      'requestId=${request.requestId}, 消息数量=${request.messages.length}',
      tag: AIConstants.tagService,
    );

    final responseBuffer = StringBuffer();
    yield AIStreamEvent.started(
      requestId: request.requestId,
      scene: request.scene,
    );

    try {
      final stream = _repository.sendMessageStream(
        messages: request.toWireMessages(),
        maxTokens: request.maxTokens,
        temperature: request.temperature,
      );

      await for (final chunk in stream) {
        responseBuffer.write(chunk);
        yield AIStreamEvent.deltaText(
          requestId: request.requestId,
          scene: request.scene,
          deltaText: chunk,
        );
      }

      yield AIStreamEvent.completed(
        requestId: request.requestId,
        scene: request.scene,
        response: AIResponse(
          requestId: request.requestId,
          scene: request.scene,
          content: responseBuffer.toString(),
          metadata: request.metadata,
        ),
      );
    } on AIException catch (e, stackTrace) {
      final errorInfo = AIErrorInfo.fromException(e);
      AILogger.error(
        '事件流请求失败',
        tag: AIConstants.tagService,
        error: e,
        stackTrace: stackTrace,
      );

      if (e is CancelledException) {
        yield AIStreamEvent.cancelled(
          requestId: request.requestId,
          scene: request.scene,
          error: errorInfo,
        );
        return;
      }

      yield AIStreamEvent.failed(
        requestId: request.requestId,
        scene: request.scene,
        error: errorInfo,
      );
    } catch (e, stackTrace) {
      AILogger.error(
        '事件流请求出现未知异常',
        tag: AIConstants.tagService,
        error: e,
        stackTrace: stackTrace,
      );
      yield AIStreamEvent.failed(
        requestId: request.requestId,
        scene: request.scene,
        error: AIErrorInfo(
          type: AIErrorType.unknown,
          message: '未知错误: $e',
          originalError: e,
        ),
      );
    }
  }

  /// 发送聊天消息（流式响应）
  Stream<String> sendChatStream({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
  }) async* {
    final request = AIRequest.fromWire(
      requestId: createRequestId('chat'),
      scene: 'legacy_chat_stream',
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
      provider: config,
    );

    await for (final event in sendRequestStream(request: request)) {
      switch (event.type) {
        case AIStreamEventType.deltaText:
          if (event.deltaText != null && event.deltaText!.isNotEmpty) {
            yield event.deltaText!;
          }
          break;
        case AIStreamEventType.failed:
          throw NetworkException(
            event.error?.message ?? AIConstants.errorUnknown,
            code: event.error?.code,
            originalError: event.error?.originalError,
          );
        case AIStreamEventType.cancelled:
          return;
        case AIStreamEventType.started:
        case AIStreamEventType.retrying:
        case AIStreamEventType.toolCallRequested:
        case AIStreamEventType.toolCallResult:
        case AIStreamEventType.usageUpdated:
        case AIStreamEventType.completed:
          break;
      }
    }
  }

  Future<Result<AIResponse>> sendRequest({
    required AIRequest request,
  }) async {
    final result = await _repository.sendMessage(
      messages: request.toWireMessages(),
      maxTokens: request.maxTokens,
      temperature: request.temperature,
    );

    return result.map((content) {
      return AIResponse(
        requestId: request.requestId,
        scene: request.scene,
        content: content,
        metadata: request.metadata,
      );
    });
  }

  /// 取消当前请求
  void cancelCurrentRequest() {
    AILogger.info('取消当前请求', tag: AIConstants.tagService);
    _repository.cancelCurrentRequest();
  }

  @Deprecated('Use AIMessageComposer.articleChat instead.')
  static List<Map<String, String>> buildMessagesWithArticle({
    required ArticleContent article,
    required String userQuestion,
    List<Map<String, String>>? history,
  }) {
    return AIMessageComposer.articleChat(
      article: article,
      userQuestion: userQuestion,
      history: history,
    );
  }

  @Deprecated('Use AIMessageComposer.plainChat instead.')
  static List<Map<String, String>> buildPlainMessages({
    required String userQuestion,
    List<Map<String, String>>? history,
  }) {
    return AIMessageComposer.plainChat(
      userQuestion: userQuestion,
      history: history,
    );
  }

  /// 构建 AI 续写消息列表（用于笔记编辑器）
  static List<Map<String, String>> buildContinueWritingMessages({
    required String existingContent,
    String? selectedText,
  }) {
    return AIMessageComposer.continueWriting(
      existingContent: existingContent,
      selectedText: selectedText,
    );
  }

  /// 构建 AI 润色消息列表（用于笔记编辑器）
  static List<Map<String, String>> buildPolishMessages({
    required String content,
  }) {
    return AIMessageComposer.polish(content: content);
  }

  @Deprecated('Use AIMessageComposer.questionExplain instead.')
  static List<Map<String, String>> buildQuestionExplanationMessages({
    required String title,
    required String description,
    String? userContext,
  }) {
    return AIMessageComposer.questionExplain(
      title: title,
      description: description,
      userContext: userContext,
    );
  }

  @Deprecated('Use AIMessageComposer.dailyReport instead.')
  static List<Map<String, String>> buildDailyReportMessages({
    required String dailyData,
    String? userContext,
  }) {
    return AIMessageComposer.dailyReport(
      dailyData: dailyData,
      userContext: userContext,
    );
  }

  @Deprecated('Use AIMessageComposer.todoAssistant instead.')
  static List<Map<String, String>> buildTodoAssistantMessages({
    required String mode,
    String? userInput,
    required String userContext,
  }) {
    return AIMessageComposer.todoAssistant(
      mode: mode,
      userInput: userInput,
      userContext: userContext,
    );
  }

  /// 估算 Token 数量（粗略估算：中文约1.5字符/token，英文约4字符/token）
  static int estimateTokens(String text) {
    return AIContextManager.estimateTokens(text);
  }

  /// 压缩消息历史（当 Token 超过限制时）
  static List<Map<String, String>> compressHistory(
    List<Map<String, String>> messages,
    int maxTokens,
  ) {
    AILogger.debug('开始压缩消息历史', tag: AIConstants.tagService);
    
    int totalTokens = messages.fold(0, (sum, msg) => sum + estimateTokens(msg['content'] ?? ''));
    
    if (totalTokens <= maxTokens) {
      AILogger.debug('无需压缩', tag: AIConstants.tagService);
      return messages;
    }

    // 保留系统消息和最近的对话
    final systemMessages = messages.where((m) => m['role'] == 'system').toList();
    final userMessages = messages.where((m) => m['role'] != 'system').toList();

    // 从最新的消息开始保留
    final compressed = <Map<String, String>>[...systemMessages];
    var currentTokens = systemMessages.fold(0, (sum, msg) => sum + estimateTokens(msg['content'] ?? ''));

    for (var i = userMessages.length - 1; i >= 0; i--) {
      final msg = userMessages[i];
      final tokens = estimateTokens(msg['content'] ?? '');
      
      if (currentTokens + tokens > maxTokens) {
        break;
      }
      
      compressed.insert(systemMessages.length, msg);
      currentTokens += tokens;
    }

    AILogger.info('消息历史已压缩: ${messages.length} -> ${compressed.length}', tag: AIConstants.tagService);
    return compressed;
  }
}
