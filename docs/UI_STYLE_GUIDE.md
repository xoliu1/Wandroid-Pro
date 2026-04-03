# UI 风格规范指南

## 概述

本项目采用**平台自适应设计**，根据运行平台自动切换 UI 风格：
- **Android**: Material Design
- **iOS/macOS**: Cupertino Design

## 核心原则

### 1. 使用平台自适应组件（`platform_utils.dart`）

```dart
// ❌ 错误 - 硬编码使用 Material 组件
Scaffold(
  appBar: AppBar(title: Text('标题')),
  body: ...,
)

// ✅ 正确 - 使用平台自适应组件
PlatformScaffold(
  appBar: PlatformAppBar(title: const Text('标题')),
  body: ...,
)
```

### 2. 使用主题颜色系统（支持暗夜模式）

```dart
// ❌ 错误 - 硬编码颜色
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black),
  ),
)

// ✅ 正确 - 使用主题颜色
Container(
  color: context.surfaceColor,  // 使用扩展方法
  child: Text(
    'Hello',
    style: TextStyle(color: context.onSurfaceColor),
  ),
)

// 或者传统方式
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Hello',
    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
  ),
)
```

## 平台自适应组件对照表

| 功能 | Android (Material) | iOS (Cupertino) | 自适应组件 |
|------|-------------------|-----------------|-----------|
| 页面容器 | `Scaffold` | `CupertinoPageScaffold` | `PlatformScaffold` |
| 导航栏 | `AppBar` | `CupertinoNavigationBar` | `PlatformAppBar` |
| 按钮 | `ElevatedButton` / `TextButton` | `CupertinoButton` | `PlatformButton` |
| 加载指示器 | `CircularProgressIndicator` | `CupertinoActivityIndicator` | `PlatformLoadingIndicator` |
| 对话框 | `AlertDialog` | `CupertinoAlertDialog` | `showPlatformDialog` |
| 路由导航 | `MaterialPageRoute` | `CupertinoPageRoute` | `navigatePlatform` |
| 图标 | `Icons` / `Icon` | `CupertinoIcons` / `Icon` | **不需要区分，直接使用 `Icon`** |

**注意**: `Icon` 组件无需区分平台，Material 的 `Icon` 在两个平台上都兼容良好。只需根据平台选择合适的图标集（`Icons.xxx` 或 `CupertinoIcons.xxx`）。

## 主题颜色扩展方法

`lib/utils/platform_utils.dart` 提供了便捷的扩展方法：

```dart
extension ThemeColors on BuildContext {
  // 主色
  Color get primaryColor => colors.primary;
  
  // 表面色（背景）
  Color get surfaceColor => colors.surface;
  
  // 表面上的文字颜色
  Color get onSurfaceColor => colors.onSurface;
  
  // 卡片/容器背景色
  Color get containerColor => colors.surfaceContainerHighest;
  
  // 错误色
  Color get errorColor => colors.error;
  
  // 成功色
  Color get successColor => Colors.green;
  
  // 警告色
  Color get warningColor => Colors.orange;
  
  // 次要文字颜色
  Color get secondaryTextColor => colors.onSurfaceVariant;
  
  // 分割线颜色
  Color get dividerColor => colors.outlineVariant;
  
  // ColorScheme 和 TextTheme
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
}
```

## 常见场景示例

### 1. 页面结构

```dart
class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformScaffold(
      backgroundColor: context.surfaceColor,
      appBar: PlatformAppBar(
        title: const Text('页面标题'),
        actions: [
          IconButton(
            icon: Icon(
              PlatformUtils.isIOS 
                  ? CupertinoIcons.search 
                  : Icons.search,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(context, ref),
    );
  }
  
  Widget _buildBody(BuildContext context, WidgetRef ref) {
    // 实现页面内容
    return Container();
  }
}
```

### 2. 加载状态

```dart
// ❌ 错误
loading: () => const Center(
  child: CircularProgressIndicator(),
)

// ✅ 正确
loading: () => Center(
  child: PlatformLoadingIndicator(),
)
```

### 3. 空状态

```dart
Widget _buildEmptyState(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          PlatformUtils.isIOS 
              ? CupertinoIcons.square_list 
              : Icons.inbox_outlined,
          size: 64,
          color: context.secondaryTextColor,
        ),
        const SizedBox(height: 16),
        Text(
          '暂无数据',
          style: TextStyle(
            fontSize: 16,
            color: context.secondaryTextColor,
          ),
        ),
      ],
    ),
  );
}
```

