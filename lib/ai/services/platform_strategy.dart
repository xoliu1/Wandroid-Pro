import 'package:html/dom.dart';
import '../models/article_content.dart';

/// 平台解析策略接口
abstract class PlatformStrategy {
  /// 解析 HTML 文档，提取文章内容
  ArticleContent parse(Document doc, String url);
  
  /// 获取元素屏蔽的 JavaScript 代码
  /// 返回 null 表示不需要屏蔽任何元素（默认行为）
  /// 子类可重写此方法以提供特定平台的屏蔽策略
  String? getBlockElementsScript() {
    return null; // 默认不屏蔽任何元素
  }
  
  /// 提取标题（子类可重写）
  String extractTitle(Document doc) {
    // 尝试多个常见的标题选择器
    final selectors = ['h1', 'title', '.title', '.article-title', '.post-title'];
    
    for (final selector in selectors) {
      final element = doc.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        return element.text.trim();
      }
    }
    
    return '未找到标题';
  }
  
  /// 提取作者（子类可重写）
  String? extractAuthor(Document doc) {
    final selectors = [
      '.author',
      '.article-author',
      '.post-author',
      '[class*="author"]',
      '[id*="author"]',
    ];
    
    for (final selector in selectors) {
      final element = doc.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        return element.text.trim();
      }
    }
    
    return null;
  }
  
  /// 提取发布时间（子类可重写）
  String? extractPublishTime(Document doc) {
    final selectors = [
      '.time',
      '.publish-time',
      '.post-time',
      '[class*="time"]',
      'time',
    ];
    
    for (final selector in selectors) {
      final element = doc.querySelector(selector);
      if (element != null && element.text.trim().isNotEmpty) {
        return element.text.trim();
      }
    }
    
    return null;
  }
  
  /// 清理文本内容
  String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // 多个空白符替换为单个空格
        .replaceAll(RegExp(r'\n\s*\n'), '\n') // 多个换行替换为单个换行
        .trim();
  }
  
  /// 移除指定元素
  void removeElements(Element? container, List<String> selectors) {
    if (container == null) return;
    
    for (final selector in selectors) {
      container.querySelectorAll(selector).forEach((element) {
        element.remove();
      });
    }
  }
}
