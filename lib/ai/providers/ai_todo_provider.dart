import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_todo_suggestion.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/user_context_provider.dart';
import '../services/ai_service.dart';

/// AI TODO 助手状态
class AITodoState {
  /// AI 返回的原始文本（用于流式显示）
  final String rawText;
  /// 解析后的结构化建议
  final AITodoSuggestion? suggestion;
  /// 是否正在加载
  final bool isLoading;
  /// 是否已完成
  final bool isCompleted;
  /// 错误信息
  final String? error;
  /// 已创建的任务 ID 集合（用于标记哪些建议已创建）
  final Set<int> createdIndices;

  const AITodoState({
    this.rawText = '',
    this.suggestion,
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
    this.createdIndices = const {},
  });

  AITodoState copyWith({
    String? rawText,
    AITodoSuggestion? suggestion,
    bool? isLoading,
    bool? isCompleted,
    String? error,
    Set<int>? createdIndices,
  }) {
    return AITodoState(
      rawText: rawText ?? this.rawText,
      suggestion: suggestion ?? this.suggestion,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
      createdIndices: createdIndices ?? this.createdIndices,
    );
  }
}

/// AI TODO 智能助手 Provider
class AITodoNotifier extends StateNotifier<AITodoState> {
  final Ref _ref;
  AIService? _aiService;

  AITodoNotifier(this._ref) : super(const AITodoState());

  /// 智能拆解：将大目标拆解为子任务
  Future<void> breakdownGoal(String goal) async {
    await _sendRequest(mode: 'breakdown', userInput: goal);
  }

  /// 每日建议：根据用户画像给出任务建议
  Future<void> getDailySuggestions() async {
    await _sendRequest(mode: 'daily');
  }

  /// 发送 AI 请求
  Future<void> _sendRequest({required String mode, String? userInput}) async {
    // 获取 AI 配置
    final config = _ref.read(activeAIProviderProvider);
    if (config == null) {
      state = const AITodoState(error: '请先配置 AI 服务');
      return;
    }

    // 获取用户上下文
    final userContext = _ref.read(userContextProvider.notifier).promptSummary;
    if (userContext == null || userContext.isEmpty) {
      state = const AITodoState(error: '用户画像数据尚未就绪，请稍后再试');
      return;
    }

    // 初始化 AI 服务
    _aiService = AIService(config);

    // 设置加载状态
    state = const AITodoState(isLoading: true);

    // 构建消息
    final messages = AIService.buildTodoAssistantMessages(
      mode: mode,
      userInput: userInput,
      userContext: userContext,
    );

    // 流式接收响应
    final responseBuffer = StringBuffer();
    int updateCounter = 0;
    const updateInterval = 5;

    try {
      final stream = _aiService!.sendChatStream(messages: messages);

      await for (final chunk in stream) {
        responseBuffer.write(chunk);
        updateCounter++;

        if (updateCounter >= updateInterval) {
          state = AITodoState(
            rawText: responseBuffer.toString(),
            isLoading: true,
          );
          updateCounter = 0;
        }
      }

      // 最终更新
      final fullResponse = responseBuffer.toString();
      final suggestion = AITodoSuggestion.tryParse(fullResponse);

      state = AITodoState(
        rawText: fullResponse,
        suggestion: suggestion,
        isLoading: false,
        isCompleted: true,
        error: suggestion == null ? '解析 AI 返回结果失败，请重试' : null,
      );

      if (suggestion != null) {
        debugPrint('📋 AI TODO 建议: ${suggestion.type}, ${suggestion.items.length} 项');
      }
    } catch (e) {
      debugPrint('AI TODO 请求失败: $e');
      state = AITodoState(
        rawText: responseBuffer.toString(),
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 标记某个建议已创建为 TODO
  void markCreated(int index) {
    state = state.copyWith(
      createdIndices: {...state.createdIndices, index},
    );
  }

  /// 取消当前请求
  void cancelRequest() {
    _aiService?.cancelCurrentRequest();
    if (state.isLoading) {
      state = const AITodoState();
    }
  }

  /// 重置状态
  void reset() {
    _aiService?.cancelCurrentRequest();
    state = const AITodoState();
  }
}

/// 全局 AI TODO Provider
final aiTodoProvider = StateNotifierProvider<AITodoNotifier, AITodoState>((ref) {
  return AITodoNotifier(ref);
});