### 4. 错误状态

```dart
Widget _buildErrorState(BuildContext context, String error) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          PlatformUtils.isIOS 
              ? CupertinoIcons.exclamationmark_triangle 
              : Icons.error_outline,
          size: 64,
          color: context.errorColor,
        ),
        const SizedBox(height: 16),
        Text(
          '加载失败: $error',
          style: TextStyle(
            fontSize: 16,
            color: context.errorColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        PlatformButton(
          onPressed: () => _retry(),
          child: const Text('重试'),
        ),
      ],
    ),
  );
}
```

### 5. 卡片组件

```dart
Widget _buildCard(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.containerColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: context.dividerColor,
        width: 0.5,
      ),
      // 可选：添加阴影（Material 风格）
      boxShadow: PlatformUtils.isAndroid ? [
        BoxShadow(
          color: context.colors.shadow.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ] : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标题',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '内容',
          style: TextStyle(
            fontSize: 14,
            color: context.secondaryTextColor,
          ),
        ),
      ],
    ),
  );
}
```

### 6. 渐变背景（品牌色）

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        context.primaryColor,
        context.primaryColor.withOpacity(0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    '内容',
    style: TextStyle(color: context.colors.onPrimary),
  ),
)
```

### 7. 对话框

```dart
// ❌ 错误
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('提示'),
    content: Text('确定要删除吗？'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('取消'),
      ),
      TextButton(
        onPressed: () {
          // 执行操作
          Navigator.pop(context);
        },
        child: Text('确定'),
      ),
    ],
  ),
)

// ✅ 正确
showPlatformDialog(
  context: context,
  title: '提示',
  content: '确定要删除吗？',
  actions: [
    PlatformDialogAction(
      text: '取消',
      onPressed: () => Navigator.pop(context),
    ),
    PlatformDialogAction(
      text: '确定',
      onPressed: () {
        // 执行操作
        Navigator.pop(context);
      },
      isDestructive: true,  // iOS 会显示为红色
    ),
  ],
)
```

### 8. 导航

```dart
// ❌ 错误
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DetailPage()),
)

// ✅ 正确
navigatePlatform(context, DetailPage())
```

## 禁止事项

### ❌ 不要硬编码颜色

```dart
// 禁止
Colors.white
Colors.black
Colors.grey[400]
Color(0xFFF5F5F5)
```

### ❌ 不要混用平台组件

```dart
// 禁止在 iOS 上强制使用 Material
Scaffold(...)  // 如果在 iOS 上运行，体验不一致
```

### ❌ 不要使用废弃的 API

```dart
// withOpacity 已废弃
color.withOpacity(0.5)

// 应使用
color.withValues(alpha: 0.5)
```

## 重构清单

重构现有页面时，请按以下顺序检查：

1. [ ] 将 `Scaffold` 替换为 `PlatformScaffold`
2. [ ] 将 `AppBar` 替换为 `PlatformAppBar`
3. [ ] 将所有硬编码颜色改为 `context.xxxColor` 或 `Theme.of(context).colorScheme.xxx`
4. [ ] 将 `CircularProgressIndicator` 替换为 `PlatformLoadingIndicator`
5. [ ] 将 `ElevatedButton`/`TextButton` 替换为 `PlatformButton`
6. [ ] 将 `showDialog` 替换为 `showPlatformDialog`
7. [ ] 将 `MaterialPageRoute`/`CupertinoPageRoute` 替换为 `navigatePlatform`
8. [ ] 根据平台选择合适的图标（`Icons.xxx` vs `CupertinoIcons.xxx`，但使用统一的 `Icon` 组件）
9. [ ] 测试暗夜模式下的显示效果

## 参考示例

已重构的页面：
- ✅ `lib/pages/coin/coin_page.dart` - 完整示例
- ✅ `lib/pages/collect/collect_list_page.dart` - 完整示例
- ✅ `lib/pages/drawer/slider.dart` - 侧边栏示例

## 暗夜模式测试

重构后，请在以下模式下测试：
1. **亮色模式 (Light Mode)**
2. **暗色模式 (Dark Mode)**
3. **跟随系统 (System)**

确保所有颜色在两种模式下都清晰可见，对比度合适。
