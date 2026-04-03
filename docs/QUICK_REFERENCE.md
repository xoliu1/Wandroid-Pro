# Flutter WanAndroid 快速参考卡片

> 开发新功能的速查手册

## 🎯 新功能开发 5 步法

### 1️⃣ API 定义 (`lib/remote/Api.dart`)

```dart
// URL 常量
const URL_MY_API = '/my/api';

// 请求类
class MyApiReq {
  final int page;
  MyApiReq({required this.page});
  String get path => '$URL_MY_API/$page/json';
}

// 响应类
class MyApiResp {
  final List<MyModel> datas;
  factory MyApiResp.fromJson(Map<String, dynamic> json) => ...;
}
```

### 2️⃣ Cgi 业务层 (`lib/remote/Cgi*.dart`)

```dart
class CgiMyFeature {
  Future<List<MyModel>> fetchData(int page, {int? pageSize}) {
    return NetworkService.get<MyApiResp>(
      url: MyApiReq(page: page).path,
      fromJsonT: MyApiResp.fromJson,
    ).getData().then((value) => value.datas);
  }
}
```

### 3️⃣ Provider 状态管理 (`lib/providers/`)

**分页列表：**
```dart
final myListProvider = StateNotifierProvider<
    MyListNotifier, AsyncValue<List<MyModel>>
>((ref) => MyListNotifier(CgiMyFeature()));

class MyListNotifier extends PaginationNotifier<MyModel> {
  MyListNotifier(this._cgi) : super(
    fetchFunction: (page, pageSize) async {
      return await _cgi.fetchData(page, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: true,
  );
  final CgiMyFeature _cgi;
}
```

**非分页数据：**
```dart
final myDataProvider = FutureProvider<MyData>((ref) async {
  return await fetchFromApi();
});
```

### 4️⃣ UI 页面 (`lib/pages/`)

```dart
class MyPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(myListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(myListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(myListProvider);
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: dataAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (items) => ListView.builder(...),
      ),
    );
  }
}
```

### 5️⃣ 通用组件 (`lib/pages/widget/`)

```dart
class MyItemCard extends StatelessWidget {
  final MyModel item;
  const MyItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(child: ...);
  }
}
```

---

## 📦 NetworkService 快速用法

### 基础请求

```dart
// GET
final data = await NetworkService.get<MyResp>(
  url: '/my/api',
  fromJsonT: MyResp.fromJson,
).getData();

// POST
final data = await NetworkService.post<MyResp>(
  url: '/my/api',
  data: {'key': 'value'},
  fromJsonT: MyResp.fromJson,
).getData();
```

### 链式调用

```dart
NetworkService.get(url: '/api')
  .retry(3)
  .cache(CachePolicy.cacheFirst)
  .onSuccess((data) => print('成功: $data'))
  .onFail((code, msg) => print('失败: $msg'));
```

### 数据提取

```dart
// 提取复杂数据
final items = await NetworkService.get(url: '/api')
  .handleData<List<Item>>(
    (data) => (data as List).map((e) => Item.fromJson(e)).toList(),
  );

// 直接处理 List
final items = await NetworkService.get(url: '/api')
  .handleListData<Item>(Item.fromJson);
```

---

## 🗄️ 本地存储 (KV)

### 定义新存储项 (`lib/local/KV.dart`)

```dart
const KEY_MY_SETTING = 'my_setting';

void saveMySetting(String value) {
  Kv.encodeString(KEY_MY_SETTING, value);
}

String? getMySetting() {
  return Kv.decodeString(KEY_MY_SETTING);
}
```

### 现有快捷方法

```dart
isLogin()              // 判断是否登录
getUserProfile()       // 获取用户信息
getPageSize()          // 获取分页大小
```

---

## 🌐 常用 API 端点

| 功能 | 方法 | 路径 |
|------|------|------|
| 登录 | POST | `/user/login` |
| 文章列表 | GET | `/article/list/{page}/json` |
| Banner | GET | `/banner/json` |
| 搜索 | POST | `/article/query/{page}/json` |
| 收藏列表 | GET | `/lg/collect/list/{page}/json` |
| 未读消息 | GET | `/message/lg/unread_list/{page}/json` |

**Base URL**: `https://www.wanandroid.com`

---

## 🎨 UI 状态处理模板

```dart
dataAsync.when(
  loading: () => const Center(child: CupertinoActivityIndicator()),
  error: (error, stack) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
        Text('错误: ${error.toString()}'),
        CupertinoButton(
          onPressed: _onRefresh,
          child: const Text('重试'),
        ),
      ],
    ),
  ),
  data: (items) {
    if (items.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }
    return ListView.builder(...);
  },
);
```

---

## 📋 分页加载底部指示器

```dart
ListView.builder(
  itemCount: items.length + 1,
  itemBuilder: (context, index) {
    if (index == items.length) {
      // 底部指示器
      if (notifier.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!notifier.hasMoreData) {
        return const Center(child: Text('没有更多了'));
      }
      return const SizedBox.shrink();
    }
    return MyItemCard(item: items[index]);
  },
);
```

---

## ✅ 代码检查清单

- [ ] API 常量、Req、Resp 都已定义
- [ ] Cgi 方法返回类型正确（`Future<T>` 或 `Future<List<T>>`）
- [ ] 分页列表使用 `PaginationNotifier<T>`
- [ ] UI 使用 `ConsumerStatefulWidget` + `ref.watch`
- [ ] 分页场景监听滚动（`_onScroll`）
- [ ] 实现下拉刷新（`RefreshIndicator`）
- [ ] 处理 loading/error/empty 状态
- [ ] 底部加载指示器逻辑正确

---

## 🚀 PaginationNotifier 核心方法

```dart
final notifier = ref.read(myListProvider.notifier);

notifier.refresh();         // 刷新（清空重新加载）
notifier.loadMore();        // 加载更多
notifier.setPageSize(20);   // 修改分页大小
notifier.clear();           // 清空所有数据

// 状态查询
notifier.currentPage;       // 当前页
notifier.hasMoreData;       // 是否还有更多
notifier.isLoading;         // 是否正在加载
notifier.items;             // 所有数据列表
```

---

## 🎯 项目目录速查

```
lib/
├── base/BaseResp.dart              # 统一响应封装
├── remote/
│   ├── Api.dart                    # API 常量 + Req/Resp
│   ├── service/NerworkService.dart # Dio 封装
│   ├── CgiArticle.dart             # 文章业务逻辑
│   ├── CgiCollect.dart             # 收藏业务逻辑
│   └── Cgi*.dart                   # 其他业务逻辑
├── providers/
│   ├── pagination_provider.dart    # 分页基类 ⭐
│   ├── article_provider.dart       # 文章状态管理
│   └── *.dart                      # 其他状态管理
├── model/                          # 数据模型
├── pages/                          # UI 页面
│   └── widget/                     # 通用组件
├── local/KV.dart                   # 本地存储
└── utils/                          # 工具类
```

---

**快速参考版本**: v1.0  
**更新日期**: 2026-01-13
