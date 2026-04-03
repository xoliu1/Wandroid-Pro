/// AI 功能模块导出文件
/// 
/// 包含:
/// - models: 数据模型 (BlogPlatform, ArticleContent)
/// - services: 内容提取服务 (ContentExtractor, 各平台策略)
/// - ui: WebView UI组件 (ArticleWebViewPage)
/// - config: AI配置 (AIConfig)

// 模型
export 'models/blog_platform.dart';
export 'models/article_content.dart';
export 'models/ai_provider_config.dart';
export 'models/chat_message.dart';

// 服务
export 'services/content_extractor.dart';
export 'services/platform_strategy.dart';
export 'services/csdn_strategy.dart';
export 'services/juejin_strategy.dart';
export 'services/weixin_strategy.dart';
export 'services/generic_strategy.dart';
export 'services/ai_test_service.dart';
export 'services/ai_service.dart';

// Providers
export 'providers/ai_provider_manager.dart';
export 'providers/ai_chat_provider.dart';

// UI
export 'ui/article_webview_page.dart';
export 'ui/extracted_content_page.dart';
export 'ui/ai_provider_management_page.dart';
export 'ui/ai_provider_edit_page.dart';
export 'ui/ai_chat_panel.dart';
