import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/ai/services/browsing_history_db.dart';
import 'package:wanandroid_pro/local/KV.dart';
import 'package:wanandroid_pro/model/db/sqflite.dart';
import 'package:wanandroid_pro/pages/coin/coin_page.dart';
import 'package:wanandroid_pro/pages/collect/collect_list_page.dart';
import 'package:wanandroid_pro/pages/drawer/note/notes.dart';
import 'package:wanandroid_pro/pages/drawer/reading_stats_page.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';
import 'package:wanandroid_pro/providers/profile_provider.dart';
import 'package:wanandroid_pro/remote/Api.dart';
import 'package:wanandroid_pro/remote/service/NerworkService.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:wanandroid_pro/utils/platform_utils.dart';

/// 个人主页数据模型
class _ProfileStats {
  final int coinCount;
  final int level;
  final String rank;
  final int collectCount;
  final int noteCount;
  final int readDays;
  final int todayRead;
  final int totalRead;

  const _ProfileStats({
    required this.coinCount,
    required this.level,
    required this.rank,
    required this.collectCount,
    required this.noteCount,
    required this.readDays,
    required this.todayRead,
    required this.totalRead,
  });
}

/// 个人主页
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  _ProfileStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final profile = getUserProfile();
      final db = BrowsingHistoryDatabase();

      final results = await Future.wait([
        // 在线积分信息
        NetworkService.get<UserCoinInfo>(
          url: URL_COIN_INFO,
          fromJsonT: UserCoinInfo.fromJson,
        ).getData().catchError((_) => UserCoinInfo(
              coinCount: profile.coinInfo.coinCount,
              level: profile.coinInfo.level,
              nickname: profile.coinInfo.nickname,
              rank: int.tryParse(profile.coinInfo.rank) ?? 0,
              userId: profile.coinInfo.userId,
              username: profile.coinInfo.username,
            )),
        // 笔记数量
        Db.getNotes(),
        // 阅读天数
        db.getTotalReadDays(),
        // 今日阅读
        db.getTodayStats(),
        // 总阅读量
        db.getTotalReadCount(),
      ]);

      final coinInfo = results[0] as UserCoinInfo;
      final notes = results[1] as List<Map<String, dynamic>>;
      final readDays = results[2] as int;
      final todayStats = results[3] as Map<String, dynamic>;
      final totalRead = results[4] as int;

      setState(() {
        _stats = _ProfileStats(
          coinCount: coinInfo.coinCount,
          level: coinInfo.level,
          rank: '#${coinInfo.rank}',
          collectCount: profile.collectArticleInfo.count,
          noteCount: notes.length,
          readDays: readDays,
          todayRead: todayStats['count'] as int,
          totalRead: totalRead,
        );
        _isLoading = false;
      });
    } catch (e) {
      // 降级：使用本地缓存数据
      final profile = getUserProfile();
      final notes = ref.read(noteProvider);
      setState(() {
        _stats = _ProfileStats(
          coinCount: profile.coinInfo.coinCount,
          level: profile.coinInfo.level,
          rank: profile.coinInfo.rank,
          collectCount: profile.collectArticleInfo.count,
          noteCount: notes.length,
          readDays: 0,
          todayRead: 0,
          totalRead: 0,
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = getUserProfile();
    final bg = MCMColors.background(context);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            MCMHeader(
              title: 'PROFILE',
              subtitle: '个人主页',
              leading: MCMBackButton(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadStats,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // 头像 + 基本信息
                    _buildAvatarSection(profile, textColor, subColor, cardBg, divColor),
                    const SizedBox(height: 16),

                    // 数据统计网格
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CupertinoActivityIndicator(radius: 12)),
                      )
                    else if (_stats != null) ...[
                      _buildStatsGrid(textColor, subColor, cardBg, divColor),
                      const SizedBox(height: 16),
                      _buildQuickActions(context, textColor, subColor, cardBg, divColor),
                    ],
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

  // ─── 头像区域 ────────────────────────────────────────────────────────────────

  Widget _buildAvatarSection(UserInfoResp profile, Color textColor, Color subColor, Color cardBg, Color divColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: divColor, width: 1),
          boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            // MCM 装饰条
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: MCMColors.orange, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(width: 32, height: 3, decoration: BoxDecoration(color: MCMColors.mustard, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 6),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: MCMColors.olive, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 16),

            // 头像
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: MCMColors.orange.withOpacity(0.3), width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CachedNetworkImage(
                  imageUrl: profile.userInfo.icon.isNotEmpty
                      ? profile.userInfo.icon
                      : 'https://avatars.githubusercontent.com/u/126433098',
                  width: 80, height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80, height: 80,
                    color: MCMColors.orange.withOpacity(0.1),
                    child: const Icon(CupertinoIcons.person_fill, size: 36, color: MCMColors.orange),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 昵称
            Text(
              profile.userInfo.publicName.isNotEmpty ? profile.userInfo.publicName : profile.userInfo.username,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.3),
            ),
            const SizedBox(height: 4),

            // 邮箱
            if (profile.userInfo.email.isNotEmpty)
              Text(profile.userInfo.email, style: TextStyle(fontSize: 13, color: subColor)),

            const SizedBox(height: 12),

            // 等级 + 排名标签
            if (_stats != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge('Lv.${_stats!.level}', MCMColors.olive),
                  const SizedBox(width: 8),
                  _buildBadge('排名 ${_stats!.rank}', MCMColors.grayBlue),
                  const SizedBox(width: 8),
                  _buildBadge('${_stats!.coinCount} 积分', MCMColors.mustard),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ─── 数据统计网格 ────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(Color textColor, Color subColor, Color cardBg, Color divColor) {
    final stats = _stats!;
    final items = [
      _StatItem(label: '积分', value: '${stats.coinCount}', icon: CupertinoIcons.star_fill, color: MCMColors.mustard, page: const CoinPage()),
      _StatItem(label: '收藏', value: '${stats.collectCount}', icon: CupertinoIcons.heart_fill, color: MCMColors.coral, page: const CollectListPage()),
      _StatItem(label: '笔记', value: '${stats.noteCount}', icon: CupertinoIcons.doc_text_fill, color: MCMColors.olive, page: NotesPage()),
      _StatItem(label: '阅读天数', value: '${stats.readDays}', icon: CupertinoIcons.calendar_today, color: MCMColors.grayBlue, page: const ReadingStatsPage()),
      _StatItem(label: '今日阅读', value: '${stats.todayRead}', icon: CupertinoIcons.sun_max_fill, color: MCMColors.orange, page: const ReadingStatsPage()),
      _StatItem(label: '累计阅读', value: '${stats.totalRead}', icon: CupertinoIcons.book_fill, color: MCMColors.grayBlue, page: const ReadingStatsPage()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: MCMSectionLabel('数据统计'.toUpperCase()),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: item.page != null ? () => navigatePlatform(context, item.page!) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: divColor, width: 1),
                    boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 18, color: item.color),
                      ),
                      const SizedBox(height: 8),
                      Text(item.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 2),
                      Text(item.label, style: TextStyle(fontSize: 11, color: subColor)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── 快捷操作 ────────────────────────────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context, Color textColor, Color subColor, Color cardBg, Color divColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: MCMSectionLabel('快捷入口'.toUpperCase()),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: divColor, width: 1),
              boxShadow: [BoxShadow(color: MCMColors.darkBrown.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                _buildActionTile(context, icon: CupertinoIcons.star_circle_fill, color: MCMColors.mustard,
                    title: '我的积分', subtitle: '查看积分明细和排行榜', page: const CoinPage(), textColor: textColor, subColor: subColor, divColor: divColor, showDivider: true),
                _buildActionTile(context, icon: CupertinoIcons.heart_circle_fill, color: MCMColors.coral,
                    title: '我的收藏', subtitle: '查看收藏的文章', page: const CollectListPage(), textColor: textColor, subColor: subColor, divColor: divColor, showDivider: true),
                _buildActionTile(context, icon: CupertinoIcons.doc_circle_fill, color: MCMColors.olive,
                    title: '我的笔记', subtitle: '查看和编辑笔记', page: NotesPage(), textColor: textColor, subColor: subColor, divColor: divColor, showDivider: true),
                _buildActionTile(context, icon: CupertinoIcons.chart_bar_circle_fill, color: MCMColors.grayBlue,
                    title: '阅读统计', subtitle: '查看阅读趋势和分析', page: const ReadingStatsPage(), textColor: textColor, subColor: subColor, divColor: divColor, showDivider: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget page,
    required Color textColor,
    required Color subColor,
    required Color divColor,
    required bool showDivider,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => navigatePlatform(context, page),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: MCMColors.mustard.withOpacity(0.6), size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Container(height: 1, color: divColor, margin: const EdgeInsets.symmetric(horizontal: 16)),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Widget? page;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.page,
  });
}
