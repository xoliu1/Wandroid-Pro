import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:notes_app/ai/providers/ai_daily_report_provider.dart';
import 'package:notes_app/utils/app_colors.dart';
import 'package:toastification/toastification.dart';

/// AI 日报总结 BottomSheet
///
/// 展示 AI 生成的每日活动总结，包括浏览回顾、任务进展、笔记动态等。
class AIDailyReportSheet extends ConsumerStatefulWidget {
  const AIDailyReportSheet({super.key});

  @override
  ConsumerState<AIDailyReportSheet> createState() => _AIDailyReportSheetState();
}

class _AIDailyReportSheetState extends ConsumerState<AIDailyReportSheet> {
  @override
  void initState() {
    super.initState();
    // 打开时自动生成日报
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(aiDailyReportProvider);
      if (!state.isLoading && !state.isCompleted) {
        ref.read(aiDailyReportProvider.notifier).generateReport();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportState = ref.watch(aiDailyReportProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                const Icon(CupertinoIcons.doc_text_fill, size: 20, color: CupertinoColors.activeOrange),
                const SizedBox(width: 8),
                Text(
                  'AI 日报总结',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(width: 8),
                // 日期标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeOrange.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _todayStr(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.activeOrange.resolveFrom(context),
                    ),
                  ),
                ),
                const Spacer(),
                // 操作按钮
                if (reportState.isCompleted && reportState.content.isNotEmpty)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _copyReport(reportState.content),
                    child: const Icon(CupertinoIcons.doc_on_clipboard, size: 20, color: Colors.grey),
                  ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref.read(aiDailyReportProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: const Icon(CupertinoIcons.xmark_circle_fill, size: 24, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 内容区域
          Flexible(
            child: _buildContent(reportState, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AIDailyReportState reportState, bool isDark) {
    // 加载中
    if (reportState.isLoading && reportState.content.isEmpty) {
      return _buildLoadingView();
    }

    // 错误
    if (reportState.error != null && reportState.content.isEmpty) {
      return _buildErrorView(reportState.error!);
    }

    // 有内容（流式输出中或已完成）
    if (reportState.content.isNotEmpty) {
      return _buildReportView(reportState, isDark);
    }

    // 初始状态
    return _buildEmptyView();
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 16),
          const SizedBox(height: 16),
          Text(
            '正在分析今日活动数据...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '包括浏览记录、待办进展、笔记动态',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.tertiaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.destructiveRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle, size: 32, color: CupertinoColors.destructiveRed),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: CupertinoColors.activeOrange,
            borderRadius: BorderRadius.circular(10),
            onPressed: () {
              ref.read(aiDailyReportProvider.notifier).reset();
              ref.read(aiDailyReportProvider.notifier).generateReport();
            },
            child: const Text('重试', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportView(AIDailyReportState reportState, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Markdown 内容
          MarkdownBody(
            data: reportState.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
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
              p: TextStyle(
                fontSize: 14,
                color: AppColors.primaryText(context),
                height: 1.6,
              ),
              listBullet: TextStyle(
                fontSize: 14,
                color: AppColors.primaryText(context),
              ),
              blockquoteDecoration: BoxDecoration(
                color: CupertinoColors.activeOrange.withOpacity(isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: CupertinoColors.activeOrange.withOpacity(0.5),
                    width: 3,
                  ),
                ),
              ),
              codeblockDecoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // 流式输出中的光标
          if (reportState.isLoading && reportState.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 16,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoActivityIndicator(radius: 6),
                ],
              ),
            ),
          // 完成后的操作区
          if (reportState.isCompleted && reportState.content.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: CupertinoColors.activeOrange.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                    onPressed: () {
                      ref.read(aiDailyReportProvider.notifier).reset();
                      ref.read(aiDailyReportProvider.notifier).generateReport();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.refresh, size: 16, color: CupertinoColors.activeOrange.resolveFrom(context)),
                        const SizedBox(width: 6),
                        Text(
                          '重新生成',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.activeOrange.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: CupertinoColors.activeOrange,
                    borderRadius: BorderRadius.circular(10),
                    onPressed: () => _copyReport(reportState.content),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_on_clipboard, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          '复制日报',
                          style: TextStyle(fontSize: 14, color: Colors.white),
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
    );
  }

  Widget _buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 48,
            color: AppColors.tertiaryText(context),
          ),
          const SizedBox(height: 16),
          Text(
            '点击生成今日日报',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  void _copyReport(String content) {
    Clipboard.setData(ClipboardData(text: content));
    toastification.show(
      context: context,
      title: const Text('日报已复制到剪贴板'),
      primaryColor: Colors.green,
      showProgressBar: false,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.month}月${now.day}日';
  }
}

/// 显示 AI 日报总结 BottomSheet
void showAIDailyReportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AIDailyReportSheet(),
  );
}
