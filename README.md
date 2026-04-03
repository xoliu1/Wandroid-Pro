<div align="center">
  <h1>Flutter WanAndroid</h1>
  <p>一个功能丰富、UI 精美的 WanAndroid 客户端</p>
  <p>
    <a href="#特性">特性</a> •
    <a href="#截图">截图</a> •
    <a href="#技术栈">技术栈</a> •
    <a href="#快速开始">快速开始</a> •
    <a href="#项目架构">项目架构</a> •
    <a href="#开发指南">开发指南</a>
  </p>
</div>

---

## 特性

### 📱 核心功能

- **首页浏览**: Banner 轮播、置顶文章、推荐文章流
- **知识体系**: 分类导航、知识树结构、体系化学习
- **项目分类**: 开源项目展示、项目详情查看
- **公众号文章**: 订阅公众号、查看历史文章
- **用户系统**: 登录/注册、个人信息、积分排行
- **收藏管理**: 收藏文章、收藏列表、取消收藏
- **文章搜索**: 关键词搜索、搜索历史
- **广场功能**: 用户分享、广场文章流

### 🤖 AI 智能功能

- **AI 对话助手**: 基于文章内容的智能问答
- **流式输出**: SSE 流式响应，打字机效果
- **预设问题**: 总结要点、深入解析、优缺点分析、实践建议
- **多厂商支持**: OpenAI、Claude、Gemini、智谱 AI、通义千问、DeepSeek 等
- **对话历史**: 本地存储，持久化管理
- **智能上下文**: 自动提取文章内容，保持对话连贯性

### 🎨 UI/UX 特性

- **iOS 风格**: 全 Cupertino 风格组件
- **深色模式**: 完整的深色模式适配
- **流畅动画**: 页面转场、下拉刷新、加载动画
- **WebView 集成**: 文章详情页、进度条、前进后退
- **响应式布局**: 适配不同屏幕尺寸
- **San Francisco 字体**: 原生 iOS 字体体验

---

## 截图

> TODO: 添加应用截图

---

## 技术栈

### 核心框架

- **Flutter**: 跨平台 UI 框架
- **flutter_riverpod**: 状态管理
- **Dio**: HTTP 网络请求
- **flutter_inappwebview**: WebView 集成

### 数据存储

- **MMKV**: 高性能键值存储（主）
- **SharedPreferences**: 轻量级存储
- **Sqflite**: 本地数据库（聊天记录）
- **cookie_jar**: Cookie 持久化

### UI 组件

- **carousel_slider**: Banner 轮播
- **pull_to_refresh**: 下拉刷新
- **cached_network_image**: 图片缓存
- **flutter_html**: HTML 渲染
- **flutter_markdown**: Markdown 渲染

### 工具库

- **dio_cache_interceptor**: 网络缓存
- **url_launcher**: 打开外部链接
- **html_unescape**: HTML 转义
- **path_provider**: 文件路径

---

## 快速开始

### 环境要求

- **Flutter**: >= 3.4.3
- **Dart**: >= 3.4.3
- **Android SDK**: >= 21
- **iOS**: >= 12.0

### 安装步骤

1. **克隆项目**

```bash
git clone https://github.com/yourusername/flutter_wanandroid.git
cd flutter_wanandroid
```

2. **安装依赖**

```bash
flutter pub get
```

3. **运行代码生成**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **运行应用**

```bash
# Android
flutter run

# iOS
flutter run

# 指定设备
flutter run -d <device_id>
```

---

## 项目架构

### 目录结构

```
lib/
├── ai/                      # AI 功能模块
│   ├── core/               # 核心组件（常量、日志、结果封装）
│   ├── models/             # 数据模型
│   ├── providers/          # 状态管理
│   ├── repositories/       # 数据仓库层
│   ├── services/           # 业务服务
│   └── ui/                 # UI 组件
├── local/                   # 本地存储
│   ├── KV.dart             # MMKV 封装
│   └── UserProfileDB.dart  # 用户信息数据库
├── model/                   # 数据模型
├── pages/                   # 页面
│   ├── article/            # 文章相关
│   ├── chapter/            # 章节分类
│   ├── coin/               # 积分
│   ├── collect/            # 收藏
│   ├── drawer/             # 侧边栏
│   ├── homepage/           # 首页
│   ├── knowledgeTree/      # 知识体系
│   ├── login/              # 登录
│   ├── settings/           # 设置
│   ├── webview/            # WebView
│   ├── widget/             # 通用组件
│   └── wxmp/               # 公众号
├── providers/               # 全局 Provider
├── remote/                  # 网络层
│   ├── service/            # 网络服务
│   ├── Api.dart            # API 定义
│   ├── CgiArticle.dart     # 文章业务层
│   ├── CgiCollect.dart     # 收藏业务层
│   └── ...                 # 其他业务层
└── main.dart               # 应用入口
```

