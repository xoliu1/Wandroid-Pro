import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wanandroid_pro/ai/services/browsing_history_db.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

/// 阅读统计页面
class ReadingStatsPage extends StatefulWidget {
  const ReadingStatsPage({super.key});

  @override
  State<ReadingStatsPage> createState() => _ReadingStatsPageState();
}

class _ReadingStatsPageState extends State<ReadingStatsPage> {
  final _db = BrowsingHistoryDatabase();
  int _chartTabIndex = 0; // 0=本周, 1=本月

  bool _isLoading = true;

  // 折线图数据
  Map<String, int> _weekData = {};
  Map<String, int> _monthData = {};

  // 分类 Top5
  List<Map<String, dynamic>> _topDomains = [];

  // 时长分布
  Map<String, int> _durationDist = {};

  // 总览数据
  int _totalDays = 0;
  int _totalCount = 0;
  int _todayCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      // 本周：周一到今天
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      // 本月：1号到今天
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _db.getDailyReadCount(from: weekStart, to: now),
        _db.getDailyReadCount(from: monthStart, to: now),
        _db.getTopDomains(limit: 5),
        _db.getDurationDistribution(),
        _db.getTotalReadDays(),
        _db.getTotalReadCount(),
        _db.getTodayStats(),
      ]);

      setState(() {
        _weekData = _fillMissingDates(results[0] as Map<String, int>, weekStart, now);
        _monthData = _fillMissingDates(results[1] as Map<String, int>, monthStart, now);
        _topDomains = results[2] as List<Map<String, dynamic>>;
        _durationDist = results[3] as Map<String, int>;
        _totalDays = results[4] as int;
        _totalCount = results[5] as int;
        final todayStats = results[6] as Map<String, dynamic>;
        _todayCount = todayStats['count'] as int;
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('❌ 阅读统计加载失败: $e\n$st');
      setState(() => _isLoading = false);
    }
  }

  /// 补全日期范围内缺失的日期（填 0），确保折线图连续
  Map<String, int> _fillMissingDates(Map<String, int> data, DateTime from, DateTime to) {
    final result = <String, int>{};
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(end)) {
      final key = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      result[key] = data[key] ?? 0;
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final bg = MCMColors.background(context);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MCMHeader(
              title: 'READING STATS',
              subtitle: '你的阅读数据一览',
              leading: MCMBackButton(),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // 总览卡片
                      _buildOverviewCards(textColor, subColor, cardBg, divColor),
                      const SizedBox(height: 8),

                      // 折线图 Tab
                      _buildChartSection(textColor, subColor, cardBg, divColor),
                      const SizedBox(height: 8),

                      // 分类 Top5
                      _buildTopDomainsSection(textColor, subColor, cardBg, divColor),
                      const SizedBox(height: 8),

                      // 时长分布
                      _buildDurationSection(textColor, subColor, cardBg, divColor),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── 总览卡片 ────────────────────────────────────────────────────────────────

  Widget _buildOverviewCards(Color textColor, Color subColor, Color cardBg, Color divColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard('今日阅读', '$_todayCount', CupertinoIcons.sun_max_fill, MCMColors.orange, cardBg, divColor, textColor, subColor),
          const SizedBox(width: 10),
          _buildStatCard('累计文章', '$_totalCount', CupertinoIcons.book_fill, MCMColors.grayBlue, cardBg, divColor, textColor, subColor),
          const SizedBox(width: 10),
          _buildStatCard('阅读天数', '$_totalDays', CupertinoIcons.calendar, MCMColors.olive, cardBg, divColor, textColor, subColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color,
      Color cardBg, Color divColor, Color textColor, Color subColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: MCMColors.darkBrown.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: subColor)),
          ],
        ),
      ),
    );
  }

  // ─── 折线图 ──────────────────────────────────────────────────────────────────

  Widget _buildTabButton(String label, int index, Color subColor) {
    final isSelected = _chartTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _chartTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? MCMColors.orange.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? MCMColors.orange : subColor,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(Color textColor, Color subColor, Color cardBg, Color divColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: MCMColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(CupertinoIcons.chart_bar_fill, size: 14, color: MCMColors.orange),
                  ),
                  const SizedBox(width: 8),
                  Text('阅读趋势', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  const Spacer(),
                  // Tab 切换（用普通按钮替代 TabBar，避免 TabBarView 嵌套 ListView 的断言错误）
                  Container(
                    decoration: BoxDecoration(
                      color: MCMColors.dividerColor(context).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton('本周', 0, subColor),
                        _buildTabButton('本月', 1, subColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: _chartTabIndex == 0
                  ? _buildLineChart(_weekData, textColor, subColor)
                  : _buildLineChart(_monthData, textColor, subColor),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<String, int> data, Color textColor, Color subColor) {
    if (data.isEmpty) {
      return Center(child: Text('暂无数据', style: TextStyle(color: subColor, fontSize: 13)));
    }

    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxVal == 0 ? 1 : maxVal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        painter: _LineChartPainter(
          entries: entries,
          maxVal: effectiveMax,
          lineColor: MCMColors.orange,
          gridColor: MCMColors.dividerColor(context),
          labelColor: subColor,
          dotColor: MCMColors.orange,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ─── 分类 Top5 ───────────────────────────────────────────────────────────────

  Widget _buildTopDomainsSection(Color textColor, Color subColor, Color cardBg, Color divColor) {
    final colors = [MCMColors.orange, MCMColors.grayBlue, MCMColors.olive, MCMColors.mustard, MCMColors.coral];
    final total = _topDomains.fold<int>(0, (sum, e) => sum + (e['count'] as int));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: MCMColors.grayBlue.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(CupertinoIcons.tag_fill, size: 14, color: MCMColors.grayBlue),
                  ),
                  const SizedBox(width: 8),
                  Text('最常阅读分类 Top 5', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: divColor),
            if (_topDomains.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('暂无数据', style: TextStyle(color: subColor, fontSize: 13))),
              )
            else
              ...(_topDomains.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final count = item['count'] as int;
                final ratio = total > 0 ? count / total : 0.0;
                final color = colors[idx % colors.length];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                            child: Center(
                              child: Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item['category'] as String,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                          ),
                          Text('$count 篇', style: TextStyle(fontSize: 12, color: subColor)),
                          const SizedBox(width: 6),
                          Text('${(ratio * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              })),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ─── 时长分布 ────────────────────────────────────────────────────────────────

  Widget _buildDurationSection(Color textColor, Color subColor, Color cardBg, Color divColor) {
    const bucketColors = {
      '未记录': MCMColors.darkBrown,
      '< 30s': MCMColors.coral,
      '30s-2min': MCMColors.orange,
      '2-5min': MCMColors.mustard,
      '5-10min': MCMColors.olive,
      '> 10min': MCMColors.grayBlue,
    };

    final total = _durationDist.values.fold<int>(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: MCMColors.mustard.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(CupertinoIcons.clock_fill, size: 14, color: MCMColors.mustard),
                  ),
                  const SizedBox(width: 8),
                  Text('阅读时长分布', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: divColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _durationDist.entries.where((e) => e.value > 0).map((entry) {
                  final color = bucketColors[entry.key] ?? MCMColors.grayBlue;
                  final ratio = total > 0 ? entry.value / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(entry.key, style: TextStyle(fontSize: 12, color: subColor)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: color.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text('${entry.value}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 折线图 Painter ──────────────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int maxVal;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color dotColor;

  _LineChartPainter({
    required this.entries,
    required this.maxVal,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const paddingLeft = 28.0;
    const paddingBottom = 24.0;
    const paddingTop = 12.0;
    const paddingRight = 8.0;

    final chartW = size.width - paddingLeft - paddingRight;
    final chartH = size.height - paddingBottom - paddingTop;

    // 网格线
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = paddingTop + chartH * (1 - i / 4);
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Y 轴标签
      final val = (maxVal * i / 4).round();
      final tp = TextPainter(
        text: TextSpan(text: '$val', style: TextStyle(fontSize: 9, color: labelColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    if (entries.isEmpty) return;

    final step = chartW / (entries.length - 1).clamp(1, 999);

    // 渐变填充
    final fillPath = Path();
    final points = <Offset>[];

    for (int i = 0; i < entries.length; i++) {
      final x = paddingLeft + i * step;
      final y = paddingTop + chartH * (1 - entries[i].value / maxVal);
      points.add(Offset(x, y));
    }

    fillPath.moveTo(points.first.dx, size.height - paddingBottom);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height - paddingBottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.02)],
      ).createShader(Rect.fromLTWH(0, paddingTop, size.width, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // 折线
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // 数据点 + X 轴标签
    final dotPaint = Paint()..color = dotColor;
    final dotBgPaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, dotBgPaint);
      canvas.drawCircle(points[i], 3, dotPaint);

      // X 轴标签（只显示部分，避免拥挤）
      final showLabel = entries.length <= 7 || i % ((entries.length / 5).ceil()) == 0 || i == entries.length - 1;
      if (showLabel) {
        final dateStr = entries[i].key;
        final label = dateStr.length >= 10 ? dateStr.substring(5) : dateStr; // MM-dd
        final tp = TextPainter(
          text: TextSpan(text: label, style: TextStyle(fontSize: 9, color: labelColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(points[i].dx - tp.width / 2, size.height - paddingBottom + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.entries != entries || old.maxVal != maxVal;
}
