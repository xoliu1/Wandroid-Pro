import 'package:flutter/material.dart';
import 'package:notes_app/local/KV.dart';
import 'package:notes_app/pages/drawer/todo/task_page.dart';
import 'package:notes_app/pages/drawer/todo/todo_list_page.dart';

/// Todo 页面入口
/// 根据用户设置决定使用新版还是旧版 UI
class TodoEntry extends StatelessWidget {
  const TodoEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final useNewUI = getUseNewTodoUI();
    
    if (useNewUI) {
      return const TodoListPage();
    } else {
      return const TasksPage();
    }
  }
}