### 五层架构

```
┌─────────────────────────────────────┐
│         UI Layer (pages/)           │  Cupertino 风格 UI
├─────────────────────────────────────┤
│    State Management (providers/)    │  Riverpod Provider
├─────────────────────────────────────┤
│    Business Logic (remote/Cgi*.dart)│  业务逻辑封装
├─────────────────────────────────────┤
│   Network Layer (NetworkService)    │  Dio + 链式调用
├─────────────────────────────────────┤
│      Data Layer (model/ + local/)   │  数据模型 + 存储
└─────────────────────────────────────┘
```

### 核心设计模式

#### 1. 网络请求流程

```dart
// API 定义
class ArticleListReq {
  final int page;
  String get path => '/article/list/$page/json';
}

class ArticleListResp {
  final List<Article> datas;
  ArticleListResp.fromJson(Map<String, dynamic> json);
}

// Cgi 业务层
class CgiArticle {
  Future<List<Article>> fetchArticleList(int page) {
    return NetworkService.get<ArticleListResp>(
      url: ArticleListReq(page: page).path,
      fromJsonT: ArticleListResp.fromJson,
    ).getData().then((value) => value.datas);
  }
}

// Provider 状态管理
final articleListProvider = StateNotifierProvider<ArticleListNotifier, AsyncValue<List<Article>>>((ref) {
  return ArticleListNotifier(CgiArticle());
});

class ArticleListNotifier extends PaginationNotifier<Article> {
  ArticleListNotifier(this._cgiService) : super(
    fetchFunction: (page, pageSize) => _cgiService.fetchArticleList(page),
    defaultPageSize: 20,
    enableCache: true,
  );
  final CgiArticle _cgiService;
}
```

#### 2. 分页加载

```dart
// 继承 PaginationNotifier 基类
class MyListNotifier extends PaginationNotifier<MyModel> {
  MyListNotifier(this._cgiService) : super(
    fetchFunction: (page, pageSize) async {
      return await _cgiService.fetchMyData(page, pageSize: pageSize);
    },
    defaultPageSize: 10,
    enableCache: true,
  );
  final CgiMyFeature _cgiService;
}

// UI 层使用
ref.read(myListProvider.notifier).loadMore();  // 加载更多
ref.read(myListProvider.notifier).refresh();   // 下拉刷新
```

#### 3. 状态管理

- **分页列表**: `PaginationNotifier<T>` 基类
- **一次性数据**: `FutureProvider`
- **可变状态**: `StateNotifierProvider`
- **全局状态**: `Provider`

---

## 开发指南

### 添加新功能

按照以下步骤添加新功能（以「我的收藏」为例）：

#### 1. 定义 API（`lib/remote/Api.dart`）

```dart
const URL_COLLECT_LIST = '/lg/collect/list';

class CollectListReq {
  final int page;
  CollectListReq({required this.page});
  String get path => '$URL_COLLECT_LIST/$page/json';
}

class CollectListResp {
  final List<Article> datas;
  CollectListResp.fromJson(Map<String, dynamic> json);
}
```

#### 2. 实现 Cgi 业务层（`lib/remote/CgiCollect.dart`）

```dart
class CgiCollect {
  Future<List<Article>> fetchCollectList(int page) {
    final req = CollectListReq(page: page);
    return NetworkService.get<CollectListResp>(
      url: req.path,
      fromJsonT: CollectListResp.fromJson,
    ).getData().then((value) => value.datas);
  }
}
```

#### 3. 创建 Provider（`lib/providers/collect_provider.dart`）

```dart
final collectListProvider = StateNotifierProvider<CollectListNotifier, AsyncValue<List<Article>>>((ref) {
  return CollectListNotifier(CgiCollect());
});

class CollectListNotifier extends PaginationNotifier<Article> {
  CollectListNotifier(this._cgiService) : super(
    fetchFunction: (page, pageSize) => _cgiService.fetchCollectList(page),
    defaultPageSize: 20,
    enableCache: false,
  );
  final CgiCollect _cgiService;
}
```

#### 4. 实现 UI（`lib/pages/collect/collect_list_page.dart`）

```dart
class CollectListPage extends ConsumerStatefulWidget {
  const CollectListPage({super.key});

  @override
  ConsumerState<CollectListPage> createState() => _CollectListPageState();
}

class _CollectListPageState extends ConsumerState<CollectListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      ref.read(collectListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(collectListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(collectListProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('我的收藏')),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: dataAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (error, stack) => _buildErrorView(error),
            data: (items) => _buildListView(items),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Article> items) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return _buildLoadMoreIndicator();
        }
        return ArticleCard(article: items[index]);
      },
    );
  }
}
```

