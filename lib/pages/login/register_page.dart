import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/profile_provider.dart';
import '../../remote/CgiUser.dart';
import '../homepage/main_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _repasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册')),
      body: AutofillGroup(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                autofillHints: const [AutofillHints.newUsername],
                controller: _usernameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                autofillHints: const [AutofillHints.newPassword],
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                autofillHints: const [AutofillHints.newPassword],
                controller: _repasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '确认密码',
                  border: OutlineInputBorder(),
                ),
                onEditingComplete: () => TextInput.finishAutofillContext(),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onRegister,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('注册'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('已有账号？去登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final repassword = _repasswordController.text;

    // 前端校验
    if (username.isEmpty || password.isEmpty || repassword.isEmpty) {
      _showError('请填写所有字段');
      return;
    }
    if (password != repassword) {
      _showError('两次输入的密码不一致');
      return;
    }

    setState(() => _isLoading = true);

    final completer = Completer<bool>();

    CgiUser().register(username, password, repassword)
      .onSuccess((user) async {
        // 注册成功 - 服务端会自动登录，更新全局状态
        ref.read(loginStateProvider.notifier).login();

        if (!completer.isCompleted) {
          completer.complete(true);
        }

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (_) => const MainPage()),
            (route) => false,
          );
        }
      })
      .onFail((errorCode, errorMsg) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        _showError(errorMsg);
      });

    await completer.future;
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('注册失败'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
