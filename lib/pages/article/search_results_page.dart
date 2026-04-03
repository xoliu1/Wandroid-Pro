import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/providers/article_provider.dart';
import 'package:notes_app/pages/widget/article_card.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

class SearchResultsPage extends ConsumerStatefulWidget {
  final String keyword;

  const SearchResultsPage({
    super.key,
    required this.keyword,
  });

  @override
  ConsumerState<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends ConsumerState<SearchResultsPage> {
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
      ref.read(searchArticleProvider(widget.keyword).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        title: Text('搜索: ${widget.keyword}'),
        backgroundColor: AppColors.cardBackground(context),
        foregroundColor: AppColors.primaryText(context),
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final articlesAsync = ref.watch(searchArticleProvider(widget.keyword));

          return articlesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.errorIcon(context)),
                  const SizedBox(height: 16),
                  Text('搜索失败: $error', style: TextStyle(color: AppColors.tertiaryText(context)),),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(searchArticleProvider(widget.keyword));
                    },
                    child: const Text('重试'),
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
                      Icon(Icons.search_off, size: 48, color: AppColors.emptyIcon(context)),
                      const SizedBox(height: 16),
                      Text(
                        '没有找到关于"${widget.keyword}"的文章',
                        style: TextStyle(color: AppColors.tertiaryText(context)),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(searchArticleProvider(widget.keyword));
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: articles.length + 1,
                  itemBuilder: (context, index) {
                    if (index < articles.length) {
                      return AnimatedListItem(
                        index: index,
                        child: ArticleCard(article: articles[index]),
                      );
                    } else {
                      // 加载更多指示器
                      final notifier = ref.read(searchArticleProvider(widget.keyword).notifier);
                      if (notifier.hasMoreData) {
                      } else {
                        return const SizedBox.shrink();
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}