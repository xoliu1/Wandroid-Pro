

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

/// 默认强调色
const Color defaultAccentColor = Color(0xFF2196F3);

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

// ==================== 主题构建 ====================

/// 构建亮色主题
ThemeData buildLightTheme(Color seedColor, PageTransitionsTheme pageTransitionsTheme) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  return ThemeData(
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 0.5,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: colorScheme.onSurface),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withOpacity(0.5);
        }
        return null;
      }),
    ),
    pageTransitionsTheme: pageTransitionsTheme,
  );
}

/// 构建暗色主题
ThemeData buildDarkTheme(Color seedColor, PageTransitionsTheme pageTransitionsTheme) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 0.5,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      indicatorColor: colorScheme.primary,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: colorScheme.onSurface),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withOpacity(0.5);
        }
        return null;
      }),
    ),
    pageTransitionsTheme: pageTransitionsTheme,
  );
}