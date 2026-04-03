import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/KV.dart';
import '../pages/login/login_page.dart';
import '../providers/profile_provider.dart';
import '../remote/service/NerworkService.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

ProviderContainer? _globalContainer;

void setGlobalProviderContainer(ProviderContainer container) {
  _globalContainer = container;
}

class AuthGuard {
  static bool _isShowingDialog = false;
  
  static void handleSessionExpired({String errorMsg = '请先登录！'}) {
    if (_isShowingDialog) return;
    
    clearLocalLoginData();
    _globalContainer?.read(loginStateProvider.notifier).logout();
    // 同时清除 Cookie
    NetworkService.clearCookies();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSessionExpiredDialog(errorMsg);
    });
  }
  
  static void _showSessionExpiredDialog(String errorMsg) {
    final context = navigatorKey.currentContext;
    if (context == null || _isShowingDialog) return;
    
    _isShowingDialog = true;
    
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('登录已过期'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              '$errorMsg\n请重新登录以继续使用。',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _isShowingDialog = false;
                _navigateToLogin(context);
              },
              child: const Text('去登录'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _isShowingDialog = false;
              },
              child: const Text('稍后再说'),
            ),
          ],
        );
      },
    );
  }
  
  static void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
  
  static bool checkLoginStatus({bool showDialogIfNeeded = true}) {
    if (isLogin()) return true;
    if (showDialogIfNeeded) {
      handleSessionExpired(errorMsg: '该功能需要登录');
    }
    return false;
  }
}
