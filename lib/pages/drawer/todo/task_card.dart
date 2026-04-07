import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wanandroid_pro/model/Todo.dart';
import 'package:wanandroid_pro/pages/drawer/todo/task_editor.dart';
import 'package:wanandroid_pro/providers/task_provider.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';
import 'package:toastification/toastification.dart';

import 'add_task_widget.dart';

class TodoCard extends ConsumerWidget {
  final Todo todo;
  final bool showDescription;

  const TodoCard({
    super.key,
    required this.todo,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.fromMillisecondsSinceEpoch(todo.date);
    final isDeadlineApproaching = date.difference(DateTime.now()).inHours < 24;
    final isDone = todo.status == 1;

    return PressableScale(
      onTap: () {
        Navigator.push(
          context,
          SlideFromBottomRoute(page: TodoEditor(todo: todo)),
        );
      },
      onLongPress: () {
        _handleLongPress(context, ref, todo);
      },
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: AppColors.divider(context),
              width: 1.0,
            ),
          ),
          height: 150,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, left: 10, right: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    todo.title,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTimeWidget(context, todo, date, isDeadlineApproaching),
                    IconButton(
                      icon: Icon(
                        isDone
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.xmark_circle_fill,
                        size: 20.0,
                        color: isDone ? Colors.green : Colors.grey,
                      ),
                      onPressed: () {
                        _handleToggleStatus(context, ref, todo);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _handleToggleStatus(BuildContext context, WidgetRef ref, Todo todo) {
  final todoNotifier = ref.read(todoNotifierProvider.notifier);
  final updatedTodo = todo.copyWith(status: todo.status == 1 ? 0 : 1);
  todoNotifier.updateTodo(todo.id, updatedTodo);
  toastification.show(
    context: context,
    title: Text(todo.status == 1 ? '已标记为未完成' : '已标记为已完成'),
    primaryColor: todo.status == 1 ? Colors.black : Colors.green,
    showProgressBar: false,
    icon: Icon(
      todo.status == 1 ? Icons.timelapse_rounded : Icons.check_circle_outline,
      color: todo.status == 1 ? Colors.black : Colors.green,
      size: 20,
    ),
    animationDuration: const Duration(milliseconds: 200),
    autoCloseDuration: const Duration(seconds: 2),
  );
}

void _handleLongPress(BuildContext context, WidgetRef ref, Todo todo) {
  showModalBottomSheet(
    context: context,
    builder: (context) => _buildBottomSheet(context, ref, todo),
  );
}

Widget _buildBottomSheet(BuildContext context, WidgetRef ref, Todo todo) {
  return Container(
    height: 140,
    margin: const EdgeInsets.symmetric(vertical: 20),
    width: double.infinity,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMarkAsDoneButton(context, ref, todo),
        _buildDeleteButton(context, ref, todo),
      ],
    ),
  );
}

Widget _buildMarkAsDoneButton(BuildContext context, WidgetRef ref, Todo todo) {
  return InkWell(
    onTap: () {
      _handleToggleStatus(context, ref, todo);
      Navigator.pop(context);
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      height: 70,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            todo.status == 1 ? '标记为未完成' : '标记为已完成',
            style: TextStyle(
              fontSize: 15,
              color: todo.status == 1 ? Colors.black : Colors.green[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            CupertinoIcons.check_mark_circled,
            size: 20,
            color: todo.status == 1 ? Colors.black : Colors.green[800],
          ),
        ],
      ),
    ),
  );
}

Widget _buildDeleteButton(BuildContext context, WidgetRef ref, Todo todo) {
  return InkWell(
    onTap: () {
      ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
      toastification.show(
        context: context,
        title: const Text('任务已删除'),
        primaryColor: Colors.red,
        showProgressBar: false,
        animationDuration: const Duration(milliseconds: 200),
        autoCloseDuration: const Duration(seconds: 2),
      );
      Navigator.pop(context);
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 50),
      height: 70,
      width: double.infinity,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '删除任务',
            style: TextStyle(
              fontSize: 15,
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            CupertinoIcons.delete,
            size: 20,
            color: Colors.red,
          ),
        ],
      ),
    ),
  );
}

Widget _buildTimeWidget(BuildContext context, Todo todo, DateTime date, bool isDeadlineApproaching) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isDeadlineApproaching && todo.status != 1
            ? Colors.red.shade700.withOpacity(0.7)
            : AppColors.cardBackground(context).withOpacity(0.7),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Center(
        child: Text(
          DateFormat.MMMd().format(date.toLocal()).toString(),
          style: TextStyle(
            color: isDeadlineApproaching && todo.status != 1
                ? Colors.white
                : AppColors.primaryText(context),
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            decoration: isDeadlineApproaching && todo.status == 1
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
      ),
    );
}