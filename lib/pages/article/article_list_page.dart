import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/pages/widget/article_card.dart';
import 'package:wanandroid_pro/pages/widget/article_banner.dart';
import 'package:wanandroid_pro/providers/article_provider.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

class ArticleListPage extends ConsumerStatefulWidget {
  const ArticleListPage({super.key});

  @override
  ConsumerState<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends ConsumerState<ArticleListPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();



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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(articleProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(articleProvider.notifier).refresh();
    await ref.read(bannerProvider.notifier).refresh();
  }



  @override
  Widget build(BuildContext context) {
    final articleNotifier = ref.read(articleProvider.notifier);
    return CupertinoPageScaffold(
      backgroundColor: MCMColors.background(context),
      child: SafeArea(
          child: _buildContent(articleNotifier),
        ),
    );
  }

  Widget _buildContent(articleNotifier) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: CupertinoColors.systemBlue,
      child: Consumer(
        builder: (context, ref, child) {
          final articlesAsync = ref.watch(articleProvider);
          final bannersAsync = ref.watch(bannerProvider);

          return articlesAsync.when(
            loading: () => const Center(
              child: CupertinoActivityIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MCMStarburst(size: 48, color: MCMColors.coral.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    '加载失败',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MCMColors.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      color: MCMColors.secondaryText(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  MCMPrimaryButton(
                    label: 'RETRY',
                    icon: Icons.refresh_rounded,
                    isSmall: true,
                    onTap: _onRefresh,
                  ),
                ],
              ),
            ),
            data: (articles) {
              if (articles.isEmpty) {
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MCMStarburst(size: 40, color: MCMColors.mustard.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        '暂无文章',
                        style: TextStyle(
                          fontSize: 15,
                          color: MCMColors.secondaryText(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: articles.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return bannersAsync.when(
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                      error: (error, stack) => const SizedBox(
                        height: 200,
                        child: Center(
                            child: Icon(CupertinoIcons.exclamationmark_circle,
                                color: CupertinoColors.systemGrey)),
                      ),
                      data: (banners) => BannerCarousel(banners: banners),
                    );
                  }

                  final articleIndex = index - 1;
                  if (articleIndex == articles.length) {
                    final hasMoreData = articleNotifier.hasMoreData;
                    final isLoading = articleNotifier.isLoading;

                    if (!hasMoreData) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(width: 20, height: 2, decoration: BoxDecoration(color: MCMColors.mustard.withOpacity(0.3), borderRadius: BorderRadius.circular(1))),
                              const SizedBox(width: 10),
                              Text(
                                '没有更多了',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: MCMColors.secondaryText(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(width: 20, height: 2, decoration: BoxDecoration(color: MCMColors.mustard.withOpacity(0.3), borderRadius: BorderRadius.circular(1))),
                            ],
                          ),
                        ),
                      );
                    }

                    if (isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }

                    return const SizedBox.shrink();
                  }

                  return AnimatedListItem(
                    index: articleIndex,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ArticleCard(article: articles[articleIndex]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
