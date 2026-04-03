import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/result.dart';
import '../models/ai_provider_config.dart';

/// AI 对话 Repository 接口
abstract class AIRepository {
  /// 流式发送消息
  Stream<String> sendMessageStream({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
  });

  /// 非流式发送消息
  Future<Result<String>> sendMessage({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
  });

  /// 取消当前请求
  void cancelCurrentRequest();
}

/// OpenAI 兼容的 AI Repository 实现
class OpenAICompatibleRepository implements AIRepository {
  final AIProviderConfig config;
  final Dio _dio;
  CancelToken? _currentCancelToken;

  OpenAICompatibleRepository(this.config)
      : _dio = Dio(BaseOptions(
          connectTimeout: AIConstants.connectTimeout,
          receiveTimeout: AIConstants.receiveTimeout,
          sendTimeout: AIConstants.sendTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${config.apiKey}',
          },
        ));

  /// 获取 Chat Completions URL
  String get _chatCompletionsUrl {
    final url = config.apiUrl.trim();
    
    // 如果已经是完整 endpoint
    if (url.endsWith(AIConstants.chatCompletionsPath)) {
      return url;
    }
    
    // 拼接路径
    final baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return '$baseUrl${AIConstants.chatCompletionsPath}';
  }

  @override
  Stream<String> sendMessageStream({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
  }) async* {
    // 取消之前的请求
    cancelCurrentRequest();
    _currentCancelToken = CancelToken();

    AILogger.info('发送流式请求: ${messages.length} 条消息', tag: AIConstants.tagRepository);

    try {
      final requestBody = {
        'model': config.modelId,
        'messages': messages,
        'stream': true,
        'temperature': temperature ?? AIConstants.defaultTemperature,
        'max_tokens': maxTokens ?? AIConstants.defaultMaxTokens,
      };

      final response = await _dio.post(
        _chatCompletionsUrl,
        data: requestBody,
        cancelToken: _currentCancelToken,
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw _handleHttpError(response.statusCode!, response.data);
      }

      AILogger.success('开始接收流式响应', tag: AIConstants.tagRepository);

      final stream = response.data.stream;
      String buffer = '';

      await for (var chunk in stream) {
        final text = utf8.decode(chunk);
        buffer += text;
        
        final lines = buffer.split('\n');
        buffer = lines.last;
        
        for (var i = 0; i < lines.length - 1; i++) {
          final line = lines[i];
          
          if (line.isEmpty || !line.startsWith('data: ')) {
            continue;
          }
          
          final data = line.substring(6).trim();
          
          if (data == '[DONE]') {
            AILogger.info('流式响应完成', tag: AIConstants.tagRepository);
            break;
          }
          
          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta'];
            final content = delta?['content'];
            
            if (content != null && content.isNotEmpty) {
              yield content as String;
            }
          } catch (e) {
            AILogger.warning('解析 SSE 数据失败: $e', tag: AIConstants.tagRepository);
            continue;
          }
        }
      }

      _currentCancelToken = null;
    } on DioException catch (e) {
      _currentCancelToken = null;
      if (e.type == DioExceptionType.cancel) {
        AILogger.info('请求已取消', tag: AIConstants.tagRepository);
        return;
      }
      throw _handleDioException(e);
    } catch (e) {
      _currentCancelToken = null;
      AILogger.error('未知错误', tag: AIConstants.tagRepository, error: e);
      throw NetworkException('未知错误: $e', originalError: e);
    }
  }

  @override
  Future<Result<String>> sendMessage({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
  }) async {
    AILogger.info('发送非流式请求: ${messages.length} 条消息', tag: AIConstants.tagRepository);

    try {
      final requestBody = {
        'model': config.modelId,
        'messages': messages,
        'temperature': temperature ?? AIConstants.defaultTemperature,
        'max_tokens': maxTokens ?? AIConstants.defaultMaxTokens,
      };

      final response = await _dio.post(
        _chatCompletionsUrl,
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'] as String;
        AILogger.success('请求成功', tag: AIConstants.tagRepository);
        return Success(content);
      } else {
        return Failure(_handleHttpError(response.statusCode!, response.data));
      }
    } on DioException catch (e) {
      return Failure(_handleDioException(e));
    } catch (e) {
      AILogger.error('未知错误', tag: AIConstants.tagRepository, error: e);
      return Failure(NetworkException('未知错误: $e', originalError: e));
    }
  }

  @override
  void cancelCurrentRequest() {
    if (_currentCancelToken != null && !_currentCancelToken!.isCancelled) {
      AILogger.info('取消当前请求', tag: AIConstants.tagRepository);
      _currentCancelToken!.cancel('用户取消');
      _currentCancelToken = null;
    }
  }

  /// 处理 HTTP 错误
  AIException _handleHttpError(int statusCode, dynamic data) {
    switch (statusCode) {
      case 401:
        return const APIException(AIConstants.errorInvalidApiKey, code: 401);
      case 429:
        return const APIException(AIConstants.errorRateLimited, code: 429);
      case 500:
      case 502:
      case 503:
        return APIException(AIConstants.errorServerError, code: statusCode);
      default:
        return APIException('服务器错误 ($statusCode)', code: statusCode);
    }
  }

  /// 处理 Dio 异常
  AIException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        return _handleHttpError(statusCode, e.response?.data);
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true) {
          return const NetworkException(AIConstants.errorNetworkFailed);
        }
        return NetworkException(e.message ?? AIConstants.errorUnknown);
      default:
        return NetworkException(e.message ?? AIConstants.errorUnknown);
    }
  }
}

/// Repository 工厂
class AIRepositoryFactory {
  /// 根据配置创建 Repository
  static AIRepository create(AIProviderConfig config) {
    final providerType = AIProviderType.fromUrl(config.apiUrl);
    
    // 目前所有厂商都兼容 OpenAI 格式
    // 未来可以针对不同厂商返回不同实现
    switch (providerType) {
      case AIProviderType.anthropic:
        // TODO: 实现 Claude 专用 Repository（如果需要）
        return OpenAICompatibleRepository(config);
      case AIProviderType.gemini:
        // TODO: 实现 Gemini 专用 Repository（如果需要）
        return OpenAICompatibleRepository(config);
      default:
        return OpenAICompatibleRepository(config);
    }
  }
}
