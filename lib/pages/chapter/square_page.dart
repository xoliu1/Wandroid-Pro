import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/widget/article_card.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

import '../../providers/chapter_provider.dart';

class SquarePage extends ConsumerStatefulWidget {
  const SquarePage({super.key});

  @override
  ConsumerState<SquarePage> createState() => _SquarePageState();
}

class _SquarePageState extends ConsumerState<SquarePage> {
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
      ref.read(squareArticleProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(squareArticleProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final squareNotifier = ref.read(squareArticleProvider.notifier);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.groupedBackground(context),
      // navigationBar: CupertinoNavigationBar(
      //   leading: CupertinoButton(
      //     padding: EdgeInsets.zero,
      //     minSize: 0,
      //     onPressed: () => _showPageSizeSheet(squareNotifier),
      //     child: const Icon(CupertinoIcons.settings, size: 24),
      //   ),
      // ),
      child: SafeArea(
        child: _buildContent(squareNotifier),
      ),
    );
  }

  Widget _buildContent(squareNotifier) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: CupertinoColors.systemBlue,
      child: Consumer(
        builder: (context, ref, child) {
          final articlesAsync = ref.watch(squareArticleProvider);

          return articlesAsync.when(
            loading: () =>
            const Center(
              child: CupertinoActivityIndicator(),
            ),
            error: (error, stack) =>
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle,
                          size: 48, color: CupertinoColors.systemGrey),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败: ${error.toString()}',
                        style: CupertinoTheme
                            .of(context)
                            .textTheme
                            .textStyle,
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
                    '暂无广场文章',
                    style: CupertinoTheme
                        .of(context)
                        .textTheme
                        .textStyle
                        .copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: articles.length + 1,
                itemBuilder: (context, index) {
                  if (index == articles.length) {
                    final hasMoreData =
                        squareNotifier.hasMoreData;
                    final isLoading =
                        squareNotifier.isLoading;

                    if (!hasMoreData) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '没有更多文章了',
                            style: CupertinoTheme
                                .of(context)
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
                        child: Center(
                            child: CupertinoActivityIndicator()),
                      );
                    }

                    return const SizedBox.shrink();
                  }

                  return AnimatedListItem(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ArticleCard(article: articles[index]),
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

  void _showPageSizeSheet(squareNotifier) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) =>
          CupertinoActionSheet(
            title: const Text('选择每页显示数量'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  squareNotifier.setPageSize(10);
                  Navigator.pop(context);
                },
                child: const Text('每页10条'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  squareNotifier.setPageSize(20);
                  Navigator.pop(context);
                },
                child: const Text('每页20条'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  squareNotifier.setPageSize(30);
                  Navigator.pop(context);
                },
                child: const Text('每页30条'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  squareNotifier.setPageSize(40);
                  Navigator.pop(context);
                },
                child: const Text('每页40条'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ),
    );
  }
}