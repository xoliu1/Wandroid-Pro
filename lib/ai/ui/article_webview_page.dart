import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article_content.dart';
import '../providers/ai_chat_provider.dart';
import '../services/content_extractor.dart';
import 'extracted_content_page.dart';
import 'ai_chat_bottom_sheet.dart';
import '../providers/ai_provider_manager.dart';
import '../services/browsing_history_db.dart';
import '../../local/KV.dart';
import '../../utils/theme.dart';
import 'ai_provider_management_page.dart';

/// 文章 WebView 页面
class ArticleWebViewPage extends ConsumerStatefulWidget {
  final String url;
  final String? title;
  final String? category;

  const ArticleWebViewPage({
    super.key,
    required this.url,
    this.title = "",
    this.category,
  });

  @override
  ConsumerState<ArticleWebViewPage> createState() => _ArticleWebViewPageState();
}

class _ArticleWebViewPageState extends ConsumerState<ArticleWebViewPage> {
  InAppWebViewController? _webViewController;
  final ContentExtractor _extractor = ContentExtractor();

  // 状态
  double _progress = 0.0;
  bool _isExtracting = false; // 是否正在提取内容
  bool _hasShownDialog = false; // 是否已显示过弹窗
  ArticleContent? _content;
  DateTime? _pageOpenTime; // 页面打开时间，用于计算浏览时长

  @override
  void dispose() {
    // 恢复状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 记录浏览时长
    if (_pageOpenTime != null) {
      final duration = DateTime.now().difference(_pageOpenTime!).inSeconds;
      BrowsingHistoryDatabase().updateDuration(widget.url, duration);
    }
    // 清理 AI 对话
    if (_content != null) {
      ref.invalidate(aiChatProvider(_content!));
    }
    debugPrint('🧹 [WebView] 页面销毁，清理 AI 资源');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 全屏模式：隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 记录页面打开时间
    _pageOpenTime = DateTime.now();
    // 延迟记录浏览历史，避免与 WebView 初始化竞争 I/O
    Future.microtask(() {
      BrowsingHistoryDatabase().recordVisit(
        url: widget.url,
        title: widget.title ?? '',
        category: widget.category ?? '',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌙 读取 App 主题设置（而非系统主题）
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return CupertinoPageScaffold(
      // 无导航栏，使用网页内置的
      child: Stack(
        children: [
          // WebView 主体 - 全屏覆盖
          Column(
            children: [
              // 加载进度条
              if (_progress < 1.0 && _progress > 0)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor:
                      CupertinoColors.separator.resolveFrom(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      CupertinoColors.activeBlue),
                ),

              // WebView
              Expanded(
                child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    initialSettings: InAppWebViewSettings(
                      // 使用移动端 UA
                      userAgent:
                          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
                      supportZoom: true,
                      builtInZoomControls: true,
                      displayZoomControls: false,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      // 允许混合内容（解决 ORB 错误）
                      mixedContentMode:
                          MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                      // 禁用部分资源拦截
                      blockNetworkImage: false,
                      blockNetworkLoads: false,
                      // 允许文件访问
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                      // 禁用一些可能导致问题的安全策略（仅用于显示网页，不执行敏感操作）
                      safeBrowsingEnabled: false,
                      // 🌙 关键：根据 App 主题设置 WebView 深色模式（与系统主题独立）
                      forceDark: isDarkMode ? ForceDark.ON : ForceDark.OFF,
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        _progress = 0;
                      });
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                      });
                    },
                    onLoadStop: (controller, url) async {
                      // 注入 CSS 隐藏移动端引导元素
                      await _injectHideMobileElements();

                      // 页面加载完成，始终自动提取内容
                      // 延迟提取内容（等待动态内容加载）
                      await Future.delayed(const Duration(seconds: 1));
                      _extractContentAsync();
                    },
                    onReceivedError: (controller, request, error) {
                      // 静默忽略所有资源错误（ORB、CORS 等通常是广告或跟踪脚本）
                      // 不在 UI 显示错误信息，避免干扰用户阅读
                      debugPrint('⚠️ 资源加载错误 (已忽略): ${error.description}');
                    },
                    // 资源加载错误处理
                    onReceivedHttpError: (controller, request, errorResponse) {
                      // 静默忽略 HTTP 错误（通常是广告或追踪脚本的 404/403）
                      debugPrint(
                          '⚠️ HTTP 错误 [${errorResponse.statusCode}] (已忽略): ${request.url}');
                    },
                  ),
                ),
              ],
            ),

            // AI 聊天 FAB 按钮
            if (_content != null) _buildAIButton(),

            // 提取中指示器（右下角小图标）
            if (_isExtracting)
              Positioned(
                right: 16,
                bottom: 100,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const CupertinoActivityIndicator(
                    radius: 12,
                    color: Colors.white,
                  ),
                ),
              ),

