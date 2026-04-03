import 'package:html/dom.dart';
import '../models/article_content.dart';
import '../models/blog_platform.dart';
import 'platform_strategy.dart';

/// CSDN 解析策略
class CSDNStrategy extends PlatformStrategy {
  @override
  String? getBlockElementsScript() {
    // CSDN 专属：隐藏 APP 引导和登录弹窗
    return '''
      (function() {
        // CSDN 特定选择器
        const selectors = [
          '.open_app_channelCode',       // APP 阅读全文按钮
          '.app_abtest_btn_open',        // APP 阅读全文按钮
          '.btn_open_app_prompt_box',    // 打开 APP 提示框
          '.weixin-shadowbox',           // 微信引导
          '.passport-login-container',   // 登录弹窗
          '.csdn-side-toolbar',          // 侧边工具栏
          '#footerRightDownload',        // 底部下载
          '.feed-Sign-weixin',           // 微信登录引导
          '.option-box',                 // 打开 App 弹窗
          '.open-app-tip',               // App 提示
          '.openApp',                    // 打开 App 按钮
          '.feed-Sign',                  // 登录引导
          '[class*="download-app"]',     // 下载 App 相关
          '[class*="open-app"]',         // 打开 App 相关
          '[class*="open_app"]',         // 打开 App 相关（下划线版本）
        ];
        
        // 移除元素
        selectors.forEach(selector => {
          try {
            document.querySelectorAll(selector).forEach(el => {
              if (el) el.remove();
            });
          } catch (e) {
            console.log('移除元素失败:', selector, e);
          }
        });
        
        // 移除 body 上的滚动锁定
        document.body.style.overflow = 'auto';
        document.documentElement.style.overflow = 'auto';
        
        // 移除固定定位的遮罩层（只针对 CSDN 特定样式）
        document.querySelectorAll('div').forEach(el => {
          const style = window.getComputedStyle(el);
          if (style.position === 'fixed' && 
              parseInt(style.zIndex) > 1000 && 
              el.className && 
              (el.className.includes('open') || 
               el.className.includes('app') || 
               el.className.includes('login'))) {
            el.remove();
          }
        });
        
        console.log('✅ CSDN 移动端引导元素已隐藏');
      })();
    ''';
  }

  @override
  ArticleContent parse(Document doc, String url) {
    // 提取标题
    final title = doc.querySelector('h1.title-article')?.text.trim() 
        ?? doc.querySelector('.article-title')?.text.trim()
        ?? extractTitle(doc);
    
    // 提取作者
    final author = doc.querySelector('.follow-nickName')?.text.trim()
        ?? doc.querySelector('.user-info a')?.text.trim()
        ?? extractAuthor(doc);
    
    // 提取时间
    final publishTime = doc.querySelector('.time')?.text.trim()
        ?? doc.querySelector('.article-bar-top .date')?.text.trim()
        ?? extractPublishTime(doc);
    
    // 提取正文
    final contentElement = doc.querySelector('#article_content')
        ?? doc.querySelector('.article_content')
        ?? doc.querySelector('#content_views')
        ?? doc.querySelector('.markdown_views');
    
    if (contentElement != null) {
      // 移除广告和无关内容
      removeElements(contentElement, [
        '.csdn-side-toolbar',
        '.comment-box',
        '.recommend-box',
        '.toolbar-box',
        '.hide-article-box',
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
      platform: BlogPlatform.csdn.displayName,
    );
  }
}
