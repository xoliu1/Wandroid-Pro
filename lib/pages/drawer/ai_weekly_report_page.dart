import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/ai/providers/ai_weekly_report_provider.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';

/// AI 周报页面（含历史列表 + 生成/查看）
class AIWeeklyReportPage extends ConsumerStatefulWidget {
  const AIWeeklyReportPage({super.key});
  @override
  ConsumerState<AIWeeklyReportPage> createState() => _AIWeeklyReportPageState();
}

class _AIWeeklyReportPageState extends ConsumerState<AIWeeklyReportPage> {
  final _repaintKey = GlobalKey();
  bool _isGeneratingImage = false;

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(aiWeeklyReportProvider);
    final history = ref.watch(weeklyReportHistoryProvider);
    return Scaffold(
      backgroundColor: MCMColors.background(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MCMHeader(
              title: 'WEEKLY',
              subtitle: 'AI 周报 · 学习成长记录',
              leading: MCMBackButton(),
              trailing: _buildGenerateButton(reportState),
            ),
            Expanded(
              child: reportState.isLoading || reportState.isCompleted
                  ? _buildReportContent(reportState)
                  : _buildHistoryList(history),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(AIWeeklyReportState reportState) {
    if (reportState.isLoading) return const CupertinoActivityIndicator(radius: 10);
    if (reportState.isCompleted) {
      return GestureDetector(
        onTap: () => ref.read(aiWeeklyReportProvider.notifier).reset(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: MCMColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text('返回列表', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MCMColors.orange)),
        ),
      );
    }
    return GestureDetector(
      onTap: () => ref.read(aiWeeklyReportProvider.notifier).generateReport(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: MCMColors.orange, borderRadius: BorderRadius.circular(8)),
        child: const Text('生成本周', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MCMColors.white)),
      ),
    );
  }

