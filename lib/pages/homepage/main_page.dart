import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/article/article_list_page.dart';
import 'package:notes_app/pages/chapter/chapter_page.dart';
import 'package:notes_app/pages/project_list_page.dart';
import 'package:notes_app/pages/ai/ai_chat_page.dart';
import 'package:notes_app/providers/project_provider.dart';
import 'package:notes_app/providers/wx_article_provider.dart';
import 'package:notes_app/remote/CgiUser.dart';

import '../../ai/providers/user_context_provider.dart';
import '../../ai/services/browsing_history_db.dart';
import '../../local/KV.dart';
import '../../providers/chapter_provider.dart';
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
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        centerTitle: true,
        title: Text(
          getAppBarTitle(),
          textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _openSearchPage,
            minimumSize: const Size(0, 0),
            child: const Icon(CupertinoIcons.search, size: 24),
          )
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
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                    controller: _tabController,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                      insets: EdgeInsets.fromLTRB(0, 0, 0, 8),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withOpacity(0.6),
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
