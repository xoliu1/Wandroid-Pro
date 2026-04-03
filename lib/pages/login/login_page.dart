import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../gen/assets.gen.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 80,
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: SizedBox(
                    height: 250,
                    child: Assets.images.welcome.image(),
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 300),
                  child: const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                const Text(
                  'Please enter your name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 60,
                  child: TextField(
                    controller: _nameController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: '输入你的名字',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF896F),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: (nameValid(_nameController.text)
                      ? () {
                          prefs.setString('name', _nameController.text.trim());
                          prefs.setBool('isInitialized', true);
                          widget.onContinue();
                        }
                      : null),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: AutofillGroup(  // 包裹 AutofillGroup，让两个字段一起填充
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: TextField(
                autofillHints: const [AutofillHints.username],
                controller: _usernameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: () => TextInput.finishAutofillContext(),  // 完成自动填充
              ),
              ),
              const SizedBox(height: 20),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: TextField(
                autofillHints: const [AutofillHints.password],
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: () => TextInput.finishAutofillContext(),  // 完成自动填充
              ),
              ),
              const SizedBox(height: 30),
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: SizedBox(
                width: double.infinity,
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
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text('没有账号？去注册'),
              ),
            ],
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

        // UI层错误处理
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('登录失败'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      });

    return completer.future;
  }
}
