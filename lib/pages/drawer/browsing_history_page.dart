
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/ai/services/browsing_history_db.dart';
import 'package:notes_app/ai/ui/article_webview_page.dart';
import 'package:notes_app/utils/app_colors.dart';
import 'package:notes_app/utils/platform_utils.dart';

/// 浏览历史页面
class BrowsingHistoryPage extends ConsumerStatefulWidget {
  const BrowsingHistoryPage({super.key});

  @override
  ConsumerState<BrowsingHistoryPage> createState() =>
      _BrowsingHistoryPageState();
}

class _BrowsingHistoryPageState extends ConsumerState<BrowsingHistoryPage> {
  final _db = BrowsingHistoryDatabase();
  List<BrowsingRecord> _records = [];
  Map<String, dynamic> _todayStats = {'count': 0, 'totalDuration': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _db.getRecentRecords(limit: 200),
        _db.getTodayStats(),
      ]);
      setState(() {
        _records = results[0] as List<BrowsingRecord>;
        _todayStats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('加载失败: $e');
      }
    }
  }

  Future<void> _deleteRecord(BrowsingRecord record) async {
    if (record.id == null) return;
    try {
      await _db.deleteRecord(record.id!);
      await _loadData();
    } catch (e) {
      if (mounted) {
        _showError('删除失败: $e');
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await _showConfirmDialog(
      '确认清空',
      '确定要清空所有浏览历史吗？此操作不可恢复。',
    );
    if (confirmed != true) return;

    try {
      await _db.clearAll();
      await _loadData();
    } catch (e) {
      if (mounted) {
        _showError('清空失败: $e');
      }
    }
  }

  void _openArticle(BrowsingRecord record) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ArticleWebViewPage(
          url: record.url,
          title: record.title.isNotEmpty ? record.title : null,
        ),
      ),
    );
  }

  /// 按日期分组记录
  Map<String, List<BrowsingRecord>> _groupByDate() {
    final grouped = <String, List<BrowsingRecord>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final record in _records) {
      final recordDate = record.visitedDateTime;
      final recordDay =
          DateTime(recordDate.year, recordDate.month, recordDate.day);

      String label;
      if (recordDay == today) {
        label = '今天';
      } else if (recordDay == yesterday) {
        label = '昨天';
      } else if (now.difference(recordDay).inDays < 7) {
        label = _weekdayName(recordDay.weekday);
      } else {
        label =
            '${recordDay.month.toString().padLeft(2, '0')}-${recordDay.day.toString().padLeft(2, '0')}';
        if (recordDay.year != now.year) {
          label = '${recordDay.year}-$label';
        }
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(record);
    }
    return grouped;
  }

  String _weekdayName(int weekday) {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[weekday];
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    if (seconds < 60) return '${seconds}秒';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes分钟';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    return remainMinutes > 0 ? '$hours小时$remainMinutes分钟' : '$hours小时';
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      backgroundColor: context.surfaceColor,
      appBar: PlatformAppBar(
        title: const Text('浏览历史'),
        actions: _records.isNotEmpty
            ? [
                PlatformUtils.isIOS
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('清空',
                            style: TextStyle(
                                color: CupertinoColors.destructiveRed)),
                        onPressed: _clearAll,
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: '清空全部',
                        onPressed: _clearAll,
                      ),
              ]
            : null,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: PlatformLoadingIndicator())
            : _records.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildContent(),
                  ),
      ),
    );
  }

  Widget _buildContent() {
    final grouped = _groupByDate();
    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: sections.length + 1, // +1 为顶部统计卡片
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatsCard();
        }
        final section = sections[index - 1];
        return _buildSection(section.key, section.value);
      },
    );
  }

  /// 今日统计卡片
  Widget _buildStatsCard() {
    final count = _todayStats['count'] as int;
    final totalDuration = _todayStats['totalDuration'] as int;
    final durationText = _formatDuration(totalDuration);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.primaryColor.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            PlatformUtils.isIOS ? CupertinoIcons.book : Icons.auto_stories,
            size: 32,
            color: context.primaryColor,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日阅读',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: context.onSurfaceColor,
                    ),
                    children: [
                      TextSpan(
                        text: '$count',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.primaryColor,
                        ),
                      ),
                      const TextSpan(text: ' 篇'),
                      if (durationText.isNotEmpty) ...[
                        const TextSpan(text: '  ·  '),
                        TextSpan(
                          text: durationText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 日期分组区域
  Widget _buildSection(String label, List<BrowsingRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.secondaryTextColor,
            ),
          ),
        ),
        // 记录列表
        ...records.map((record) => _buildRecordItem(record)),
      ],
    );
  }

  /// 单条浏览记录
  Widget _buildRecordItem(BrowsingRecord record) {
    final timeStr = _formatTime(record.visitedDateTime);
    final durationStr = _formatDuration(record.duration);

    return Dismissible(
      key: Key('browsing_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: PlatformUtils.isIOS
            ? CupertinoColors.destructiveRed
            : Colors.red,
        child: Icon(
          PlatformUtils.isIOS ? CupertinoIcons.delete : Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) => _showConfirmDialog(
        '确认删除',
        '确定要删除这条浏览记录吗？',
      ),
      onDismissed: (direction) => _deleteRecord(record),
      child: InkWell(
        onTap: () => _openArticle(record),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间列
              SizedBox(
                width: 44,
                child: Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.secondaryTextColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 内容列
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title.isNotEmpty ? record.title : record.url,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // URL 域名
                        Flexible(
                          child: Text(
                            _extractDomain(record.url),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.secondaryTextColor,
                            ),
                          ),
                        ),
                        if (durationStr.isNotEmpty) ...[
                          Text(
                            '  ·  ',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.secondaryTextColor,
                            ),
                          ),
                          Text(
                            durationStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.primaryColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 箭头
              Icon(
                PlatformUtils.isIOS
                    ? CupertinoIcons.chevron_right
                    : Icons.chevron_right,
                size: 18,
                color: context.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 从 URL 中提取域名
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  /// 空状态
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PlatformUtils.isIOS
                ? CupertinoIcons.book
                : Icons.history,
            size: 64,
            color: context.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无浏览记录',
            style: TextStyle(
              fontSize: 16,
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '浏览文章后会自动记录在这里',
            style: TextStyle(
              fontSize: 13,
              color: context.secondaryTextColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    if (PlatformUtils.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('确定', style: TextStyle(color: context.errorColor)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (PlatformUtils.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('错误'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
