
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart' hide CachePolicy;
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import '../../base/BaseResp.dart';
import '../../local/KV.dart';
import '../../utils/auth_guard.dart';
import '../Api.dart';
import 'DioCacheInterceptor.dart';
import 'NetworkInterfaces.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final errorCode = data['errorCode'];
      if (errorCode == -1001) {
        final errorMsg = data['errorMsg'] ?? '请先登录！';
        AuthGuard.handleSessionExpired(errorMsg: errorMsg);
      }
    }
    handler.next(response);
  }
}

class NetworkCall<T> {
  final Future<BaseResp<T>> _future;
  final Response<dynamic>? rawResponse;
  final CancelToken _cancelToken;
  final List<RequestInterceptor> _requestInterceptors = [];
  final List<ResponseInterceptor> _responseInterceptors = [];
  final List<ErrorInterceptor> _errorInterceptors = [];
  int _maxRetries = 0;
  Duration _retryDelay = const Duration(seconds: 1);
  CachePolicy _cachePolicy = CachePolicy.noCache;
  Duration _cacheDuration = const Duration(minutes: 5);
  final Map<String, dynamic> _cache = {};

  NetworkCall(this._future, [CancelToken? cancelToken, Response<dynamic>? rawResponse])
      : _cancelToken = cancelToken ?? CancelToken(),
        rawResponse = rawResponse;

  /// 添加请求拦截器
  NetworkCall<T> addRequestInterceptor(RequestInterceptor interceptor) {
    _requestInterceptors.add(interceptor);
    return this;
  }

  /// 添加响应拦截器
  NetworkCall<T> addResponseInterceptor(ResponseInterceptor interceptor) {
    _responseInterceptors.add(interceptor);
    return this;
  }

  /// 添加错误拦截器
  NetworkCall<T> addErrorInterceptor(ErrorInterceptor interceptor) {
    _errorInterceptors.add(interceptor);
    return this;
  }

  /// 设置重试次数和延迟
  NetworkCall<T> retry(int maxRetries, {Duration? delay}) {
    _maxRetries = maxRetries;
    if (delay != null) _retryDelay = delay;
    return this;
  }

  /// 设置缓存策略
  NetworkCall<T> cache(CachePolicy policy, {Duration? duration}) {
    _cachePolicy = policy;
    if (duration != null) _cacheDuration = duration;
    return this;
  }

