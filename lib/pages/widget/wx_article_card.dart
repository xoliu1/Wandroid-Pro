import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wanandroid_pro/model/project.dart';
import 'package:wanandroid_pro/remote/CgiCollect.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

class WxArticleCard extends StatefulWidget {
  final ProjectArticle article;
  final VoidCallback? onTap;

  const WxArticleCard({
    super.key,
    required this.article,
    this.onTap,
  });

  @override
  State<WxArticleCard> createState() => _WxArticleCardState();
}

class _WxArticleCardState extends State<WxArticleCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.article.collect;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

    return PressableScale(
      onTap: widget.onTap,
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
                          widget.article.author.isNotEmpty ? widget.article.author : '匿名',
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
                        widget.article.niceShareDate,
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
                        widget.article.title,
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
              // 描述（如果有）
              if (widget.article.desc.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.article.desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: subColor,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              // 底部：收藏按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedFavoriteButton(
                    isFavorite: _isFavorite,
                    size: 18,
                    onTap: () async {
                      final cgiCollect = CgiCollect();
                      bool result;
                      if (_isFavorite) {
                        result = await cgiCollect.uncollectArticle(widget.article.id);
                      } else {
                        result = await cgiCollect.collectArticle(widget.article.id);
                      }
                      if (result && mounted) {
                        setState(() {
                          _isFavorite = !_isFavorite;
                          widget.article.collect = _isFavorite;
                        });
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