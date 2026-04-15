import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/Todo.dart';
import 'package:wanandroid_pro/pages/drawer/todo/task_editor.dart';
import 'package:wanandroid_pro/providers/task_provider.dart';
import 'package:toastification/toastification.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:wanandroid_pro/pages/drawer/todo/ai_todo_sheet.dart';
import 'package:wanandroid_pro/pages/drawer/todo/pomodoro_page.dart';

enum TodoFilter {
  all,
  pending,
  completed,
}

final todoFilterProvider = StateProvider<TodoFilter>((ref) => TodoFilter.all);

class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
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
      final notifier = ref.read(todoNotifierProvider.notifier);
      final state = ref.read(todoNotifierProvider);
      if (!state.isLoading && state.hasMore) {
        notifier.loadNextPage();
      }
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(todoNotifierProvider.notifier).refresh();
  }

  List<Todo> _filterTodos(List<Todo> todos, TodoFilter filter) {
    switch (filter) {
      case TodoFilter.pending:
        return todos.where((todo) => todo.status == 0).toList();
      case TodoFilter.completed:
        return todos.where((todo) => todo.status == 1).toList();
      case TodoFilter.all:
        return todos;
    }
  }

  Map<String, List<Todo>> _groupTodosByDate(List<Todo> todos) {
    final groups = <String, List<Todo>>{};

    for (final todo in todos) {
      final date = DateTime.fromMillisecondsSinceEpoch(todo.date);
      final key = DateFormat('yyyy-MM-dd').format(date);
      groups.putIfAbsent(key, () => []).add(todo);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, groups[key]!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todoNotifierProvider);
    final filter = ref.watch(todoFilterProvider);
    final filteredTodos = _filterTodos(state.items, filter);

    return Scaffold(
      backgroundColor: AppColors.groupedBackground(context),
      appBar: AppBar(
        title: const Text('待办事项'),
        actions: [
          // 番茄钟专注按钮
          IconButton(
            icon: const Icon(CupertinoIcons.timer, size: 22),
            tooltip: '番茄钟专注',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PomodoroPage()),
            ),
          ),
          // AI 智能助手按钮
          IconButton(
            icon: const Icon(CupertinoIcons.sparkles, size: 22),
            tooltip: 'AI 智能助手',
            onPressed: () => showAITodoSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTodoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(state.items),
          _buildFilterSegment(filter),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildContent(state, filteredTodos),
            ),
          ),
        ],
      ),
    );
  }

  /// 统计看板：今日完成 / 待完成 / 逾期
  Widget _buildStatsCard(List<Todo> allTodos) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final total = allTodos.length;
    final completed = allTodos.where((t) => t.status == 1).length;
    final pending = allTodos.where((t) => t.status == 0).length;
    final overdue = allTodos.where((t) {
      if (t.status == 1) return false;
      final date = DateTime.fromMillisecondsSinceEpoch(t.date);
      return date.isBefore(today);
    }).length;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MCMColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MCMColors.dividerColor(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: MCMColors.darkBrown.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('总计', total, MCMColors.grayBlue),
          _buildStatDivider(),
          _buildStatItem('待完成', pending, MCMColors.mustard),
          _buildStatDivider(),
          _buildStatItem('已完成', completed, MCMColors.olive),
          if (overdue > 0) ...[
            _buildStatDivider(),
            _buildStatItem('逾期', overdue, MCMColors.coral),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: MCMColors.secondaryText(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: MCMColors.dividerColor(context),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFilterSegment(TodoFilter currentFilter) {
    final divColor = MCMColors.dividerColor(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: divColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildFilterButton('全部', TodoFilter.all, currentFilter),
          _buildFilterButton('待办', TodoFilter.pending, currentFilter),
          _buildFilterButton('已完成', TodoFilter.completed, currentFilter),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
      String title, TodoFilter filter, TodoFilter current) {
    final isSelected = filter == current;
    final cardBg = MCMColors.card(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(todoFilterProvider.notifier).state = filter;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: MCMColors.darkBrown.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? AppColors.link(context)
                  : AppColors.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TodoState state, List<Todo> todos) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: MCMColors.secondaryText(context),
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败: ${state.error}',
              style: TextStyle(color: MCMColors.secondaryText(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onRefresh,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (todos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MCMStarburst(
              size: 64,
              color: MCMColors.mustard.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(),
              style: TextStyle(
                fontSize: 16,
                color: MCMColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddTodoDialog(context),
              child: const Text('添加待办'),
            ),
          ],
        ),
      );
    }

    final groupedTodos = _groupTodosByDate(todos);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _calculateItemCount(groupedTodos, state),
      itemBuilder: (context, index) {
        return _buildListItem(context, index, groupedTodos, state);
      },
    );
  }

  int _calculateItemCount(
      Map<String, List<Todo>> groupedTodos, TodoState state) {
    int count = 0;
    for (final entry in groupedTodos.entries) {
      count++;
      count += entry.value.length;
    }
    if (state.isLoading || !state.hasMore) {
      count++;
    }
    return count;
  }

  Widget? _buildListItem(BuildContext context, int index,
      Map<String, List<Todo>> groupedTodos, TodoState state) {
    int currentIndex = 0;

    int groupIndex = 0; // 当前是第几个日期分组
    for (final entry in groupedTodos.entries) {
      if (currentIndex == index) {
        // 日期头部：左右展开滑入 + 底部装饰线动画
        return _AnimatedDateHeader(
          dateKey: entry.key,
          delay: Duration(milliseconds: groupIndex * 120),
        );
      }
      currentIndex++;

      int itemInGroup = 0; // 当前分组内第几个任务
      for (final todo in entry.value) {
        if (currentIndex == index) {
          // 任务项：从下方滑入，延迟在日期头部之后，组内交错
          return AnimatedListItem(
            index: itemInGroup,
            delay: Duration(milliseconds: groupIndex * 120 + 80 + itemInGroup * 60),
            child: _TodoListItem(
              todo: todo,
              onToggle: () => _toggleTodoStatus(todo),
              onEdit: () => _editTodo(todo),
              onDelete: () => _deleteTodo(todo),
            ),
          );
        }
        currentIndex++;
        itemInGroup++;
      }
      groupIndex++;
    }

    if (index == currentIndex) {
      if (state.isLoading) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (!state.hasMore) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text(
              '没有更多了',
              style: TextStyle(
                color: MCMColors.walnut,
                fontSize: 12,
              ),
            ),
          ),
        );
      }
    }

    return null;
  }

  String _getEmptyMessage() {
    final filter = ref.read(todoFilterProvider);
    switch (filter) {
      case TodoFilter.pending:
        return '没有待办事项';
      case TodoFilter.completed:
        return '还没有完成的事项';
      case TodoFilter.all:
        return '暂无待办事项';
    }
  }

  void _showAddTodoDialog(BuildContext context) async {
    final todo = Todo(
      id: -1,
      title: '',
      content: '',
      date: DateTime.now().millisecondsSinceEpoch,
      status: 0,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodoEditor(todo: todo, isCreate: true),
      ),
    );

    if (mounted &&
        result != null &&
        result is Todo &&
        result.title.isNotEmpty) {
      ref.read(todoNotifierProvider.notifier).addTodo(result);
      toastification.show(
        context: context,
        title: const Text('待办已添加'),
        primaryColor: Colors.green,
        showProgressBar: false,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  void _toggleTodoStatus(Todo todo) {
    final newStatus = todo.status == 0 ? 1 : 0;
    final updatedTodo = todo.copyWith(status: newStatus);
    ref.read(todoNotifierProvider.notifier).updateTodo(todo.id, updatedTodo);

    toastification.show(
      context: context,
      title: Text(newStatus == 1 ? '已完成' : '已标记为未完成'),
      primaryColor: newStatus == 1 ? Colors.green : Colors.orange,
      showProgressBar: false,
      autoCloseDuration: const Duration(seconds: 2),
    );
  }

  void _editTodo(Todo todo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodoEditor(todo: todo),
      ),
    );

    if (result != null && result is Todo) {
      ref.read(todoNotifierProvider.notifier).updateTodo(todo.id, result);
    }
  }

  void _deleteTodo(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除待办'),
        content: const Text('确定要删除这个待办事项吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
              toastification.show(
                context: context,
                title: const Text('已删除'),
                primaryColor: Colors.red,
                showProgressBar: false,
                autoCloseDuration: const Duration(seconds: 2),
              );
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日期头部的水平滑入动画
/// 日期数字从左侧滑入，星期从右侧滑入，形成展开效果
class _AnimatedDateHeader extends StatefulWidget {
  final String dateKey;
  final Duration delay;

  const _AnimatedDateHeader({
    required this.dateKey,
    required this.delay,
  });

  @override
  State<_AnimatedDateHeader> createState() => _AnimatedDateHeaderState();
}

class _AnimatedDateHeaderState extends State<_AnimatedDateHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slideLeft;  // 日期数字从左侧滑入
  late Animation<Offset> _slideRight; // 星期从右侧滑入
  late Animation<double> _lineWidth;  // 底部装饰线展开

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // 日期数字从左侧 -20px 滑入
    _slideLeft = Tween<Offset>(
      begin: const Offset(-20, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 星期从右侧 +20px 滑入
    _slideRight = Tween<Offset>(
      begin: const Offset(20, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // 底部装饰线从 0 展开到 1
    _lineWidth = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.dateKey);
    final monthText = DateFormat('MMMM', 'zh_CN').format(date);
    final dayText = DateFormat('dd').format(date);
    final weekdayText = DateFormat('EEEE', 'zh_CN').format(date);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(top: 24, bottom: 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 日期数字 + 月份：从左侧滑入
                  Transform.translate(
                    offset: _slideLeft.value,
                    child: Opacity(
                      opacity: _opacity.value,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dayText,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              monthText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.secondaryText(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 星期：从右侧滑入
                  Transform.translate(
                    offset: _slideRight.value,
                    child: Opacity(
                      opacity: _opacity.value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          weekdayText,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.secondaryText(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 底部装饰线：从中间向两边展开
              const SizedBox(height: 8),
              FractionallySizedBox(
                widthFactor: _lineWidth.value,
                child: Container(
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.divider(context).withOpacity(0),
                        AppColors.divider(context),
                        AppColors.divider(context).withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodoListItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TodoListItem({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == 1;
    final date = DateTime.fromMillisecondsSinceEpoch(todo.date);
    final now = DateTime.now();
    final isOverdue =
        date.isBefore(DateTime(now.year, now.month, now.day)) && !isDone;

    return Dismissible(
      key: Key('todo_${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
          child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: MCMColors.dividerColor(context),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: MCMColors.darkBrown.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                  child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? MCMColors.olive : MCMColors.walnut,
                      width: 2,
                    ),
                    color: isDone ? MCMColors.olive : Colors.transparent,
                  ),
                  child: isDone
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDone
                            ? AppColors.tertiaryText(context)
                            : AppColors.primaryText(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (todo.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          todo.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (isOverdue)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MCMColors.coral.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '已逾期',
                            style: TextStyle(
                              fontSize: 10,
                              color: MCMColors.coral,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: MCMColors.secondaryText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
