import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 浏览记录模型
class BrowsingRecord {
  final int? id;
  final String url;
  final String title;
  final int visitedAt; // 毫秒时间戳
  final int duration; // 浏览时长（秒），0 表示未记录

  BrowsingRecord({
    this.id,
    required this.url,
    required this.title,
    required this.visitedAt,
    this.duration = 0,
  });

  Map<String, dynamic> toMap() => {
    'url': url,
    'title': title,
    'visited_at': visitedAt,
    'duration': duration,
  };

  factory BrowsingRecord.fromMap(Map<String, dynamic> map) => BrowsingRecord(
    id: map['id'] as int?,
    url: map['url'] as String? ?? '',
    title: map['title'] as String? ?? '',
    visitedAt: map['visited_at'] as int? ?? 0,
    duration: map['duration'] as int? ?? 0,
  );

  /// 浏览时间的 DateTime
  DateTime get visitedDateTime =>
      DateTime.fromMillisecondsSinceEpoch(visitedAt);
}

/// 浏览历史数据库服务
///
/// 记录用户浏览过的文章，为 AI 提供更丰富的用户画像数据。
/// 采用单例模式。
class BrowsingHistoryDatabase {
  static final BrowsingHistoryDatabase _instance =
      BrowsingHistoryDatabase._internal();
  factory BrowsingHistoryDatabase() => _instance;
  BrowsingHistoryDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'browsing_history.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE browsing_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        visited_at INTEGER NOT NULL,
        duration INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // 为 visited_at 创建索引，加速按时间查询
    await db.execute(
        'CREATE INDEX idx_browsing_visited_at ON browsing_history(visited_at)');
  }

  /// 记录一次浏览（防重复：5秒内同 URL 不重复插入）
  Future<void> recordVisit({
    required String url,
    String title = '',
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    // 5秒内同 URL 已有记录则跳过，避免重复插入
    final existing = await db.query(
      'browsing_history',
      where: 'url = ? AND visited_at > ?',
      whereArgs: [url, now - 5000],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      debugPrint('📖 跳过重复浏览记录: $url');
      return;
    }
    await db.insert('browsing_history', {
      'url': url,
      'title': title,
      'visited_at': now,
      'duration': 0,
    });
    debugPrint('📖 记录浏览: $title ($url)');
  }

  /// 更新最近一条记录的标题（用于内容提取后补充标题）
  Future<void> updateTitle(String url, String title) async {
    if (title.isEmpty) return;
    final db = await database;
    final records = await db.query(
      'browsing_history',
      where: 'url = ?',
      whereArgs: [url],
      orderBy: 'visited_at DESC',
      limit: 1,
    );
    if (records.isNotEmpty) {
      await db.update(
        'browsing_history',
        {'title': title},
        where: 'id = ?',
        whereArgs: [records.first['id']],
      );
      debugPrint('📖 更新浏览标题: $title');
    }
  }

  /// 更新浏览时长（页面离开时调用）
  Future<void> updateDuration(String url, int durationSeconds) async {
    final db = await database;
    // 更新最近一条该 URL 的记录
    final records = await db.query(
      'browsing_history',
      where: 'url = ?',
      whereArgs: [url],
      orderBy: 'visited_at DESC',
      limit: 1,
    );
    if (records.isNotEmpty) {
      await db.update(
        'browsing_history',
        {'duration': durationSeconds},
        where: 'id = ?',
        whereArgs: [records.first['id']],
      );
    }
  }

  /// 获取最近的浏览记录
  Future<List<BrowsingRecord>> getRecentRecords({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'browsing_history',
      orderBy: 'visited_at DESC',
      limit: limit,
    );
    return maps.map((m) => BrowsingRecord.fromMap(m)).toList();
  }

  /// 获取指定日期的浏览记录
  Future<List<BrowsingRecord>> getRecordsByDate(DateTime date) async {
    final db = await database;
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    final maps = await db.query(
      'browsing_history',
      where: 'visited_at >= ? AND visited_at <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'visited_at DESC',
    );
    return maps.map((m) => BrowsingRecord.fromMap(m)).toList();
  }

  /// 获取最近浏览的文章标题（去重，用于 AI 上下文）
  Future<List<String>> getRecentTitles({int limit = 15}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT title FROM browsing_history 
      WHERE title != '' 
      ORDER BY visited_at DESC 
      LIMIT ?
    ''', [limit]);
    return maps.map((m) => m['title'] as String).toList();
  }

  /// 获取今日浏览统计
  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final countResult = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(duration), 0) as total_duration
      FROM browsing_history 
      WHERE visited_at >= ?
    ''', [startOfDay]);

    return {
      'count': (countResult.first['count'] as num?)?.toInt() ?? 0,
      'totalDuration': (countResult.first['total_duration'] as num?)?.toInt() ?? 0,
    };
  }

  /// 删除单条浏览记录
  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete(
      'browsing_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 清空所有浏览记录
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('browsing_history');
  }

  /// 获取指定时间范围内每天的阅读量
  /// 返回 Map<'yyyy-MM-dd', count>
  Future<Map<String, int>> getDailyReadCount({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database;
    final fromMs = DateTime(from.year, from.month, from.day).millisecondsSinceEpoch;
    final toMs = DateTime(to.year, to.month, to.day, 23, 59, 59).millisecondsSinceEpoch;

    // 注意：SQLite 的 localtime 在移动端不可靠，改用手动偏移本地时区
    final tzOffsetSeconds = DateTime.now().timeZoneOffset.inSeconds;
    final rows = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m-%d', datetime((visited_at / 1000) + ?, 'unixepoch')) AS day,
        COUNT(*) AS cnt
      FROM browsing_history
      WHERE visited_at >= ? AND visited_at <= ?
      GROUP BY day
      ORDER BY day ASC
    ''', [tzOffsetSeconds, fromMs, toMs]);

    return {for (final r in rows) r['day'] as String: ((r['cnt'] as num?)?.toInt() ?? 0)};
  }

  /// 获取 URL 域名 Top N（用于模拟"分类"统计）
  Future<List<Map<String, dynamic>>> getTopDomains({int limit = 5}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT 
        CASE
          WHEN url LIKE '%wanandroid.com%' THEN 'WanAndroid'
          WHEN url LIKE '%github.com%' THEN 'GitHub'
          WHEN url LIKE '%juejin%' THEN '掘金'
          WHEN url LIKE '%csdn%' THEN 'CSDN'
          WHEN url LIKE '%zhihu%' THEN '知乎'
          WHEN url LIKE '%medium%' THEN 'Medium'
          WHEN url LIKE '%stackoverflow%' THEN 'StackOverflow'
          WHEN url LIKE '%developer.android%' THEN 'Android Docs'
          WHEN url LIKE '%flutter.dev%' THEN 'Flutter Docs'
          ELSE '其他'
        END AS category,
        COUNT(*) AS cnt
      FROM browsing_history
      GROUP BY category
      ORDER BY cnt DESC
      LIMIT ?
    ''', [limit]);

    return rows.map((r) => {'category': r['category'] as String, 'count': (r['cnt'] as num?)?.toInt() ?? 0}).toList();
  }

  /// 获取阅读时长分布（按时长区间分组）
  /// 返回各区间的文章数量
  Future<Map<String, int>> getDurationDistribution() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT
        CASE
          WHEN duration = 0 THEN '未记录'
          WHEN duration < 30 THEN '< 30s'
          WHEN duration < 120 THEN '30s-2min'
          WHEN duration < 300 THEN '2-5min'
          WHEN duration < 600 THEN '5-10min'
          ELSE '> 10min'
        END AS bucket,
        COUNT(*) AS cnt
      FROM browsing_history
      GROUP BY bucket
    ''');

    // 按固定顺序返回
    const order = ['未记录', '< 30s', '30s-2min', '2-5min', '5-10min', '> 10min'];
    final raw = {for (final r in rows) r['bucket'] as String: (r['cnt'] as num?)?.toInt() ?? 0};
    return {for (final k in order) k: raw[k] ?? 0};
  }

  /// 获取总阅读天数（有浏览记录的不同日期数）
  Future<int> getTotalReadDays() async {
    final db = await database;
    final tzOffsetSeconds = DateTime.now().timeZoneOffset.inSeconds;
    final rows = await db.rawQuery('''
      SELECT COUNT(DISTINCT strftime('%Y-%m-%d', datetime((visited_at / 1000) + ?, 'unixepoch'))) AS days
      FROM browsing_history
    ''', [tzOffsetSeconds]);
    return (rows.first['days'] as num?)?.toInt() ?? 0;
  }

  /// 获取总阅读量
  Future<int> getTotalReadCount() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS cnt FROM browsing_history');
    return (rows.first['cnt'] as num?)?.toInt() ?? 0;
  }

  /// 清理 30 天前的旧数据
  Future<void> cleanOldRecords({int keepDays = 30}) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: keepDays))
        .millisecondsSinceEpoch;
    final deleted = await db.delete(
      'browsing_history',
      where: 'visited_at < ?',
      whereArgs: [cutoff],
    );
    if (deleted > 0) {
      debugPrint('📖 清理了 $deleted 条旧浏览记录');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
