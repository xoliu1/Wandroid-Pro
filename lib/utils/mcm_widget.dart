import 'dart:math' as math;

import 'package:flutter/material.dart';

// ─── Mid-Century Modern 色彩体系 ─────────────────────────────────────────────
/// MCM 风格颜色常量，全局唯一定义，避免各文件重复声明
class MCMColors {
  MCMColors._();

  // 主色调
  static const cream = Color(0xFFF5E6D3);       // 温暖米色（页面背景）
  static const white = Color(0xFFFFFFFF);
  static const darkBrown = Color(0xFF2C2416);    // 深棕色（主文字）
  static const surface = Color(0xFFFAF0E6);      // 亚麻白（卡片背景）
  static const divider = Color(0xFFE8D5C0);      // 分割线

  // 强调色
  static const orange = Color(0xFFD97642);       // 橙红（主强调色）
  static const mustard = Color(0xFFD4A574);      // 芥末黄
  static const olive = Color(0xFF4A7C59);        // 橄榄绿（成功/激活）
  static const coral = Color(0xFFE57A77);        // 珊瑚粉（错误/删除）
  static const grayBlue = Color(0xFF7D9BA8);     // 灰蓝（信息/次要）

  // 木质色
  static const walnut = Color(0xFF6B5D4F);       // 胡桃木（次要文字）
  static const teak = Color(0xFF8B7355);         // 柚木

  // 暗色模式适配
  static const darkSurface = Color(0xFF2A1F14);  // 暗色背景
  static const darkCard = Color(0xFF3A2D1F);     // 暗色卡片
  static const darkDivider = Color(0xFF4A3828);  // 暗色分割线
  static const darkText = Color(0xFFF0DCC8);     // 暗色主文字

  /// 判断当前是否为 MCM 主题
  static bool isMCM(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // MCM 主题的 seed color 是橙红色，primary 会接近橙红
    return scheme.primary.red > 180 && scheme.primary.green < 130 && scheme.primary.blue < 100;
  }

  /// 根据主题返回背景色（MCM 用米色，其他用系统色）
  static Color background(BuildContext context) {
    if (isMCM(context)) {
      return Theme.of(context).brightness == Brightness.dark ? darkSurface : cream;
    }
    return Theme.of(context).colorScheme.surface;
  }

  /// 根据主题返回卡片色
  static Color card(BuildContext context) {
    if (isMCM(context)) {
      return Theme.of(context).brightness == Brightness.dark ? darkCard : surface;
    }
    return Theme.of(context).colorScheme.surface;
  }

  /// 根据主题返回分割线色
  static Color dividerColor(BuildContext context) {
    if (isMCM(context)) {
      return Theme.of(context).brightness == Brightness.dark ? darkDivider : divider;
    }
    return Theme.of(context).colorScheme.outlineVariant;
  }

  /// 根据主题返回主文字色
  static Color primaryText(BuildContext context) {
    if (isMCM(context)) {
      return Theme.of(context).brightness == Brightness.dark ? darkText : darkBrown;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  /// 根据主题返回次要文字色
  static Color secondaryText(BuildContext context) {
    if (isMCM(context)) {
      return Theme.of(context).brightness == Brightness.dark
          ? darkText.withValues(alpha: 0.6)
          : walnut;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

// ─── MCM 公共组件 ─────────────────────────────────────────────────────────────

/// MCM 风格页面 Header（大标题 + 装饰几何元素）
///
/// 用法：
/// ```dart
/// MCMHeader(
///   title: 'MY PAGE',
///   subtitle: 'Description text',
///   leading: backButton,
///   trailing: addButton,
/// )
/// ```
class MCMHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? backgroundColor;

  const MCMHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? MCMColors.background(context);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);

    return Container(
      color: bg,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部操作行
          if (leading != null || trailing != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                leading ?? const SizedBox(width: 40),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
          if (leading != null || trailing != null) const SizedBox(height: 28),
          // 装饰几何元素
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: MCMColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: MCMColors.mustard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 大标题
          Text(
            title,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: subColor,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// MCM 风格返回按钮
class MCMBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const MCMBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: MCMColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MCMColors.darkBrown.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: MCMColors.darkBrown,
        ),
      ),
    );
  }
}

/// MCM 风格主按钮（橙红色）
class MCMPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isSmall;

  const MCMPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSmall ? 40 : 56,
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
        decoration: BoxDecoration(
          color: MCMColors.orange,
          borderRadius: BorderRadius.circular(isSmall ? 20 : 18),
          boxShadow: [
            BoxShadow(
              color: MCMColors.orange.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isSmall ? 18 : 20, color: MCMColors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: MCMColors.white,
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// MCM 风格 Section 标签（全大写 + 左侧橙色竖线）
class MCMSectionLabel extends StatelessWidget {
  final String label;

  const MCMSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: MCMColors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: MCMColors.walnut,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }
}

/// MCM 风格卡片容器
class MCMCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const MCMCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: divColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: MCMColors.darkBrown.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// MCM 风格底部弹出菜单项
class MCMSheetItem {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;

  const MCMSheetItem({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.color,
    required this.onTap,
  });
}

/// MCM 风格底部弹出菜单
class MCMBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<MCMSheetItem> items;

  const MCMBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bg = MCMColors.card(context);
    final cream = MCMColors.background(context);
    final divColor = MCMColors.dividerColor(context);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: divColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题区
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.close_rounded, size: 16, color: subColor),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: divColor, margin: const EdgeInsets.symmetric(horizontal: 24)),
          const SizedBox(height: 8),
          // 操作项
          ...items.map((item) => GestureDetector(
            onTap: item.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (item.sublabel != null)
                          Text(
                            item.sublabel!,
                            style: TextStyle(fontSize: 12, color: subColor),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: MCMColors.mustard.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ],
              ),
            ),
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

/// MCM 风格确认对话框
class MCMConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const MCMConfirmDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    this.cancelText = 'CANCEL',
    this.confirmText = 'CONFIRM',
    this.isDestructive = false,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bg = MCMColors.card(context);
    final cream = MCMColors.background(context);
    final divColor = MCMColors.dividerColor(context);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final confirmColor = isDestructive ? MCMColors.coral : MCMColors.orange;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: subColor, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: divColor),
                      ),
                      child: Center(
                        child: Text(
                          cancelText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: subColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: confirmColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: MCMColors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// MCM 星爆装饰图案（用于空状态页面）
class MCMStarburst extends StatelessWidget {
  final double size;
  final Color color;

  const MCMStarburst({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarburstPainter(color: color),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  final Color color;
  _StarburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = size.width / 4.5;
    const points = 12;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      center,
      size.width / 8,
      Paint()..color = color.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_StarburstPainter old) => old.color != color;
}

/// 显示 MCM 风格底部弹出菜单的便捷方法
Future<T?> showMCMBottomSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<MCMSheetItem> items,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => MCMBottomSheet(
      title: title,
      subtitle: subtitle,
      items: items,
    ),
  );
}
