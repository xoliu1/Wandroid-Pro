import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/remote/Api.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/functions.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../../model/article.dart';
import '../../providers/chapter_provider.dart';


final selectedIndexProvider = StateProvider<int>((ref) => 0);

class NaviPage extends ConsumerStatefulWidget {
  const NaviPage({super.key});

  @override
  ConsumerState<NaviPage> createState() => _NaviPageState();
}

class _NaviPageState extends ConsumerState<NaviPage> {

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    super.dispose();
  }

  void _launchUrl(String url) {
    launchInApp(context, Uri.parse(url));
  }

  ListObserverController? observerController;

  @override
  Widget build(BuildContext context) {
    final naviAsync = ref.watch(naviProvider);
    final selectedIndex = ref.watch(selectedIndexProvider);
    final selectedNotifier = ref.read(selectedIndexProvider.notifier);
    observerController ??= ListObserverController(controller: scrollController);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: naviAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('加载失败: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(naviProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (naviItems) {
          return Row(
            children: [
              // 左侧分类列表
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: AppColors.sidebarBackground(context),
                  border: Border(
                    right: BorderSide(
                      color: AppColors.sidebarBorder(context),
                      width: 1,
                    ),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 60),
                  itemCount: naviItems.length,
                  itemBuilder: (context, index) {
                    final item = naviItems[index];
                    return InkWell(
                      onTap: () {
                        selectedNotifier.state = index;
                        observerController?.animateTo(
                            index: index,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selectedIndex == index
                              ? AppColors.sidebarSelected(context)
                              : AppColors.sidebarUnselected(context),
                          border: Border(
                            left: BorderSide(
                              color: selectedIndex == index
                                  ? AppColors.accent(context)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          item.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selectedIndex == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedIndex == index
                                ? AppColors.accent(context)
                                : AppColors.secondaryText(context),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 右侧内容区域
              Expanded(child: _buildRightList(naviItems, selectedNotifier)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNaviChip(Article article) {
    return PressableScale(
      onTap: () => _launchUrl(article.link),
      scaleDown: 0.93,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accent(context).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          article.title,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.accent(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  ScrollController scrollController = ScrollController();
  Widget _buildRightList(List<NaviItem> naviItems, selectedNotifier)  {
    return ListViewObserver(
      controller: observerController,
      child: ListView.builder(
        controller: scrollController,
        padding:
            const EdgeInsets.only(top: 16, bottom: 46, left: 16, right: 16),
        itemCount: naviItems.length,
        itemBuilder: (context, index) {
          final item = naviItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.articles.map((article) {
                    return _buildNaviChip(article);
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
      onObserve: (resultMode) {
        selectedNotifier.state = resultMode.firstChild?.index ?? 0;
      },
    );
  }
}
