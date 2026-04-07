import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/remote/CgiCollect.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:wanandroid_pro/utils/platform_utils.dart';

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
      backgroundColor: MCMColors.background(context),
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
                  MCMStarburst(size: 48, color: MCMColors.mustard.withOpacity(0.25)),
                  const SizedBox(height: 16),
                  Text(
                    '暂无收藏',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MCMColors.secondaryText(context),
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
                style: TextStyle(fontSize: 13, color: MCMColors.secondaryText(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              MCMPrimaryButton(
                label: 'RETRY',
                icon: Icons.refresh_rounded,
                isSmall: true,
                onTap: () {
                  ref.read(collectArticleProvider.notifier).refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}