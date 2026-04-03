import 'package:flutter/cupertino.dart';
import 'package:notes_app/model/project.dart';
import 'package:notes_app/remote/CgiCollect.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

class WxArticleCard extends StatelessWidget {
  final ProjectArticle article;
  final VoidCallback? onTap;

  const WxArticleCard({
    super.key,
    required this.article,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            AppColors.cardShadow(context),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                article.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText(context),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 描述（如果有）
              if (article.desc.isNotEmpty) ...[
                Text(
                  article.desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText(context),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // 底部信息栏
              Row(
                children: [
                  // 作者头像和名称
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.avatarBackground(context),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        article.author.isNotEmpty ? article.author[0] : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.avatarText(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 作者名称
                  Text(
                    article.author,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText(context),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // 时间
                  Text(
                    article.niceShareDate,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.tertiaryText(context),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 收藏按钮（toggle，带心跳动画）
                  AnimatedFavoriteButton(
                    isFavorite: article.collect,
                    size: 18,
                    onTap: () async {
                      final cgiCollect = CgiCollect();
                      bool result;
                      if (article.collect) {
                        result = await cgiCollect.uncollectArticle(article.id);
                      } else {
                        result = await cgiCollect.collectArticle(article.id);
                      }
                      if (result) {
                        article.collect = !article.collect;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
              
              // 标签（如果有）
              // if (article.tags.isNotEmpty) ...[
              //   const SizedBox(height: 12),
              //   Wrap(
              //     spacing: 8,
              //     runSpacing: 4,
              //     children: article.tags.take(2).map((tag) {
              //       return Container(
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 8,
              //           vertical: 4,
              //         ),
              //         decoration: BoxDecoration(
              //           color: CupertinoColors.systemGrey6,
              //           borderRadius: BorderRadius.circular(6),
              //         ),
              //
              //         child: Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             const Icon(
              //               CupertinoIcons.tag_fill,
              //               size: 12,
              //               color: CupertinoColors.systemGrey2,
              //             ),
              //             const SizedBox(width: 4),
              //             Text(
              //               tag.name,
              //               style: TextStyle(
              //                 fontSize: 12,
              //                 color: CupertinoColors.systemGrey2,
              //                 fontWeight: FontWeight.w500,
              //               ),
              //             ),
              //           ],
              //         ),
              //       );
              //     }).toList(),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }
}