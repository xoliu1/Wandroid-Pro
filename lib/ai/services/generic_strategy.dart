import 'package:html/dom.dart';
import '../models/article_content.dart';
import 'platform_strategy.dart';

/// 通用解析策略（降级方案）
/// 当无法识别平台时使用
class GenericStrategy extends PlatformStrategy {
  @override
  ArticleContent parse(Document doc, String url) {
    final title = extractTitle(doc);
    final author = extractAuthor(doc);
    final publishTime = extractPublishTime(doc);
    
    // 尝试找到主要内容区域
    final contentElement = doc.querySelector('article')
        ?? doc.querySelector('main')
        ?? doc.querySelector('[role="main"]')
        ?? doc.querySelector('.content')
        ?? doc.querySelector('.main-content')
        ?? doc.body;
    
    if (contentElement != null) {
      // 移除常见的无关元素
      removeElements(contentElement, [
        'header',
        'footer',
        'nav',
        'aside',
        '.sidebar',
        '.nav',
        '.header',
        '.footer',
        '.comment',
        '.related',
        '.recommend',
        'script',
        'style',
        'iframe',
        '[class*="ad"]',
        '[id*="ad"]',
      ]);
    }
    
    final content = cleanText(contentElement?.text ?? '');
    
    return ArticleContent.create(
      title: title,
      content: content,
      author: author,
      publishTime: publishTime,
      url: url,
      platform: '未知平台',
    );
  }
}
