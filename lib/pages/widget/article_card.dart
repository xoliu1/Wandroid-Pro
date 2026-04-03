import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:notes_app/model/article.dart';
import 'package:notes_app/remote/CgiCollect.dart';
import 'package:notes_app/ai/ui/article_webview_page.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/functions.dart';
import 'package:notes_app/utils/mcm_widget.dart';

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
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

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
        color: cardBg.withOpacity(opcity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2416).withOpacity(0.04),
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
              // 第一排：作者在最左边，时间在最右边
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左边：作者带图标 — MCM 风格标签
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: MCMColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_fill,
                          size: 13,
                          color: MCMColors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.displayAuthor,
                          style: TextStyle(
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
                  // 右边：时间
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
              // 标题 — MCM 粗体风格，带左侧竖线装饰
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
              // 描述（如果有）
              if (article.desc?.isNotEmpty == true) ...[
                Text(
                  article.desc ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    color: subColor,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
              ],
              // 最后一排：左边分类，右边收藏按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左边分类 — MCM 风格小标签
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MCMColors.grayBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.tag,
                          size: 11,
                          color: MCMColors.grayBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.displayCategory,
                          style: TextStyle(
                            fontSize: 11,
                            color: MCMColors.grayBlue,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 右边收藏按钮
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
