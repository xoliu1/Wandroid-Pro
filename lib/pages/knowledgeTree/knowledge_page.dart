
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/knowledgeTree/tree_article_page.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

import '../../providers/chapter_provider.dart';
import '../../remote/Api.dart';

/// 知识体系 - 目录
class KnowledgeSystemTab extends ConsumerWidget {
  const KnowledgeSystemTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(chapterProvider);

    return chaptersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载失败: $error')),
      data: (chapters) {
        return Scrollbar(
          child: ListView.builder(
            itemCount: chapters.length,
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            return AnimatedListItem(
              index: index,
              child: Column(
                children: [
                  _buildItem(context, chapter),
                  const Divider(height: 1, thickness: 1),
                ],
              ),
            );
          },
        ));
      },
    );
  }

  Widget _buildItem(BuildContext context, Chapter chapter) {
    return InkWell(
        onTap: () {
          // 检查是否有子分类
          if (chapter.children.isEmpty) {
            // 没有子分类，显示提示
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('「${chapter.name}」暂无子分类内容'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          
          showCupertinoModalPopup(
            context: context,
            builder: (context) => SizedBox.expand(
              child: TreeArticlePage(
                chapter: chapter,
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 8),
                          child: chapter.children.isEmpty
                              ? Text(
                                  '暂无子分类',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.tertiaryText(context),
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: chapter.children.map((child) {
                                    return Text(
                                      child.name,
                                      style: TextStyle(
                                          fontSize: 14, color: AppColors.secondaryText(context)),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.arrow_circle_right, color: AppColors.iconSecondary(context)),
            ],
          ),
        ));
  }
}
