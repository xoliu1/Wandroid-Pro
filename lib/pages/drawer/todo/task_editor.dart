import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/model/Todo.dart';
import 'package:notes_app/providers/task_provider.dart';
import 'package:toastification/toastification.dart';
import 'package:notes_app/utils/app_colors.dart';

import '../../../remote/CgiTodo.dart';


class TodoEditor extends ConsumerStatefulWidget {
  final Todo todo;
  final bool isCreate;

  const TodoEditor({super.key, required this.todo, this.isCreate = false});

  @override
  ConsumerState<TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends ConsumerState<TodoEditor> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  late Todo todo;
  late bool isCreate;

  @override
  void initState() {
    super.initState();
    todo = widget.todo;
    isCreate = widget.isCreate;
    _titleController.text = todo.title;
    _contentController.text = todo.content;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: SizedBox(
        height: MediaQuery
            .sizeOf(context)
            .height,
        width: MediaQuery
            .sizeOf(context)
            .width,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildAppBar(),
                _buildTitleField(),
                _buildContentField(),
                const SizedBox(height: 80),
              ],
            ),
            _buildDateTimePicker(),
          ],
        ),

      ),
    );
  }

  Widget _buildAppBar() {
    final todoNotifier = ref.read(todoNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(top: 30, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              CupertinoIcons.back,
              color: AppColors.secondaryText(context),
              size: 30,
            ),
            onPressed: () {
              Navigator.pop(context);
              todoNotifier.updateTodo(todo.id, todo);
            },
          ),
          Row(
            children: [
              _buildPriorityButton(todoNotifier),
              const SizedBox(width: 10),
              _buildStatusButton(todoNotifier),
              const SizedBox(width: 10),
              _buildDeleteButton(todoNotifier),
              _buildDoneButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityButton(TodoNotifier todoNotifier) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: todo.priority > 0 ? Colors.orange : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondaryText(context)),
      ),
      child: Center(
        child: IconButton(
          icon: Icon(
            CupertinoIcons.flag,
            color:
            todo.status == 1 ? Colors.green : AppColors.secondaryText(context),
            size: 16,
          ),
          onPressed: () {
            setState(() {
              todo.priority = todo.priority == 1 ? 0 : 1;
            });
            todoNotifier.updateTodo(todo.id, todo);
          },
        ),
      ),
    );
  }

  Widget _buildStatusButton(TodoNotifier todoNotifier) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: todo.status == 1 ? Colors.green : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondaryText(context)),
      ),
      child: Center(
        child: IconButton(
          icon: Icon(
            CupertinoIcons.check_mark,
            color:
            todo.status == 1 ? Colors.white : AppColors.secondaryText(context),
            size: 16,
          ),
          onPressed: () {
            setState(() {
              todo.status = todo.status == 1 ? 0 : 1;
            });
            todoNotifier.updateTodo(todo.id, todo);
          },
        ),
      ),
    );
  }

  Widget _buildDeleteButton(TodoNotifier todoNotifier) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.secondaryText(context)),
      ),
      child: Center(
        child: IconButton(
          icon: Icon(
            CupertinoIcons.delete,
            color: AppColors.secondaryText(context),
            size: 16,
          ),
          onPressed: () => _showDeleteDialog(todoNotifier),
        ),
      ),
    );
  }

  Widget _buildDoneButton() {
    return TextButton(
      onPressed: () {
        todo.title = _titleController.text;
        todo.content = _contentController.text;
        if (isCreate) {
          saveTodo(todo);
        } else {
          updateTodo(todo);
        }
      },
      child: Text(
        'Done',
        style: TextStyle(color: AppColors.secondaryText(context)),
      ),
    );
  }

  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
      child: TextField(
        controller: _titleController,
        autofocus: false,
        onChanged: (value) => todo.title = value,
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Add a new todo',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey.shade700),
        ),
        style: TextStyle(
          fontSize: 30,
          color: AppColors.primaryText(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildContentField() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: TextField(
        controller: _contentController,
        onChanged: (value) => todo.content = value,
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Content',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Colors.grey.shade700.withOpacity(0.5),
            fontWeight: FontWeight.w400,
          ),
        ),
        style: TextStyle(fontSize: 20, color: AppColors.primaryText(context)),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -2),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: InkWell(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    todo.dateStr,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          onTap: () => _showDateTimePicker(),
        ),
      ),
    );
  }

  void _showDeleteDialog(TodoNotifier todoNotifier) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Todo'),
            content: const Text('Are you sure you want to delete this todo?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Delete'),
                onPressed: () {
                  todoNotifier.deleteTodo(todo.id);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  toastification.show(
                    context: context,
                    title: const Text('Todo deleted'),
                    primaryColor: Colors.red,
                    showProgressBar: false,
                    animationDuration: const Duration(milliseconds: 200),
                    autoCloseDuration: const Duration(seconds: 2),
                  );
                },
              ),
            ],
          ),
    );
  }

  void _showDateTimePicker() {
    DatePicker.showDateTimePicker(
      context,
      showTitleActions: true,
      minTime: DateTime(2018, 3, 5),
      maxTime: DateTime(2030, 6, 7),
      currentTime: DateTime.fromMillisecondsSinceEpoch(todo.date).toLocal(),
      onChanged: (date) {},
      onConfirm: (date) =>
          setState(() {
            todo.date = date.millisecondsSinceEpoch;
            todo.dateStr = DateFormat('yyyy-MM-dd').format(date);
          }),
      locale: LocaleType.zh,
    );
  }

  void saveTodo(Todo todo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    CgiTodo().addTodo(todo).onSuccess((t) {
      Navigator.pop(context); // 关闭加载对话框
      toastification.show(
        context: context,
        title: const Text('保存成功！'),
        primaryColor: Colors.green,
        showProgressBar: false,
        autoCloseDuration: const Duration(seconds: 2),
      );
      // 新增成功后，将服务端返回的 Todo 添加到列表
      final newTodo = Todo(
        id: t.id,
        title: t.title,
        content: t.content,
        date: t.date,
        status: t.status,
        type: t.type,
        priority: t.priority,
        completeDate: t.completeDate,
        completeDateStr: t.completeDateStr,
        dateStr: t.dateStr,
        userId: t.userId,
      );
      ref.read(todoNotifierProvider.notifier).addTodo(newTodo);
      Navigator.pop(context, newTodo); // 返回结果触发刷新
    }).onFail((code, msg) {
      Navigator.pop(context); // 关闭加载对话框
      toastification.show(
        context: context,
        title: Text('Save failed: $code , $msg'),
        primaryColor: Colors.red,
        showProgressBar: false,
        autoCloseDuration: const Duration(seconds: 2),
      );
    });
  }

  void updateTodo(Todo todo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      CgiTodo().updateTodo(todo).onSuccess((t) {
        Navigator.pop(context); // 关闭加载对话框
        toastification.show(
          context: context,
          title: const Text('保存成功！'),
          primaryColor: Colors.green,
          showProgressBar: false,
          autoCloseDuration: const Duration(seconds: 2),
        );
        ref.read(todoNotifierProvider.notifier).updateTodo(todo.id, todo);
        Navigator.pop(context, todo); // 返回结果触发刷新
      }).onFail((code, msg) {
        Navigator.pop(context); // 关闭加载对话框
        toastification.show(
          context: context,
          title: Text('Save failed: $code , $msg'),
          showProgressBar: false,
          autoCloseDuration: const Duration(seconds: 2),
        );
      });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭加载对话框
      }
    }
  }
}
