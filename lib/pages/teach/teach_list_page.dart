import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';
import '../../providers/article_provider.dart';
import '../../remote/Api.dart';
import 'teach_content_page.dart';

class TeachListPage extends ConsumerWidget {
  const TeachListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachListAsync = ref.watch(teachListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.groupedBackground(context),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            teachListAsync.when(
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
                        onPressed: () => ref.refresh(teachListProvider),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (teachList) => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final teach = teachList[index];
                      return AnimatedListItem(
                        index: index,
                        child: _buildTeachCard(context, teach),
                      );
                    },
                    childCount: teachList.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeachCard(BuildContext context, BookSection teach) {
    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => TeachContentPage(teach: teach),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧封面图片
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CachedNetworkImage(
                    imageUrl: teach.cover,
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
              
              // 右侧内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 标题
                      Text(
                        teach.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // 描述
                      Text(
                        teach.desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText(context),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 作者
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent(context).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              teach.author,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accent(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}