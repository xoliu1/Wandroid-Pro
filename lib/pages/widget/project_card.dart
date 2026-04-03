import 'package:flutter/material.dart';
import '../../model/project.dart';
import '../../remote/CgiCollect.dart';
import '../../utils/animations.dart';
import '../../utils/functions.dart';
import '../../utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProjectCard extends StatelessWidget {
  final ProjectArticle project;
  final bool useModernStyle;

  const ProjectCard({
    super.key,
    required this.project,
    this.useModernStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    return useModernStyle 
        ? _buildModernHorizontalCard(context)
        : _buildClassicHorizontalCard(context);
  }

  // 现代化水平卡片样式
  Widget _buildModernHorizontalCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return PressableScale(
      onTap: () {
        final uri = Uri.parse(project.link);
        launchInApp(context, uri);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左侧图片区域
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 120,
                  height: 160,
                  child: CachedNetworkImage(
                    imageUrl: project.envelopePic,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey[400],
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 右侧内容区域
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 顶部内容
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题
                          Text(
                            project.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // 描述
                          Text(
                            project.desc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                              // 作者和章节
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.avatarBackground(context),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        project.author.isNotEmpty ? project.author[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          color: AppColors.avatarText(context),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    project.author,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondaryText(context),
                                    ),
                                  ),
                              const SizedBox(width: 8),
                              Text(
                                '·',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.tertiaryText(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                project.chapterName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.tertiaryText(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8,),

                      // 底部信息
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 项目链接按钮
                          InkWell(
                            onTap: () {
                              final uri = Uri.parse(project.projectLink);
                              launchInApp(context, uri);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.accent(context).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.code,
                                    color: AppColors.link(context),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(child:
                                  Text(
                                    project.projectLink,
                                    style: TextStyle(
                                      color: AppColors.link(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),)
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10,),
                          // 时间和收藏
                          Row(
                            children: [
                              Text(
                                project.niceDate,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.tertiaryText(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final cgiCollect = CgiCollect();
                                  bool result;
                                  if (project.collect) {
                                    result = await cgiCollect.uncollectArticle(project.id);
                                  } else {
                                    result = await cgiCollect.collectArticle(project.id);
                                  }
                                  if (result) {
                                    project.collect = !project.collect;
                                    (context as Element).markNeedsBuild();
                                  }
                                },
                                child: Icon(
                                  project.collect ? Icons.favorite : Icons.favorite_border,
                                  color: project.collect ? Colors.red : AppColors.iconSecondary(context),
                                  size: 16,
                                ),
                              ),
                            ],
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

  // 经典水平卡片样式
  Widget _buildClassicHorizontalCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final uri = Uri.parse(project.link);
            launchInApp(context, uri);
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧图片区域
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: CachedNetworkImage(
                    imageUrl: project.envelopePic,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 32),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 标题
                      Text(
                        project.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // 描述
                      Text(
                        project.desc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 作者和标签
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              project.author,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (project.tags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                project.tags.first.name,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[700],
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
                          // 项目链接
                          InkWell(
                            onTap: () {
                              final uri = Uri.parse(project.projectLink);
                              launchInApp(context, uri);
                            },
                            child: Text(
                              '查看源码',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // 时间和收藏
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                project.niceDate,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  final cgiCollect = CgiCollect();
                                  bool result;
                                  if (project.collect) {
                                    result = await cgiCollect.uncollectArticle(project.id);
                                  } else {
                                    result = await cgiCollect.collectArticle(project.id);
                                  }
                                  if (result) {
                                    project.collect = !project.collect;
                                    (context as Element).markNeedsBuild();
                                  }
                                },
                                child: Icon(
                                  project.collect ? Icons.favorite : Icons.favorite_border,
                                  color: project.collect ? Colors.red : Colors.grey[400],
                                  size: 16,
                                ),
                              ),
                            ],
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