import 'package:dio/dio.dart';

/// 请求拦截器接口
abstract class RequestInterceptor {
  void onRequest(RequestOptions options);
}

/// 响应拦截器接口
abstract class ResponseInterceptor {
  void onResponse(Response response);
}

/// 错误拦截器接口
abstract class ErrorInterceptor {
  void onError(DioException error);
}

/// 缓存策略
enum CachePolicy {
  noCache,
  cacheFirst,
  networkFirst,
  cacheOnly,
  networkOnly,
}