  /// 取消请求
  void cancel([String? reason]) {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel(reason ?? 'Request cancelled by user');
    }
  }

  /// 原始响应回调（保留原有功能）
  NetworkCall<T> onRawResponse(void Function(Response<dynamic> resp) callback) {
    _future.then((response) {
      if (response.isSuccess && response.data != null && response.rawResponse != null) {
        callback(response.rawResponse!);
      }
    });
    return this;
  }

  /// 成功回调（保留原有功能）
  NetworkCall<T> onSuccess(void Function(T data) callback) {
    _future.then((response) {
      if (response.isSuccess && response.data != null) {
        callback(response.data as T);
      }
    });
    return this;
  }

  /// 失败回调（保留原有功能）
  NetworkCall<T> onFail(
      void Function(int errorCode, String errorMsg) callback) {
    _future.then((response) {
      if (!response.isSuccess) {
        callback(response.errorCode, response.errorMsg);
      }
    });
    return this;
  }

  /// 增强的成功回调（带缓存）
  NetworkCall<T> onSuccessWithCache(void Function(T data, bool fromCache) callback) {
    _future.then((response) async {
      if (response.isSuccess && response.data != null) {
        final cacheKey = _generateCacheKey();
        bool fromCache = false;

        if (_cachePolicy != CachePolicy.noCache) {
          final cached = _cache[cacheKey];
          if (cached != null && DateTime.now().difference(cached['timestamp']).inSeconds < _cacheDuration.inSeconds) {
            callback(cached['data'], true);
            fromCache = true;
          }
        }

        if (!fromCache || _cachePolicy == CachePolicy.networkFirst) {
          callback(response.data as T, false);
          if (_cachePolicy != CachePolicy.noCache) {
            _cache[cacheKey] = {
              'data': response.data,
              'timestamp': DateTime.now(),
            };
          }
        }
      }
    });
    return this;
  }

  /// 增强的失败回调（带重试）
  NetworkCall<T> onFailWithRetry(
      void Function(int errorCode, String errorMsg, int retryCount) callback) {
    _future.then((response) {
      if (!response.isSuccess) {
        _handleRetry(response, callback, 0);
      }
    });
    return this;
  }

  /// 完成回调（无论成功失败）
  NetworkCall<T> onComplete(void Function() callback) {
    _future.whenComplete(callback);
    return this;
  }

  /// 处理重试逻辑
  Future<void> _handleRetry(
    BaseResp<T> response,
    void Function(int, String, int) callback,
    int retryCount,
  ) async {
    if (retryCount < _maxRetries) {
      await Future.delayed(_retryDelay * (retryCount + 1));

      try {
        final newResponse = await _retryRequest();
        if (!newResponse.isSuccess) {
          callback(newResponse.errorCode, newResponse.errorMsg, retryCount + 1);
          _handleRetry(newResponse, callback, retryCount + 1);
        }
      } catch (e) {
        callback(-1, e.toString(), retryCount + 1);
      }
    } else {
      callback(response.errorCode, response.errorMsg, retryCount);
    }
  }

  /// 重试请求
  Future<BaseResp<T>> _retryRequest() async {
    // 这里需要重新构建请求，但保持原有参数
    // 由于无法直接访问原始参数，这里返回原始响应
    return _future;
  }

  /// 生成缓存键
  String _generateCacheKey() {
    return NetworkService._dio.options.baseUrl;
  }

  /// 获取取消令牌
  CancelToken get cancelToken => _cancelToken;

  Future<T> getData() async {
    final response = await _future;
    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw Exception('Request failed: ${response.errorMsg} (code: ${response.errorCode})');
    }
  }

  /// 直接返回 T 的便捷方法（带默认值）
  Future<T> getDataOrDefault(T defaultValue) async {
    try {
      final response = await _future;
      return response.isSuccess && response.data != null
          ? response.data!
          : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

/// 直接返回 T 的便捷方法（带错误处理回调）
  Future<T> getDataWithErrorHandler(
    T Function(int errorCode, String errorMsg) errorHandler,
  ) async {
    final response = await _future;
    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      return errorHandler(response.errorCode, response.errorMsg);
    }
  }

  /// 判断响应是否成功
  Future<bool> isSuccess() async {
    final response = await _future;
    return response.isSuccess;
  }

  /// 自定义数据提取方法，允许用户定义如何从 T 中提取所需数据
  Future<R> handleData<R>(
    R Function(T data) extractor, {
    R Function(int errorCode, String errorMsg)? errorHandler,
  }) async {
    final response = await _future;
    if (response.isSuccess && response.data != null) {
      print(response.data);
      return extractor(response.data as T);
    } else {
      if (errorHandler != null) {
        return errorHandler(response.errorCode, response.errorMsg);
      } else {
        throw Exception('Request failed: ${response.errorMsg} (code: ${response.errorCode})');
      }
    }
  }

  /// 处理直接返回List<R>的情况，自动使用R.fromJson转换，直接返回Future<List<R>>
  Future<List<R>> handleListData<R>(
      R Function(Map<String, dynamic>)? fromJsonT,) async {
    final response = await _future;
    if (response.isSuccess && response.data != null) {
      final data = response.data! as List<dynamic>;
      return data.map((item) => fromJsonT!(item as Map<String, dynamic>) ).toList();
    } else {
        throw Exception('Request failed: ${response.errorMsg} (code: ${response.errorCode})');
      }
  }



  /// 自定义数据提取方法（带默认值）
  Future<R> getCustomDataOrDefault<R>(
    R Function(T data) extractor,
    R defaultValue,
  ) async {
    try {
      final response = await _future;
      return response.isSuccess && response.data != null
          ? extractor(response.data as T)
          : defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}

class NetworkService {
  static final Dio _dio = Dio(BaseOptions(baseUrl: BASE_URL));
  static final List<RequestInterceptor> _globalRequestInterceptors = [];
  static final List<ResponseInterceptor> _globalResponseInterceptors = [];
  static final List<ErrorInterceptor> _globalErrorInterceptors = [];
  static PersistCookieJar? _cookieJar;

  static Future<void> init() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    _cookieJar = PersistCookieJar(storage: FileStorage(appDocPath));
    _dio.interceptors
      ..add(DioCacheInterceptor(options: cacheOption))
      ..add(CookieManager(_cookieJar!))
      ..add(AuthInterceptor());
  }

  /// 清除所有 Cookie
  static Future<void> clearCookies() async {
    await _cookieJar?.deleteAll();
  }

  /// 添加全局请求拦截器
  static void addGlobalRequestInterceptor(RequestInterceptor interceptor) {
    _globalRequestInterceptors.add(interceptor);
  }

  /// 添加全局响应拦截器
  static void addGlobalResponseInterceptor(ResponseInterceptor interceptor) {
    _globalResponseInterceptors.add(interceptor);
  }

  /// 添加全局错误拦截器
  static void addGlobalErrorInterceptor(ErrorInterceptor interceptor) {
    _globalErrorInterceptors.add(interceptor);
  }

  static NetworkCall<T> request<T>({
    required String url,
    T Function(Map<String, dynamic>)? fromJsonT,
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    // final defaultHeaders = {
    //   'Content-Type': 'application/json',
    //   // 'Cookie': Kv.decodeString(KEY_COOKIE) ?? '',
    // };

    final future = _requestFuture(
      url: url,
      fromJsonT: fromJsonT,
      method: method,
      data: data,
      queryParameters: queryParameters,
      headers: headers != null ? { ...headers} : null,
      cancelToken: cancelToken,
    );
    return NetworkCall(future, cancelToken);
  }

  static Future<BaseResp<T>> _requestFuture<T>({
    required String url,
    T Function(Map<String, dynamic>)? fromJsonT,
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      print('''        Request: $method $url       Headers: $headers        Query Parameters: $queryParameters''');
      if(data is FormData) {
        debugPrint('FormData ： ${data.fields}');
      }

      // 应用全局请求拦截器
      final options = Options(
        method: method,
        headers: headers,
      );
      for (final interceptor in _globalRequestInterceptors) {
        interceptor.onRequest(RequestOptions(
          path: url,
          method: method,
          headers: headers,
          data: data,
          queryParameters: queryParameters,
        ));
      }

      final response = await _dio.request(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      // 应用全局响应拦截器
      for (final interceptor in _globalResponseInterceptors) {
        interceptor.onResponse(response);
      }

      print('Response: Status ${response.statusCode} \\n Response: ${response.data}');
      debugPrint(response.headers.toString());

      return BaseResp<T>.fromJson(
        response.data,
        fromJsonT != null
            ? (json) => fromJsonT(json as Map<String, dynamic>)
            : null,
      )..rawResponse = response;
    } on DioException catch (e) {
      print('DioError: ${e.message} \\n Response: ${e.response}');

      // 应用全局错误拦截器
      for (final interceptor in _globalErrorInterceptors) {
        interceptor.onError(e);
      }

      return BaseResp<T>(
        data: null,
        errorCode: e.response?.statusCode ?? -1,
        errorMsg: e.response?.data?['errorMsg'] ?? e.message ?? 'Network error',
      )..rawResponse = e.response;
    } catch (e) {
      print('Unexpected Error: $e');
      return BaseResp<T>(
        data: null,
        errorCode: -2,
        errorMsg: e.toString(),
      );
    }
  }

  static NetworkCall<T> get<T>({
    required String url,
    T Function(Map<String, dynamic>)? fromJsonT,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    final formData = data is Map<String, dynamic> ? buildFormData(data) : data;
    return request(
      url: url,
      fromJsonT: fromJsonT,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      data: formData,
      cancelToken: cancelToken,
    );
  }

  static FormData buildFormData(Map<String, dynamic> data) {
    return FormData.fromMap(data);
  }

  static NetworkCall<T> post<T>({
    required String url,
    T Function(Map<String, dynamic>)? fromJsonT,
    required dynamic data,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) {
    final formData = data is Map<String, dynamic> ? buildFormData(data) : data;
    return request(
      url: url,
      fromJsonT: fromJsonT,
      method: 'POST',
      data: formData,
      headers: headers,
      cancelToken: cancelToken,
    );
  }

  /// 文件下载
  static NetworkCall<Response> download({
    required String url,
    required String savePath,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) {
    final future = _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    ).then((response) => BaseResp<Response>(
      data: response,
      errorCode: 0,
      errorMsg: 'Success',
    )..rawResponse = response);

    return NetworkCall(future, cancelToken);
  }
}