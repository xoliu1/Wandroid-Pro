import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/project.dart';
import '../../remote/CgiCollect.dart';
import '../../utils/animations.dart';
import '../../utils/functions.dart';
import '../../utils/mcm_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProjectCard extends StatefulWidget {
  final ProjectArticle project;

  const ProjectCard({
    super.key,
    required this.project,
    // 保留参数兼容旧调用，但不再区分样式
    bool useModernStyle = true,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.project.collect;
  }

  // 长按弹出 MCM 风格操作菜单
  void _showActionSheet(BuildContext context) {
    final project = widget.project;
    showMCMBottomSheet(
      context: context,
      title: project.title,
      subtitle: project.author.isNotEmpty ? project.author : null,
      items: [
        // 分享
        MCMSheetItem(
          icon: CupertinoIcons.share,
          label: '分享项目',
          sublabel: project.link,
          color: MCMColors.grayBlue,
          onTap: () {
            Navigator.pop(context);
            Share.share(project.link, subject: project.title);
          },
        ),
        // 复制链接
        MCMSheetItem(
          icon: CupertinoIcons.link,
          label: '复制链接',
          sublabel: '复制文章链接到剪贴板',
          color: MCMColors.mustard,
          onTap: () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: project.link));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('链接已复制'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        // 复制源码链接
        if (project.projectLink.isNotEmpty)
          MCMSheetItem(
            icon: CupertinoIcons.doc_on_clipboard,
            label: '复制源码链接',
            sublabel: project.projectLink,
            color: MCMColors.olive,
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: project.projectLink));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('源码链接已复制'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        // 外部浏览器打开
        MCMSheetItem(
          icon: CupertinoIcons.globe,
          label: '在浏览器中打开',
          sublabel: '使用系统默认浏览器打开',
          color: MCMColors.orange,
          onTap: () async {
            Navigator.pop(context);
            final uri = Uri.parse(project.link);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);
    final bgColor = MCMColors.background(context);

    final project = widget.project;
    return PressableScale(
      onTap: () {
        final uri = Uri.parse(project.link);
        launchInApp(context, uri);
      },
      onLongPress: () => _showActionSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 左侧封面图 ──────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(15),
              ),
              child: SizedBox(
                width: 110,
                height: 160,
                child: CachedNetworkImage(
                  imageUrl: project.envelopePic,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildImageShimmer(bgColor, divColor),
                  errorWidget: (context, url, error) => _buildImageError(bgColor, subColor),
                ),
              ),
            ),

            // ── 右侧内容区 ──────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      project.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // 描述
                    Text(
                      project.desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: subColor,
                        height: 1.45,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // 作者标签 + Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // 作者
                        if (project.author.isNotEmpty)
                          _buildChip(
                            icon: CupertinoIcons.person_fill,
                            label: project.author,
                            color: MCMColors.orange,
                          ),
                        // 分类
                        if (project.chapterName.isNotEmpty)
                          _buildChip(
                            icon: CupertinoIcons.tag,
                            label: project.chapterName,
                            color: MCMColors.grayBlue,
                          ),
                        // 动态 Tags（置顶、新鲜等）
                        ...project.tags.take(2).map(
                          (tag) => _buildChip(
                            icon: CupertinoIcons.star_fill,
                            label: tag.name,
                            color: MCMColors.olive,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 源码链接按钮
                    if (project.projectLink.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          final uri = Uri.parse(project.projectLink);
                          launchInApp(context, uri);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: MCMColors.mustard.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: MCMColors.mustard.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.chevron_left_slash_chevron_right,
                                size: 12,
                                color: MCMColors.mustard,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  project.projectLink,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: MCMColors.mustard,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // 底部：时间 + 收藏
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: 11,
                          color: subColor.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.niceDate,
                          style: TextStyle(
                            fontSize: 11,
                            color: subColor.withOpacity(0.6),
                          ),
                        ),
                        const Spacer(),
                        AnimatedFavoriteButton(
                          isFavorite: _isFavorite,
                          size: 18,
                          onTap: () async {
                            final cgiCollect = CgiCollect();
                            bool result;
                            if (_isFavorite) {
                              result =
                                  await cgiCollect.uncollectArticle(project.id);
                            } else {
                              result =
                                  await cgiCollect.collectArticle(project.id);
                            }
                            if (result && mounted) {
                              setState(() {
                                _isFavorite = !_isFavorite;
                                widget.project.collect = _isFavorite;
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
          ],
        ),
      ),
    );
  }

  // 标签 chip
  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Shimmer 骨架屏占位
  Widget _buildImageShimmer(Color bg, Color shimmer) {
    return _ShimmerBox(baseColor: bg, highlightColor: shimmer);
  }

  // 加载失败占位
  Widget _buildImageError(Color bg, Color iconColor) {
    return Container(
      color: bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.photo,
              color: iconColor.withOpacity(0.3),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 10,
                color: iconColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 简单 Shimmer 动画骨架屏
class _ShimmerBox extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerBox({
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor.withOpacity(0.6),
                widget.baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}