import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/KV.dart';

// ==================== 预设强调色 ====================

/// 预设的强调色列表，供用户选择
class AccentColorPreset {
  final String name;
  final Color color;
  const AccentColorPreset(this.name, this.color);
}

const List<AccentColorPreset> accentColorPresets = [
  AccentColorPreset('MCM 橙红', Color(0xFFD97642)),   // Mid-Century Modern 主色
  AccentColorPreset('默认蓝', Color(0xFF2196F3)),
  AccentColorPreset('靛蓝', Color(0xFF3F51B5)),
  AccentColorPreset('青色', Color(0xFF00BCD4)),
  AccentColorPreset('翠绿', Color(0xFF4CAF50)),
  AccentColorPreset('橙色', Color(0xFFFF9800)),
  AccentColorPreset('珊瑚红', Color(0xFFFF6B6B)),
  AccentColorPreset('紫色', Color(0xFF9C27B0)),
  AccentColorPreset('粉色', Color(0xFFE91E63)),
  AccentColorPreset('棕色', Color(0xFF795548)),
  AccentColorPreset('蓝灰', Color(0xFF607D8B)),
];

/// 默认强调色 — MCM 橙红
const Color defaultAccentColor = Color(0xFFD97642);

// ==================== 强调色 Provider ====================

/// 强调色状态管理
final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  final notifier = AccentColorNotifier();
  notifier.loadAccentColor();
  return notifier;
});

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(defaultAccentColor);

  /// 加载本地保存的强调色
  void loadAccentColor() {
    final savedValue = getAccentColorValue();
    if (savedValue != null) {
      state = Color(savedValue);
    } else {
      state = defaultAccentColor;
    }
  }

  /// 设置强调色
  void setAccentColor(Color color) {
    state = color;
    setAccentColorValue(color.value);
  }

  /// 重置为默认强调色
  void resetToDefault() {
    state = defaultAccentColor;
    resetAccentColor();
  }
}

// ==================== 主题模式 Provider ====================

/// 状态：保存当前主题模式
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final notifier = ThemeModeNotifier();
  notifier.loadTheme();
  return notifier;
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light);

  /// 加载本地保存的配置
  void loadTheme() {
    final saved = Kv.decodeString(keyThemeMode);

    if (saved != null) {
      switch (saved) {
        case "light":
          state = ThemeMode.light;
          break;
        case "dark":
          state = ThemeMode.dark;
          break;
        case "system":
          state = ThemeMode.system;
          break;
      }
    } else {
      state = ThemeMode.light;
    }
  }

  /// 切换并保存
  void setTheme(ThemeMode mode) {
    state = mode;
    switch (mode) {
      case ThemeMode.light:
        Kv.encodeString(keyThemeMode, "light");
        break;
      case ThemeMode.dark:
        Kv.encodeString(keyThemeMode, "dark");
        break;
      case ThemeMode.system:
        Kv.encodeString(keyThemeMode, "system");
        break;
    }
  }
}

// ==================== MCM 色彩常量 ====================

/// Mid-Century Modern 亮色调色板
class _MCMLightPalette {
  static const cream = Color(0xFFF5E6D3);
  static const surface = Color(0xFFFAF0E6);
  static const darkBrown = Color(0xFF2C2416);
  static const walnut = Color(0xFF6B5D4F);
  static const divider = Color(0xFFE8D5C0);
  static const orange = Color(0xFFD97642);
}

/// Mid-Century Modern 暗色调色板
class _MCMDarkPalette {
  static const background = Color(0xFF2A1F14);
  static const surface = Color(0xFF3A2D1F);
  static const text = Color(0xFFF0DCC8);
  static const walnut = Color(0xFFA08B78);
  static const divider = Color(0xFF4A3828);
  static const orange = Color(0xFFE08A52);
}

// ==================== 主题构建 ====================

