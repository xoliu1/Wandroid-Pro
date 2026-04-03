# Flutter WanAndroid 项目开发指南

> 基于 Riverpod 状态管理和分层架构的 Flutter 项目开发规范

## 📋 目录

- [项目架构概览](#项目架构概览)
- [技术栈](#技术栈)
- [目录结构](#目录结构)
- [核心设计模式](#核心设计模式)
- [开发新功能完整流程](#开发新功能完整流程)
- [网络请求规范](#网络请求规范)
- [状态管理规范](#状态管理规范)
- [分页加载实现](#分页加载实现)
- [UI 层开发规范](#ui-层开发规范)
- [本地存储规范](#本地存储规范)
- [常见问题与最佳实践](#常见问题与最佳实践)

---

## 🏗️ 项目架构概览

本项目采用**清晰的分层架构**，遵循单一职责原则：

```
┌─────────────────────────────────────────┐
│           UI Layer (pages/)             │  ← 页面展示与用户交互
├─────────────────────────────────────────┤
│    State Management (providers/)        │  ← Riverpod 状态管理
├─────────────────────────────────────────┤
│     Business Logic (remote/Cgi*.dart)   │  ← 业务逻辑封装
├─────────────────────────────────────────┤
│   Network Layer (remote/service/)       │  ← 网络请求封装
├─────────────────────────────────────────┤
│    Data Layer (model/ + local/)         │  ← 数据模型与本地存储
└─────────────────────────────────────────┘
```

### 核心设计理念

1. **分离关注点**：UI、状态、业务逻辑、网络、数据各司其职
2. **可测试性**：每一层都可独立测试
3. **可维护性**：职责明确，易于定位和修改
4. **可扩展性**：新增功能遵循相同模式

---

## 🛠️ 技术栈

| 技术 | 用途 | 版本要求 |
|------|------|----------|
| **flutter_riverpod** | 状态管理 | ^2.0.0 |
| **dio** | HTTP 网络请求 | ^5.0.0 |
| **cookie_jar** | Cookie 持久化 | ^4.0.0 |
| **dio_cookie_manager** | Dio Cookie 管理 | ^3.0.0 |
| **dio_cache_interceptor** | 请求缓存 | ^3.0.0 |
| **mmkv** | 高性能键值存储 | ^1.0.0 |
| **shared_preferences** | 轻量级存储 | ^2.0.0 |
| **sqflite** | SQLite 本地数据库 | ^2.0.0 |
| **json_serializable** | JSON 序列化 | ^6.0.0 |

---

## 📁 目录结构

```
lib/
├── base/                          # 基础类
│   └── BaseResp.dart             # 统一响应封装
│
├── remote/                        # 网络层
│   ├── Api.dart                  # API 常量 + 请求/响应模型定义
│   ├── service/                  # 网络服务
│   │   ├── NerworkService.dart   # Dio 封装 + NetworkCall 链式调用
│   │   ├── DioCacheInterceptor.dart  # 缓存拦截器
│   │   └── NetworkInterfaces.dart    # 网络接口定义
│   ├── CgiArticle.dart           # 文章相关业务逻辑
│   ├── CgiCollect.dart           # 收藏相关业务逻辑
│   ├── CgiTodo.dart              # Todo 相关业务逻辑
│   ├── CgiUser.dart              # 用户相关业务逻辑
│   └── CgiMessage.dart           # 消息相关业务逻辑
│
├── providers/                     # 状态管理层
│   ├── pagination_provider.dart  # 通用分页基类 🔥
│   ├── article_provider.dart     # 文章状态管理
│   ├── chapter_provider.dart     # 章节/体系状态管理
│   ├── collect_provider.dart     # 收藏状态管理
│   ├── profile_provider.dart     # 用户信息状态管理
│   ├── project_provider.dart     # 项目列表状态管理
│   ├── wx_article_provider.dart  # 公众号状态管理
│   └── ...
│
├── model/                         # 数据模型
│   ├── article.dart              # 文章模型
│   ├── project.dart              # 项目模型
│   ├── Todo.dart                 # Todo 模型
│   ├── message.dart              # 消息模型
│   ├── note.dart                 # 笔记模型
│   └── ...
│
├── pages/                         # UI 层
│   ├── article/                  # 文章相关页面
│   ├── chapter/                  # 章节相关页面
│   ├── collect/                  # 收藏页面
│   ├── login/                    # 登录页面
│   ├── widget/                   # 通用组件
│   │   ├── article_card.dart     # 文章卡片
│   │   ├── article_banner.dart   # Banner 组件
│   │   └── ...
│   └── ...
│
├── local/                         # 本地存储
│   ├── KV.dart                   # MMKV 封装 + 存储常量
│   └── SearchHistoryManager.dart # 搜索历史管理
│
├── utils/                         # 工具类
│   ├── functions.dart            # 通用函数（HTML 解码、日期判断等）
│   ├── DateUtils.dart            # 日期格式化
│   └── theme.dart                # 主题管理
│
└── main.dart                      # 应用入口
```

---

## 🎯 核心设计模式

### 1. BaseResp 统一响应封装

所有网络请求响应统一使用 `BaseResp<T>` 包装：

```dart
class BaseResp<T> {
  final T? data;              // 业务数据
  final int errorCode;        // 错误码（0 表示成功）
  final String errorMsg;      // 错误信息
  Response<dynamic>? rawResponse;  // 原始响应

  bool get isSuccess => errorCode == 0;
  bool get needLogin => errorCode == -1001;
}
```

### 2. NetworkCall 链式调用

网络请求支持链式调用，提供强大的扩展能力：

```dart
NetworkService.get<ArticleListResp>(
  url: URL_ARTICLE_LIST,
  fromJsonT: ArticleListResp.fromJson,
)
  .retry(3, delay: Duration(seconds: 2))  // 重试机制
  .cache(CachePolicy.cacheFirst)          // 缓存策略
  .onSuccess((data) { /* 成功回调 */ })
  .onFail((code, msg) { /* 失败回调 */ })
  .onComplete(() { /* 完成回调 */ });
```

### 3. PaginationNotifier 通用分页基类

所有分页列表都继承自 `PaginationNotifier<T>`，自动处理：
- ✅ 分页加载
- ✅ 下拉刷新
- ✅ 上拉加载更多
- ✅ 缓存机制
- ✅ 动态 pageSize

```dart
class ArticleNotifier extends PaginationNotifier<Article> {
  ArticleNotifier(this._articleService) : super(
    fetchFunction: (page, pageSize) async {
      return await _articleService.fetchArticles(page, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: true,  // 启用缓存
  );

  final CgiArticle _articleService;
}
```

---

## 🚀 开发新功能完整流程

### 场景：新增"收藏的项目列表"功能

#### 步骤 1：定义 API 常量和模型（在 `Api.dart`）

```dart
// 1. 添加 URL 常量
const URL_COLLECT_PROJECT_LIST = '/lg/collect/projectlist';

// 2. 定义请求类
class CollectProjectListReq {
  final int page;
  final int? pageSize;
  
  CollectProjectListReq({required this.page, this.pageSize});
  
  String get path => '$URL_COLLECT_PROJECT_LIST/$page/json';
}

// 3. 定义响应类
class CollectProjectListResp {
  final List<ProjectArticle> datas;
  final int curPage;
  final int pageCount;
  
  CollectProjectListResp({
    required this.datas,
    required this.curPage,
    required this.pageCount,
  });
  
  factory CollectProjectListResp.fromJson(Map<String, dynamic> json) {
    return CollectProjectListResp(
      datas: (json['datas'] as List)
          .map((item) => ProjectArticle.fromJson(item))
          .toList(),
      curPage: json['curPage'] ?? 0,
      pageCount: json['pageCount'] ?? 0,
    );
  }
}
```

#### 步骤 2：创建 Cgi 业务逻辑层（新建 `CgiCollectProject.dart`）

```dart
import '../model/project.dart';
import 'Api.dart';
import 'service/NerworkService.dart';

class CgiCollectProject {
  /// 获取收藏的项目列表
  Future<List<ProjectArticle>> fetchCollectProjects(int page, {int? pageSize}) {
    final req = CollectProjectListReq(page: page, pageSize: pageSize);
    return NetworkService.get<CollectProjectListResp>(
      url: req.path,
      fromJsonT: CollectProjectListResp.fromJson,
    ).getData().then((value) => value.datas);
  }
}
```

#### 步骤 3：创建 Provider 状态管理（在 `collect_provider.dart` 或新建文件）

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/project.dart';
import '../providers/pagination_provider.dart';
import '../remote/CgiCollectProject.dart';

/// 收藏项目列表 Provider
final collectProjectProvider = StateNotifierProvider<
    CollectProjectNotifier, 
    AsyncValue<List<ProjectArticle>>
>((ref) {
  return CollectProjectNotifier(CgiCollectProject());
});

class CollectProjectNotifier extends PaginationNotifier<ProjectArticle> {
  CollectProjectNotifier(this._cgiService) : super(
    fetchFunction: (page, pageSize) async {
      return await _cgiService.fetchCollectProjects(page, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: true,
  );

  final CgiCollectProject _cgiService;
}
```

#### 步骤 4：创建 UI 页面（新建 `collect_project_page.dart`）

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/collect_provider.dart';
import '../pages/widget/project_card.dart';

class CollectProjectPage extends ConsumerStatefulWidget {
  const CollectProjectPage({super.key});

  @override
  ConsumerState<CollectProjectPage> createState() => _CollectProjectPageState();
}

class _CollectProjectPageState extends ConsumerState<CollectProjectPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动监听，触发加载更多
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      ref.read(collectProjectProvider.notifier).loadMore();
    }
  }

  // 下拉刷新
  Future<void> _onRefresh() async {
    await ref.read(collectProjectProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(collectProjectProvider.notifier);
    final projectsAsync = ref.watch(collectProjectProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('收藏的项目'),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: projectsAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
                  const SizedBox(height: 16),
                  Text('加载失败: ${error.toString()}'),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: _onRefresh,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return const Center(child: Text('暂无收藏项目'));
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: projects.length + 1,
                itemBuilder: (context, index) {
                  // 最后一项：加载更多或"没有更多"提示
                  if (index == projects.length) {
                    if (notifier.isLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    if (!notifier.hasMoreData) {
                      return const Center(child: Text('没有更多了'));
                    }
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ProjectCard(project: projects[index]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
```

#### 步骤 5：路由集成

在导航或路由中添加跳转逻辑：

```dart
Navigator.push(
  context,
  CupertinoPageRoute(builder: (context) => const CollectProjectPage()),
);
```

---

## 🌐 网络请求规范

### 网络层文件位置

| 文件 | 路径 | 职责 |
|------|------|------|
| **API 常量与模型** | `lib/remote/Api.dart` | 所有 URL 常量、请求/响应数据类 |
| **网络服务** | `lib/remote/service/NerworkService.dart` | Dio 封装、NetworkCall 链式调用 |
| **业务逻辑** | `lib/remote/Cgi*.dart` | 封装具体业务请求（如 CgiArticle） |

### NetworkService 使用方式

#### 1. 简单 GET 请求

```dart
NetworkService.get<ArticleListResp>(
  url: '/article/list/0/json',
  fromJsonT: ArticleListResp.fromJson,
).getData();  // 直接返回 ArticleListResp
```

#### 2. POST 请求（自动转 FormData）

```dart
NetworkService.post<LoginResp>(
  url: URL_LOGIN,
  data: {
    'username': 'test',
    'password': '123456',
  },
  fromJsonT: LoginResp.fromJson,
).getData();
```

#### 3. 链式调用处理成功/失败

```dart
NetworkService.get(url: URL_BANNER)
  .onSuccess((data) {
    print('请求成功: $data');
  })
  .onFail((errorCode, errorMsg) {
    print('请求失败: [$errorCode] $errorMsg');
  })
  .onComplete(() {
    print('请求完成');
  });
```

#### 4. 自定义数据提取（handleData）

```dart
// 从复杂响应中提取 List
final banners = await NetworkService.get(url: URL_BANNER)
  .handleData<List<BannerItem>>(
    (data) {
      return (data as List<dynamic>)
          .map((json) => BannerItem.fromJson(json))
          .toList();
    },
    errorHandler: (errorCode, errorMsg) {
      throw Exception('Failed: $errorMsg');
    },
  );
```

#### 5. 直接处理 List 响应（handleListData）

```dart
final sections = await NetworkService.get(url: URL_TEACH_LIST)
  .handleListData<BookSection>(BookSection.fromJson);
```

### 错误处理

```dart
try {
  final data = await NetworkService.get(url: '/some/api').getData();
  // 处理成功数据
} catch (e) {
  // 处理异常：网络错误、业务错误
  print('Error: $e');
}
```

---

## 🔄 状态管理规范

### Riverpod Provider 类型选择

| Provider 类型 | 使用场景 | 示例 |
|--------------|---------|------|
| **StateNotifierProvider** | 需要修改状态的复杂逻辑 | 文章列表、分页加载 |
| **FutureProvider** | 一次性异步数据获取 | 教程目录列表 |
| **StateProvider** | 简单状态管理 | 主题模式、页面索引 |
| **Provider** | 只读数据/依赖注入 | 配置、常量 |

### PaginationNotifier 使用详解

#### 基础使用

```dart
final myListProvider = StateNotifierProvider<
    MyListNotifier, 
    AsyncValue<List<MyModel>>
>((ref) {
  return MyListNotifier();
});

class MyListNotifier extends PaginationNotifier<MyModel> {
  MyListNotifier() : super(
    fetchFunction: (page, pageSize) async {
      // 返回 Future<List<MyModel>>
      return await fetchDataFromApi(page, pageSize);
    },
    defaultPageSize: 10,    // 默认每页 10 条
    enableCache: true,      // 启用缓存
  );
}
```

#### 在 UI 中使用

```dart
class MyListPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyListPage> createState() => _MyListPageState();
}

class _MyListPageState extends ConsumerState<MyListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // 触发加载更多
      ref.read(myListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    // 下拉刷新
    await ref.read(myListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(myListProvider.notifier);
    final itemsAsync = ref.watch(myListProvider);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: itemsAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (items) {
          return ListView.builder(
            controller: _scrollController,
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
                // 底部加载指示器
                if (notifier.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!notifier.hasMoreData) {
                  return Center(child: Text('没有更多了'));
                }
                return SizedBox.shrink();
              }
              return ListTile(title: Text(items[index].toString()));
            },
          );
        },
      ),
    );
  }
}
```

#### 高级特性

```dart
// 动态修改 pageSize
ref.read(myListProvider.notifier).setPageSize(20);

// 清空列表
ref.read(myListProvider.notifier).clear();

// 清除缓存
ref.read(myListProvider.notifier).clearCache();

// 获取状态信息
final notifier = ref.read(myListProvider.notifier);
print('当前页: ${notifier.currentPage}');
print('是否还有更多: ${notifier.hasMoreData}');
print('是否正在加载: ${notifier.isLoading}');
```

### 带参数的 Provider（family）

```dart
// 定义：搜索文章（关键词作为参数）
final searchArticleProvider = StateNotifierProvider.family<
    SearchArticleNotifier, 
    AsyncValue<List<Article>>, 
    String  // 参数类型：关键词
>((ref, keyword) {
  return SearchArticleNotifier(CgiArticle(), keyword);
});

// 使用
final articlesAsync = ref.watch(searchArticleProvider('Flutter'));
```

---

## 📄 分页加载实现

### 核心流程

```
用户打开页面
    ↓
PaginationNotifier 初始化
    ↓
检查缓存 → 有缓存？→ 是 → 显示缓存数据（不请求网络）
    ↓ 否
发起网络请求（page=0）
    ↓
返回数据 → 追加到 _items
    ↓
更新 state = AsyncValue.data(_items)
    ↓
UI 渲染
    ↓
用户滚动到底部
    ↓
触发 loadMore() → 请求下一页（page++）
    ↓
返回数据为空？→ 是 → hasMoreData = false
    ↓ 否
追加数据 → 更新 state
    ↓
用户下拉刷新
    ↓
触发 refresh() → 清空 _items → 重新请求 page=0
```

### 关键方法

| 方法 | 说明 | 触发时机 |
|------|------|----------|
| `loadData(refresh: false)` | 加载下一页数据 | 滚动到底部 |
| `refresh()` | 清空并重新加载 | 下拉刷新 |
| `loadMore()` | 加载更多（内部调用 loadData） | 滚动到底部 |
| `setPageSize(int size)` | 动态修改分页大小 | 用户设置 |
| `clear()` | 清空所有数据和缓存 | 退出登录等场景 |

---

## 🎨 UI 层开发规范

### 页面结构模板

```dart
class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 初始化逻辑
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('页面标题'),
      ),
      child: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    final dataAsync = ref.watch(myProvider);
    
    return dataAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, stack) => _buildErrorView(error),
      data: (data) => _buildDataView(data),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
          const SizedBox(height: 16),
          Text('加载失败: ${error.toString()}'),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: () => ref.read(myProvider.notifier).refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataView(MyData data) {
    // 实现数据展示逻辑
    return ListView(...);
  }
}
```

### 通用组件位置

所有可复用组件放在 `lib/pages/widget/` 目录：

```
pages/widget/
├── article_card.dart           # 文章卡片
├── article_banner.dart         # Banner 轮播
├── collect_article_card.dart   # 收藏文章卡片
├── project_card.dart           # 项目卡片
├── question_card.dart          # 问答卡片
├── message_item.dart           # 消息条目
└── ...
```

### 组件开发规范

```dart
class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;
  
  const ArticleCard({
    super.key,
    required this.article,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // 组件实现
      ),
    );
  }
}
```

---

## 💾 本地存储规范

### 存储方案选择

| 技术 | 适用场景 | 性能 | 示例 |
|------|---------|------|------|
| **MMKV** | 高频读写的键值对 | 🚀🚀🚀 | 用户登录状态、主题设置 |
| **SharedPreferences** | 轻量级配置 | 🚀🚀 | 首次启动标记 |
| **Sqflite** | 复杂数据结构 | 🚀 | 笔记本地存储 |

### KV 存储（MMKV）

**文件位置：** `lib/local/KV.dart`

#### 定义常量

```dart
// 1. 定义存储 Key
const KEY_MY_SETTING = 'my_setting';

// 2. 提供工具方法
void saveMySettingsetting(String value) {
  Kv.encodeString(KEY_MY_SETTING, value);
}

String? getMySettingsetting() {
  return Kv.decodeString(KEY_MY_SETTING);
}
```

#### 支持的数据类型

```dart
// String
Kv.encodeString('key', 'value');
String? value = Kv.decodeString('key');

// Bool
Kv.encodeBool('key', true);
bool value = Kv.decodeBool('key', defaultValue: false);

// Int
Kv.encodeInt('key', 100);
int value = Kv.decodeInt('key', defaultValue: 0);

// Double
Kv.encodeDouble('key', 3.14);
double value = Kv.decodeDouble('key', defaultValue: 0.0);

// 删除
Kv.removeValue('key');
```

#### 现有常量

```dart
KEY_USER_LOGINED      // 用户登录状态（bool）
KEY_USER_INFO         // 用户信息（JSON string）
keyThemeMode          // 主题模式（string: 'light'/'dark'/'system'）
KEY_PAGE_LOAD_SIZE    // 分页大小（int: 10/20/30）
```

#### 快捷方法

```dart
// 判断是否登录
if (isLogin()) {
  // 已登录逻辑
}

// 获取用户信息
UserInfoResp user = getUserProfile();

// 获取分页大小
int pageSize = getPageSize();
```

---

## 📖 API 文档速查

### API Base URL

```dart
const BASE_URL = 'https://www.wanandroid.com';
```

### 常用 API 端点

#### 用户相关

| API | 路径 | 方法 | 说明 |
|-----|------|------|------|
| 登录 | `/user/login` | POST | username, password |
| 注册 | `/user/register` | POST | username, password, repassword |
| 退出登录 | `/user/logout/json` | GET | - |
| 获取用户信息 | `/user/lg/userinfo/json` | GET | 需登录 |

#### 文章相关

| API | 路径 | 方法 | 说明 |
|-----|------|------|------|
| 首页文章列表 | `/article/list/{page}/json` | GET | page: 页码（从0开始） |
| Banner | `/banner/json` | GET | - |
| 搜索文章 | `/article/query/{page}/json` | POST | k: 关键词 |
| 热搜词 | `/hotkey/json` | GET | - |
| 广场文章 | `/user_article/list/{page}/json` | GET | - |
| 问答列表 | `/wenda/list/{page}/json` | GET | - |

#### 收藏相关

| API | 路径 | 方法 | 说明 |
|-----|------|------|------|
| 收藏列表 | `/lg/collect/list/{page}/json` | GET | 需登录 |
| 收藏站内文章 | `/lg/collect/{id}/json` | POST | id: 文章ID |
| 取消收藏 | `/lg/uncollect_originId/{id}/json` | POST | id: 文章ID |
| 收藏站外文章 | `/lg/collect/add/json` | POST | title, author, link |

#### Todo 相关

| API | 路径 | 方法 | 说明 |
|-----|------|------|------|
| 查询Todo | `/lg/todo/v2/list/{page}/json` | GET | status: 待办状态 |
| 新增Todo | `/lg/todo/add/json` | POST | title, content, date, priority |
| 更新Todo | `/lg/todo/update/{id}/json` | POST | 同新增参数 |
| 删除Todo | `/lg/todo/delete/{id}/json` | POST | - |
| 完成Todo | `/lg/todo/done/{id}/json` | POST | status: 0/1 |

#### 消息相关

| API | 路径 | 方法 | 说明 |
|-----|------|------|------|
| 未读消息数量 | `/message/lg/count_unread/json` | GET | 需登录 |
| 未读消息列表 | `/message/lg/unread_list/{page}/json` | GET | 需登录 |
| 已读消息列表 | `/message/lg/readed_list/{page}/json` | GET | 需登录 |

#### 其他

| API | 路径 | 方法 | 说明 |
|-----|------|------|------|
| 知识体系 | `/tree/json` | GET | - |
| 导航数据 | `/navi/json` | GET | - |
| 公众号列表 | `/wxarticle/chapters/json` | GET | - |
| 公众号文章 | `/wxarticle/list/{id}/{page}/json` | GET | id: 公众号ID |
| 教程目录 | `/chapter/547/sublist/json` | GET | - |
| 项目列表 | `/article/listproject/{page}/json` | GET | cid: 分类ID |
| 积分信息 | `/lg/coin/userinfo/json` | GET | 需登录 |
| 积分历史 | `/lg/coin/list/{page}/json` | GET | 需登录 |

---

## ❓ 常见问题与最佳实践

### 1. 何时创建新的 Cgi 文件？

**原则：** 按业务模块划分

- ✅ 新增一个独立业务模块（如"积分商城"）→ 创建 `CgiCoinShop.dart`
- ❌ 只有 1-2 个接口且与现有模块高度相关 → 添加到现有 Cgi 文件

### 2. 何时使用 FutureProvider vs StateNotifierProvider？

| 场景 | 推荐 | 理由 |
|------|------|------|
| 一次性加载（如配置、静态列表） | FutureProvider | 简洁，自动处理 loading/error |
| 需要刷新/重新加载 | StateNotifierProvider | 可控制刷新逻辑 |
| 分页列表 | StateNotifierProvider + PaginationNotifier | 专为分页设计 |

### 3. 如何处理登录状态？

```dart
// 检查登录
if (!isLogin()) {
  // 跳转登录页
  Navigator.push(context, CupertinoPageRoute(
    builder: (_) => const LoginPage(),
  ));
  return;
}

// 网络请求自动带 Cookie（已配置 CookieManager）
```

### 4. 如何实现 Banner 轮播？

项目已有 `card_swiper` 本地库，使用示例：

```dart
import '../card_swiper/flutter_swiper_view.dart';

Swiper(
  itemBuilder: (BuildContext context, int index) {
    return Image.network(banners[index].imagePath, fit: BoxFit.cover);
  },
  itemCount: banners.length,
  pagination: const SwiperPagination(),
  autoplay: true,
)
```

### 5. 如何调试网络请求？

`NetworkService` 已内置日志打印：

```dart
print('Request: $method $url');
print('Response: Status ${response.statusCode} \n ${response.data}');
```

查看控制台输出即可调试。

### 6. 如何处理 HTML 实体编码？

使用 `utils/functions.dart` 中的扩展方法：

```dart
String title = article.title.decodeHtmlEntities();
```

### 7. 如何优雅地打开 WebView？

```dart
import 'package:url_launcher/url_launcher.dart';

void openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
  }
}
```

### 8. 分页加载性能优化

```dart
// 1. 合理设置 pageSize（默认 10）
// 2. 启用缓存（enableCache: true）
// 3. 使用 ListView.builder 而非 ListView（懒加载）
```

### 9. 如何实现主题切换？

参考 `utils/theme.dart`：

```dart
// 保存主题模式
Kv.encodeString(keyThemeMode, 'dark');

// 读取主题模式
String? themeMode = Kv.decodeString(keyThemeMode);
```

### 10. 错误处理最佳实践

```dart
try {
  final data = await NetworkService.get(...).getData();
  // 成功处理
} on DioException catch (e) {
  // 网络错误
  if (e.type == DioExceptionType.connectionTimeout) {
    showErrorToast('连接超时');
  }
} catch (e) {
  // 其他错误
  showErrorToast('请求失败: $e');
}
```

---

## 📝 快速检查清单

开发新功能时，按以下步骤检查：

- [ ] **步骤 1：** 在 `Api.dart` 中定义 URL 常量、请求类、响应类
- [ ] **步骤 2：** 在 `Cgi*.dart` 中封装业务逻辑方法
- [ ] **步骤 3：** 在 `providers/` 中创建 Provider（分页使用 PaginationNotifier）
- [ ] **步骤 4：** 在 `pages/` 中创建页面 UI
- [ ] **步骤 5：** 监听滚动实现加载更多（分页场景）
- [ ] **步骤 6：** 实现下拉刷新（RefreshIndicator）
- [ ] **步骤 7：** 处理 loading/error/empty 状态
- [ ] **步骤 8：** 提取可复用组件到 `pages/widget/`
- [ ] **步骤 9：** 本地存储相关配置添加到 `KV.dart`
- [ ] **步骤 10：** 测试各种边界情况（无数据、网络错误、登录态等）

---

## 🎉 总结

本项目采用**成熟的分层架构**和**统一的开发规范**，核心优势：

1. ✅ **清晰的职责分离**：UI、状态、业务、网络、数据各司其职
2. ✅ **强大的分页基类**：`PaginationNotifier` 开箱即用
3. ✅ **灵活的网络封装**：`NetworkCall` 链式调用，支持重试、缓存
4. ✅ **统一的错误处理**：`BaseResp` 封装响应
5. ✅ **高性能本地存储**：MMKV + Sqflite
6. ✅ **可维护的代码组织**：模块化、可复用

遵循本指南，你可以高效、规范地开发新功能，保持代码质量和项目的一致性。

---

**更新日期：** 2026-01-13  
**维护者：** Flutter WanAndroid Team
