import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/pages/article/article_list_page.dart';
import 'package:wanandroid_pro/pages/chapter/chapter_page.dart';
import 'package:wanandroid_pro/pages/project_list_page.dart';
import 'package:wanandroid_pro/pages/ai/ai_chat_page.dart';
import 'package:wanandroid_pro/providers/project_provider.dart';
import 'package:wanandroid_pro/providers/wx_article_provider.dart';
import 'package:wanandroid_pro/remote/CgiUser.dart';

import '../../ai/providers/user_context_provider.dart';
import '../../ai/services/browsing_history_db.dart';
import '../../local/KV.dart';
import '../../providers/chapter_provider.dart';
import '../../utils/mcm_widget.dart';
import '../article/search_page.dart';
import '../drawer/slider.dart';
import '../knowledgeTree/knowledge_page.dart';
import '../wxmp/wx_article_page.dart';
import '../../remote/CgiCollect.dart';

/// 首页 多tab
class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final pages = [
    const ArticleListPage(),
    const KnowledgeSystemTab(),
    const AIChatPage(),
    const ChapterPage(),
    const WxArticleTabsPage(),
    const ProjectListPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: pages.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async{

      getUserInfo();
      ref.read(chapterProvider);
      ref.read(projectProvider);
      ref.read(wxAuthorProvider);
      ref.read(wxArticleProvider(408));
      ref.read(naviProvider);
      ref.read(squareArticleProvider);

      // 每日检查一次登录态是否过期
      _dailySessionCheck();

      // 注册收藏变更回调，触发用户画像刷新
      CgiCollect.onCollectChanged = () {
        ref.read(userContextProvider.notifier).scheduleRefresh();
      };

      // 后台采集用户上下文（不阻塞 UI，供全局 AI 功能使用）
      ref.read(userContextProvider.notifier).initialize();

      // 清理 30 天前的旧浏览记录
      BrowsingHistoryDatabase().cleanOldRecords();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 每天检查一次登录态是否过期
  ///
  /// 流程：
  /// 1. 检查本地是否标记为已登录 && 今天还没检查过
  /// 2. 请求用户信息接口验证 Cookie 有效性
  /// 3. 如果过期（请求失败/返回 -1001），AuthInterceptor 会自动触发
  ///    AuthGuard.handleSessionExpired()，清除本地数据+Cookie 并弹窗引导登录
  /// 4. 标记今天已检查，避免重复触发
  Future<void> _dailySessionCheck() async {
    // 未登录或今天已检查过，跳过
    if (!isLogin() || hasCheckedSessionToday()) return;

    // 标记今天已检查（无论结果如何，一天只查一次）
    markSessionCheckedToday();

    try {
      final isValid = await CgiUser().checkSessionValid();
      if (!isValid && mounted) {
        // 登录态已过期，checkSessionValid 内部请求会触发 AuthInterceptor
        // AuthInterceptor -> AuthGuard.handleSessionExpired() 会：
        //   1. 清除本地登录数据 (clearLocalLoginData)
        //   2. 更新 loginStateProvider 状态
        //   3. 清除 Cookie (NetworkService.clearCookies)
        //   4. 弹窗引导用户登录（可选择"稍后再说"）
        if (kDebugMode) {
          print('每日检查：登录态已过期，已触发清理和弹窗引导');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('每日登录态检查异常: $e');
      }
    }
  }

  String getAppBarTitle() {
    final titles = ["首页",  "知识体系", "AI 对话","导航与问答",  "公众号", "项目",];
    final index = _tabController.index;
    return index >= 0 && index < titles.length ? titles[index] : "wan Android";
  }

  void _openSearchPage() async {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const SearchPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF2C2416) : const Color(0xFF3A2D1F);
    final barBorder = isDark ? const Color(0xFF4A3828) : const Color(0xFF6B5D4F);

    return Scaffold(
      backgroundColor: colorTheme.surface,
      drawer: const HomeSlider(),
      onDrawerChanged: (isOpened) {
        // Drawer 关闭时主动清除焦点，防止 IndexedStack 中的 TextField 意外获取焦点导致键盘弹出
        if (!isOpened) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      appBar: AppBar(
        backgroundColor: colorTheme.surface,
        leading: Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: MCMColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_rounded, size: 20),
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: MCMColors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              getAppBarTitle().toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: MCMColors.mustard,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _openSearchPage,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MCMColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.search, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
          children: [
            IndexedStack(
              index: _tabController.index,
              children: pages,
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: SlideUpEntrance(
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: barBg,
                      border: Border.all(color: barBorder.withOpacity(0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C2416).withOpacity(0.25),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: MCMColors.orange, width: 2.5),
                      ),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: MCMColors.orange,
                    unselectedLabelColor: const Color(0xFFA08B78),
                    tabs: [
                      _buildTab(0, CupertinoIcons.news_solid),
                      _buildTab(1, CupertinoIcons.map_fill),
                      _buildTab(2, CupertinoIcons.chat_bubble_2_fill),
                      _buildTab(3, CupertinoIcons.square_grid_2x2_fill),
                      _buildTab(4, Icons.wechat),
                      _buildTab(5, CupertinoIcons.folder_fill),
                    ],
                  ),
                  ),
                ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon) {
    return Tab(
      icon: AnimatedTabIcon(
        isSelected: _tabController.index == index,
        icon: icon,
      ),
    );
  }
}
