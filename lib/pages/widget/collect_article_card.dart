import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/functions.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

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
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

    return PressableScale(
      onTap: () {
        final url = Uri.parse(article.link);
        launchInApp(context, url);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: MCMColors.darkBrown.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一排：作者标签 + 时间
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 作者胶囊标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: MCMColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.person_fill,
                          size: 13,
                          color: MCMColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.author.isNotEmpty ? article.author : '匿名',
                          style: const TextStyle(
                            fontSize: 12,
                            color: MCMColors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // 时间
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 13,
                        color: subColor.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.niceDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 标题 — 左侧芥末黄竖线装饰
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: MCMColors.mustard,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        article.title.decodeHtmlEntities(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 底部：分类标签 + 取消收藏按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 分类标签
                  if (article.chapterName.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: MCMColors.grayBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.tag,
                            size: 11,
                            color: MCMColors.grayBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            article.chapterName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MCMColors.grayBlue,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  // 取消收藏按钮（已收藏状态，点击取消）
                  AnimatedFavoriteButton(
                    isFavorite: true,
                    size: 18,
                    onTap: () {
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
