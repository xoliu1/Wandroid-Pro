import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_context.dart';
import '../services/user_context_service.dart';

/// 用户上下文 Provider — 全局可用
/// 
/// 在 App 启动时初始化，任何页面都可以通过 ref.watch(userContextProvider) 获取用户画像数据。
/// 
/// 使用示例：
/// ```dart
/// final contextAsync = ref.watch(userContextProvider);
/// contextAsync.when(
///   data: (ctx) => ctx?.toPromptSummary(),
///   loading: () => '加载中...',
///   error: (e, s) => '获取失败',
/// );
/// ```
final userContextProvider = StateNotifierProvider<UserContextNotifier, AsyncValue<UserContext?>>((ref) {
  return UserContextNotifier();
});

class UserContextNotifier extends StateNotifier<AsyncValue<UserContext?>> {
  UserContextNotifier() : super(const AsyncValue.loading());

  /// 防抖定时器，避免短时间内多次刷新
  Timer? _debounceTimer;
  
  /// 是否正在刷新中
  bool _isRefreshing = false;

  /// App 启动时调用，后台采集用户上下文
  Future<void> initialize() async {
    try {
      final context = await UserContextService.collectAndSave();
      if (mounted) {
        state = AsyncValue.data(context);
      }
    } catch (e, s) {
      debugPrint('📋 用户上下文初始化失败: $e');
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  /// 强制刷新（用户手动触发或数据变更后）
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    
    if (mounted) {
      state = const AsyncValue.loading();
    }
    try {
      final context = await UserContextService.forceRefresh();
      if (mounted) {
        state = AsyncValue.data(context);
      }
    } catch (e, s) {
      debugPrint('📋 用户上下文刷新失败: $e');
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// 延迟刷新（事件触发时调用，防抖 5 秒）
  /// 
  /// 适用于收藏/笔记/TODO 变更后的自动刷新。
  /// 短时间内多次调用只会执行最后一次。
  void scheduleRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('📋 事件触发：延迟刷新用户上下文');
      refresh();
    });
  }

  /// 快速获取 prompt 摘要（给 AI 用）
  /// 如果数据未就绪，返回 null
  String? get promptSummary => state.valueOrNull?.toPromptSummary();

  /// 获取当前用户上下文（如果已加载）
  UserContext? get currentContext => state.valueOrNull;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
