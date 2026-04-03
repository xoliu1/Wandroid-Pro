import 'package:html/dom.dart';
import '../models/article_content.dart';
import '../models/blog_platform.dart';
import 'platform_strategy.dart';

/// 掘金解析策略
class JuejinStrategy extends PlatformStrategy {
  @override
  String? getBlockElementsScript() {
    // 掘金专属：隐藏 APP 内打开按钮（增强版：支持动态元素）
    return '''
      (function() {
        // 掘金特定选择器
        const selectors = [
          '.open-button.app-open-button',    // APP 内打开按钮
          '.app-open-button',                // APP 打开按钮（通用）
          '[class*="open-button"]',          // 所有包含 open-button 的元素
          '[class*="app-open"]',             // 所有包含 app-open 的元素
        ];
        
        // 移除元素的核心函数
        function removeElements() {
          let removed = false;
          
          // 方法1：CSS 选择器
          selectors.forEach(selector => {
            try {
              document.querySelectorAll(selector).forEach(el => {
                if (el && el.parentNode) {
                  el.remove();
                  removed = true;
                  console.log('✅ 移除元素:', selector);
                }
              });
            } catch (e) {
              console.log('❌ 移除元素失败:', selector, e);
            }
          });
          
          // 方法2：通过 data 属性精确匹配
          document.querySelectorAll('[data-v-644f89e1][data-v-539963b4]').forEach(el => {
            const text = el.textContent || el.innerText || '';
            if (text.includes('APP内打开') || text.includes('APP內打開')) {
              el.remove();
              removed = true;
              console.log('✅ 移除掘金 APP 按钮（data 属性匹配）');
            }
          });
          
          // 方法3：通过文本内容匹配（兜底）
          document.querySelectorAll('div, a, button').forEach(el => {
            const text = el.textContent || el.innerText || '';
            if ((text.trim() === 'APP内打开' || text.trim() === 'APP內打開') && 
                el.className && 
                (el.className.includes('open') || el.className.includes('app'))) {
              el.remove();
              removed = true;
              console.log('✅ 移除元素（文本匹配）:', el.className);
            }
          });
          
          return removed;
        }
        
        // 立即执行一次
        removeElements();
        
        // 延迟重试（应对异步加载）
        setTimeout(() => {
          if (removeElements()) {
            console.log('🔄 延迟移除成功（500ms）');
          }
        }, 500);
        
        setTimeout(() => {
          if (removeElements()) {
            console.log('🔄 延迟移除成功（1000ms）');
          }
        }, 1000);
        
        setTimeout(() => {
          if (removeElements()) {
            console.log('🔄 延迟移除成功（2000ms）');
          }
        }, 2000);
        
        // 使用 MutationObserver 监听 DOM 变化（持续监控）
        const observer = new MutationObserver((mutations) => {
          removeElements();
        });
        
        // 开始观察
        observer.observe(document.body, {
          childList: true,
          subtree: true
        });
        
        console.log('✅ 掘金元素拦截器已启动（增强版）');
      })();
    ''';
  }

  @override
  ArticleContent parse(Document doc, String url) {
    // 提取标题
    final title = doc.querySelector('.article-title')?.text.trim()
        ?? doc.querySelector('h1')?.text.trim()
        ?? extractTitle(doc);
    
    // 提取作者
    final author = doc.querySelector('.username')?.text.trim()
        ?? doc.querySelector('.author-name')?.text.trim()
        ?? extractAuthor(doc);
    
    // 提取时间
    final publishTime = doc.querySelector('.meta-box time')?.text.trim()
        ?? doc.querySelector('.time')?.text.trim()
        ?? extractPublishTime(doc);
    
    // 提取正文
    final contentElement = doc.querySelector('.article-content')
        ?? doc.querySelector('.markdown-body')
        ?? doc.querySelector('[class*="article-content"]');
    
    if (contentElement != null) {
      // 移除广告和无关内容
      removeElements(contentElement, [
        '.sidebar',
        '.author-info-block',
        '.recommended-area',
        'script',
        'style',
        'iframe',
        '.ad',
        '[class*="ad-"]',
      ]);
    }
    
    final content = cleanText(contentElement?.text ?? '');
    
    return ArticleContent.create(
      title: title,
      content: content,
      author: author,
      publishTime: publishTime,
      url: url,
      platform: BlogPlatform.juejin.displayName,
    );
  }
}
