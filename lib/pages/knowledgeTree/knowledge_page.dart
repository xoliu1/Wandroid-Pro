
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/pages/knowledgeTree/knowledge_graph_page.dart';
import 'package:wanandroid_pro/pages/knowledgeTree/tree_article_page.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

import '../../providers/chapter_provider.dart';
import '../../remote/Api.dart';

/// 知识体系视图模式
final knowledgeViewModeProvider = StateProvider<bool>((ref) => false); // false=列表, true=图谱

/// 知识体系 - 目录
class KnowledgeSystemTab extends ConsumerWidget {
  const KnowledgeSystemTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGraphMode = ref.watch(knowledgeViewModeProvider);
    final chaptersAsync = ref.watch(chapterProvider);

    return Column(
      children: [
        // 视图切换按钮
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                isGraphMode ? '图谱视图' : '列表视图',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MCMColors.secondaryText(context)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref.read(knowledgeViewModeProvider.notifier).state = !isGraphMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: MCMColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGraphMode ? CupertinoIcons.list_bullet : CupertinoIcons.circle_grid_hex,
                        size: 14,
                        color: MCMColors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isGraphMode ? '列表' : '图谱',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MCMColors.orange),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: isGraphMode
              ? const KnowledgeGraphPage()
              : _buildListView(chaptersAsync, context),
        ),
      ],
    );
  }

  Widget _buildListView(AsyncValue<List<Chapter>> chaptersAsync, BuildContext context) {
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
                child: _buildItem(context, chapter),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, Chapter chapter) {
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final divColor = MCMColors.dividerColor(context);

    return GestureDetector(
        onTap: () {
          if (chapter.children.isEmpty) {
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MCMColors.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: divColor, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    if (chapter.children.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: chapter.children.map((child) {
                          return Text(
                            child.name,
                            style: TextStyle(fontSize: 13, color: subColor),
                          );
                        }).toList(),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '暂无子分类',
                          style: TextStyle(fontSize: 13, color: subColor.withOpacity(0.5), fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: MCMColors.mustard.withOpacity(0.6), size: 22),
            ],
          ),
        ));
  }
}
