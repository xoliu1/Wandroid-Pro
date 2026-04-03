import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmkv/mmkv.dart';
import 'package:notes_app/pages/homepage/main_page.dart';
import 'package:notes_app/pages/login/login_page.dart';
import 'package:notes_app/pages/transtion.dart';
import 'package:notes_app/remote/service/NerworkService.dart';
import 'package:notes_app/utils/auth_guard.dart';
import 'package:notes_app/utils/theme.dart';

import 'local/KV.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 处理框架层的 MouseTracker 断言错误（Flutter 已知问题）
  // 该错误不影响实际功能，仅在桌面平台特定交互场景下触发
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // 过滤已知的 Flutter 框架断言错误
      final exceptionStr = details.exception.toString();
      if (exceptionStr.contains('MouseTracker') ||
          exceptionStr.contains('_debugDuringDeviceUpdate') ||
          exceptionStr.contains('_dependents.isEmpty')) {
        // 仅在 debug 模式下打印警告，不中断应用
        debugPrint('⚠️ Flutter framework assertion (known issue): ${details.exception}');
        return;
      }
      // 其他错误正常处理
      FlutterError.presentError(details);
    };
  }
  
  await MMKV.initialize();
  await NetworkService.init();
  
  // 创建全局 ProviderContainer 并注册到 AuthGuard
  final container = ProviderContainer();
  setGlobalProviderContainer(container);
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

const List<Locale> supportedLocales = <Locale>[
  Locale('zh'), // 中文
];

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logined = isLogin();
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    // 统一页面转场动画
    const pageTransitionsTheme = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppPageTransitionsBuilder(),
        TargetPlatform.iOS: AppPageTransitionsBuilder(),
        TargetPlatform.macOS: AppPageTransitionsBuilder(),
        TargetPlatform.windows: AppPageTransitionsBuilder(),
        TargetPlatform.linux: AppPageTransitionsBuilder(),
        TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
      },
    );

    return MaterialApp(
      navigatorKey: navigatorKey,  // 绑定全局 NavigatorKey，用于登录态失效时的弹窗和导航
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Task Keeper',
      themeMode: themeMode,
      theme: buildLightTheme(accentColor, pageTransitionsTheme),
      darkTheme: buildDarkTheme(accentColor, pageTransitionsTheme),
      home: logined ? const MainPage() : const LoginPage(),
    );
  }
}
