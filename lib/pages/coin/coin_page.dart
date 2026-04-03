import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/local/KV.dart';
import 'package:notes_app/providers/profile_provider.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/platform_utils.dart';

import '../../remote/Api.dart';
import 'coin_rank_page.dart';

class CoinPage extends ConsumerWidget {
  const CoinPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinInfoAsync = ref.watch(coinInfoProvider);
    final coinHistoryAsync = ref.watch(coinHistoryProvider);

    return PlatformScaffold(
      backgroundColor: context.surfaceColor,
      appBar: PlatformAppBar(
        title: const Text('我的积分'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.chart_bar_alt_fill, size: 22),
            tooltip: '积分排行榜',
            onPressed: () => navigatePlatform(context, const CoinRankPage()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(coinInfoProvider);
          ref.invalidate(coinHistoryProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: coinInfoAsync.when(
                loading: () => _buildCoinCardShimmer(context),
                error: (error, stack) => _buildErrorCard(context, error.toString()),
                data: (coinInfo) => FadeSlideIn(
                  child: _buildCoinCard(context, coinInfo),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  '积分明细',
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.onSurfaceColor,
                  ),
                ),
              ),
            ),
            coinHistoryAsync.when(
              loading: () => SliverFillRemaining(
                child: Center(child: PlatformLoadingIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    '加载失败: ${error.toString()}',
                    style: TextStyle(color: context.errorColor),
                  ),
                ),
              ),
              data: (coinHistory) => _buildHistoryList(context, coinHistory),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinCard(BuildContext context, UserCoinInfo coinInfo) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前积分',
                    style: TextStyle(
                      color: context.colors.onPrimary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${coinInfo.coinCount}',
                    style: TextStyle(
                      color: context.colors.onPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '排名', '#${coinInfo.rank}'),
              _buildStatItem(context, '用户名', getUserProfile().userInfo.username ?? '未设置'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: context.colors.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: context.colors.onPrimary.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCoinCardShimmer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.containerColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: PlatformLoadingIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            PlatformUtils.isIOS ? Icons.error_outline : Icons.error_outline,
            color: context.errorColor,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '加载失败: $error',
            style: TextStyle(color: context.errorColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, CoinHistory coinHistory) {
    if (coinHistory.datas.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            '暂无积分记录',
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = coinHistory.datas[index];
          return AnimatedListItem(
            index: index,
            child: _buildHistoryItem(context, item),
          );
        },
        childCount: coinHistory.datas.length,
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, CoinHistoryItem item) {
    final date = DateTime.fromMillisecondsSinceEpoch(item.date);
    final formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: item.type == 1 
                ? context.successColor.withOpacity(0.1)
                : context.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            item.type == 1 ? Icons.add_circle_outline : Icons.remove_circle_outline,
            color: item.type == 1 ? context.successColor : context.warningColor,
            size: 24,
          ),
        ),
        title: Text(
          item.reason,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.onSurfaceColor,
          ),
        ),
        subtitle: Text(
          formattedDate,
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
              '${item.type == 1 ? '+' : '-'}${item.coinCount}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: item.type == 1 ? context.successColor : context.errorColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '积分: ${item.coinCount}',
              style: TextStyle(
                fontSize: 12,
                color: context.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}