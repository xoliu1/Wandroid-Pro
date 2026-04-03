import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:notes_app/ai/providers/ai_question_provider.dart';
import 'package:notes_app/model/article.dart';
import 'package:notes_app/remote/CgiCollect.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/functions.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:notes_app/utils/app_colors.dart';
import '../../ai/ui/article_webview_page.dart';

class QuestionCard extends ConsumerStatefulWidget {
  const QuestionCard({super.key, required this.article});

  final Article article;

  @override
  ConsumerState<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends ConsumerState<QuestionCard> {
  bool _isAIExpanded = false;

  Article get article => widget.article;

  void _toggleAIExplanation() {
    final aiState = ref.read(aiQuestionProvider);
    final existing = aiState[article.id];

    if (_isAIExpanded) {
      // 收起
      setState(() => _isAIExpanded = false);
      return;
    }

    // 展开
    setState(() => _isAIExpanded = true);

    // 如果还没有请求过，发起请求
    if (existing == null || (!existing.isLoading && !existing.isCompleted && existing.error == null)) {
      // 从 HTML desc 中提取纯文本
      final desc = article.desc?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
      ref.read(aiQuestionProvider.notifier).requestExplanation(
        articleId: article.id,
        title: article.title.decodeHtmlEntities(),
        description: desc,
      );
    }
  }

  void _retryAIExplanation() {
    ref.read(aiQuestionProvider.notifier).clearExplanation(article.id);
    final desc = article.desc?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
    ref.read(aiQuestionProvider.notifier).requestExplanation(
      articleId: article.id,
      title: article.title.decodeHtmlEntities(),
      description: desc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiState = ref.watch(aiQuestionProvider)[article.id];

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
              // 问答标签和点赞数
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 问答标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemOrange.withOpacity(isDark ? 0.5 : 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.question_circle_fill,
                          size: 14,
                          color: CupertinoColors.systemOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '每日问答',
                          style: CupertinoTheme.of(context)
                              .textTheme
                              .textStyle
                              .copyWith(
                                fontSize: 12,
                                color: CupertinoColors.systemOrange,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  // 点赞数
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.hand_thumbsup_fill,
                        size: 16,
                        color: AppColors.iconSecondary(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article.zan ?? 0}',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                              fontSize: 14,
                              color: AppColors.secondaryText(context),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 标题
              Text(
                article.title.decodeHtmlEntities(),
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText(context),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 问题描述
              if (article.desc?.isNotEmpty == true) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '问题描述:',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText(context),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Html(
                        data: article.desc!,
                        style: {
                          "body": Style(
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(14),
                            color: isDark ? const Color(0xFFB0B0B0) : CupertinoColors.secondaryLabel,
                          ),
                          "p": Style(
                          ),
                          "pre": Style(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey5,
                            padding: HtmlPaddings.all(8),

                          ),
                          "code": Style(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey5,
                            padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
                            fontFamily: 'monospace',
                          ),
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // 作者和时间
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 作者
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.person_fill,
                        size: 14,
                        color: AppColors.link(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.displayAuthor,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                              fontSize: 14,
                              color: AppColors.link(context),
                            ),
                      ),
                    ],
                  ),
                  // 时间
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock_fill,
                        size: 14,
                        color: AppColors.iconSecondary(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article.niceDate,
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                              fontSize: 14,
                              color: AppColors.tertiaryText(context),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 底部操作栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 分类
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tagBackground(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.displayCategory,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .textStyle
                          .copyWith(
                            fontSize: 12,
                            color: AppColors.tagText(context),
                          ),
                    ),
                  ),
                  Row(
                    children: [
                      // AI 解答按钮
                      GestureDetector(
                        onTap: _toggleAIExplanation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isAIExpanded
                                ? CupertinoColors.activeBlue.withOpacity(isDark ? 0.3 : 0.15)
                                : CupertinoColors.activeBlue.withOpacity(isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.activeBlue.withOpacity(isDark ? 0.5 : 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                aiState?.isLoading == true
                                    ? CupertinoIcons.hourglass
                                    : CupertinoIcons.sparkles,
                                size: 14,
                                color: CupertinoColors.activeBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAIExpanded ? '收起' : 'AI 解答',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.activeBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 收藏按钮
                      AnimatedFavoriteButton(
                        isFavorite: article.collect,
                        size: 20,
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
                ],
              ),
              // AI 解析展开区域
              if (_isAIExpanded) ...[
                const SizedBox(height: 12),
                _buildAIExplanationArea(context, aiState, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建 AI 解析展开区域
  Widget _buildAIExplanationArea(BuildContext context, QuestionAIState? aiState, bool isDark) {
    return GestureDetector(
      // 阻止点击事件冒泡到外层的 PressableScale（避免跳转 WebView）
      onTap: () {},
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.activeBlue.withOpacity(0.08)
                : CupertinoColors.activeBlue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.activeBlue.withOpacity(isDark ? 0.2 : 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.sparkles,
                    size: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI 解析',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                  const Spacer(),
                  if (aiState?.isLoading == true)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CupertinoActivityIndicator(radius: 7),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 内容区域
              if (aiState == null || (aiState.isLoading && aiState.content.isEmpty))
                _buildLoadingPlaceholder(context)
              else if (aiState.error != null && aiState.content.isEmpty)
                _buildErrorView(context, aiState.error!)
              else
                _buildMarkdownContent(context, aiState.content, isDark),
              // 底部操作
              if (aiState != null && (aiState.isCompleted || aiState.error != null)) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (aiState.error != null)
                      GestureDetector(
                        onTap: _retryAIExplanation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.refresh,
                                size: 12,
                                color: AppColors.secondaryText(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '重试',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (aiState.isCompleted && aiState.content.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: aiState.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已复制到剪贴板'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.doc_on_clipboard,
                                size: 12,
                                color: AppColors.secondaryText(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '复制',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondaryText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 8),
          const SizedBox(width: 8),
          Text(
            'AI 正在分析问题...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '解析失败: $error',
        style: const TextStyle(
          fontSize: 13,
          color: CupertinoColors.destructiveRed,
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, String content, bool isDark) {
    return MarkdownBody(
      data: content,
      selectable: true,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.primaryText(context),
        ),
        h1: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText(context),
        ),
        h2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText(context),
        ),
        h3: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryText(context),
        ),
        code: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
          color: AppColors.primaryText(context),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        listBullet: TextStyle(
          fontSize: 14,
          color: AppColors.primaryText(context),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: CupertinoColors.activeBlue.withOpacity(0.5),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}

extension on Article {
  int? get zan => tags.isNotEmpty ? 0 : null;
}