import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_provider.dart';
import '../pages/widget/project_card.dart';
import '../utils/animations.dart';
import '../utils/app_colors.dart';

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});

  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 初始加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectProvider.notifier).loadData(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 接近底部时加载更多
      ref.read(projectProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(projectProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.groupedBackground(context),

      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: projectState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载失败: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _onRefresh(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
          data: (projects) {
            if (projects.isEmpty) {
              return const Center(
                child: Text('暂无项目数据'),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: projects.length + 1, // +1 for loading indicator
              itemBuilder: (context, index) {
                if (index < projects.length) {
                  final project = projects[index];
                  return AnimatedListItem(
                    index: index,
                    child: ProjectCard(
                      project: project,
                    ),
                  );
                } else {
                  // 加载更多指示器
                  final hasMoreData = ref.watch(projectProvider.notifier).hasMoreData;
                  if (hasMoreData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('没有更多数据了'),
                      ),
                    );
                  }
                }
              },
            );
          },
        ),
      ),
    );
  }
}