  Widget _buildHistoryList(List<WeeklyReportRecord> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MCMStarburst(size: 64, color: MCMColors.mustard.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('还没有周报记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MCMColors.primaryText(context))),
            const SizedBox(height: 8),
            Text('点击右上角「生成本周」开始', style: TextStyle(fontSize: 13, color: MCMColors.secondaryText(context))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: history.length,
      itemBuilder: (context, index) => _buildHistoryCard(history[index]),
    );
  }

  Widget _buildHistoryCard(WeeklyReportRecord record) {
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final divColor = MCMColors.dividerColor(context);
    final score = record.report.growth?.score ?? 0;
    final scoreColor = score >= 8 ? MCMColors.olive : score >= 5 ? MCMColors.mustard : MCMColors.coral;

    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(
        builder: (_) => WeeklyReportDetailPage(record: record),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MCMColors.card(context), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: MCMColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(record.weekKey.split('-W').last, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MCMColors.orange))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('第 ${record.weekKey.split('-W').last} 周', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 2),
                Text(record.weekRange, style: TextStyle(fontSize: 12, color: subColor)),
              ])),
              if (score > 0) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: scoreColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(CupertinoIcons.star_fill, size: 12, color: scoreColor),
                  const SizedBox(width: 4),
                  Text('$score/10', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scoreColor)),
                ]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDelete(record.weekKey),
                child: Icon(CupertinoIcons.trash, size: 16, color: subColor),
              ),
            ]),
            const SizedBox(height: 10),
            Text(record.report.overview, style: TextStyle(fontSize: 13, color: subColor, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              if (record.report.reading != null) _buildMiniTag('📖 ${record.report.reading!.totalCount} 篇', MCMColors.grayBlue),
              if (record.report.todos != null) ...[const SizedBox(width: 8), _buildMiniTag('✅ ${record.report.todos!.completedCount} 完成', MCMColors.olive)],
              if (record.report.notes != null) ...[const SizedBox(width: 8), _buildMiniTag('📝 ${record.report.notes!.totalCount} 笔记', MCMColors.mustard)],
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _confirmDelete(String weekKey) {
    showDialog(context: context, builder: (context) => MCMConfirmDialog(
      icon: CupertinoIcons.trash, iconColor: MCMColors.coral,
      title: '删除周报', content: '确定要删除这份周报吗？此操作不可撤销。',
      confirmText: 'DELETE', isDestructive: true,
      onConfirm: () {
        deleteWeeklyReport(weekKey);
        ref.read(weeklyReportHistoryProvider.notifier).state = getWeeklyReportHistory();
      },
    ));
  }

  Widget _buildReportContent(AIWeeklyReportState reportState) {
    if (reportState.isLoading && reportState.report == null) return _buildLoadingView();
    if (reportState.error != null && reportState.report == null) return _buildErrorView(reportState.error!);
    if (reportState.report != null) return _buildReportView(reportState);
    return const SizedBox.shrink();
  }

  Widget _buildLoadingView() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: MCMColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CupertinoActivityIndicator(radius: 14))),
      const SizedBox(height: 20),
      Text('正在分析本周活动...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MCMColors.primaryText(context))),
      const SizedBox(height: 8),
      Text('汇总浏览记录、待办进展、笔记动态', style: TextStyle(fontSize: 13, color: MCMColors.secondaryText(context))),
    ]));
  }

  Widget _buildErrorView(String error) {
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        color: CupertinoColors.destructiveRed.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.destructiveRed.withOpacity(0.2))),
        child: Column(children: [
          const Icon(CupertinoIcons.exclamationmark_triangle, size: 32, color: CupertinoColors.destructiveRed),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: CupertinoColors.destructiveRed)),
        ])),
      const SizedBox(height: 20),
      CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), color: MCMColors.orange, borderRadius: BorderRadius.circular(12),
        onPressed: () { ref.read(aiWeeklyReportProvider.notifier).reset(); ref.read(aiWeeklyReportProvider.notifier).generateReport(); },
        child: const Text('重试', style: TextStyle(fontSize: 15))),
    ])));
  }

  Widget _buildReportView(AIWeeklyReportState reportState) {
    final report = reportState.report!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: RepaintBoundary(key: _repaintKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        buildOverviewCard(context, report),
        const SizedBox(height: 12),
        if (report.growth != null) ...[buildGrowthCard(context, report.growth!), const SizedBox(height: 12)],
        if (report.reading != null) ...[buildSectionCard(context, icon: CupertinoIcons.book_fill, iconColor: MCMColors.grayBlue, title: '阅读回顾', summary: report.reading!.summary, badge: '${report.reading!.totalCount} 篇', items: report.reading!.items, itemIcon: CupertinoIcons.doc_text), const SizedBox(height: 12)],
        if (report.todos != null) ...[buildSectionCard(context, icon: CupertinoIcons.checkmark_circle_fill, iconColor: MCMColors.olive, title: '任务进展', summary: report.todos!.summary, badge: '完成 ${report.todos!.completedCount} · 待办 ${report.todos!.pendingCount}', items: report.todos!.highlights, itemIcon: CupertinoIcons.checkmark_square), const SizedBox(height: 12)],
        if (report.notes != null) ...[buildSectionCard(context, icon: CupertinoIcons.pencil_outline, iconColor: MCMColors.mustard, title: '笔记动态', summary: report.notes!.summary, badge: '${report.notes!.totalCount} 条', items: report.notes!.topics, itemIcon: CupertinoIcons.doc_plaintext), const SizedBox(height: 12)],
        if (report.nextWeekGoals.isNotEmpty) ...[buildGoalsCard(context, report.nextWeekGoals), const SizedBox(height: 12)],
        if (reportState.isCompleted) ...[const SizedBox(height: 8), Row(children: [
          Expanded(child: CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 12), color: MCMColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
            onPressed: () { ref.read(aiWeeklyReportProvider.notifier).reset(); ref.read(aiWeeklyReportProvider.notifier).generateReport(forceRegenerate: true); },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.refresh, size: 15, color: MCMColors.orange), const SizedBox(width: 6), Text('重新生成', style: TextStyle(fontSize: 14, color: MCMColors.orange))]))),
          const SizedBox(width: 8),
          Expanded(child: CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 12), color: MCMColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
            onPressed: () { Clipboard.setData(ClipboardData(text: reportState.rawContent)); toastification.show(context: context, title: const Text('已复制'), primaryColor: Colors.green, showProgressBar: false, autoCloseDuration: const Duration(seconds: 2)); },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.doc_on_clipboard, size: 15, color: MCMColors.orange), const SizedBox(width: 6), Text('复制', style: TextStyle(fontSize: 14, color: MCMColors.orange))]))),
          const SizedBox(width: 8),
          Expanded(child: _isGeneratingImage
            ? Container(height: 44, decoration: BoxDecoration(color: MCMColors.grayBlue, borderRadius: BorderRadius.circular(12)), child: const Center(child: CupertinoActivityIndicator(radius: 8)))
            : CupertinoButton(padding: const EdgeInsets.symmetric(vertical: 12), color: MCMColors.grayBlue, borderRadius: BorderRadius.circular(12),
              onPressed: _shareAsImage,
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(CupertinoIcons.share, size: 15, color: Colors.white), const SizedBox(width: 6), const Text('分享', style: TextStyle(fontSize: 14, color: Colors.white))]))),
        ])],
      ])),
    );
  }

  Future<void> _shareAsImage() async {
    if (_isGeneratingImage) return;
    setState(() => _isGeneratingImage = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('无法获取渲染对象');
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('图片数据为空');
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/weekly_report_${getCurrentWeekKey()}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')], subject: 'AI 周报 - ${getCurrentWeekRange()}');
    } catch (e) {
      if (mounted) toastification.show(context: context, title: Text('生成图片失败: $e'), primaryColor: Colors.red, showProgressBar: false, autoCloseDuration: const Duration(seconds: 3));
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }
}

