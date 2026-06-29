import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../core/diagnostics.dart';
import '../core/result.dart' as ai_result;
import '../models/ai_contract.dart';
import '../models/ai_request_status.dart';
import '../models/ai_todo_suggestion.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/user_context_provider.dart';
import '../services/ai_client.dart';
import '../services/ai_message_composer.dart';
import '../services/ai_response_validator.dart';
import '../services/ai_schema_catalog.dart';

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
  final AIRequestStatus status;

  const AITodoState({
    this.rawText = '',
    this.suggestion,
    this.isLoading = false,
    this.isCompleted = false,
    this.error,
    this.createdIndices = const {},
    this.status = AIRequestStatus.idle,
  });

  AITodoState copyWith({
    String? rawText,
    AITodoSuggestion? suggestion,
    bool? isLoading,
    bool? isCompleted,
    String? error,
    Set<int>? createdIndices,
    AIRequestStatus? status,
  }) {
    return AITodoState(
      rawText: rawText ?? this.rawText,
      suggestion: suggestion ?? this.suggestion,
      isLoading: isLoading ?? this.isLoading,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error ?? this.error,
      createdIndices: createdIndices ?? this.createdIndices,
      status: status ?? this.status,
    );
  }
}

/// AI TODO 智能助手 Provider
class AITodoNotifier extends StateNotifier<AITodoState> {
  final Ref _ref;
  AIClient? _aiClient;

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
    if (state.isLoading) {
      AIDiagnosticsStore.instance.record(
        scene: mode == 'daily' ? 'todo_daily_suggestion' : 'todo_breakdown',
        level: 'warning',
        message: 'duplicate request ignored',
        metadata: {
          'mode': mode,
        },
      );
      return;
    }

    // 获取 AI 配置
    final config = _ref.read(activeAIProviderProvider);
    if (config == null) {
      state = const AITodoState(
        error: '请先配置 AI 服务',
        status: AIRequestStatus.error,
      );
      return;
    }

    // 获取用户上下文
    final userContext = _ref.read(userContextProvider.notifier).promptSummary;
    if (userContext == null || userContext.isEmpty) {
      state = const AITodoState(
        error: '用户画像数据尚未就绪，请稍后再试',
        status: AIRequestStatus.error,
      );
      return;
    }

    // 初始化 AI 服务
    _aiClient = AIClient(config);

    // 设置加载状态
    state = const AITodoState(
      isLoading: true,
      status: AIRequestStatus.loading,
    );

    // 构建消息
    final messages = AIMessageComposer.todoAssistant(
      mode: mode,
      userInput: userInput,
      userContext: userContext,
    );

    // 流式接收响应
    final responseBuffer = StringBuffer();
    int updateCounter = 0;
    const updateInterval = 5;

    try {
      final scene = mode == 'daily' ? 'todo_daily_suggestion' : 'todo_breakdown';
      final stream = _aiClient!.sendStream(
        scene: scene,
        messages: messages,
        maxRetries: 1,
        metadata: {
          'mode': mode,
          'hasUserInput': userInput != null && userInput.isNotEmpty,
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
              state = AITodoState(
                rawText: responseBuffer.toString(),
                isLoading: true,
                status: AIRequestStatus.loading,
              );
              updateCounter = 0;
            }
            break;
          case AIStreamEventType.retrying:
            state = AITodoState(
              rawText: responseBuffer.toString(),
              isLoading: true,
              error: event.error?.message,
              status: AIRequestStatus.retrying,
            );
            break;
          case AIStreamEventType.completed:
            final fullResponse = event.response?.content ?? responseBuffer.toString();
            var suggestion = _validateSuggestionResult(fullResponse).dataOrNull;
            if (suggestion == null) {
              AIDiagnosticsStore.instance.record(
                scene: scene,
                level: 'warning',
                message: 'structured validation failed',
                metadata: {
                  'schemaVersion': AISchemaCatalog.todoSuggestion.fullName,
                },
              );
              final repaired = await _aiClient!.repairStructuredJson<AITodoSuggestion>(
                scene: scene,
                originalMessages: messages,
                invalidOutput: fullResponse,
                validator: _validateSuggestionResult,
                repairInstruction:
                    '返回格式必须为包含 ${AISchemaCatalog.todoSuggestion.requiredKeys.join('、')} 字段的合法 JSON 对象。',
              );
              switch (repaired) {
                case ai_result.Success(data: final repairedSuggestion):
                  suggestion = repairedSuggestion;
                case ai_result.Failure():
                  suggestion = null;
              }
            }

            AIDiagnosticsStore.instance.record(
              scene: scene,
              level: suggestion != null ? 'success' : 'error',
              message: suggestion != null
                  ? 'structured validation succeeded'
                  : 'structured validation failed after repair',
              metadata: {
                'schemaVersion': AISchemaCatalog.todoSuggestion.fullName,
              },
            );

            state = AITodoState(
              rawText: suggestion != null ? fullResponse : fullResponse,
              suggestion: suggestion,
              isLoading: false,
              isCompleted: true,
              error: suggestion == null ? '解析 AI 返回结果失败，请重试' : null,
              status: suggestion == null ? AIRequestStatus.error : AIRequestStatus.completed,
            );

            if (suggestion != null) {
              debugPrint('📋 AI TODO 建议: ${suggestion.type}, ${suggestion.items.length} 项');
            }
            break;
          case AIStreamEventType.failed:
          case AIStreamEventType.cancelled:
            state = AITodoState(
              rawText: responseBuffer.toString(),
              isLoading: false,
              error: event.error?.message ?? AIConstants.errorUnknown,
              status: _mapErrorToStatus(event.error),
            );
            break;
          case AIStreamEventType.started:
          case AIStreamEventType.toolCallRequested:
          case AIStreamEventType.toolCallResult:
          case AIStreamEventType.usageUpdated:
            break;
        }
      }
    } catch (e) {
      debugPrint('AI TODO 请求失败: $e');
      state = AITodoState(
        rawText: responseBuffer.toString(),
        isLoading: false,
        error: e.toString(),
        status: AIRequestStatus.error,
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
    _aiClient?.cancelCurrentRequest();
    if (state.isLoading) {
      state = const AITodoState(
        error: AIConstants.errorCancelled,
        status: AIRequestStatus.cancelled,
      );
    }
  }

  /// 重置状态
  void reset() {
    _aiClient?.cancelCurrentRequest();
    state = const AITodoState();
  }

  ai_result.Result<AITodoSuggestion> _validateSuggestionResult(String raw) {
    return AIResponseValidator.validateJsonObject(
      raw: raw,
      parser: AITodoSuggestion.fromJson,
      schema: AISchemaCatalog.todoSuggestion,
    );
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

/// 全局 AI TODO Provider
final aiTodoProvider = StateNotifierProvider<AITodoNotifier, AITodoState>((ref) {
  return AITodoNotifier(ref);
});
