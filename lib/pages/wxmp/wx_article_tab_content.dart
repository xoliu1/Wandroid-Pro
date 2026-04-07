import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/pages/widget/wx_article_card.dart';
import 'package:wanandroid_pro/providers/wx_article_provider.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/functions.dart';

import '../../ai/ui/article_webview_page.dart';

class WxArticleTabContent extends ConsumerStatefulWidget {
  final int authorId;

  const WxArticleTabContent({super.key, required this.authorId});

  @override
  ConsumerState<WxArticleTabContent> createState() => _WxArticleTabContentState();
}

class _WxArticleTabContentState extends ConsumerState<WxArticleTabContent>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(wxArticleProvider(widget.authorId).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(wxArticleProvider(widget.authorId).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: CupertinoColors.systemBlue,
      child: Consumer(
        builder: (context, ref, child) {
          final articlesAsync = ref.watch(wxArticleProvider(widget.authorId));
          final articleNotifier = ref.read(wxArticleProvider(widget.authorId).notifier);

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
                    style: CupertinoTheme.of(context)
                        .textTheme
                        .textStyle
                        .copyWith(color: CupertinoColors.systemGrey),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8),
                itemCount: articles.length + 1,
                itemBuilder: (context, index) {
                  if (index == articles.length) {
                    final hasMoreData = articleNotifier.hasMoreData;
                    final isLoading = articleNotifier.isLoading;

                    if (!hasMoreData) {
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Text(
                            '没有更多文章了',
                            style: CupertinoTheme.of(context)
                                .textTheme
                                .textStyle
                                .copyWith(
                              color: CupertinoColors.systemGrey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    if (isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CupertinoActivityIndicator()),
                      );
                    }

                    return const SizedBox.shrink();
                  }

                  return AnimatedListItem(
                    index: index,
                    child: WxArticleCard(
                      article: articles[index],
                      onTap: () {
                        final article = articles[index];
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => ArticleWebViewPage(
                              url: article.link,
                              title: article.title,
                            ),
                          ),
                        );
                      },
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