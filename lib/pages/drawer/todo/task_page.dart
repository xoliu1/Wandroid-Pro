import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/Todo.dart';
import 'package:wanandroid_pro/pages/drawer/todo/task_card.dart';
import 'package:wanandroid_pro/providers/page_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';

import 'add_task_widget.dart';

const backgroundColor = Color(0xFFFF896F);

// 页面状态管理
class TaskPageState {
  final DateTime selectedDay;
  final ScrollController scrollController;
  final bool hasLoadedData;

  TaskPageState({
    required this.selectedDay,
    required this.scrollController,
    this.hasLoadedData = false,
  });

  TaskPageState copyWith({
    DateTime? selectedDay,
    ScrollController? scrollController,
    bool? hasLoadedData,
  }) {
    return TaskPageState(
      selectedDay: selectedDay ?? this.selectedDay,
      scrollController: scrollController ?? this.scrollController,
      hasLoadedData: hasLoadedData ?? this.hasLoadedData,
    );
  }
}

// 页面状态provider
final taskPageStateProvider = StateProvider<TaskPageState>((ref) {
  final controller = ScrollController();

  // 添加滚动监听
  controller.addListener(() {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      final notifier = ref.read(todoPaginationProvider.notifier);
      if (!ref.read(isLoadingProvider) && ref.read(hasMoreProvider)) {
        notifier.loadNextPage();
      }
    }
  });

  return TaskPageState(
    selectedDay: DateTime.now(),
    scrollController: controller,
    hasLoadedData: false,
  );
});

// 日期选择provider
final selectedDayProvider = Provider<DateTime>((ref) {
  return ref.watch(taskPageStateProvider).selectedDay;
});

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 延迟执行，确保widget树构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final pageState = ref.read(taskPageStateProvider);
    if (!pageState.hasLoadedData) {
      print('首次加载数据...');
      ref.read(todoPaginationProvider.notifier).loadFirstPage();
      ref.read(taskPageStateProvider.notifier).update(
        (state) => state.copyWith(hasLoadedData: true),
      );
    } else {
      print('使用缓存数据，跳过网络请求');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用，用于AutomaticKeepAliveClientMixin
    final selectedDay = ref.watch(selectedDayProvider);
    final state = ref.watch(todoPaginationProvider);
    final pageState = ref.watch(taskPageStateProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('用户点击刷新按钮');
          ref.read(todoPaginationProvider.notifier).refresh();
        },
        child: const Icon(Icons.refresh),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(todoPaginationProvider.notifier).refresh(),
        child: SingleChildScrollView(
          controller: pageState.scrollController,
          child: Column(
            children: [
              Container(
                height: 490,
                width: double.infinity,
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        backgroundColor.withOpacity(0.65),
                        backgroundColor,
                      ],
                    )),
                child: Column(
                  children: [
                    const SizedBox(height: 48.0),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: TableCalendar(
                          onDaySelected: (day, focusedDay) {
                            ref.read(taskPageStateProvider.notifier).update(
                                (state) => state.copyWith(selectedDay: day));
                          },
                          locale: 'zh_CN',
                          rowHeight: 56,
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            // 设置事件标记样式
                            markerDecoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          firstDay: DateTime.utc(2010, 10, 16),
                          lastDay: DateTime.utc(2030, 3, 14),
                          selectedDayPredicate: (day) =>
                              isSameDay(selectedDay, day),
                          focusedDay: selectedDay,
                          // 设置事件加载器
                          eventLoader: (day) {
                            return state.items.where((todo) {
                              final todoDate =
                                  DateTime.fromMillisecondsSinceEpoch(
                                      todo.date);
                              return isSameDay(todoDate, day);
                            }).toList();
                          },
                          headerStyle: const HeaderStyle(
                            headerPadding: EdgeInsets.only(bottom: 20),
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: Colors.transparent,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: Colors.transparent,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            todayBuilder: (context, day, focusedDay) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.5),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600),
                                ),
                              );
                            },
                            selectedBuilder: (context, day, focusedDay) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  day.day.toString(),
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600),
                                ),
                              );
                            },
                            // 添加事件标记构建器
                            markerBuilder: (context, day, events) {
                              if (events.isNotEmpty) {
                                return Positioned(
                                  bottom: 2,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                            dowBuilder: (context, day) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 0.0),
                              child: Center(
                                child: Text(
                                  [
                                    '一',
                                    '二',
                                    '三',
                                    '四',
                                    '五',
                                    '六',
                                    '日',
                                  ][day.weekday - 1],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            outsideBuilder: (context, day, focusedDay) =>
                                Container(),
                            defaultBuilder: (context, day, focusedDay) {
                              return Container(
                                margin: const EdgeInsets.all(10.0),
                                alignment: Alignment.center,
                                child: Text(
                                  day.day.toString(),
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTodoList(state, selectedDay, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList(
      PaginationState<Todo> state, DateTime selectedDay, WidgetRef ref) {
    print(
        '构建任务列表 - 总数据: ${state.items.length}条, 选中日期: ${selectedDay.year}-${selectedDay.month} - ${selectedDay.day}');

    if (state.isLoading && state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('错误: ${state.error}'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    ref.read(todoPaginationProvider.notifier).refresh(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 过滤选中日期的任务
    var filteredTodos = state.items.where((todo) {
      final todoDate = DateTime.fromMillisecondsSinceEpoch(todo.date);
      final isSame = isSameDay(todoDate, selectedDay);
      print(
          '任务日期: ${DateTime.fromMillisecondsSinceEpoch(todo.date)}, 选中日期: $selectedDay, 是否匹配: $isSame');
      return isSame;
    }).toList();

    if (filteredTodos.isEmpty) {
      print('显示空数据提示');
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              const Text('今天没有任务'),
              const SizedBox(height: 20),
              AddTodoWidget(date: selectedDay),
            ],
          ),
        ),
      );
    }

    var todoWidgets = filteredTodos
        .map((todo) => TodoCard(
              todo: todo,
              showDescription: true,
            ))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          GridView.count(
            padding: const EdgeInsets.only(left: 5.0, right: 5, top: 20),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              ...todoWidgets,
              AddTodoWidget(date: selectedDay),
            ],
          ),
          // 加载更多指示器
          if (state.isLoading && state.items.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          if (!state.hasMore && state.items.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('已加载当天全部任务'),
            ),
        ],
      ),
    );
  }
}
