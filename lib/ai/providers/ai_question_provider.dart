import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/user_context_provider.dart';
import '../services/ai_service.dart';

/// 单个问答的 AI 解析状态
class QuestionAIState {
  final String content;
  final bool isLoading;
  final bool isCompleted;
  final String? error;

  const QuestionAIState({
    this.content = '',
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
  });

  QuestionAIState copyWith({
    String? content,
    bool? isLoading,
    bool? isCompleted,
    String? error,
  }) {
    return QuestionAIState(
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
    );
  }
}

/// 每日问答 AI 解析 Provider
/// 
/// 使用 Map<int, QuestionAIState> 管理每个问答的独立解析状态。
/// key 为 article.id。
class AIQuestionNotifier extends StateNotifier<Map<int, QuestionAIState>> {
  final Ref _ref;
  AIService? _aiService;

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
        articleId: const QuestionAIState(error: '请先配置 AI 服务'),
      };
      return;
    }

    // 初始化 AI 服务
    _aiService = AIService(config);

    // 设置加载状态
    state = {
      ...state,
      articleId: const QuestionAIState(isLoading: true),
    };

    // 获取用户上下文（如果有）
    final userContext = _ref.read(userContextProvider.notifier).promptSummary;

    // 构建消息
    final messages = AIService.buildQuestionExplanationMessages(
      title: title,
      description: description,
      userContext: userContext,
    );

    // 流式接收响应
    final responseBuffer = StringBuffer();
    int updateCounter = 0;
    const updateInterval = 3;

    try {
      final stream = _aiService!.sendChatStream(messages: messages);

      await for (final chunk in stream) {
        responseBuffer.write(chunk);
        updateCounter++;

        if (updateCounter >= updateInterval) {
          state = {
            ...state,
            articleId: QuestionAIState(
              content: responseBuffer.toString(),
              isLoading: true,
            ),
          };
          updateCounter = 0;
        }
      }

      // 最终更新
      state = {
        ...state,
        articleId: QuestionAIState(
          content: responseBuffer.toString(),
          isLoading: false,
          isCompleted: true,
        ),
      };
    } catch (e) {
      debugPrint('AI 问答解析失败: $e');
      state = {
        ...state,
        articleId: QuestionAIState(
          content: responseBuffer.toString(),
          isLoading: false,
          error: e.toString(),
        ),
      };
    }
  }

  /// 取消当前请求
  void cancelRequest() {
    _aiService?.cancelCurrentRequest();
  }

  /// 清除某个问答的解析状态（用于重试）
  void clearExplanation(int articleId) {
    final newState = Map<int, QuestionAIState>.from(state);
    newState.remove(articleId);
    state = newState;
  }
}

/// 全局 AI 问答解析 Provider
final aiQuestionProvider = StateNotifierProvider<AIQuestionNotifier, Map<int, QuestionAIState>>((ref) {
  return AIQuestionNotifier(ref);
});
