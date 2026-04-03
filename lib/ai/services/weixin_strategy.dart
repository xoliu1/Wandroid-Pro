import 'package:html/dom.dart';
import '../models/article_content.dart';
import '../models/blog_platform.dart';
import 'platform_strategy.dart';

/// 微信公众号解析策略
class WeixinStrategy extends PlatformStrategy {
  @override
  ArticleContent parse(Document doc, String url) {
    // 提取标题
    final title = doc.querySelector('#activity-name')?.text.trim()
        ?? doc.querySelector('h1')?.text.trim()
        ?? extractTitle(doc);
    
    // 提取作者
    final author = doc.querySelector('#js_name')?.text.trim()
        ?? doc.querySelector('.profile_nickname')?.text.trim()
        ?? extractAuthor(doc);
    
    // 提取时间
    final publishTime = doc.querySelector('#publish_time')?.text.trim()
        ?? extractPublishTime(doc);
    
    // 提取正文
    final contentElement = doc.querySelector('#js_content')
        ?? doc.querySelector('.rich_media_content');
    
    if (contentElement != null) {
      // 移除广告和无关内容
      removeElements(contentElement, [
        '.rich_media_tool',
        '.profile_container',
        'script',
        'style',
        'iframe',
        '[class*="ad"]',
      ]);
    }
    
    final content = cleanText(contentElement?.text ?? '');
    
    return ArticleContent.create(
      title: title,
      content: content,
      author: author,
      publishTime: publishTime,
      url: url,
      platform: BlogPlatform.weixin.displayName,
    );
  }
}
