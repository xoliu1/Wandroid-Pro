import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/model/Todo.dart';

import '../ai/providers/user_context_provider.dart';
import '../remote/CgiTodo.dart';

// 分页状态类
class PaginationState<T> {
  final List<T> items;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const PaginationState({
    this.items = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    int? currentPage,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }
}

// 分页加载的StateNotifier
class TodoPaginationNotifier extends StateNotifier<PaginationState<Todo>> {
  TodoPaginationNotifier({this.onDataChanged}) : super(const PaginationState<Todo>());

  final int _pageSize = 10;
  final CgiTodo _cgi = CgiTodo();
  
  /// 数据变更回调（用于通知用户画像刷新）
  final VoidCallback? onDataChanged;

  // 加载第一页
  Future<void> loadFirstPage() async {
    print('开始加载第一页数据...');
    state = state.copyWith(isLoading: true, error: null);

      final response = await _cgi.queryTodo(1);
      if (response.isEmpty) {
        print('第一页返回空数据');
        state = state.copyWith(
          items: [],
          currentPage: 1,
          isLoading: false,
          hasMore: false,
        );
        return;
      }
      state = state.copyWith(
        items: response,
        currentPage: 1,
        isLoading: false,
        hasMore: response.length >= _pageSize,
      );
      print('第一页数据加载完成，当前页码:1，是否有更多数据:${state.hasMore}');
      state = state.copyWith(
        isLoading: false,
      );

  }

  // 加载下一页
  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) {
      print('跳过加载下一页: isLoading=${state.isLoading}, hasMore=${state.hasMore}');
      return;
    }

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('开始加载第$nextPage页数据...');

      final newTodos = await _cgi.queryTodo(nextPage);
      print('第$nextPage页返回: ${newTodos.length}条记录');

      final allTodos = [...state.items, ...newTodos];
      if (newTodos.isEmpty) {
        print('第$nextPage页无数据，停止加载');
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
        );
        return;
      }

      state = state.copyWith(
        items: allTodos,
        currentPage: nextPage,
        isLoading: false,
        hasMore: newTodos.length >= _pageSize,
      );
    } catch (e, stackTrace) {
      print('加载第${state.currentPage + 1}页数据失败: $e');
      print('错误堆栈: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadFirstPage();
  }

  // 添加新任务并更新列表
  void addTodo(Todo todo) {
    state = state.copyWith(
      items: [todo, ...state.items],
    );
    onDataChanged?.call();
  }

  // 更新任务
  void updateTodo(int id, Todo updatedTodo) {
    final updatedItems = state.items.map((todo) {
      return todo.id == id ? updatedTodo : todo;
    }).toList();

    state = state.copyWith(items: updatedItems);
    onDataChanged?.call();
  }

  // 删除任务
  void deleteTodo(int id) {
    final updatedItems = state.items.where((todo) => todo.id != id).toList();
    state = state.copyWith(items: updatedItems);
    onDataChanged?.call();
  }
}

// 使用StateNotifierProvider创建provider
final todoPaginationProvider = StateNotifierProvider<TodoPaginationNotifier, PaginationState<Todo>>(
  (ref) {
    final notifier = TodoPaginationNotifier(
      onDataChanged: () {
        // TODO 数据变更时，延迟刷新用户画像
        try {
          ref.read(userContextProvider.notifier).scheduleRefresh();
        } catch (_) {
          // Provider 可能尚未初始化，忽略
        }
      },
    );
    // 延迟加载第一页，避免在provider创建时立即加载
    Future.microtask(() {
      if (notifier.state.items.isEmpty && !notifier.state.isLoading) {
        notifier.loadFirstPage();
      }
    });
    return notifier;
  },
);

// 用于监听分页状态的Provider
final currentPageProvider = Provider<int>((ref) {
  return ref.watch(todoPaginationProvider).currentPage;
});

final hasMoreProvider = Provider<bool>((ref) {
  return ref.watch(todoPaginationProvider).hasMore;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(todoPaginationProvider).isLoading;
});