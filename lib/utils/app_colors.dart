import 'package:flutter/material.dart';

/// 应用颜色管理类
/// 统一管理深色/浅色主题的颜色，确保在深夜模式下的良好可读性
/// 
/// 强调色相关的颜色（link、accent、tab、avatar 等）会从 Theme.colorScheme 取色，
/// 支持用户自定义强调色。
class AppColors {
  /// 根据上下文获取当前是否为深色模式
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 获取当前主题的 ColorScheme
  static ColorScheme _colorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  // ==================== 背景颜色 ====================
  
  /// 主背景色 (页面背景) — 使用主题 surface
  static Color backgroundColor(BuildContext context) {
    return _colorScheme(context).surface;
  }

  /// 次级背景色 (卡片背景)
  static Color cardBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).surfaceContainer
        : _colorScheme(context).surface;
  }

  /// 分组背景色 (列表分组背景)
  static Color groupedBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).surfaceContainerLowest
        : _colorScheme(context).surfaceContainerHighest;
  }

  /// 输入框背景色
  static Color inputBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).surfaceContainerHigh
        : _colorScheme(context).surfaceContainerHighest;
  }

  // ==================== 文本颜色 ====================
  
  /// 主文本颜色 (标题、重要文本)
  static Color primaryText(BuildContext context) {
    return _colorScheme(context).onSurface;
  }

  /// 次级文本颜色 (正文、描述)
  static Color secondaryText(BuildContext context) {
    return _colorScheme(context).onSurfaceVariant;
  }

  /// 第三级文本颜色 (提示文本、辅助信息)
  static Color tertiaryText(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFFB0B0B0) : const Color(0xFF8E8E93);
  }

  /// 禁用/灰色文本
  static Color disabledText(BuildContext context) {
    return isDarkMode(context) ? const Color(0xFF707070) : const Color(0xFFC7C7CC);
  }

  // ==================== 链接和强调色 ====================
  
  /// 链接颜色 — 跟随主题强调色
  static Color link(BuildContext context) {
    return _colorScheme(context).primary;
  }

  /// 强调/高亮颜色 — 跟随主题强调色
  static Color accent(BuildContext context) {
    return _colorScheme(context).primary;
  }

  // ==================== 分隔线和边框 ====================
  
  /// 分隔线颜色
  static Color divider(BuildContext context) {
    return _colorScheme(context).outlineVariant;
  }

  /// 边框颜色
  static Color border(BuildContext context) {
    return _colorScheme(context).outline;
  }

  // ==================== 图标颜色 ====================
  
  /// 主图标颜色
  static Color iconPrimary(BuildContext context) {
    return _colorScheme(context).onSurface;
  }

  /// 次级图标颜色
  static Color iconSecondary(BuildContext context) {
    return _colorScheme(context).onSurfaceVariant;
  }

  // ==================== 特殊元素颜色 ====================
  
  /// 作者头像背景色 — 跟随主题强调色
  static Color avatarBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).primary
        : _colorScheme(context).primaryContainer;
  }

  /// 作者头像文字颜色
  static Color avatarText(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).onPrimary
        : _colorScheme(context).onPrimaryContainer;
  }

  /// 标签/徽章背景色
  static Color tagBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).surfaceContainerHigh
        : _colorScheme(context).surfaceContainerHighest;
  }

  /// 标签/徽章文字颜色
  static Color tagText(BuildContext context) {
    return _colorScheme(context).onSurfaceVariant;
  }

  /// 芯片(Chip)背景色 - 搜索历史等
  static Color chipBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).surfaceContainerHigh
        : _colorScheme(context).surfaceContainerHighest;
  }

  /// 芯片(Chip)文字颜色
  static Color chipText(BuildContext context) {
    return _colorScheme(context).onSurface;
  }

  /// 阴影颜色 (减少深色模式下的阴影强度)
  static BoxShadow cardShadow(BuildContext context) {
    return BoxShadow(
      color: isDarkMode(context) 
          ? Colors.black.withOpacity(0.3) 
          : Colors.black.withOpacity(0.08),
      blurRadius: isDarkMode(context) ? 8 : 12,
      offset: const Offset(0, 2),
    );
  }

  // ==================== Tab 相关颜色 ====================
  
  /// Tab 选中颜色 — 跟随主题强调色
  static Color tabSelected(BuildContext context) {
    return _colorScheme(context).primary;
  }

  /// Tab 未选中颜色
  static Color tabUnselected(BuildContext context) {
    return _colorScheme(context).onSurfaceVariant;
  }

  /// Tab 背景颜色
  static Color tabBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).surfaceContainer
        : _colorScheme(context).surface;
  }

  // ==================== 列表相关颜色 ====================
  
  /// 侧边栏选中背景色 — 跟随主题强调色
  static Color sidebarSelected(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).primaryContainer
        : _colorScheme(context).primaryContainer;
  }

  /// 侧边栏未选中背景色
  static Color sidebarUnselected(BuildContext context) {
    return Colors.transparent;
  }

  /// 侧边栏背景色
  static Color sidebarBackground(BuildContext context) {
    return isDarkMode(context) 
        ? _colorScheme(context).surfaceContainer
        : _colorScheme(context).surfaceContainerHighest;
  }

  /// 侧边栏边框色
  static Color sidebarBorder(BuildContext context) {
    return _colorScheme(context).outlineVariant;
  }

  // ==================== 其他 ====================
  
  /// 空状态图标颜色
  static Color emptyIcon(BuildContext context) {
    return _colorScheme(context).onSurfaceVariant;
  }

  /// 错误图标颜色
  static Color errorIcon(BuildContext context) {
    return _colorScheme(context).error;
  }
}
