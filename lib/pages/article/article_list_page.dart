import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/widget/article_card.dart';
import 'package:notes_app/pages/widget/article_banner.dart';
import 'package:notes_app/providers/article_provider.dart';
import 'package:notes_app/remote/CgiUser.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

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
    //todo 抽屉样式改
    return CupertinoPageScaffold(
      backgroundColor: AppColors.groupedBackground(context),
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
                    onPressed: _onRefresh,
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
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              color: CupertinoColors.systemGrey,
                            ),
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
                          child: Text(
                            '没有更多文章了',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .copyWith(
                                  color: CupertinoColors.systemGrey,
                                ),
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