          // Debug 模式下：提取成功后显示弹窗
          // 点击可查看提取的内容
        ],
      ),
    );
  }

  /// 构建 AI 按钮
  Widget _buildAIButton() {
    return Positioned(
      right: 16,
      bottom: 80,
      child: GestureDetector(
        onTap: _showAIChatBottomSheet,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.sparkles,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  /// 显示 AI 对话 BottomSheet
  void _showAIChatBottomSheet() {
    if (_content == null) return;

    // 检查是否有激活的 AI 配置
    final activeProvider = ref.read(activeAIProviderProvider);
    if (activeProvider == null) {
      _showNoAIConfigDialog();
      return;
    }

    // 显示 BottomSheet
    AIChatBottomSheet.show(context, _content!);
  }

  /// 显示未配置 AI 的提示
  void _showNoAIConfigDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: const Text('请先在设置中配置 AI 服务'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('去配置'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const AIProviderManagementPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 注入 JavaScript 隐藏移动端引导元素
  Future<void> _injectHideMobileElements() async {
    if (_webViewController == null) return;

    // 🎯 使用 ContentExtractor 获取平台专属的屏蔽脚本
    final blockScript = _extractor.getBlockElementsScript(widget.url);
    
    if (blockScript != null) {
      try {
        await _webViewController!.evaluateJavascript(source: blockScript);
        debugPrint('✅ 注入平台专属屏蔽脚本成功: ${widget.url}');
      } catch (e) {
        debugPrint('⚠️ 注入 JavaScript 失败: $e');
      }
    } else {
      // 该平台不需要屏蔽任何元素
      debugPrint('ℹ️ 该平台无需元素拦截: ${widget.url}');
    }
  }

  /// 异步提取网页内容（不阻塞 UI）
  void _extractContentAsync() {
    if (_isExtracting) return;

    setState(() {
      _isExtracting = true;
    });

    // 在后台线程提取内容
    Future(() async {
      try {
        // 获取 HTML
        final html = await _webViewController?.evaluateJavascript(
          source: 'document.documentElement.outerHTML',
        );

        if (html == null || html.toString().isEmpty) {
          throw Exception('无法获取网页内容');
        }

        // 提取内容
        final content = await _extractor.extractFromHtml(
          html.toString(),
          widget.url,
        );

        // 更新状态
        if (mounted) {
          setState(() {
            _content = content;
            _isExtracting = false;
          });

          // Debug 模式下且开启调试弹窗设置时显示提取结果（只显示一次）
          if (kDebugMode && getShowExtractDebugDialog() && !_hasShownDialog) {
            _hasShownDialog = true;
            _showExtractionSuccessDialog(content);
          }

          // 打印调试信息
          debugPrint('✅ 提取成功: ${content.title}');
          debugPrint('📱 平台: ${content.platform}');
          debugPrint('📝 字数: ${content.wordCount}');
          debugPrint('🎯 Token: ${content.estimatedTokens}');
          
          // 更新浏览记录的标题（launchInApp 可能传入空标题）
          if (content.title.isNotEmpty) {
            BrowsingHistoryDatabase().updateTitle(
              widget.url,
              content.title,
            );
          }
        }
      } catch (e, stack) {
        debugPrint('❌ 提取失败: $e');
        debugPrint('Stack trace: $stack');

        if (mounted) {
          setState(() {
            _isExtracting = false;
          });
        }
      }
    });
  }

  /// Debug 模式下显示提取成功弹窗
  void _showExtractionSuccessDialog(ArticleContent content) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: CupertinoColors.activeGreen,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('内容提取成功'),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('平台', content.platform),
              _buildInfoRow('标题', content.title),
              _buildInfoRow('作者', content.author ?? '未知'),
              _buildInfoRow('字数', '${content.wordCount} 字'),
              _buildInfoRow('Token', '约 ${content.estimatedTokens}'),
              if (content.publishTime != null)
                _buildInfoRow('发布时间', content.publishTime!),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('关闭'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('查看内容'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => ExtractedContentPage(content: content),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
