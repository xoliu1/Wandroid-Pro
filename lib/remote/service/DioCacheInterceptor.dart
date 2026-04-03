
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

final cacheOption = CacheOptions(
  // 拦截器必须提供一个默认缓存存储
  store: MemCacheStore(),
  policy: CachePolicy.request,
  // 当遇到指定状态码的错误时，返回已缓存的响应
  // 默认为 `[]`
  hitCacheOnErrorCodes: const [500],
  // 允许在网络错误（例如离线）时返回已缓存的响应
  // 默认为 `false`
  hitCacheOnNetworkFailure: true,
  // 覆盖任何 HTTP 指令，在此持续时间后删除缓存条目
  // 仅在源服务器无缓存配置或需要自定义行为时有用
  // 默认为 `null`
  maxStale: const Duration(days: 7),
  // 默认值。允许 3 个缓存集合并便于清理
  priority: CachePriority.high,
  // 默认值。使用你自己的算法对响应体和头部进行加密
  cipher: null,
  // 默认值。用于检索请求的键构建器
  keyBuilder: CacheOptions.defaultCacheKeyBuilder,
  // 默认值。允许缓存 POST 请求
  // 当设为 `true` 时，强烈建议指定一个 [keyBuilder]
  allowPostMethod: true,
);