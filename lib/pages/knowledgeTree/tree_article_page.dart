import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/widget/article_card.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:tab_container/tab_container.dart';
import 'package:notes_app/utils/app_colors.dart';
import '../../providers/chapter_provider.dart';
import '../../remote/Api.dart';

/// 知识体系 - 详情
class TreeArticlePage extends ConsumerStatefulWidget {
  const TreeArticlePage({
    super.key,
    required this.chapter,
     this.cid = 0,
  });

  final Chapter chapter;

  //从外面进来点击的那个 chip 对应的 child
  final int cid;


  @override
  ConsumerState<TreeArticlePage> createState() => _TreeArticlePageState();
}

class _TreeArticlePageState extends ConsumerState<TreeArticlePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Chapter> get children => widget.chapter.children;

  int get cid => widget.cid;

  final tabColors = const <Color>[
    Color(0xfffa86be),
    Color(0xffa275e3),
    Color(0xff9aebed),
    Color(0xff9aebed),
    Color(0xffffb347),
    Color(0xff90ee90),
    Color(0xffadd8e6),
    Color(0xffffcccb),
    Color(0xffd3d3d3),
  ];

  @override
  void initState() {
    super.initState();
    // 防御性检查：如果没有子分类，避免崩溃
    if (widget.chapter.children.isEmpty) {
      return;
    }
    _tabController = TabController(
      length: widget.chapter.children.length,
      vsync: this,
    );
  }


  @override
  void dispose() {
    // 只有在 TabController 初始化后才 dispose
    if (widget.chapter.children.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果没有子分类，显示空状态页面
    if (widget.chapter.children.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.groupedBackground(context),
        appBar: AppBar(
          title: Text(widget.chapter.name),
          backgroundColor: AppColors.cardBackground(context),
          foregroundColor: AppColors.primaryText(context),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 80,
                color: AppColors.emptyIcon(context),
              ),
              const SizedBox(height: 16),
              Text(
                '暂无子分类',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.tertiaryText(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '「${widget.chapter.name}」目前没有内容',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.disabledText(context),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 方案 D：始终使用 TabContainer，tab 多时包在横向可滚动容器里
    // 每个 tab 至少需要 90 的宽度才能显示清楚
    final screenWidth = MediaQuery.of(context).size.width;
    final minTabWidth = 90.0;
    // 当所有 tab 需要的总宽度超过屏幕宽度时，启用横向滚动
    final needsScroll = children.length * minTabWidth > screenWidth;
    // 动态计算 TabContainer 的宽度：取屏幕宽度和 tab 总需求宽度的较大值
    final containerWidth = needsScroll
        ? children.length * minTabWidth
        : screenWidth;

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      appBar: AppBar(
        title: Text(widget.chapter.name),
        backgroundColor: AppColors.cardBackground(context),
        foregroundColor: AppColors.primaryText(context),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab 区域：需要滚动时包在 SingleChildScrollView 里
          if (needsScroll)
            SizedBox(
              height: 46,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: containerWidth,
                  height: 46,
                  child: TabContainer(
                    controller: _tabController,
                    borderRadius: BorderRadius.circular(12),
                    tabEdge: TabEdge.top,
                    tabExtent: 46,
                    childPadding: EdgeInsets.zero,
                    curve: Curves.easeInToLinear,
                    colors: List<Color>.generate(
                      children.length,
                      (index) => tabColors[index % tabColors.length],
                    ),
                    selectedTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 15.0),
                    unselectedTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13.0),
                    tabs: children.map((child) {
                      return Text(child.name);
                    }).toList(),
                    // 使用 child 模式，只渲染 tab 头部，内容区域单独展示
                    child: const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          // 内容区域
          Expanded(
            child: needsScroll
                // tab 多时：用 AnimatedBuilder 监听 tabController，
                // 并用 AnimatedContainer 模拟 TabContainer 的颜色背景效果
                ? AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      final currentColor = tabColors[_tabController.index % tabColors.length];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInToLinear,
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IndexedStack(
                          index: _tabController.index,
                          children: children.map((child) {
                            return _ArticleListTab(
                              cid: child.id,
                              title: child.name,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  )
                // tab 少时：直接用 TabContainer 完整展示（tab + 内容一体）
                : TabContainer(
                    controller: _tabController,
                    borderRadius: BorderRadius.circular(12),
                    tabEdge: TabEdge.top,
                    curve: Curves.easeInToLinear,
                    transitionBuilder: (child, animation) {
                      animation = CurvedAnimation(
                          curve: Curves.easeInToLinear, parent: animation);
                      return SlideTransition(
                        position: Tween(
                          begin: const Offset(0.2, 0.0),
                          end: const Offset(0.0, 0.0),
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    colors: List<Color>.generate(
                      children.length,
                      (index) => tabColors[index % tabColors.length],
                    ),
                    selectedTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 15.0),
                    unselectedTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13.0),
                    tabs: children.map((child) {
                      return Text(child.name);
                    }).toList(),
                    children: children.map((child) {
                      return _ArticleListTab(
                        cid: child.id,
                        title: child.name,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ArticleListTab extends ConsumerStatefulWidget {
  const _ArticleListTab({
    required this.cid,
    required this.title,
  });

  final int cid;
  final String title;

  @override
  ConsumerState<_ArticleListTab> createState() => _ArticleListTabState();
}

class _ArticleListTabState extends ConsumerState<_ArticleListTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

   int get cid => widget.cid;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    ref.read(treeArticleProvider(cid).notifier).loadMore();
  }

  Future<void> _refresh() async {
    await ref.read(treeArticleProvider(cid).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final articlesAsync = ref.watch(treeArticleProvider(cid));

    return articlesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败: ${error.toString()}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _refresh,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      data: (articles) {
        if (articles.isEmpty) {
          return Center(
            child: Text(
              '暂无文章',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey),
            ),
          );
        }

        final notifier = ref.read(treeArticleProvider(cid).notifier);

        return RefreshIndicator(
          onRefresh: _refresh,
          color: Theme.of(context).primaryColor,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: articles.length + 1,
            itemBuilder: (context, index) {
              if (index == articles.length) {
                if (!notifier.hasMoreData) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        '没有更多文章了',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                  );
                }

                if (notifier.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return const SizedBox.shrink();
              }

              return AnimatedListItem(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ArticleCard(article: articles[index], opcity: 0.5,),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
