import 'package:flutter/material.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/functions.dart';
import 'package:notes_app/utils/app_colors.dart';

import '../../remote/Api.dart';

class CollectArticleCard extends StatelessWidget {
  final CollectArticle article;
  final VoidCallback? onCollectChanged;

  const CollectArticleCard({
    super.key,
    required this.article,
    this.onCollectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        final url = Uri.parse(article.link);
        launchInApp(context, url);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        elevation: 2,
        color: AppColors.cardBackground(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // 标题
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppColors.primaryText(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // 作者和分类
              Row(
                children: [
                  // 作者头像
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.avatarBackground(context),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        article.author.isNotEmpty ? article.author[0] : 'A',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.avatarText(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 作者名
                  Text(
                    article.author,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText(context),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 分类
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tagBackground(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      article.chapterName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.tagText(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 底部信息
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 时间
                  Text(
                    article.niceDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.tertiaryText(context),
                    ),
                  ),

                  // 收藏按钮
                  IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () {
                      // 取消收藏
                      onCollectChanged?.call();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