// ─── 周报详情页 ──────────────────────────────────────────────────────────────

class WeeklyReportDetailPage extends StatelessWidget {
  final WeeklyReportRecord record;
  const WeeklyReportDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final report = record.report;
    return Scaffold(
      backgroundColor: MCMColors.background(context),
      body: SafeArea(child: Column(children: [
        MCMHeader(title: '第 ${record.weekKey.split('-W').last} 周', subtitle: record.weekRange, leading: MCMBackButton()),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            buildOverviewCard(context, report),
            const SizedBox(height: 12),
            if (report.growth != null) ...[buildGrowthCard(context, report.growth!), const SizedBox(height: 12)],
            if (report.reading != null) ...[buildSectionCard(context, icon: CupertinoIcons.book_fill, iconColor: MCMColors.grayBlue, title: '阅读回顾', summary: report.reading!.summary, badge: '${report.reading!.totalCount} 篇', items: report.reading!.items, itemIcon: CupertinoIcons.doc_text), const SizedBox(height: 12)],
            if (report.todos != null) ...[buildSectionCard(context, icon: CupertinoIcons.checkmark_circle_fill, iconColor: MCMColors.olive, title: '任务进展', summary: report.todos!.summary, badge: '完成 ${report.todos!.completedCount} · 待办 ${report.todos!.pendingCount}', items: report.todos!.highlights, itemIcon: CupertinoIcons.checkmark_square), const SizedBox(height: 12)],
            if (report.notes != null) ...[buildSectionCard(context, icon: CupertinoIcons.pencil_outline, iconColor: MCMColors.mustard, title: '笔记动态', summary: report.notes!.summary, badge: '${report.notes!.totalCount} 条', items: report.notes!.topics, itemIcon: CupertinoIcons.doc_plaintext), const SizedBox(height: 12)],
            if (report.nextWeekGoals.isNotEmpty) ...[buildGoalsCard(context, report.nextWeekGoals)],
          ]),
        )),
      ])),
    );
  }
}

// ─── 公共卡片构建方法 ────────────────────────────────────────────────────────

Widget buildOverviewCard(BuildContext context, WeeklyReport report) {
  return Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [MCMColors.orange.withOpacity(0.15), MCMColors.mustard.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16), border: Border.all(color: MCMColors.orange.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: MCMColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: const Icon(CupertinoIcons.calendar, size: 18, color: MCMColors.orange)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('周报概览', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MCMColors.orange)),
          if (report.weekRange.isNotEmpty) Text(report.weekRange, style: TextStyle(fontSize: 11, color: MCMColors.secondaryText(context))),
        ])),
      ]),
      const SizedBox(height: 12),
      Text(report.overview, style: TextStyle(fontSize: 14, color: MCMColors.primaryText(context), height: 1.5)),
    ]),
  );
}

