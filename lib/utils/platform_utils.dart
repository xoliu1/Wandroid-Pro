import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';

/// 平台工具类 - 用于创建跨平台自适应 UI
/// 
/// Android 使用 Material Design
/// iOS 使用 Cupertino Design
class PlatformUtils {
  /// 是否为 iOS 平台
  static bool get isIOS => Platform.isIOS;
  
  /// 是否为 Android 平台
  static bool get isAndroid => Platform.isAndroid;
  
  /// 是否为 Apple 平台 (iOS/macOS)
  static bool get isApple => Platform.isIOS || Platform.isMacOS;
  
  /// 是否为 macOS 平台
  static bool get isMacOS => Platform.isMacOS;
  
  /// 是否为 Windows 平台
  static bool get isWindows => Platform.isWindows;
  
  /// 是否为 Linux 平台
  static bool get isLinux => Platform.isLinux;
  
  /// 是否为桌面平台 (macOS/Windows/Linux)
  static bool get isDesktop => Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  
  /// 是否为移动平台 (iOS/Android)
  static bool get isMobile => Platform.isIOS || Platform.isAndroid;
}

/// 平台自适应 Scaffold
/// 
/// Android: Material Scaffold
/// iOS: CupertinoPageScaffold
class PlatformScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  
  const PlatformScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor ?? CupertinoTheme.of(context).scaffoldBackgroundColor,
        navigationBar: appBar is PreferredSizeWidget 
            ? _convertToIOSNavBar(appBar as PreferredSizeWidget, context)
            : null,
        child: body,
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      appBar: appBar as PreferredSizeWidget?,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
  
  CupertinoNavigationBar? _convertToIOSNavBar(PreferredSizeWidget appBar, BuildContext context) {
    if (appBar is AppBar) {
      return CupertinoNavigationBar(
        backgroundColor: appBar.backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
        middle: appBar.title,
        leading: appBar.leading,
        trailing: appBar.actions != null && appBar.actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: appBar.actions!,
              )
            : null,
      );
    }
    return null;
  }
}

/// 平台自适应 AppBar
/// 
/// Android: Material AppBar
/// iOS: CupertinoNavigationBar
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  
  const PlatformAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (PlatformUtils.isIOS) {
      return CupertinoNavigationBar(
        backgroundColor: backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
        middle: title,
        leading: leading,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
        automaticallyImplyLeading: automaticallyImplyLeading,
      );
    }
    
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44.0);
}

/// 平台自适应按钮
/// 
/// Android: ElevatedButton
/// iOS: CupertinoButton
class PlatformButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final bool filled;
  
  const PlatformButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.padding,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (PlatformUtils.isIOS) {
      if (filled) {
        return CupertinoButton.filled(
          onPressed: onPressed,
          padding: padding,
          child: child,
        );
      }
      return CupertinoButton(
        onPressed: onPressed,
        padding: padding ?? const EdgeInsets.all(16),
        color: color,
        child: child,
      );
    }
    
    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: child,
      );
    }
    
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? colorScheme.primary,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: child,
    );
  }
}

/// 平台自适应加载指示器
/// 
/// Android: CircularProgressIndicator
/// iOS: CupertinoActivityIndicator
class PlatformLoadingIndicator extends StatelessWidget {
  final double? radius;
  final Color? color;
  
  const PlatformLoadingIndicator({
    super.key,
    this.radius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isIOS) {
      return CupertinoActivityIndicator(
        radius: radius ?? 10,
        color: color,
      );
    }
    
    return CircularProgressIndicator(
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }
}

/// 平台自适应对话框
Future<T?> showPlatformDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  List<PlatformDialogAction>? actions,
}) {
  if (PlatformUtils.isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: content != null ? Text(content) : null,
        actions: actions?.map((action) => CupertinoDialogAction(
          onPressed: action.onPressed,
          isDestructiveAction: action.isDestructive,
          isDefaultAction: action.isDefault,
          child: Text(action.text),
        )).toList() ?? [],
      ),
    );
  }
  
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: content != null ? Text(content) : null,
      actions: actions?.map((action) => TextButton(
        onPressed: action.onPressed,
        child: Text(
          action.text,
          style: TextStyle(
            color: action.isDestructive ? Colors.red : null,
          ),
        ),
      )).toList() ?? [],
    ),
  );
}

class PlatformDialogAction {
  final String text;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool isDefault;
  
  const PlatformDialogAction({
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

/// 平台自适应路由导航
void navigatePlatform(BuildContext context, Widget page) {
  if (PlatformUtils.isIOS) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => page),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

/// 主题颜色扩展 - 统一使用 MCM 风格颜色，确保全局一致
extension ThemeColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// 主色（强调色，由用户选择）
  Color get primaryColor => colors.primary;
  
  /// 表面色（背景）— MCM 米色/深棕
  Color get surfaceColor => MCMColors.background(this);
  
  /// 表面上的文字颜色 — MCM 深棕/暗色文字
  Color get onSurfaceColor => MCMColors.primaryText(this);
  
  /// 卡片/容器背景色 — MCM 亚麻白/暗色卡片
  Color get containerColor => MCMColors.card(this);
  
  /// 错误色 — MCM 珊瑚粉
  Color get errorColor => MCMColors.coral;
  
  /// 成功色 — MCM 橄榄绿
  Color get successColor => MCMColors.olive;
  
  /// 警告色 — MCM 芥末黄
  Color get warningColor => MCMColors.mustard;
  
  /// 次要文字颜色 — MCM 胡桃木
  Color get secondaryTextColor => MCMColors.secondaryText(this);
  
  /// 分割线颜色 — MCM 分割线
  Color get dividerColor => MCMColors.dividerColor(this);
}
