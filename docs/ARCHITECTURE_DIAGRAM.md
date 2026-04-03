# Flutter WanAndroid 架构可视化

## 📐 整体架构图

```
┌────────────────────────────────────────────────────────────────────────┐
│                           用户界面层 (UI Layer)                          │
│                        lib/pages/ & lib/pages/widget/                   │
├────────────────────────────────────────────────────────────────────────┤
│  • 页面组件 (ConsumerStatefulWidget)                                    │
│  • 通用组件 (StatelessWidget)                                           │
│  • 用户交互处理                                                         │
│  • 状态监听与 UI 更新                                                   │
└────────────────────────────────────────────────────────────────────────┘
                                    ↕ ref.watch / ref.read
┌────────────────────────────────────────────────────────────────────────┐
│                      状态管理层 (State Management)                       │
│                           lib/providers/                                │
├────────────────────────────────────────────────────────────────────────┤
│  • StateNotifierProvider (复杂状态)                                     │
│  • FutureProvider (一次性异步数据)                                      │
│  • PaginationNotifier<T> (分页通用基类) ⭐                              │
│  • 状态变更通知 & 缓存管理                                              │
└────────────────────────────────────────────────────────────────────────┘
                                    ↕ 调用业务逻辑
┌────────────────────────────────────────────────────────────────────────┐
│                      业务逻辑层 (Business Logic)                         │
│                          lib/remote/Cgi*.dart                           │
├────────────────────────────────────────────────────────────────────────┤
│  • CgiArticle (文章相关)                                                │
│  • CgiCollect (收藏相关)                                                │
│  • CgiUser (用户相关)                                                   │
│  • CgiTodo (待办相关)                                                   │
│  • CgiMessage (消息相关)                                                │
│  • 封装业务请求 & 返回处理后的数据                                      │
└────────────────────────────────────────────────────────────────────────┘
                                    ↕ 发起网络请求
┌────────────────────────────────────────────────────────────────────────┐
│                        网络层 (Network Layer)                            │
│                     lib/remote/service/NerworkService.dart              │
├────────────────────────────────────────────────────────────────────────┤
│  • Dio 实例配置                                                         │
│  • NetworkCall<T> 链式调用封装                                          │
│  • Cookie 管理 (PersistCookieJar)                                       │
│  • 缓存拦截器 (DioCacheInterceptor)                                     │
│  • 错误处理 & 重试机制                                                  │
│  • BaseResp<T> 统一响应封装                                             │
└────────────────────────────────────────────────────────────────────────┘
                                    ↕ 读写数据
┌────────────────────────────────────────────────────────────────────────┐
│                        数据层 (Data Layer)                               │
│                      lib/model/ + lib/local/                            │
├────────────────────────────────────────────────────────────────────────┤
│  • Model 数据模型 (JSON 序列化)                                         │
│  • MMKV (高性能键值存储)                                                │
│  • SharedPreferences (轻量级存储)                                       │
│  • Sqflite (SQLite 本地数据库)                                          │
│  • API 常量定义 (lib/remote/Api.dart)                                   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 数据流向图

### 场景 1：加载文章列表

```
用户打开文章列表页面
    ↓
UI Layer (ArticleListPage)
    ↓ ref.watch(articleProvider)
State Management (ArticleNotifier extends PaginationNotifier<Article>)
    ↓ 初始化时调用 fetchFunction
    ↓ fetchFunction: (page, pageSize) => _articleService.fetchArticles(page, pageSize)
Business Logic (CgiArticle.fetchArticles)
    ↓ 构造请求: ArticleListReq(page: 0, pageSize: 10)
    ↓ NetworkService.get<ArticleListResp>()
Network Layer (NetworkService)
    ↓ Dio.request('/article/list/0/json')
    ↓ 发送 HTTP GET 请求
[远程服务器]
    ↓ 返回 JSON 响应
Network Layer
    ↓ 解析为 BaseResp<ArticleListResp>
    ↓ 检查 errorCode == 0 (成功)
    ↓ 返回 ArticleListResp.datas (List<Article>)
