import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../models/article_content.dart';
import '../models/blog_platform.dart';
import 'csdn_strategy.dart';
import 'generic_strategy.dart';
import 'juejin_strategy.dart';
import 'platform_strategy.dart';
import 'weixin_strategy.dart';

/// 内容提取器
class ContentExtractor {
  // 策略缓存
  final Map<BlogPlatform, PlatformStrategy> _strategies = {};

  ContentExtractor() {
    // 初始化策略
    _strategies[BlogPlatform.csdn] = CSDNStrategy();
    _strategies[BlogPlatform.juejin] = JuejinStrategy();
    _strategies[BlogPlatform.weixin] = WeixinStrategy();
  }

  /// 从 HTML 字符串提取内容
  Future<ArticleContent> extractFromHtml(String htmlString, String url) async {
    // 解析 HTML
    final document = html_parser.parse(htmlString);

    // 识别平台
    final platform = BlogPlatform.fromUrl(url);

    // 获取对应策略
    final strategy = _strategies[platform] ?? GenericStrategy();

    // 执行解析
    return strategy.parse(document, url);
  }

  /// 从 Document 提取内容
  ArticleContent extractFromDocument(Document document, String url) {
    final platform = BlogPlatform.fromUrl(url);
    final strategy = _strategies[platform] ?? GenericStrategy();
    return strategy.parse(document, url);
  }

  /// 识别平台
  BlogPlatform identifyPlatform(String url) {
    return BlogPlatform.fromUrl(url);
  }

  /// 获取指定 URL 的元素屏蔽脚本
  /// 返回 null 表示该平台不需要屏蔽任何元素
  String? getBlockElementsScript(String url) {
    final platform = BlogPlatform.fromUrl(url);
    final strategy = _strategies[platform] ?? GenericStrategy();
    return strategy.getBlockElementsScript();
  }

  /// 添加自定义策略
  void registerStrategy(BlogPlatform platform, PlatformStrategy strategy) {
    _strategies[platform] = strategy;
  }
}
