import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/remote/CgiCollect.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/platform_utils.dart';

import '../../providers/collect_provider.dart';
import '../widget/collect_article_card.dart';

class CollectListPage extends ConsumerStatefulWidget {
  const CollectListPage({super.key});

  @override
  ConsumerState<CollectListPage> createState() => _CollectListPageState();
}

class _CollectListPageState extends ConsumerState<CollectListPage> {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(collectArticleProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(collectArticleProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final collectState = ref.watch(collectArticleProvider);
    
    return PlatformScaffold(
      backgroundColor: context.surfaceColor,
      appBar: PlatformAppBar(
        title: const Text('我的收藏'),
      ),
      body: collectState.when(
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PlatformUtils.isIOS 
                        ? CupertinoIcons.heart 
                        : Icons.favorite_border,
                    size: 64,
                    color: context.secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无收藏',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: articles.length + 1,
              itemBuilder: (context, index) {
                if (index < articles.length) {
                  final article = articles[index];
                  return AnimatedListItem(
                    index: index,
                    child: CollectArticleCard(
                      article: article,
                      onCollectChanged: ((){
                        CgiCollect().uncollectArticle(article.id, isMyCollect: true, originId: article.originId);
                        ref.read(collectArticleProvider.notifier).removeById(article.id);
                      }),
                    ),
                  );
                } else {
                  // 加载更多指示器
                  final isLoadingMore = ref.watch(
                    collectArticleProvider.select(
                      (state) => state.maybeWhen(
                        data: (_) => false,
                        loading: () => true,
                        orElse: () => false,
                      ),
                    ),
                  );

                  if (isLoadingMore) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: PlatformLoadingIndicator(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
              },
            ),
          );
        },
        loading: () => Center(
          child: PlatformLoadingIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PlatformUtils.isIOS 
                    ? CupertinoIcons.exclamationmark_triangle 
                    : Icons.error_outline,
                size: 64,
                color: context.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                '加载失败: ${error.toString()}',
                style: TextStyle(
                  fontSize: 16,
                  color: context.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              PlatformButton(
                onPressed: () {
                  ref.read(collectArticleProvider.notifier).refresh();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}