Business Logic
    ↓ 返回 Future<List<Article>>
State Management
    ↓ 更新 _items，设置 state = AsyncValue.data(items)
    ↓ 通知监听者（UI）
UI Layer
    ↓ ref.watch 监听到变化
    ↓ 重新构建 ListView.builder
    ↓ 显示文章列表
[用户看到文章]
```

### 场景 2：下拉刷新

```
用户下拉刷新
    ↓
UI Layer (_onRefresh 回调)
    ↓ ref.read(articleProvider.notifier).refresh()
State Management (ArticleNotifier.refresh)
    ↓ 调用 loadData(refresh: true)
    ↓ 清空 _items，_currentPage = 0
    ↓ state = AsyncValue.loading()
    ↓ 重新调用 fetchFunction(page: 0)
... (后续流程同场景 1)
```

### 场景 3：上拉加载更多

```
用户滚动到底部
    ↓
UI Layer (_onScroll 检测到到达底部)
    ↓ ref.read(articleProvider.notifier).loadMore()
State Management (ArticleNotifier.loadMore)
    ↓ 检查 _hasMoreData && !_isLoading
    ↓ 调用 loadData(refresh: false)
    ↓ 使用当前 _currentPage (例如 1)
    ↓ 调用 fetchFunction(page: 1)
... (后续流程同场景 1)
    ↓ 新数据追加到 _items
    ↓ _currentPage++ (变为 2)
    ↓ state = AsyncValue.data(全部 items)
UI Layer
    ↓ ListView 自动显示新追加的数据
[用户看到更多文章]
```

---

## 🏗️ 核心类关系图

```
┌─────────────────────────────────────────────────────────────────┐
│                        BaseResp<T>                              │
├─────────────────────────────────────────────────────────────────┤
│ + data: T?                                                      │
│ + errorCode: int                                                │
│ + errorMsg: String                                              │
│ + isSuccess: bool (getter)                                      │
│ + needLogin: bool (getter)                                      │
└─────────────────────────────────────────────────────────────────┘
                            ↑ 返回
┌─────────────────────────────────────────────────────────────────┐
│                     NetworkCall<T>                              │
├─────────────────────────────────────────────────────────────────┤
│ - _future: Future<BaseResp<T>>                                  │
│ - _cancelToken: CancelToken                                     │
│ + retry(maxRetries): NetworkCall<T>                             │
│ + cache(policy): NetworkCall<T>                                 │
│ + onSuccess(callback): NetworkCall<T>                           │
│ + onFail(callback): NetworkCall<T>                              │
│ + getData(): Future<T>                                          │
│ + handleData<R>(extractor): Future<R>                           │
│ + handleListData<R>(fromJson): Future<List<R>>                  │
└─────────────────────────────────────────────────────────────────┘
                            ↑ 创建
┌─────────────────────────────────────────────────────────────────┐
│                      NetworkService                             │
├─────────────────────────────────────────────────────────────────┤
│ - _dio: Dio (static)                                            │
│ + request<T>(...): NetworkCall<T>                               │
│ + get<T>(...): NetworkCall<T>                                   │
│ + post<T>(...): NetworkCall<T>                                  │
│ + download(...): NetworkCall<Response>                          │
└─────────────────────────────────────────────────────────────────┘
                            ↑ 使用
┌─────────────────────────────────────────────────────────────────┐
│                      CgiArticle                                 │
├─────────────────────────────────────────────────────────────────┤
│ + fetchArticles(page, pageSize): Future<List<Article>>         │
│ + fetchSquareArticles(page, pageSize): Future<List<Article>>   │
│ + searchArticles(page, keyword): Future<List<Article>>         │
│ + fetchBanners(): Future<List<BannerItem>>                      │
│ + fetchHotKey(): Future<List<HotKeyItem>>                       │
└─────────────────────────────────────────────────────────────────┘
                            ↑ 注入