### 本地存储

在 `lib/local/KV.dart` 中添加新的存储项：

```dart
const KEY_MY_SETTING = 'my_setting';

void saveMySetting(String value) {
  Kv.encodeString(KEY_MY_SETTING, value);
}

String? getMySetting() {
  return Kv.decodeString(KEY_MY_SETTING);
}
```

### 代码规范

- **命名规范**: 遵循 Dart 命名规范（驼峰命名）
- **文件命名**: 小写+下划线（如 `article_list_page.dart`）
- **常量命名**: 全大写+下划线（如 `URL_ARTICLE_LIST`）
- **类命名**: 大驼峰（如 `ArticleListPage`）
- **方法命名**: 小驼峰（如 `fetchArticleList`）
- **优先使用 const**: 提高性能
- **空安全**: 正确使用 `?` 和 `!`

### 性能优化

- **分页加载**: 避免一次性加载过多数据
- **图片缓存**: 使用 `cached_network_image`
- **列表优化**: 使用 `ListView.builder`
- **状态缓存**: 合理使用 `enableCache`
- **dispose 资源**: 及时释放 Controller 和 Listener

---

## API 文档

### Base URL

```
https://www.wanandroid.com
```

### 常用接口

| 功能 | 方法 | 端点 | 参数 |
|------|------|------|------|
| 首页文章列表 | GET | `/article/list/{page}/json` | page: 页码（从0开始） |
| Banner | GET | `/banner/json` | - |
| 登录 | POST | `/user/login` | username, password |
| 注册 | POST | `/user/register` | username, password, repassword |
| 收藏列表 | GET | `/lg/collect/list/{page}/json` | page: 页码（从0开始） |
| 收藏文章 | POST | `/lg/collect/{id}/json` | id: 文章ID |
| 取消收藏 | POST | `/lg/uncollect_originId/{id}/json` | id: 文章ID |
| 搜索 | POST | `/article/query/{page}/json` | k: 关键词 |
| 知识体系 | GET | `/tree/json` | - |
| 项目分类 | GET | `/project/tree/json` | - |

详细 API 文档请参考：[WanAndroid API](https://www.wanandroid.com/blog/show/2)

---

## AI 功能配置

### 支持的 AI 服务商

- **OpenAI**: GPT-3.5/4/4o
- **Anthropic**: Claude 3 系列
- **Google**: Gemini 1.5/2.0
- **智谱 AI**: GLM-4 系列
- **阿里云**: 通义千问
- **DeepSeek**: DeepSeek Chat
- **Moonshot**: Kimi Chat
- **硅基流动**: 多模型支持

### 配置步骤

1. 打开侧边栏 → 点击「AI 配置」
2. 选择预设服务商或自定义
3. 填写 API Key
4. 测试连接是否成功
5. 保存配置

### 使用场景

- 阅读技术文章时，快速总结要点
- 深入解析文章内容
- 分析技术优缺点
- 获取实践建议
- 探索相关技术

---

## 贡献指南

欢迎贡献代码！请遵循以下流程：

1. Fork 本项目
2. 创建特性分支（`git checkout -b feature/AmazingFeature`）
3. 提交更改（`git commit -m 'Add some AmazingFeature'`）
4. 推送到分支（`git push origin feature/AmazingFeature`）
5. 提交 Pull Request

### 提交规范

使用语义化提交信息：

- `feat`: 新功能
- `fix`: 修复 Bug
- `docs`: 文档更新
- `style`: 代码格式调整
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建/工具链相关

示例：
```
feat: 添加文章搜索功能
fix: 修复收藏列表分页问题
docs: 更新 README 安装步骤
```

---

## 常见问题

### 1. 编译失败

```bash
# 清理缓存
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. iOS 编译失败

```bash
cd ios
pod install
cd ..
flutter run
```

### 3. MMKV 初始化失败

确保在 `main()` 函数中初始化：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Kv.initialize();
  runApp(const MyApp());
}
```

### 4. AI 功能无法使用

- 检查网络连接
- 确认 API Key 正确
- 使用「测试配置」功能验证
- 查看日志输出（开发模式）

---

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 致谢

- [WanAndroid](https://www.wanandroid.com/) - 提供优质的学习资源和 API
- [Flutter](https://flutter.dev/) - 强大的跨平台框架
- [Riverpod](https://riverpod.dev/) - 优雅的状态管理方案

---

## 联系方式

- **Issues**: [GitHub Issues](https://github.com/yourusername/flutter_wanandroid/issues)
- **Email**: your.email@example.com

---

<div align="center">
  <p>如果这个项目对你有帮助，请给一个 ⭐️ Star 支持一下！</p>
</div>
