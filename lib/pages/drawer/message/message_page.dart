import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

import '../../../providers/profile_provider.dart';
import '../../widget/message_item.dart';


class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 页面加载时同时加载未读和已读消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      ref.read(unreadMessageCountProvider.notifier).loadUnreadCount(),
      ref.read(unreadMessagesProvider.notifier).refresh(),
      ref.read(readedMessagesProvider.notifier).refresh(),
    ]);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(readedMessagesProvider.notifier);
      if (notifier.hasMoreData && !notifier.isLoading) {
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text('消息中心'),
      ),
      backgroundColor: AppColors.groupedBackground(context),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final unreadMessages = ref.watch(unreadMessagesProvider);
            final readedMessages = ref.watch(readedMessagesProvider);
            final unreadCount = ref.watch(unreadMessageCountProvider);

            return RefreshIndicator(
              onRefresh: _loadInitialData,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // 未读消息部分
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.divider(context).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.bell_fill,
                            color: AppColors.accent(context),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '未读消息',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText(context),
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const Spacer(),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(top: 8)),
                  unreadMessages.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: const Center(
                              child: Text(
                                '没有未读消息',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  decoration: TextDecoration.none,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= messages.length) return null;
                            return AnimatedListItem(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: MessageItem(message: messages[index]),
                              ),
                            );
                          },
                          childCount: messages.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: Text('加载失败: $error')),
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(top: 24)),
                  // 历史消息部分
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.divider(context).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock_fill,
                            color: AppColors.iconSecondary(context),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '历史消息',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText(context),
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(top: 8)),
                  readedMessages.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: const Center(
                              child: Text(
                                '没有历史消息',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  decoration: TextDecoration.none,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= messages.length) return null;
                            return AnimatedListItem(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: MessageItem(message: messages[index]),
                              ),
                            );
                          },
                          childCount: messages.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: Text('加载失败: $error')),
                      ),
                    ),
                  ),
                  // 加载更多提示
                  // Consumer(
                  //   builder: (context, ref, child) {
                  //     final notifier = ref.watch(readedMessagesProvider.notifier);
                  //     if (notifier.hasMoreData && notifier.isLoading) {
                  //       return const SliverToBoxAdapter(
                  //         child: Padding(
                  //           padding: EdgeInsets.all(16),
                  //           child: Center(child: CupertinoActivityIndicator()),
                  //         ),
                  //       );
                  //     }
                  //     return const SliverToBoxAdapter(
                  //       child: SizedBox(height: 20),
                  //     );
                  //   },
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}