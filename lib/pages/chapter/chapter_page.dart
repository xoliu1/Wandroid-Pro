import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';

import 'daily_question_page.dart';
import 'square_page.dart';
import 'navi_page.dart';
import '../teach/teach_list_page.dart';

class ChapterPage extends ConsumerStatefulWidget {
  const ChapterPage({super.key});

  @override
  ConsumerState<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends ConsumerState<ChapterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          Container(
            color: AppColors.tabBackground(context),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '导航'),
                Tab(text: '问答'),
                Tab(text: '广场'),
                Tab(text: '教程'),
              ],
              indicatorColor: AppColors.tabSelected(context),
              labelColor: AppColors.tabSelected(context),
              unselectedLabelColor: AppColors.tabUnselected(context),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                NaviPage(),
                DailyQuestionPage(),
                SquarePage(),
                TeachListPage(),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundColor(context),
    );
  }
}
