import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/providers/profile_provider.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/platform_utils.dart';

import '../../remote/Api.dart';

class CoinRankPage extends ConsumerStatefulWidget {
  const CoinRankPage({super.key});

  @override
  ConsumerState<CoinRankPage> createState() => _CoinRankPageState();
}

class _CoinRankPageState extends ConsumerState<CoinRankPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(coinRankProvider.notifier);
      if (!notifier.isLoading && notifier.hasMoreData) {
        notifier.loadMore();
      }
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(coinRankProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(coinRankProvider);

    return PlatformScaffold(
      backgroundColor: context.surfaceColor,
      appBar: PlatformAppBar(
        title: const Text('积分排行榜'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: dataAsync.when(
            loading: () => const Center(child: PlatformLoadingIndicator()),
            error: (error, stack) => _buildErrorView(error),
            data: (items) => _buildListView(items),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: context.secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败: ${error.toString()}',
            style: TextStyle(color: context.secondaryTextColor),
          ),
          const SizedBox(height: 16),
          PlatformButton(
            onPressed: _onRefresh,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<CoinRankItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无排行数据'));
    }

    final notifier = ref.read(coinRankProvider.notifier);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 前三名特殊展示
        if (items.length >= 3)
          SliverToBoxAdapter(
            child: FadeSlideIn(
              child: _buildTopThree(items.sublist(0, 3)),
            ),
          ),
        // 分割标题
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '完整排行',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.onSurfaceColor,
              ),
            ),
          ),
        ),
        // 排行列表
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == items.length) {
                // 底部加载指示器
                if (notifier.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: PlatformLoadingIndicator()),
                  );
                }
                if (!notifier.hasMoreData) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        '没有更多了',
                        style: TextStyle(
                          color: context.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              return AnimatedListItem(
                index: index,
                child: _buildRankItem(items[index]),
              );
            },
            childCount: items.length + 1,
          ),
        ),
      ],
    );
  }

  /// 前三名特殊展示区域
  Widget _buildTopThree(List<CoinRankItem> topThree) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor,
            context.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 第二名
          _buildTopItem(topThree[1], 2),
          // 第一名（最高）
          _buildTopItem(topThree[0], 1),
          // 第三名
          _buildTopItem(topThree[2], 3),
        ],
      ),
    );
  }

  Widget _buildTopItem(CoinRankItem item, int position) {
    final isFirst = position == 1;
    final avatarSize = isFirst ? 56.0 : 44.0;
    final fontSize = isFirst ? 20.0 : 16.0;

    // 奖牌颜色
    Color medalColor;
    String medalEmoji;
    switch (position) {
      case 1:
        medalColor = const Color(0xFFFFD700); // 金色
        medalEmoji = '🥇';
        break;
      case 2:
        medalColor = const Color(0xFFC0C0C0); // 银色
        medalEmoji = '🥈';
        break;
      default:
        medalColor = const Color(0xFFCD7F32); // 铜色
        medalEmoji = '🥉';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          medalEmoji,
          style: TextStyle(fontSize: isFirst ? 28 : 22),
        ),
        const SizedBox(height: 8),
        // 头像
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: medalColor.withOpacity(0.3),
            border: Border.all(color: medalColor, width: 2),
          ),
          child: Center(
            child: Text(
              _getDisplayName(item).substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: context.colors.onPrimary,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 用户名
        SizedBox(
          width: 80,
          child: Text(
            _getDisplayName(item),
            style: TextStyle(
              color: context.colors.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        // 积分
        Text(
          '${item.coinCount}',
          style: TextStyle(
            color: context.colors.onPrimary.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 普通排行项
  Widget _buildRankItem(CoinRankItem item) {
    final rankNum = int.tryParse(item.rank) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.dividerColor,
          width: 0.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 40,
          child: Center(
            child: _buildRankBadge(rankNum),
          ),
        ),
        title: Text(
          _getDisplayName(item),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.onSurfaceColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Lv.${item.level}',
          style: TextStyle(
            fontSize: 12,
            color: context.secondaryTextColor,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.coinCount}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '积分',
              style: TextStyle(
                fontSize: 11,
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 排名徽章
  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      final colors = [
        const Color(0xFFFFD700), // 金
        const Color(0xFFC0C0C0), // 银
        const Color(0xFFCD7F32), // 铜
      ];
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[rank - 1].withOpacity(0.2),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors[rank - 1],
            ),
          ),
        ),
      );
    }

    return Text(
      '$rank',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: context.secondaryTextColor,
      ),
    );
  }

  /// 获取显示名称（优先 nickname，其次 username）
  String _getDisplayName(CoinRankItem item) {
    if (item.nickname.isNotEmpty) return item.nickname;
    return item.username;
  }
}