┌─────────────────────────────────────────────────────────────────┐
│          PaginationNotifier<T> extends StateNotifier            │
├─────────────────────────────────────────────────────────────────┤
│ + fetchFunction: (page, pageSize) => Future<List<T>>           │
│ - _items: List<T>                                               │
│ - _currentPage: int                                             │
│ - _hasMoreData: bool                                            │
│ - _isLoading: bool                                              │
│ + loadData(refresh): Future<void>                               │
│ + refresh(): Future<void>                                       │
│ + loadMore(): Future<void>                                      │
│ + setPageSize(size): Future<void>                               │
│ + clear(): void                                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↑ 继承
┌─────────────────────────────────────────────────────────────────┐
│          ArticleNotifier extends PaginationNotifier<Article>    │
├─────────────────────────────────────────────────────────────────┤
│ - _articleService: CgiArticle                                   │
│ + ArticleNotifier(CgiArticle)                                   │
└─────────────────────────────────────────────────────────────────┘
                            ↑ 使用
┌─────────────────────────────────────────────────────────────────┐
│ articleProvider = StateNotifierProvider<ArticleNotifier, ...>  │
└─────────────────────────────────────────────────────────────────┘
                            ↑ 监听
┌─────────────────────────────────────────────────────────────────┐
│      ArticleListPage extends ConsumerStatefulWidget            │
├─────────────────────────────────────────────────────────────────┤
│ - _scrollController: ScrollController                           │
│ + _onScroll(): void                                             │
│ + _onRefresh(): Future<void>                                    │
│ + build(context): Widget                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔗 依赖注入流程

```
main.dart
    ↓ runApp(ProviderScope(child: MyApp()))
[Riverpod 初始化]
    ↓
lib/providers/article_provider.dart
    ↓ articleProvider = StateNotifierProvider((ref) {...})
    ↓ 创建 ArticleNotifier 实例
    ↓ 注入 CgiArticle() 依赖
ArticleNotifier 初始化
    ↓ super(fetchFunction: ...)
    ↓ PaginationNotifier 初始化
    ↓ 自动调用 _loadInitialWithCache()
[检查缓存]
    ├─ 有缓存 → 直接使用缓存数据 (state = AsyncValue.data(cachedItems))
    └─ 无缓存 → 调用 loadData(refresh: true)
        ↓ fetchFunction(page: 0, pageSize: 10)
        ↓ _articleService.fetchArticles(0, pageSize: 10)
        ↓ NetworkService.get<ArticleListResp>(...)
        ↓ 发起 HTTP 请求
        ↓ 返回数据后更新 state
[Provider 就绪]
    ↓
ArticleListPage.build()
    ↓ ref.watch(articleProvider)
    ↓ 获取 AsyncValue<List<Article>>
    ↓ 根据状态渲染 UI (loading / error / data)
[UI 渲染完成，用户可见]
```

---

## 📂 模块依赖关系

```
main.dart
    ↓ 导入
lib/pages/ (UI Layer)
    ↓ 依赖
lib/providers/ (State Management)
    ↓ 依赖
lib/remote/Cgi*.dart (Business Logic)
    ↓ 依赖
lib/remote/service/NerworkService.dart (Network)
    ↓ 依赖
lib/base/BaseResp.dart (Base Classes)
    ↓ 依赖
lib/model/ (Data Models)

lib/pages/
    ↓ 同时依赖
lib/pages/widget/ (Reusable Components)
    ↓ 依赖
lib/model/ (Data Models)

lib/providers/
    ↓ 使用
lib/providers/pagination_provider.dart (Base Class)

lib/remote/
    ↓ 使用
lib/remote/Api.dart (API Constants & Req/Resp)

lib/local/ (Local Storage)
    ← 被所有层使用（工具类）

lib/utils/ (Utilities)
    ← 被所有层使用（工具类）
```

---

## 🎯 关键设计模式

### 1. Repository Pattern（仓库模式）

```
UI Layer
    ↓
State Management
    ↓ 不直接调用网络层
Business Logic (Cgi*.dart) ← [Repository]
    ↓ 唯一与网络层交互的地方
Network Layer
```

