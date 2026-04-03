import 'package:flutter_riverpod/flutter_riverpod.dart';


/// 可复用的分页 provider，只需传入 load 逻辑即可。
abstract class PaginationState<T> {
  List<T> get items;
  bool get hasMoreData;
  bool get isLoading;
  int get currentPage;
  int? get pageSize;
}

class PaginationNotifier<T> extends StateNotifier<AsyncValue<List<T>>> {
  PaginationNotifier({
    required this.fetchFunction,
    this.defaultPageSize,
    this.enableCache = true,
  }) : super(const AsyncValue.loading()) {
    _loadInitialWithCache();
  }

  final Future<List<T>> Function(int page, int? pageSize) fetchFunction;
  final int? defaultPageSize;
  final bool enableCache;

  final List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMoreData = true;
  int? _pageSize;
  bool _isFirstLoad = true;
  bool _hasCache = false;

  List<T> get items => List.from(_items);
  bool get hasMoreData => _hasMoreData;
  bool get isLoading => _isLoading;
  int get currentPage => _currentPage;
  int? get pageSize => _pageSize ?? defaultPageSize;

  // 缓存相关
  List<T>? _cachedItems;
  int? _cachedPage;
  int? _cachedPageSize;

  Future<void> _loadInitialWithCache() async {
    if (enableCache && _cachedItems != null && _cachedPageSize == pageSize) {
      // 使用缓存
      _items.addAll(_cachedItems!);
      _currentPage = _cachedPage ?? 0;
      _hasCache = true;
      state = AsyncValue.data(List.from(_items));
    } else {
      // 首次加载
      await loadData(refresh: true);
    }
  }

  Future<void> loadData({bool refresh = false}) async {
    if (_isLoading) return;

    // 如果是刷新，强制重新加载
    if (refresh) {
      _currentPage = 0;
      _items.clear();
      _hasMoreData = true;
      _hasCache = false;
      state = const AsyncValue.loading();
    } else if (_isFirstLoad && _hasCache) {
      // 首次加载但有缓存，跳过网络请求
      return;
    }

    _isLoading = true;

    try {
      final newItems = await fetchFunction(_currentPage, pageSize);

      if (newItems.isEmpty) {
        _hasMoreData = false;
      } else {
        _items.addAll(newItems);
        _currentPage++;
      }

      // 更新缓存
      if (enableCache && (refresh || _isFirstLoad)) {
        _cachedItems = List.from(_items);
        _cachedPage = _currentPage;
        _cachedPageSize = pageSize;
      }

      state = AsyncValue.data(List.from(_items));
      _isFirstLoad = false;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    await loadData(refresh: true);
  }

  Future<void> loadMore() async {
    if (_hasMoreData && !_isLoading) {
      await loadData();
    }
  }

  Future<void> setPageSize(int size) async {
    if (size >= 1 && size <= 40) {
      _pageSize = size;
      _currentPage = 0;
      _items.clear();
      _hasMoreData = true;
      _hasCache = false;
      _cachedItems = null; // 清除缓存
      await loadData();
    }
  }

  void clear() {
    _items.clear();
    _currentPage = 0;
    _hasMoreData = true;
    _hasCache = false;
    _cachedItems = null;
    _cachedPage = null;
    _cachedPageSize = null;
    state = const AsyncValue.data([]);
  }

  void clearCache() {
    _cachedItems = null;
    _cachedPage = null;
    _cachedPageSize = null;
    _hasCache = false;
  }
}