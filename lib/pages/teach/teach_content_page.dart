import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';
import '../../providers/article_provider.dart';
import '../../pages/widget/article_card.dart';
import '../../remote/Api.dart';

class TeachContentPage extends ConsumerStatefulWidget {
  final BookSection teach;

  const TeachContentPage({
    super.key,
    required this.teach,
  });

  @override
  ConsumerState<TeachContentPage> createState() => _TeachContentPageState();
}

class _TeachContentPageState extends ConsumerState<TeachContentPage> {
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
      ref.read(teachArticleProvider(widget.teach.id).notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(teachArticleProvider(widget.teach.id).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final teachArticlesAsync = ref.watch(teachArticleProvider(widget.teach.id));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.groupedBackground(context),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(widget.teach.name),
              backgroundColor: AppColors.groupedBackground(context),
              border: null,
            ),
            
            // 教程信息卡片
            SliverToBoxAdapter(
              child: FadeSlideIn(
                child: _buildTeachInfoCard(),
              ),
            ),
            
            // 文章列表
            teachArticlesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle,
                          size: 48, color: CupertinoColors.systemGrey),
                      const SizedBox(height: 16),
                      Text('加载失败: ${error.toString()}'),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        color: CupertinoColors.systemBlue,
                        onPressed: _onRefresh,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('暂无文章'),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == articles.length) {
                          final hasMoreData = ref.read(
                            teachArticleProvider(widget.teach.id).notifier,
                          ).hasMoreData;
                          final isLoading = ref.read(
                            teachArticleProvider(widget.teach.id).notifier,
                          ).isLoading;

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
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ArticleCard(article: articles[index]),
                          ),
                        );
                      },
                      childCount: articles.length + 1,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          AppColors.cardShadow(context),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图片
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: widget.teach.cover,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: CupertinoColors.systemGrey5,
                  child: const Center(
                    child: CupertinoActivityIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: CupertinoColors.systemGrey5,
                  child: const Center(
                    child: Icon(CupertinoIcons.photo,
                        color: CupertinoColors.systemGrey),
                  ),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  widget.teach.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                    decoration: TextDecoration.none,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 描述
                Text(
                  widget.teach.desc,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.none,
                    color: AppColors.secondaryText(context),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 作者信息
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.avatarBackground(context),
                      child: Text(
                        widget.teach.author.isNotEmpty 
                            ? widget.teach.author[0].toUpperCase() 
                            : '?',
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          color: AppColors.avatarText(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.teach.author,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        color: AppColors.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}