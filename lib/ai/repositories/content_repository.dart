import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/result.dart';
import '../models/article_content.dart';
import '../models/blog_platform.dart';
import '../services/content_extractor.dart';

/// 内容提取 Repository
class ContentRepository {
  final ContentExtractor _extractor;
  final Map<String, _CachedContent> _cache = {};

  ContentRepository(this._extractor);

  /// 从 HTML 字符串提取内容
  Future<Result<ArticleContent>> extractFromHtml(
    String htmlString,
    String url, {
    CachePolicy cachePolicy = CachePolicy.cacheFirst,
  }) async {
    try {
      // 检查缓存
      if (cachePolicy == CachePolicy.cacheFirst) {
        final cached = _getFromCache(url);
        if (cached != null) {
          AILogger.debug('使用缓存内容: $url', tag: AIConstants.tagExtractor);
          return Success(cached);
        }
      }

      AILogger.info('开始解析 HTML: $url', tag: AIConstants.tagExtractor);

      // 解析 HTML
      final document = html_parser.parse(htmlString);

      // 识别平台
      final platform = BlogPlatform.fromUrl(url);
      AILogger.debug('识别平台: ${platform.name}', tag: AIConstants.tagExtractor);

      // 提取内容
      final content = _extractor.extractFromDocument(document, url);

      // 验证
      if (!content.isValid) {
        AILogger.warning('提取内容无效', tag: AIConstants.tagExtractor);
        return const Failure(ParseException('提取的内容无效'));
      }

      // 缓存
      _putToCache(url, content);

      AILogger.success('内容提取成功: ${content.title}', tag: AIConstants.tagExtractor);
      return Success(content);
    } catch (e, stackTrace) {
      AILogger.error('内容提取失败', tag: AIConstants.tagExtractor, error: e, stackTrace: stackTrace);
      return Failure(ParseException('内容提取失败: $e', originalError: e));
    }
  }

  /// 从 Document 提取内容
  Result<ArticleContent> extractFromDocument(
    Document document,
    String url, {
    CachePolicy cachePolicy = CachePolicy.cacheFirst,
  }) {
    try {
      // 检查缓存
      if (cachePolicy == CachePolicy.cacheFirst) {
        final cached = _getFromCache(url);
        if (cached != null) {
          AILogger.debug('使用缓存内容: $url', tag: AIConstants.tagExtractor);
          return Success(cached);
        }
      }

      AILogger.info('开始解析 Document: $url', tag: AIConstants.tagExtractor);

      // 提取内容
      final content = _extractor.extractFromDocument(document, url);

      // 验证
      if (!content.isValid) {
        AILogger.warning('提取内容无效', tag: AIConstants.tagExtractor);
        return const Failure(ParseException('提取的内容无效'));
      }

      // 缓存
      _putToCache(url, content);

      AILogger.success('内容提取成功: ${content.title}', tag: AIConstants.tagExtractor);
      return Success(content);
    } catch (e, stackTrace) {
      AILogger.error('内容提取失败', tag: AIConstants.tagExtractor, error: e, stackTrace: stackTrace);
      return Failure(ParseException('内容提取失败: $e', originalError: e));
    }
  }

  /// 识别平台
  BlogPlatform identifyPlatform(String url) {
    return _extractor.identifyPlatform(url);
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
    AILogger.info('已清除内容缓存', tag: AIConstants.tagExtractor);
  }

  /// 清除过期缓存
  void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) => now.isAfter(value.expireAt));
    AILogger.debug('已清除过期缓存', tag: AIConstants.tagExtractor);
  }

  /// 从缓存获取
  ArticleContent? _getFromCache(String url) {
    final cached = _cache[url];
    if (cached == null) return null;

    // 检查是否过期
    if (DateTime.now().isAfter(cached.expireAt)) {
      _cache.remove(url);
      return null;
    }

    return cached.content;
  }

  /// 放入缓存
  void _putToCache(String url, ArticleContent content) {
    _cache[url] = _CachedContent(
      content: content,
      expireAt: DateTime.now().add(AIConstants.contentCacheDuration),
    );
  }
}

/// 缓存项
class _CachedContent {
  final ArticleContent content;
  final DateTime expireAt;

  _CachedContent({
    required this.content,
    required this.expireAt,
  });
}
