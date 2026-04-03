import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/wxmp/wx_article_tab_content.dart';
import 'package:notes_app/providers/wx_article_provider.dart';
import 'package:notes_app/utils/app_colors.dart';

class WxArticleTabsPage extends ConsumerStatefulWidget {
  const WxArticleTabsPage({super.key});

  @override
  ConsumerState<WxArticleTabsPage> createState() => _WxArticleTabsPageState();
}

class _WxArticleTabsPageState extends ConsumerState<WxArticleTabsPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.groupedBackground(context),
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final authorsAsync = ref.watch(wxAuthorProvider);

            return authorsAsync.when(
              loading: () => const Center(
                child: CupertinoActivityIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle,
                        size: 48, color: CupertinoColors.systemGrey),
                    const SizedBox(height: 16),
                    Text(
                      '加载失败: ${error.toString()}',
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      color: CupertinoColors.systemBlue,
                      onPressed: () => ref.invalidate(wxAuthorProvider),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (authors) {
                if (authors.isEmpty) {
                  return Center(
                    child: Text(
                      '暂无公众号',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .copyWith(color: CupertinoColors.systemGrey),
                    ),
                  );
                }

                // 初始化或更新 TabController（仅在数量变化时）
                if (_tabController == null || _tabController!.length != authors.length) {
                  _tabController?.dispose();
                  _tabController = TabController(
                    length: authors.length,
                    vsync: this,
                  );
                }

                return Column(
                  children: [
                    // 自定义Tab栏
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.tabBackground(context),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.divider(context),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController!,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: AppColors.tabSelected(context),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        labelColor: AppColors.tabSelected(context),
                        unselectedLabelColor: AppColors.tabUnselected(context),
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                        tabs: authors.map((author) {
                          return Tab(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                author.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Tab内容 - 使用独立的页面
                    Expanded(
                      child: TabBarView(
                        controller: _tabController!,
                        children: authors.map((author) {
                          return WxArticleTabContent(authorId: author.id);
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}