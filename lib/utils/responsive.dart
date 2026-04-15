import 'package:flutter/material.dart';

/// 响应式断点系统
/// 
/// 断点定义：
/// - 移动端 (Mobile): < 600px
/// - 平板端 (Tablet): 600px ~ 1200px
/// - 桌面端 (Desktop): >= 1200px
class Responsive {
  Responsive._();

  /// 移动端断点
  static const double mobileBreakpoint = 600;
  
  /// 桌面端断点
  static const double desktopBreakpoint = 1200;

  /// 是否为移动端布局
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// 是否为平板端布局
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  /// 是否为桌面端布局
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// 是否为宽屏（平板或桌面）
  static bool isWideScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint;

  /// 获取当前屏幕宽度
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// 获取内容区域最大宽度
  /// 移动端：不限制
  /// 平板端：最大 800px
  /// 桌面端：最大 1000px
  static double contentMaxWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width >= desktopBreakpoint) return 1000;
    if (width >= mobileBreakpoint) return 800;
    return width;
  }

  /// 获取侧边栏宽度（仅桌面端显示）
  static double sidebarWidth(BuildContext context) {
    if (isDesktop(context)) return 280;
    return 0;
  }

  /// 获取列表项水平内边距
  static double listPaddingH(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }
}

/// 响应式布局构建器
/// 
/// 根据屏幕宽度自动选择不同的布局
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.desktopBreakpoint && desktop != null) {
          return desktop!(context);
        }
        if (constraints.maxWidth >= Responsive.mobileBreakpoint && tablet != null) {
          return tablet!(context);
        }
        return mobile(context);
      },
    );
  }
}

/// 内容区域最大宽度约束包装器
/// 
/// 在宽屏上自动居中并限制最大宽度，避免内容过度拉伸
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? Responsive.contentMaxWidth(context);
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// 桌面端鼠标悬停效果包装器
/// 
/// 在桌面端为卡片添加 hover 效果（微微上浮 + 阴影加深）
/// 移动端不生效，保持原有触摸交互
class HoverEffect extends StatefulWidget {
  final Widget child;
  final double hoverElevation;
  final double hoverScale;
  final Duration duration;

  const HoverEffect({
    super.key,
    required this.child,
    this.hoverElevation = -2.0,
    this.hoverScale = 1.005,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverEffect> createState() => _HoverEffectState();
}

class _HoverEffectState extends State<HoverEffect> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // 移动端不需要 hover 效果
    if (Responsive.isMobile(context)) {
      return widget.child;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? widget.hoverElevation : 0.0)
          ..scale(_isHovered ? widget.hoverScale : 1.0),
        child: widget.child,
      ),
    );
  }
}
