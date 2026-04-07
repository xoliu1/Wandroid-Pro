import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/Todo.dart';
import '../remote/CgiTodo.dart';
import 'page_provider.dart';

/// 兼容类型别名：TodoState 等价于 PaginationState<Todo>
typedef TodoState = PaginationState<Todo>;

/// 兼容类型别名：TodoNotifier 等价于 TodoPaginationNotifier
typedef TodoNotifier = TodoPaginationNotifier;

/// 统一使用 page_provider 中的 TodoPaginationNotifier
/// todoNotifierProvider 作为向后兼容的别名
final todoNotifierProvider = todoPaginationProvider;

final allTasksProvider = FutureProvider.autoDispose((ref) async {
  final result = await CgiTodo().queryTodo(1);
  return result;
});