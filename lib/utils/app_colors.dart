import 'package:flutter/material.dart';
import 'mcm_widget.dart';

/// 应用颜色管理类
/// 统一管理深色/浅色主题的颜色，确保在深夜模式下的良好可读性
/// 
/// 已适配 MCM (Mid-Century Modern) 风格色彩体系
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
  
  /// 主背景色 (页面背景) — MCM 米色/深棕
  static Color backgroundColor(BuildContext context) {
    return MCMColors.background(context);
  }

  /// 次级背景色 (卡片背景) — MCM 亚麻白/暗色卡片
  static Color cardBackground(BuildContext context) {
    return MCMColors.card(context);
  }

  /// 分组背景色 (列表分组背景)
  static Color groupedBackground(BuildContext context) {
    return MCMColors.background(context);
  }

  /// 输入框背景色
  static Color inputBackground(BuildContext context) {
    return MCMColors.card(context);
  }

  // ==================== 文本颜色 ====================
  
  /// 主文本颜色 (标题、重要文本) — MCM 深棕
  static Color primaryText(BuildContext context) {
    return MCMColors.primaryText(context);
  }

  /// 次级文本颜色 (正文、描述) — MCM 胡桃木
  static Color secondaryText(BuildContext context) {
    return MCMColors.secondaryText(context);
  }

  /// 第三级文本颜色 (提示文本、辅助信息)
  static Color tertiaryText(BuildContext context) {
    return MCMColors.secondaryText(context).withOpacity(0.6);
  }

  /// 禁用/灰色文本
  static Color disabledText(BuildContext context) {
    return MCMColors.secondaryText(context).withOpacity(0.4);
  }

  // ==================== 链接和强调色 ====================
  
  /// 链接颜色 — MCM 橙红
  static Color link(BuildContext context) {
    return _colorScheme(context).primary;
  }

  /// 强调/高亮颜色 — MCM 橙红
  static Color accent(BuildContext context) {
    return _colorScheme(context).primary;
  }

  // ==================== 分隔线和边框 ====================
  
  /// 分隔线颜色 — MCM 分割线
  static Color divider(BuildContext context) {
    return MCMColors.dividerColor(context);
  }

  /// 边框颜色
  static Color border(BuildContext context) {
    return MCMColors.dividerColor(context);
  }

  // ==================== 图标颜色 ====================
  
  /// 主图标颜色
  static Color iconPrimary(BuildContext context) {
    return MCMColors.primaryText(context);
  }

  /// 次级图标颜色
  static Color iconSecondary(BuildContext context) {
    return MCMColors.secondaryText(context);
  }

  // ==================== 特殊元素颜色 ====================
  
  /// 作者头像背景色 — MCM 橙红
  static Color avatarBackground(BuildContext context) {
    return MCMColors.orange.withOpacity(isDarkMode(context) ? 0.3 : 0.15);
  }

  /// 作者头像文字颜色
  static Color avatarText(BuildContext context) {
    return MCMColors.orange;
  }

  /// 标签/徽章背景色
  static Color tagBackground(BuildContext context) {
    return MCMColors.grayBlue.withOpacity(0.12);
  }

  /// 标签/徽章文字颜色
  static Color tagText(BuildContext context) {
    return MCMColors.grayBlue;
  }

  /// 芯片(Chip)背景色 - 搜索历史等
  static Color chipBackground(BuildContext context) {
    return MCMColors.card(context);
  }

  /// 芯片(Chip)文字颜色
  static Color chipText(BuildContext context) {
    return MCMColors.primaryText(context);
  }

  /// 阴影颜色 — MCM 柔和阴影
  static BoxShadow cardShadow(BuildContext context) {
    return BoxShadow(
      color: const Color(0xFF2C2416).withOpacity(isDarkMode(context) ? 0.15 : 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );
  }

  // ==================== Tab 相关颜色 ====================
  
  /// Tab 选中颜色 — MCM 橙红
  static Color tabSelected(BuildContext context) {
    return _colorScheme(context).primary;
  }

  /// Tab 未选中颜色
  static Color tabUnselected(BuildContext context) {
    return MCMColors.secondaryText(context);
  }

  /// Tab 背景颜色
  static Color tabBackground(BuildContext context) {
    return MCMColors.card(context);
  }

  // ==================== 列表相关颜色 ====================
  
  /// 侧边栏选中背景色
  static Color sidebarSelected(BuildContext context) {
    return MCMColors.orange.withOpacity(0.12);
  }

  /// 侧边栏未选中背景色
  static Color sidebarUnselected(BuildContext context) {
    return Colors.transparent;
  }

  /// 侧边栏背景色
  static Color sidebarBackground(BuildContext context) {
    return MCMColors.background(context);
  }

  /// 侧边栏边框色
  static Color sidebarBorder(BuildContext context) {
    return MCMColors.dividerColor(context);
  }

  // ==================== 其他 ====================
  
  /// 空状态图标颜色
  static Color emptyIcon(BuildContext context) {
    return MCMColors.secondaryText(context);
  }

  /// 错误图标颜色
  static Color errorIcon(BuildContext context) {
    return MCMColors.coral;
  }
}
