import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_provider_config.dart';
import '../services/ai_test_service.dart';

/// AI 测试状态
class AITestState {
  final bool isTesting;
  final AITestResult? result;
  final AIProviderConfig? config;

  const AITestState({
    this.isTesting = false,
    this.result,
    this.config,
  });

  AITestState copyWith({
    bool? isTesting,
    AITestResult? result,
    AIProviderConfig? config,
  }) {
    return AITestState(
      isTesting: isTesting ?? this.isTesting,
      result: result ?? this.result,
      config: config ?? this.config,
    );
  }
}

/// AI 测试 Provider
class AITestNotifier extends StateNotifier<AITestState> {
  AITestNotifier() : super(const AITestState());

  /// 开始测试
  Future<void> testConfig(AIProviderConfig config) async {
    print('🔍 [Provider] 开始测试配置: ${config.name}');
    
    // 设置测试中状态
    state = AITestState(
      isTesting: true,
      config: config,
      result: null,
    );

    try {
      // 执行测试，带超时保护
      final result = await AITestService.testConfig(config).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          print('⏰ [Provider] 测试超时');
          return AITestResult(
            success: false,
            message: '❌ 测试超时：服务器响应时间过长（超过45秒）\n请检查网络连接或更换其他配置',
            responseTime: 45000,
          );
        },
      );

      print('✅ [Provider] 测试完成: ${result.success ? "成功" : "失败"}');
      
      // 更新结果
      state = AITestState(
        isTesting: false,
        config: config,
        result: result,
      );
    } catch (e) {
      print('❌ [Provider] 测试异常: $e');
      
      // 更新错误结果
      state = AITestState(
        isTesting: false,
        config: config,
        result: AITestResult(
          success: false,
          message: '测试异常: $e',
          responseTime: 0,
        ),
      );
    }
  }

  /// 重置状态
  void reset() {
    print('🔄 [Provider] 重置测试状态');
    state = const AITestState();
  }
}

/// AI 测试 Provider 实例
final aiTestProvider = StateNotifierProvider<AITestNotifier, AITestState>((ref) {
  return AITestNotifier();
});
