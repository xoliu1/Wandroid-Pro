import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/model/article.dart';
import 'package:notes_app/remote/CgiCollect.dart';
import 'package:notes_app/ai/ui/article_webview_page.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/functions.dart';

class ArticleCard extends StatelessWidget {
   ArticleCard(
      {super.key,
      required this.article,
        this.isMyCollect = false,
      this.opcity = 0.9,
      });

  final Article article;

  final double opcity;

  bool isMyCollect;

  final _cgiCollect = CgiCollect();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressableScale(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => ArticleWebViewPage(
              url: article.link,
              title: article.title,
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.secondarySystemBackground, // 🔥 动态背景色
          context,
        ).withOpacity(opcity),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.separator, // 🔥 分隔线颜色，暗黑适配
              context,
            ).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一排：作者在最左边，时间在最右边
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左边：作者带图标
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.person_fill,
                          size: 14,
                          color: CupertinoColors.activeBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.displayAuthor,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .copyWith(
                                fontSize: 13,
                                color: CupertinoColors.activeBlue,
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // 右边：时间带图标
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.clock_fill,
                        size: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.niceDate,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 标题单独一排
              Text(
                article.title.decodeHtmlEntities(),
                style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 描述（如果有）
              if (article.desc?.isNotEmpty == true) ...[
                Text(
                  article.desc ?? "",
                  style: const TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.secondaryLabel,
                            height: 1.4,
                          ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              // 最后一排：左边分类带图标，右边点赞按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左边分类带图标
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey.withOpacity(opcity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.tag_circle,
                          size: 12,
                          color: CupertinoColors.systemGrey3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.displayCategory,
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .copyWith(
                                fontSize: 11,
                                color: CupertinoColors.systemGrey3,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // 右边点赞按钮（更大，带状态，带心跳动画）
                  AnimatedFavoriteButton(
                    isFavorite: article.collect,
                    onTap: () async {
                      bool result;
                      if (article.collect) {
                        result = await _cgiCollect.uncollectArticle(article.id);
                      } else {
                        result = await _cgiCollect.collectArticle(article.id);
                      }
                      if (result) {
                        article.collect = !article.collect;
                        (context as Element).markNeedsBuild();
                      }
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
