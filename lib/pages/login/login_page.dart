import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/utils/animations.dart';
import 'package:wanandroid_pro/utils/functions.dart';
import 'package:wanandroid_pro/utils/mcm_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../gen/assets.gen.dart';
import '../../local/KV.dart';
import '../../providers/profile_provider.dart';
import '../../remote/CgiUser.dart';
import '../homepage/main_page.dart';
import 'register_page.dart';

class Setup extends StatefulWidget {
  final Function() onContinue;

  const Setup({super.key, required this.onContinue});

  @override
  State<Setup> createState() => _SetupState();
}

class _SetupState extends State<Setup> {
  final _nameController = TextEditingController();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _prefs.then((value) {
      prefs = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MCMColors.background(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: SizedBox(
                    height: 220,
                    child: Assets.images.welcome.image(),
                  ),
                ),
                const SizedBox(height: 16),
                // MCM 装饰元素
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: MCMColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32, height: 4,
                        decoration: BoxDecoration(
                          color: MCMColors.mustard,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: MCMColors.olive,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'WELCOME',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: MCMColors.primaryText(context),
                      letterSpacing: 3.0,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  'ENTER YOUR NAME',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MCMColors.secondaryText(context),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: TextField(
                    controller: _nameController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    style: TextStyle(color: MCMColors.primaryText(context)),
                    decoration: InputDecoration(
                      hintText: '输入你的名字',
                      hintStyle: TextStyle(color: MCMColors.secondaryText(context).withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (nameValid(_nameController.text)
                        ? () {
                            prefs.setString('name', _nameController.text.trim());
                            prefs.setBool('isInitialized', true);
                            widget.onContinue();
                          }
                        : null),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends ConsumerStatefulWidget {
  final Function()? onSuccess;

  const LoginPage({super.key, this.onSuccess});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);

    return Scaffold(
      backgroundColor: MCMColors.background(context),
      body: SafeArea(
        child: AutofillGroup(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // MCM 返回按钮
                if (Navigator.of(context).canPop())
                  MCMBackButton(),
                const SizedBox(height: 32),
                // MCM 装饰几何元素
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: MCMColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 24, height: 4,
                        decoration: BoxDecoration(
                          color: MCMColors.mustard,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 大标题
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 2.0,
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 250),
                  child: Text(
                    '登录你的 WanAndroid 账号',
                    style: TextStyle(
                      fontSize: 14,
                      color: subColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // 用户名输入
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'USERNAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        autofillHints: const [AutofillHints.username],
                        controller: _usernameController,
                        autofocus: true,
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: '请输入用户名',
                          prefixIcon: Icon(CupertinoIcons.person, size: 20),
                        ),
                        onEditingComplete: () => TextInput.finishAutofillContext(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 密码输入
                FadeSlideIn(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PASSWORD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: subColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        autofillHints: const [AutofillHints.password],
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: textColor, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: '请输入密码',
                          prefixIcon: Icon(CupertinoIcons.lock, size: 20),
                        ),
                        onEditingComplete: () => TextInput.finishAutofillContext(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // 登录按钮
                FadeSlideIn(
                  delay: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() {
                                _isLoading = true;
                              });
                              if (await login(_usernameController.text,
                                  _passwordController.text)) {
                                widget.onSuccess?.call();
                              }
                              setState(() {
                                _isLoading = false;
                              });
                            },
                      child: _isLoading
                          ? SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 注册链接
                FadeSlideIn(
                  delay: const Duration(milliseconds: 550),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        '没有账号？去注册',
                        style: TextStyle(
                          color: MCMColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 跳过登录入口
                FadeSlideIn(
                  delay: const Duration(milliseconds: 600),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        // 保存跳过登录的选择
                        setSkipLogin(true);
                        Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const MainPage(),
                          ),
                        );
                      },
                      child: Text(
                        '跳过登录，随便看看',
                        style: TextStyle(
                          color: MCMColors.secondaryText(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // 底部 MCM 装饰
                Center(
                  child: MCMStarburst(
                    size: 40,
                    color: MCMColors.mustard.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> login(String username, String password) async {
    final completer = Completer<bool>();

    CgiUser().login(username, password)
      .onSuccess((user) async {
        // 登录成功 - 更新全局登录状态
        ref.read(loginStateProvider.notifier).login();
        
        // 清除跳过登录标记（登录成功后不再需要这个标记）
        setSkipLogin(false);
        
        if (!completer.isCompleted) {
          completer.complete(true);
        }
        // 登录成功后跳转到主页面
      Navigator.pushReplacement(
        context,
          CupertinoPageRoute(builder: (_) => const MainPage()));
      })
      .onFail((errorCode, errorMsg) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }

        // MCM 风格错误对话框
        showDialog(
          context: context,
          builder: (context) => MCMConfirmDialog(
            icon: Icons.error_outline_rounded,
            iconColor: MCMColors.coral,
            title: '登录失败',
            content: errorMsg,
            cancelText: '',
            confirmText: 'OK',
            onConfirm: () {},
          ),
        );
      });

    return completer.future;
  }
}