**优点**：
- UI 层与网络层解耦
- 业务逻辑集中管理
- 易于测试和维护

### 2. Builder Pattern（构建器模式）

```dart
NetworkService.get(...)
  .retry(3)              // 链式调用
  .cache(CachePolicy.cacheFirst)
  .onSuccess(...)
  .onFail(...)
  .getData()
```

**优点**：
- 代码可读性强
- 功能组合灵活
- 可选配置清晰

### 3. Template Method Pattern（模板方法模式）

```dart
abstract class PaginationNotifier<T> {
  // 模板方法：固定流程
  Future<void> loadData({bool refresh = false}) {
    // 1. 检查状态
    // 2. 调用 fetchFunction (子类实现)
    // 3. 更新状态
    // 4. 更新缓存
  }
  
  // 抽象方法：子类必须提供
  final Future<List<T>> Function(int page, int? pageSize) fetchFunction;
}
```

**优点**：
- 分页逻辑复用
- 减少重复代码
- 统一行为规范

### 4. Observer Pattern（观察者模式）

```dart
// Subject: StateNotifier
class ArticleNotifier extends StateNotifier<AsyncValue<List<Article>>> {
  void loadData() {
    state = AsyncValue.data(newData);  // 通知所有观察者
  }
}

// Observer: UI Widget
class ArticleListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articleProvider);  // 订阅变化
    // 当 state 变化时，自动重建
  }
}
```

**优点**：
- 自动 UI 更新
- 状态与 UI 分离
- 多个 Widget 可监听同一状态

---

## 🔧 技术栈依赖图

```
Flutter SDK
    ↓
┌─────────────────────────────────────────┐
│          核心依赖                        │
├─────────────────────────────────────────┤
│ • flutter_riverpod (状态管理)           │
│ • dio (HTTP 客户端)                      │
│ • mmkv (键值存储)                        │
│ • sqflite (SQLite)                       │
└─────────────────────────────────────────┘
    ↓ 扩展
┌─────────────────────────────────────────┐
│          网络相关                        │
├─────────────────────────────────────────┤
│ • cookie_jar (Cookie 存储)              │
│ • dio_cookie_manager (Cookie 管理器)    │
│ • dio_cache_interceptor (缓存拦截)      │
└─────────────────────────────────────────┘
    ↓ 扩展
┌─────────────────────────────────────────┐
│          数据处理                        │
├─────────────────────────────────────────┤
│ • json_serializable (JSON 序列化)       │
│ • shared_preferences (轻量级存储)       │
│ • path_provider (路径提供)              │
└─────────────────────────────────────────┘
    ↓ 扩展
┌─────────────────────────────────────────┐
│          UI 组件                         │
├─────────────────────────────────────────┤
│ • card_swiper (轮播组件，本地库)         │
│ • url_launcher (URL 打开)               │
└─────────────────────────────────────────┘
```

---

## 📊 性能优化策略

### 缓存层级

```
┌───────────────────────────────────────────┐
│         L1: PaginationNotifier 内存缓存   │  ← 最快
│         (首次加载后自动缓存)              │
├───────────────────────────────────────────┤
│         L2: Dio 缓存拦截器                │  ← 快
│         (DioCacheInterceptor)             │
├───────────────────────────────────────────┤
│         L3: MMKV 持久化缓存               │  ← 中等
│         (用户信息、设置等)                │
├───────────────────────────────────────────┤
│         L4: Sqflite 本地数据库            │  ← 慢但可靠
│         (笔记、复杂数据)                  │
└───────────────────────────────────────────┘
```

### 请求优化

1. **重试机制**: `NetworkCall.retry(3)`
2. **请求取消**: `CancelToken` 支持
3. **Cookie 持久化**: 自动管理登录态
4. **FormData 自动转换**: POST 请求优化

---

这份架构文档可视化了项目的各个层次、数据流向和设计模式，帮助开发者快速理解整个系统的运作机制。
