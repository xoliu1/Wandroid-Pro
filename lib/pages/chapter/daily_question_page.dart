import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/widget/question_card.dart';
import 'package:notes_app/providers/article_provider.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';

class DailyQuestionPage extends ConsumerStatefulWidget {
  const DailyQuestionPage({super.key});

  @override
  ConsumerState<DailyQuestionPage> createState() => _DailyQuestionPageState();
}

class _DailyQuestionPageState extends ConsumerState<DailyQuestionPage> {
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(dailyQuestionProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(dailyQuestionProvider.notifier).refresh();
  }


  @override
  Widget build(BuildContext context) {
    final questionNotifier = ref.read(dailyQuestionProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.groupedBackground(context),
      // navigationBar: CupertinoNavigationBar(
      //   middle: const Text('每日问答'),
      //   trailing: CupertinoButton(
      //     padding: EdgeInsets.zero,
      //     minSize: 0,
      //     onPressed: () => _showPageSizeSheet(questionNotifier),
      //     child: const Icon(CupertinoIcons.settings, size: 24),
      //   ),
      // ),
      child: SafeArea(
        child: _buildContent(questionNotifier),
      ),
    );
  }

  Widget _buildContent(DailyQuestionNotifier questionNotifier) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: CupertinoColors.systemBlue,
      child: Consumer(
        builder: (context, ref, child) {
          final questionsAsync = ref.watch(dailyQuestionProvider);

          return questionsAsync.when(
            loading: () =>
            const Center(
              child: CupertinoActivityIndicator(),
            ),
            error: (error, stack) =>
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle,
                          size: 48, color: CupertinoColors.systemGrey),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败: ${error.toString()}',
                        style: CupertinoTheme
                            .of(context)
                            .textTheme
                            .textStyle,
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        color: CupertinoColors.systemBlue,
                        onPressed: _onRefresh,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
            data: (questions) {
              if (questions.isEmpty) {
                return Center(
                  child: Text(
                    '暂无问答内容',
                    style: CupertinoTheme
                        .of(context)
                        .textTheme
                        .textStyle
                        .copyWith(
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: questions.length + 1,
                itemBuilder: (context, index) {
                  if (index == questions.length) {
                    final hasMoreData = questionNotifier.hasMoreData;
                    final isLoading = questionNotifier.isLoading;

                    if (!hasMoreData) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            '没有更多问答了',
                            style: CupertinoTheme
                                .of(context)
                                .textTheme
                                .textStyle
                                .copyWith(
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      );
                    }

                    if (isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                            child: CupertinoActivityIndicator()),
                      );
                    }

                    return const SizedBox.shrink();
                  }

                  return AnimatedListItem(
                    index: index,
                    child: QuestionCard(article: questions[index]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}