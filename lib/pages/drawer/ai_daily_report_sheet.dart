import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/ai/providers/ai_daily_report_provider.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
  /// 用于截图的 GlobalKey
  final _repaintKey = GlobalKey();
  bool _isGeneratingImage = false;

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
    final reportState = ref.watch(aiDailyReportProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: MCMColors.background(context),
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
              color: MCMColors.dividerColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: MCMColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_fill,
                    size: 18,
                    color: MCMColors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 日报',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: MCMColors.primaryText(context),
                      ),
                    ),
                    Text(
                      _todayStr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: MCMColors.secondaryText(context),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // 复制按钮
                if (reportState.isCompleted && reportState.report != null)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _copyReport(reportState.rawContent),
                    child: Icon(
                      CupertinoIcons.doc_on_clipboard,
                      size: 20,
                      color: MCMColors.secondaryText(context),
                    ),
                  ),
                // 关闭按钮
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref.read(aiDailyReportProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 24,
                    color: MCMColors.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: MCMColors.dividerColor(context)),
          // 内容区域
          Flexible(
            child: _buildContent(reportState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AIDailyReportState reportState) {
    // 加载中
    if (reportState.isLoading && reportState.report == null) {
      return _buildLoadingView();
    }

    // 错误
    if (reportState.error != null && reportState.report == null) {
      return _buildErrorView(reportState.error!);
    }

    // 有结构化数据
    if (reportState.report != null) {
      return _buildReportView(reportState);
    }

    // 初始状态
    return _buildEmptyView();
  }

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MCMColors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CupertinoActivityIndicator(radius: 14),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '正在分析今日活动...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MCMColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '包括浏览记录、待办进展、笔记动态',
            style: TextStyle(
              fontSize: 13,
              color: MCMColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CupertinoColors.destructiveRed.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CupertinoColors.destructiveRed.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 32,
                  color: CupertinoColors.destructiveRed,
                ),
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
          const SizedBox(height: 20),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            color: MCMColors.orange,
            borderRadius: BorderRadius.circular(12),
            onPressed: () {
              ref.read(aiDailyReportProvider.notifier).reset();
              ref.read(aiDailyReportProvider.notifier).generateReport();
            },
            child: const Text('重试', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportView(AIDailyReportState reportState) {
    final report = reportState.report!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: RepaintBoundary(
        key: _repaintKey,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 今日概览卡片
          _buildOverviewCard(report.overview),
          const SizedBox(height: 12),

          // 阅读回顾
          if (report.reading != null && report.reading!.items.isNotEmpty) ...[
            _buildSectionCard(
              icon: CupertinoIcons.book_fill,
              iconColor: MCMColors.grayBlue,
              title: '阅读回顾',
              summary: report.reading!.summary,
              items: report.reading!.items,
              itemIcon: CupertinoIcons.doc_text,
            ),
            const SizedBox(height: 12),
          ],

          // 任务进展
          if (report.todos != null) ...[
            _buildTodosCard(report.todos!),
            const SizedBox(height: 12),
          ],

          // 笔记动态
          if (report.notes != null && report.notes!.items.isNotEmpty) ...[
            _buildSectionCard(
              icon: CupertinoIcons.pencil_outline,
              iconColor: MCMColors.mustard,
              title: '笔记动态',
              summary: report.notes!.summary,
              items: report.notes!.items,
              itemIcon: CupertinoIcons.doc_plaintext,
            ),
            const SizedBox(height: 12),
          ],

          // 明日建议
          if (report.suggestions.isNotEmpty) ...[
            _buildSuggestionsCard(report.suggestions),
            const SizedBox(height: 12),
          ],

          // 流式输出中的指示器
          if (reportState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 14,
                    decoration: BoxDecoration(
                      color: MCMColors.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CupertinoActivityIndicator(radius: 6),
                  const SizedBox(width: 8),
                  Text(
                    '正在生成...',
                    style: TextStyle(
                      fontSize: 12,
                      color: MCMColors.secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),

          // 完成后的操作区
          if (reportState.isCompleted) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: CupertinoIcons.refresh,
                    label: '重新生成',
                    color: MCMColors.orange,
                    filled: false,
                    onTap: () {
                      ref.read(aiDailyReportProvider.notifier).reset();
                      ref.read(aiDailyReportProvider.notifier).generateReport(forceRegenerate: true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: CupertinoIcons.doc_on_clipboard,
                    label: '复制',
                    color: MCMColors.orange,
                    filled: false,
                    onTap: () => _copyReport(reportState.rawContent),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _isGeneratingImage
                      ? Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: MCMColors.grayBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: CupertinoActivityIndicator(radius: 8),
                          ),
                        )
                      : _buildActionButton(
                          icon: CupertinoIcons.share,
                          label: '分享图片',
                          color: MCMColors.grayBlue,
                          filled: true,
                          onTap: () => _shareAsImage(reportState),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// 今日概览卡片
  Widget _buildOverviewCard(String overview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MCMColors.orange.withOpacity(0.15),
            MCMColors.mustard.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MCMColors.orange.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: MCMColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              CupertinoIcons.sun_max_fill,
              size: 18,
              color: MCMColors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日概览',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MCMColors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overview,
                  style: TextStyle(
                    fontSize: 14,
                    color: MCMColors.primaryText(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 通用板块卡片（阅读/笔记）
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? summary,
    required List<String> items,
    required IconData itemIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MCMColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MCMColors.dividerColor(context)),
        boxShadow: [
          BoxShadow(
            color: MCMColors.darkBrown.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MCMColors.primaryText(context),
                  ),
                ),
                if (summary != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: MCMColors.secondaryText(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: MCMColors.dividerColor(context)),
          // 列表项
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        itemIcon,
                        size: 13,
                        color: iconColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          color: MCMColors.primaryText(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// 任务进展卡片（分已完成/待完成两组）
  Widget _buildTodosCard(DailyTodosSection todos) {
    return Container(
      decoration: BoxDecoration(
        color: MCMColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MCMColors.dividerColor(context)),
        boxShadow: [
          BoxShadow(
            color: MCMColors.darkBrown.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 14,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '任务进展',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MCMColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: MCMColors.dividerColor(context)),

          // 已完成
          if (todos.completed.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '已完成 ${todos.completed.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  if (todos.completedSummary != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        todos.completedSummary!,
                        style: TextStyle(
                          fontSize: 12,
                          color: MCMColors.secondaryText(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...todos.completed.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          size: 13,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            color: MCMColors.primaryText(context),
                            height: 1.4,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: MCMColors.secondaryText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          // 待完成
          if (todos.pending.isNotEmpty) ...[
            if (todos.completed.isNotEmpty)
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: MCMColors.dividerColor(context),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MCMColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '待完成 ${todos.pending.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MCMColors.orange,
                      ),
                    ),
                  ),
                  if (todos.pendingSummary != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        todos.pendingSummary!,
                        style: TextStyle(
                          fontSize: 12,
                          color: MCMColors.secondaryText(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ...todos.pending.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          CupertinoIcons.circle,
                          size: 13,
                          color: MCMColors.orange.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 13,
                            color: MCMColors.primaryText(context),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 明日建议卡片
  Widget _buildSuggestionsCard(List<String> suggestions) {
    return Container(
      decoration: BoxDecoration(
        color: MCMColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MCMColors.dividerColor(context)),
        boxShadow: [
          BoxShadow(
            color: MCMColors.darkBrown.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: MCMColors.mustard.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.lightbulb_fill,
                    size: 14,
                    color: MCMColors.mustard,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '明日建议',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MCMColors.primaryText(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: MCMColors.dividerColor(context)),
          ...suggestions.asMap().entries.map((entry) {
            final index = entry.key;
            final suggestion = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: MCMColors.mustard.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: MCMColors.mustard,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 13,
                        color: MCMColors.primaryText(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: MCMColors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              CupertinoIcons.doc_text,
              size: 28,
              color: MCMColors.orange.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '点击生成今日日报',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: MCMColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI 将分析你今天的浏览、任务和笔记',
            style: TextStyle(
              fontSize: 13,
              color: MCMColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: filled ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: filled ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: filled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  /// 将日报渲染为图片并分享
  Future<void> _shareAsImage(AIDailyReportState reportState) async {
    if (_isGeneratingImage) return;
    setState(() => _isGeneratingImage = true);

    try {
      // 等待一帧确保 RepaintBoundary 已渲染
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('无法获取渲染对象');
      }

      // 渲染为图片（2x 分辨率）
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('图片数据为空');

      final bytes = byteData.buffer.asUint8List();

      // 写入临时文件
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'daily_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // 分享
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'AI 日报 - ${_todayStr()}',
      );
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: Text('生成图片失败: $e'),
          primaryColor: Colors.red,
          showProgressBar: false,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
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
    return '${now.year}年${now.month}月${now.day}日';
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