/// 构建亮色主题 — MCM 风格
ThemeData buildLightTheme(Color seedColor, PageTransitionsTheme pageTransitionsTheme) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    surface: _MCMLightPalette.cream,
    onSurface: _MCMLightPalette.darkBrown,
    onSurfaceVariant: _MCMLightPalette.walnut,
    outlineVariant: _MCMLightPalette.divider,
    surfaceContainerHighest: const Color(0xFFF0DCC8),
  );

  return ThemeData(
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _MCMLightPalette.cream,
    canvasColor: _MCMLightPalette.surface,
    cardColor: _MCMLightPalette.surface,
    dividerColor: _MCMLightPalette.divider,
    appBarTheme: AppBarTheme(
      backgroundColor: _MCMLightPalette.cream,
      foregroundColor: _MCMLightPalette.darkBrown,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: _MCMLightPalette.darkBrown,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: _MCMLightPalette.darkBrown),
    ),
    cardTheme: CardThemeData(
      color: _MCMLightPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _MCMLightPalette.divider, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _MCMLightPalette.divider,
      thickness: 0.5,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: _MCMLightPalette.walnut,
      indicatorColor: colorScheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _MCMLightPalette.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0DCC8),
      labelStyle: const TextStyle(color: _MCMLightPalette.darkBrown),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: _MCMLightPalette.divider),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _MCMLightPalette.walnut,
      textColor: _MCMLightPalette.darkBrown,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _MCMLightPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _MCMLightPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0DCC8).withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _MCMLightPalette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _MCMLightPalette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _MCMLightPalette.orange, width: 2),
      ),
      hintStyle: TextStyle(color: _MCMLightPalette.walnut.withOpacity(0.6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _MCMLightPalette.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _MCMLightPalette.orange,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _MCMLightPalette.orange;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _MCMLightPalette.orange.withOpacity(0.4);
        }
        return null;
      }),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _MCMLightPalette.darkBrown,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _MCMLightPalette.darkBrown,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: _MCMLightPalette.darkBrown,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: _MCMLightPalette.darkBrown,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _MCMLightPalette.darkBrown),
      bodyMedium: TextStyle(color: _MCMLightPalette.darkBrown),
      bodySmall: TextStyle(color: _MCMLightPalette.walnut),
      labelLarge: TextStyle(
        color: _MCMLightPalette.darkBrown,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      labelSmall: TextStyle(
        color: _MCMLightPalette.walnut,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    ),
    pageTransitionsTheme: pageTransitionsTheme,
  );
}

/// 构建暗色主题 — MCM 风格
ThemeData buildDarkTheme(Color seedColor, PageTransitionsTheme pageTransitionsTheme) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
    surface: _MCMDarkPalette.background,
    onSurface: _MCMDarkPalette.text,
    onSurfaceVariant: _MCMDarkPalette.walnut,
    outlineVariant: _MCMDarkPalette.divider,
    surfaceContainerHighest: const Color(0xFF4A3828),
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _MCMDarkPalette.background,
    canvasColor: _MCMDarkPalette.surface,
    cardColor: _MCMDarkPalette.surface,
    dividerColor: _MCMDarkPalette.divider,
    appBarTheme: AppBarTheme(
      backgroundColor: _MCMDarkPalette.background,
      foregroundColor: _MCMDarkPalette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: _MCMDarkPalette.text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: _MCMDarkPalette.text),
    ),
    cardTheme: CardThemeData(
      color: _MCMDarkPalette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _MCMDarkPalette.divider, width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _MCMDarkPalette.divider,
      thickness: 0.5,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _MCMDarkPalette.orange,
      unselectedLabelColor: _MCMDarkPalette.walnut,
      indicatorColor: _MCMDarkPalette.orange,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _MCMDarkPalette.orange,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF4A3828),
      labelStyle: const TextStyle(color: _MCMDarkPalette.text),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: _MCMDarkPalette.divider),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: _MCMDarkPalette.walnut,
      textColor: _MCMDarkPalette.text,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _MCMDarkPalette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _MCMDarkPalette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF4A3828).withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _MCMDarkPalette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _MCMDarkPalette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _MCMDarkPalette.orange, width: 2),
      ),
      hintStyle: TextStyle(color: _MCMDarkPalette.walnut.withOpacity(0.6)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _MCMDarkPalette.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _MCMDarkPalette.orange,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _MCMDarkPalette.orange;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _MCMDarkPalette.orange.withOpacity(0.4);
        }
        return null;
      }),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _MCMDarkPalette.text,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: _MCMDarkPalette.text,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: _MCMDarkPalette.text,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: _MCMDarkPalette.text,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _MCMDarkPalette.text),
      bodyMedium: TextStyle(color: _MCMDarkPalette.text),
      bodySmall: TextStyle(color: _MCMDarkPalette.walnut),
      labelLarge: TextStyle(
        color: _MCMDarkPalette.text,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      labelSmall: TextStyle(
        color: _MCMDarkPalette.walnut,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    ),
    pageTransitionsTheme: pageTransitionsTheme,
  );
}