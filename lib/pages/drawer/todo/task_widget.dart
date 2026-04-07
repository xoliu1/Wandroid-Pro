import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:wanandroid_pro/model/Todo.dart';
import 'package:wanandroid_pro/pages/drawer/todo/task_editor.dart';
import 'package:wanandroid_pro/providers/task_provider.dart';
import 'package:wanandroid_pro/utils/app_colors.dart';
import 'package:wanandroid_pro/utils/functions.dart';
import 'package:toastification/toastification.dart';

class TodoWidget extends ConsumerStatefulWidget {
  final Todo todo;
  final bool showTime;

  const TodoWidget({super.key, required this.todo, this.showTime = false});

  @override
  ConsumerState<TodoWidget> createState() => _TodoWidgetState();
}

class _TodoWidgetState extends ConsumerState<TodoWidget> {
  late bool isDeadlineApproaching;

  @override
  void initState() {
    super.initState();
    isDeadlineApproaching = deadlineApproaching(DateTime.fromMillisecondsSinceEpoch(widget.todo.date));
  }

  @override
  Widget build(BuildContext context) {
    final todoNotifier = ref.read(todoNotifierProvider.notifier);

    return Hero(
      tag: 'todo_${widget.todo.id}',
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  TodoEditor(todo: widget.todo),
            ),
          );
        },
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => _buildActionSheet(todoNotifier),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppColors.divider(context),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardBackground(context).withOpacity(0.3),
                blurRadius: 5.0,
                spreadRadius: 5.0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          height: 150,
          width: 150,
          child: Stack(
            children: [
              Padding(
                  padding: const EdgeInsets.all(15),
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      SizedBox(
                        child: Text(
                          widget.todo.title,
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: AppColors.primaryText(context).withOpacity(0.8),
                            fontSize: 16.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Visibility(
                        visible: widget.todo.content.isNotEmpty,
                        child: const Divider(height: 1, color: Colors.grey),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.todo.content,
                        softWrap: true,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )),
              Positioned(
                bottom: 10,
                child: Container(
                  height: 40,
                  width: 150,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cardBackground(context).withOpacity(0.8),
                        blurRadius: 10.0,
                        spreadRadius: 16.0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        iconSize: 40,
                        onPressed: () {
                          done(widget.todo, ref);
                        },
                        isSelected: widget.todo.status == 1,
                        style: IconButton.styleFrom(
                          shape: const CircleBorder(),
                        ),
                        selectedIcon: const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: Colors.white,
                            size: 40.0),
                        icon: Icon(CupertinoIcons.time_solid,
                            color: AppColors.primaryText(context).withValues(alpha: 0.8),
                            size: 40.0),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        height: 18,
                        decoration: BoxDecoration(
                          color: isDeadlineApproaching && widget.todo.status != 1
                              ? Colors.red.shade700.withOpacity(0.7)
                              : AppColors.cardBackground(context).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(5.0),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cardBackground(context).withOpacity(0.15),
                              blurRadius: 10.0,
                              spreadRadius: 5.0,
                              offset: const Offset(0.5, 0.8),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.showTime
                              ? DateFormat.jm()
                                  .format(DateTime.fromMillisecondsSinceEpoch(widget.todo.date).toLocal())
                                  .toString()
                              : DateFormat.EEEE()
                                  .format(DateTime.fromMillisecondsSinceEpoch(widget.todo.date).toLocal())
                                  .toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDeadlineApproaching && widget.todo.status != 1
                                ? Colors.white
                                : AppColors.primaryText(context),
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void done(Todo todo, WidgetRef ref) {
    final todoNotifier = ref.read(todoNotifierProvider.notifier);
    final updatedTodo = todo.copyWith(status: todo.status == 1 ? 0 : 1);
    todoNotifier.updateTodo(todo.id, updatedTodo);

    toastification.show(
      context: context,
      title: Text(todo.status == 1 ? '未完成' : '已完成'),
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

  Widget _buildActionSheet(TodoNotifier todoNotifier) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 20),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () {
              final updatedTodo =
                  widget.todo.copyWith(status: widget.todo.status == 1 ? 0 : 1);
              todoNotifier.updateTodo(widget.todo.id, updatedTodo);
              toastification.show(
                context: context,
                title: Text(widget.todo.status == 1
                    ? 'Marked as undone'
                    : 'Marked as done'),
                primaryColor:
                    widget.todo.status == 1 ? Colors.black : Colors.green,
                showProgressBar: false,
                icon: Icon(
                  widget.todo.status == 1
                      ? Icons.timelapse_rounded
                      : Icons.check_circle_outline,
                  color: widget.todo.status == 1 ? Colors.black : Colors.green,
                  size: 20,
                ),
                animationDuration: const Duration(milliseconds: 200),
                autoCloseDuration: const Duration(seconds: 2),
              );
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
                    widget.todo.status == 1 ? 'Mark as undone' : 'Mark as done',
                    style: TextStyle(
                      fontSize: 15,
                      color: widget.todo.status == 1
                          ? Colors.black
                          : Colors.green[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.check_mark_circled,
                    size: 20,
                    color: widget.todo.status == 1
                        ? Colors.black
                        : Colors.green[800],
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              todoNotifier.deleteTodo(widget.todo.id);
              toastification.show(
                context: context,
                title: const Text('Todo deleted'),
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
                    'Delete todo',
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
          ),
        ],
      ),
    );
  }
}
