import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/ai_contract.dart';
import '../models/ai_request_status.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/user_context_provider.dart';
import '../services/ai_client.dart';
import '../services/ai_message_composer.dart';

/// 单个问答的 AI 解析状态
class QuestionAIState {
  final String content;
  final bool isLoading;
  final bool isCompleted;
  final String? error;
  final AIRequestStatus status;

  const QuestionAIState({
    this.content = '',
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
    this.status = AIRequestStatus.idle,
  });

  QuestionAIState copyWith({
    String? content,
    bool? isLoading,
    bool? isCompleted,
    String? error,
    AIRequestStatus? status,
  }) {
    return QuestionAIState(
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }
}

/// 每日问答 AI 解析 Provider
/// 
/// 使用 Map<int, QuestionAIState> 管理每个问答的独立解析状态。
/// key 为 article.id。
class AIQuestionNotifier extends StateNotifier<Map<int, QuestionAIState>> {
  final Ref _ref;
  AIClient? _aiClient;

  AIQuestionNotifier(this._ref) : super({});

  /// 请求 AI 解析某个问答
  Future<void> requestExplanation({
    required int articleId,
    required String title,
    required String description,
  }) async {
    // 如果已经在加载或已完成，跳过
    final existing = state[articleId];
    if (existing != null && (existing.isLoading || existing.isCompleted)) return;

    // 获取 AI 配置
    final config = _ref.read(activeAIProviderProvider);
    if (config == null) {
      state = {
        ...state,
        articleId: const QuestionAIState(error: '请先配置 AI 服务', status: AIRequestStatus.error),
      };
      return;
    }

    // 初始化 AI 服务
    _aiClient = AIClient(config);

    // 设置加载状态
    state = {
      ...state,
      articleId: const QuestionAIState(isLoading: true, status: AIRequestStatus.loading),
    };

    // 获取用户上下文（如果有）
    final userContext = _ref.read(userContextProvider.notifier).promptSummary;

    // 构建消息
    final messages = AIMessageComposer.questionExplain(
      title: title,
      description: description,
      userContext: userContext,
    );

    // 流式接收响应
    final responseBuffer = StringBuffer();
    int updateCounter = 0;
    const updateInterval = 3;

    try {
      final stream = _aiClient!.sendStream(
        scene: 'daily_question_explanation',
        messages: messages,
        maxRetries: 1,
        metadata: {
          'articleId': articleId,
          'title': title,
        },
      );

      await for (final event in stream) {
        switch (event.type) {
          case AIStreamEventType.deltaText:
            if (event.deltaText == null || event.deltaText!.isEmpty) {
              continue;
            }
            responseBuffer.write(event.deltaText!);
            updateCounter++;

            if (updateCounter >= updateInterval) {
              state = {
                ...state,
                articleId: QuestionAIState(
                  content: responseBuffer.toString(),
                  isLoading: true,
                  status: AIRequestStatus.loading,
                ),
              };
              updateCounter = 0;
            }
            break;
          case AIStreamEventType.completed:
            state = {
              ...state,
              articleId: QuestionAIState(
                content: event.response?.content ?? responseBuffer.toString(),
                isLoading: false,
                isCompleted: true,
                status: AIRequestStatus.completed,
              ),
            };
            break;
          case AIStreamEventType.retrying:
            state = {
              ...state,
              articleId: QuestionAIState(
                content: responseBuffer.toString(),
                isLoading: true,
                error: event.error?.message,
                status: AIRequestStatus.retrying,
              ),
            };
            break;
          case AIStreamEventType.failed:
          case AIStreamEventType.cancelled:
            state = {
              ...state,
              articleId: QuestionAIState(
                content: responseBuffer.toString(),
                isLoading: false,
                error: event.error?.message ?? AIConstants.errorUnknown,
                status: _mapErrorToStatus(event.error),
              ),
            };
            break;
          case AIStreamEventType.started:
          case AIStreamEventType.toolCallRequested:
          case AIStreamEventType.toolCallResult:
          case AIStreamEventType.usageUpdated:
            break;
        }
      }
    } catch (e) {
      debugPrint('AI 问答解析失败: $e');
      state = {
        ...state,
        articleId: QuestionAIState(
          content: responseBuffer.toString(),
          isLoading: false,
          error: e.toString(),
          status: AIRequestStatus.error,
        ),
      };
    }
  }

  /// 取消当前请求
  void cancelRequest() {
    _aiClient?.cancelCurrentRequest();
  }

  /// 清除某个问答的解析状态（用于重试）
  void clearExplanation(int articleId) {
    final newState = Map<int, QuestionAIState>.from(state);
    newState.remove(articleId);
    state = newState;
  }

  AIRequestStatus _mapErrorToStatus(AIErrorInfo? error) {
    switch (error?.type) {
      case AIErrorType.timeout:
        return AIRequestStatus.timedOut;
      case AIErrorType.rateLimited:
        return AIRequestStatus.rateLimited;
      case AIErrorType.cancelled:
        return AIRequestStatus.cancelled;
      default:
        return AIRequestStatus.error;
    }
  }
}

/// 全局 AI 问答解析 Provider
final aiQuestionProvider = StateNotifierProvider<AIQuestionNotifier, Map<int, QuestionAIState>>((ref) {
  return AIQuestionNotifier(ref);
});
