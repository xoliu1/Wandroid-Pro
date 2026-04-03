import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobkit_dashed_border/mobkit_dashed_border.dart';
import 'package:notes_app/model/Todo.dart';
import 'package:notes_app/pages/drawer/todo/task_editor.dart';
import 'package:notes_app/providers/task_provider.dart';

class AddTodoWidget extends ConsumerWidget {
  var backgroundColor = const Color(0xFFFF896F);
  DateTime date;

  AddTodoWidget({
    super.key,
    required this.date,
    this.backgroundColor = const Color(0xFFFF896F),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoNotifier = ref.read(todoNotifierProvider.notifier);

    return InkWell(
      onTap: () async {
        var todo = Todo(
          id: -1,
          title: '',
          content: '',
          date: date.millisecondsSinceEpoch,
          status: 0,
        );

        final editedTodo = await Navigator.push(
          context,
          SlideFromBottomRoute(
            page: TodoEditor(
              todo: todo,
              isCreate: true,
            ),
          ),
        );

        if (editedTodo != null && editedTodo.title.isNotEmpty) {
          todoNotifier.addTodo(editedTodo);
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: DashedBorder.fromBorderSide(
            dashLength: 10,
            side: BorderSide(color: backgroundColor.withOpacity(0.8), width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0),
              blurRadius: 5.0,
              spreadRadius: 3.0,
              offset: const Offset(2, 2),
            )
          ],
        ),
        height: 150,
        width: 150,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15),
          child: Stack(
            children: [
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: backgroundColor,
                      size: 18.0,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      'New Todo',
                      style: TextStyle(
                        color: backgroundColor,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Icon(
                    CupertinoIcons.add_circled_solid,
                    color: backgroundColor.withOpacity(0.8),
                    size: 30.0,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// 统一的底部弹出动效路由
class SlideFromBottomRoute extends PageRouteBuilder {
  final Widget page;

  SlideFromBottomRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}