Widget buildGrowthCard(BuildContext context, WeeklyGrowthSection growth) {
  final scoreColor = growth.score >= 8 ? MCMColors.olive : growth.score >= 5 ? MCMColors.mustard : MCMColors.coral;
  return Container(
    decoration: BoxDecoration(color: MCMColors.card(context), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MCMColors.dividerColor(context)),
      boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 0), child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: scoreColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(CupertinoIcons.star_fill, size: 14, color: scoreColor)),
        const SizedBox(width: 8),
        Text('成长评估', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MCMColors.primaryText(context))),
        const Spacer(),
        Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: scoreColor.withOpacity(0.3), width: 3)),
          child: Center(child: Text('${growth.score}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scoreColor)))),
      ])),
      if (growth.assessment != null) Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Text(growth.assessment!, style: TextStyle(fontSize: 13, color: MCMColors.primaryText(context), height: 1.4))),
      const SizedBox(height: 10),
      Divider(height: 1, color: MCMColors.dividerColor(context)),
      if (growth.strengths.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 4), child: Text('💪 做得好', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MCMColors.olive))),
        ...growth.strengths.map((s) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 4), child: Icon(CupertinoIcons.checkmark_circle_fill, size: 12, color: MCMColors.olive)),
          const SizedBox(width: 8),
          Expanded(child: Text(s, style: TextStyle(fontSize: 13, color: MCMColors.primaryText(context), height: 1.4))),
        ]))),
      ],
      if (growth.improvements.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 4), child: Text('🎯 可改进', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MCMColors.mustard))),
        ...growth.improvements.map((s) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 4), child: Icon(CupertinoIcons.arrow_right_circle, size: 12, color: MCMColors.mustard)),
          const SizedBox(width: 8),
          Expanded(child: Text(s, style: TextStyle(fontSize: 13, color: MCMColors.primaryText(context), height: 1.4))),
        ]))),
      ],
      const SizedBox(height: 10),
    ]),
  );
}

Widget buildSectionCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, String? summary, String? badge, required List<String> items, required IconData itemIcon}) {
  return Container(
    decoration: BoxDecoration(color: MCMColors.card(context), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MCMColors.dividerColor(context)),
      boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 0), child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: iconColor)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MCMColors.primaryText(context))),
        if (badge != null) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(badge, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: iconColor)))],
      ])),
      if (summary != null) Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Text(summary, style: TextStyle(fontSize: 13, color: MCMColors.secondaryText(context), height: 1.4))),
      const SizedBox(height: 10),
      Divider(height: 1, color: MCMColors.dividerColor(context)),
      ...items.map((item) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: Icon(itemIcon, size: 13, color: iconColor.withOpacity(0.7))),
        const SizedBox(width: 8),
        Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: MCMColors.primaryText(context), height: 1.4))),
      ]))),
      const SizedBox(height: 4),
    ]),
  );
}

Widget buildGoalsCard(BuildContext context, List<String> goals) {
  return Container(
    decoration: BoxDecoration(color: MCMColors.card(context), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MCMColors.dividerColor(context)),
      boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 0), child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: MCMColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: const Icon(CupertinoIcons.flag_fill, size: 14, color: MCMColors.orange)),
        const SizedBox(width: 8),
        Text('下周目标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MCMColors.primaryText(context))),
      ])),
      const SizedBox(height: 10),
      Divider(height: 1, color: MCMColors.dividerColor(context)),
      ...goals.asMap().entries.map((entry) => Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 20, height: 20, decoration: BoxDecoration(color: MCMColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
          child: Center(child: Text('${entry.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MCMColors.orange)))),
        const SizedBox(width: 10),
        Expanded(child: Text(entry.value, style: TextStyle(fontSize: 13, color: MCMColors.primaryText(context), height: 1.4))),
      ]))),
      const SizedBox(height: 4),
    ]),
  );
}
