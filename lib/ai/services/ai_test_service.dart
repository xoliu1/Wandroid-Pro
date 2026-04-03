import 'package:dio/dio.dart';
import '../models/ai_provider_config.dart';

/// AI 配置测试服务
class AITestService {
  /// 测试 AI 配置是否可用
  /// 
  /// 返回结果:
  /// - success: 是否成功
  /// - message: 提示消息
  /// - responseTime: 响应时间（毫秒）
  static Future<AITestResult> testConfig(AIProviderConfig config) async {
    final startTime = DateTime.now();
    
    print('🔍 开始测试配置: ${config.name}');
    print('📡 API URL: ${config.apiUrl}');
    print('🤖 Model ID: ${config.modelId}');
    
    try {
      // 检查配置完整性
      if (!config.isConfigured) {
        print('❌ 配置不完整');
        return AITestResult(
          success: false,
          message: '配置不完整：请填写 API 地址、模型 ID 和 API Key',
          responseTime: 0,
        );
      }

      print('🚀 开始发送请求...');
      // 根据不同厂商使用不同的测试策略
      final result = await _testByProvider(config);
      
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      print('✅ 请求完成，响应时间: ${responseTime}ms');
      
      return AITestResult(
        success: result.success,
        message: result.message,
        responseTime: responseTime,
        response: result.response,
      );
    } catch (e) {
      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime).inMilliseconds;
      
      print('❌ 请求异常: $e');
      
      return AITestResult(
        success: false,
        message: '测试失败: ${_formatError(e)}',
        responseTime: responseTime,
      );
    }
  }

  /// 根据提供商类型进行测试
  static Future<AITestResult> _testByProvider(AIProviderConfig config) async {
    // 判断提供商类型
    if (config.apiUrl.contains('openai.com')) {
      return await _testOpenAI(config);
    } else if (config.apiUrl.contains('anthropic.com')) {
      return await _testClaude(config);
    } else if (config.apiUrl.contains('generativelanguage.googleapis.com')) {
      return await _testGemini(config);
    } else if (config.apiUrl.contains('bigmodel.cn')) {
      return await _testZhipu(config);
    } else if (config.apiUrl.contains('dashscope.aliyuncs.com')) {
      // 通义千问新版兼容模式走 OpenAI 兼容格式
      if (config.apiUrl.contains('compatible-mode')) {
        return await _testOpenAICompatible(config);
      }
      return await _testQwen(config);
    } else if (config.apiUrl.contains('deepseek.com')) {
      return await _testDeepSeek(config);
    } else if (config.apiUrl.contains('moonshot.cn')) {
      return await _testMoonshot(config);
    } else if (config.apiUrl.contains('siliconflow.cn')) {
      return await _testSiliconFlow(config);
    } else if (config.apiUrl.contains('minimax.chat')) {
      // MiniMax 走 OpenAI 兼容格式
      return await _testOpenAICompatible(config);
    } else if (config.apiUrl.contains('volces.com')) {
      // 豆包（字节跳动）走 OpenAI 兼容格式
      return await _testOpenAICompatible(config);
    } else if (config.apiUrl.contains('x.ai')) {
      // Grok 走 OpenAI 兼容格式
      return await _testOpenAICompatible(config);
    } else {
      // 通用测试（OpenAI 兼容格式）
      return await _testOpenAICompatible(config);
    }
  }

  /// 测试 OpenAI
  static Future<AITestResult> _testOpenAI(AIProviderConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    try {
      final response = await dio.post(
        config.apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true, // 接受所有状态码
        ),
        data: {
          'model': config.modelId,
          'messages': [
            {'role': 'user', 'content': 'Hello, this is a test.'}
          ],
          'max_tokens': 10,
        },
      );

      if (response.statusCode == 200) {
        return AITestResult(
          success: true,
          message: '✅ 测试成功！API 配置正常',
          responseTime: 0,
          response: response.data,
        );
      } else if (response.statusCode == 401) {
        return AITestResult(
          success: false,
          message: '❌ API Key 无效或已过期',
          responseTime: 0,
        );
      } else if (response.statusCode == 429) {
        return AITestResult(
          success: false,
          message: '❌ 请求频率过高，请稍后再试',
          responseTime: 0,
        );
      } else {
        return AITestResult(
          success: false,
          message: '❌ 请求失败 (${response.statusCode}): ${response.data}',
          responseTime: 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 测试 Claude
  static Future<AITestResult> _testClaude(AIProviderConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    try {
      final response = await dio.post(
        config.apiUrl,
        options: Options(
          headers: {
            'x-api-key': config.apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
        ),
        data: {
          'model': config.modelId,
          'messages': [
            {'role': 'user', 'content': 'Hello, this is a test.'}
          ],
          'max_tokens': 10,
        },
      );

      if (response.statusCode == 200) {
        return AITestResult(
          success: true,
          message: '✅ 测试成功！Claude API 配置正常',
          responseTime: 0,
          response: response.data,
        );
      } else if (response.statusCode == 401) {
        return AITestResult(
          success: false,
          message: '❌ API Key 无效',
          responseTime: 0,
        );
      } else {
        return AITestResult(
          success: false,
          message: '❌ 请求失败 (${response.statusCode}): ${response.data}',
          responseTime: 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 测试 Gemini
  static Future<AITestResult> _testGemini(AIProviderConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    try {
      final url = '${config.apiUrl}?key=${config.apiKey}';
      final response = await dio.post(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true,
        ),
        data: {
          'contents': [
            {
              'parts': [
                {'text': 'Hello, this is a test.'}
              ]
            }
          ],
        },
      );

      if (response.statusCode == 200) {
        return AITestResult(
          success: true,
          message: '✅ 测试成功！Gemini API 配置正常',
          responseTime: 0,
          response: response.data,
        );
      } else if (response.statusCode == 400) {
        return AITestResult(
          success: false,
          message: '❌ API Key 无效或请求格式错误',
          responseTime: 0,
        );
      } else {
        return AITestResult(
          success: false,
          message: '❌ 请求失败 (${response.statusCode}): ${response.data}',
          responseTime: 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 测试智谱 AI
  static Future<AITestResult> _testZhipu(AIProviderConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    try {
      final response = await dio.post(
        config.apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
        ),
        data: {
          'model': config.modelId,
          'messages': [
            {'role': 'user', 'content': '你好，这是一个测试'}
          ],
        },
      );

      if (response.statusCode == 200) {
        return AITestResult(
          success: true,
          message: '✅ 测试成功！智谱 AI 配置正常',
          responseTime: 0,
          response: response.data,
        );
      } else if (response.statusCode == 401) {
        return AITestResult(
          success: false,
          message: '❌ API Key 无效',
          responseTime: 0,
        );
      } else {
        return AITestResult(
          success: false,
          message: '❌ 请求失败 (${response.statusCode}): ${response.data}',
          responseTime: 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 测试通义千问
  static Future<AITestResult> _testQwen(AIProviderConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    try {
      final response = await dio.post(
        config.apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
        ),
        data: {
          'model': config.modelId,
          'input': {'messages': [{'role': 'user', 'content': '你好，这是一个测试'}]},
          'parameters': {},
        },
      );

      if (response.statusCode == 200) {
        return AITestResult(
          success: true,
          message: '✅ 测试成功！通义千问配置正常',
          responseTime: 0,
          response: response.data,
        );
      } else if (response.statusCode == 401 || response.statusCode == 400) {
        return AITestResult(
          success: false,
          message: '❌ API Key 无效',
          responseTime: 0,
        );
      } else {
        return AITestResult(
          success: false,
          message: '❌ 请求失败 (${response.statusCode}): ${response.data}',
          responseTime: 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 测试 DeepSeek
  static Future<AITestResult> _testDeepSeek(AIProviderConfig config) async {
    return await _testOpenAICompatible(config);
  }

  /// 测试 Moonshot
  static Future<AITestResult> _testMoonshot(AIProviderConfig config) async {
    return await _testOpenAICompatible(config);
  }

  /// 测试硅基流动 (SiliconFlow)
  static Future<AITestResult> _testSiliconFlow(AIProviderConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    try {
      final response = await dio.post(
        config.apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
        ),
        data: {
          'model': config.modelId,
          'messages': [
            {'role': 'user', 'content': '你好，这是一个测试'}
          ],
          'max_tokens': 10,
          'stream': false,
        },
      );

      if (response.statusCode == 200) {
        return AITestResult(
          success: true,
          message: '✅ 测试成功！硅基流动 API 配置正常',
          responseTime: 0,
          response: response.data,
        );
      } else if (response.statusCode == 401) {
        return AITestResult(
          success: false,
          message: '❌ API Key 无效或已过期',
          responseTime: 0,
        );
      } else if (response.statusCode == 429) {
        return AITestResult(
          success: false,
          message: '❌ 请求频率过高，请稍后再试',
          responseTime: 0,
        );
      } else if (response.statusCode == 400) {
        final error = response.data;
        return AITestResult(
          success: false,
          message: '❌ 请求参数错误: ${error['error']?['message'] ?? '未知错误'}',
          responseTime: 0,
        );
      } else {
        return AITestResult(
          success: false,
          message: '❌ 请求失败 (${response.statusCode}): ${response.data}',
          responseTime: 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 测试 OpenAI 兼容接口
  static Future<AITestResult> _testOpenAICompatible(AIProviderConfig config) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ));
    
    try {
      final response = await dio.post(
        config.apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => true,
        ),
        data: {
          'model': config.modelId,
          'messages': [
            {'role': 'user', 'content': '你好，这是一个测试'}
          ],
          'max_tokens': 10,
        },
      );

      if (response.statusCode == 200) {
        return AITestResult(
          success: true,
          message: '✅ 测试成功！API 配置正常',
          responseTime: 0,
          response: response.data,
        );
      } else if (response.statusCode == 401) {
        return AITestResult(
          success: false,
          message: '❌ API Key 无效',
          responseTime: 0,
        );
      } else {
        return AITestResult(
          success: false,
          message: '❌ 请求失败 (${response.statusCode}): ${response.data}',
          responseTime: 0,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 格式化错误信息
  static String _formatError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return '连接超时，请检查网络';
        case DioExceptionType.badResponse:
          return '服务器响应错误 (${error.response?.statusCode})';
        case DioExceptionType.cancel:
          return '请求已取消';
        case DioExceptionType.unknown:
          if (error.message?.contains('SocketException') == true) {
            return '网络连接失败，请检查网络或 API 地址';
          }
          return '未知错误: ${error.message}';
        default:
          return error.message ?? '未知错误';
      }
    }
    return error.toString();
  }
}

/// AI 测试结果
class AITestResult {
  final bool success;
  final String message;
  final int responseTime; // 毫秒
  final dynamic response;

  AITestResult({
    required this.success,
    required this.message,
    required this.responseTime,
    this.response,
  });

  /// 格式化响应时间
  String get formattedResponseTime {
    if (responseTime < 1000) {
      return '$responseTime ms';
    } else {
      return '${(responseTime / 1000).toStringAsFixed(2)} s';
    }
  }
}
