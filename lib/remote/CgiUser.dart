import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../local/KV.dart';
import '../model/login/User.dart';
import 'service/NerworkService.dart';

import 'Api.dart';


class CgiUser {
  /// 用户登录
  ///
  /// 通过用户名和密码发起登录请求，成功后自动保存 Cookie 与用户信息
  NetworkCall<User> login(String username, String password) {
    return NetworkService.post(
      url: URL_LOGIN,
      fromJsonT: User.fromJson,
      data: {
        "username": username,
        "password": password,
      },
    ).onSuccess((data){
      loginLocal(true);
    }).onFail((code, msg){
      loginLocal(false);
    });
  }


  /// 处理登录响应头，提取并保存 Cookie 及其过期时间
  @Deprecated("用CookieJar")
  Future<void> _handleLoginResponse(resp) async {
    var cookie = (resp as Response).headers['set-cookie'];
    // _saveCookie(
    //     json.encode((cookie?.join() ?? ''))
    //     .replaceAll("[\"", "")
    //     .replaceAll("\"]", "")
    //     .replaceAll("\",\"", "; ") );
  }

  /// 用户注册
  ///
  /// 通过用户名、密码和确认密码发起注册请求，注册成功后自动登录（服务端会返回 Cookie）
  NetworkCall<User> register(String username, String password, String repassword) {
    return NetworkService.post(
      url: URL_REGISTER,
      fromJsonT: User.fromJson,
      data: {
        "username": username,
        "password": password,
        "repassword": repassword,
      },
    ).onSuccess((data) {
      loginLocal(true);
    }).onFail((code, msg) {
      loginLocal(false);
    });
  }

  /// 检查登录态是否有效
  ///
  /// 通过请求用户信息接口来验证当前 Cookie 是否仍然有效。
  /// 返回 true 表示登录态有效，false 表示已过期。
  Future<bool> checkSessionValid() async {
    if (!isLogin()) return false;
    
    try {
      await NetworkService.get<UserInfoResp>(
        url: URL_USER_INFO,
        fromJsonT: UserInfoResp.fromJson,
      ).getData();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('检查登录态失败: $e');
      }
      return false;
    }
  }

  /// 清理过期的登录态
  ///
  /// 清除本地用户数据 + Cookie，供每日检查使用
  Future<void> clearExpiredSession() async {
    _clearLocalUserData();
    await NetworkService.clearCookies();
  }

  /// 退出登录
  ///
  /// 调用服务端退出接口，服务端会返回 Set-Cookie 头部（max-age=0）来清除 Cookie。
  /// PersistCookieJar 会自动处理这个响应，清除对应的 Cookie。
  /// 同时清理本地存储的用户信息和登录状态。
  /// 
  /// 注意：退出成功后，需要在 UI 层调用 ref.read(loginStateProvider.notifier).logout()
  /// 来更新全局登录状态，这样所有监听登录状态的 Widget 都会自动重建
  Future<void> logout() async {
    try {
      // 1. 调用服务端退出接口（服务端会返回 max-age=0 的 Cookie 清除指令）
      // 注意：退出登录接口返回 data: null，使用 getDataOrDefault 允许 null 值
      await NetworkService.get(url: URL_LOGOUT).getDataOrDefault(null);
      
      // 2. 清理本地登录状态和用户信息
      _clearLocalUserData();
      
      if (kDebugMode) {
        print('退出登录成功');
      }
      
    } catch (e) {
      // 即使网络请求失败，也要清理本地数据
      if (kDebugMode) {
        print('退出登录请求失败: $e，但仍会清理本地数据');
      }
      _clearLocalUserData();
      rethrow;
    }
  }

  /// 清理本地用户数据
  ///
  /// 清理所有与用户相关的本地存储数据
  void _clearLocalUserData() {
    // 清除登录状态
    loginLocal(false);
    
    // 清除用户信息缓存
    Kv.removeValue(KEY_USER_INFO);
    
    // 清除 Cookie 过期时间记录（如果有的话）
    Kv.removeValue(KEY_COOKIE_EXPIRED);
    
    // 清除跳过登录标记（退出登录后重新显示登录页面）
    setSkipLogin(false);
    
    if (kDebugMode) {
      print('本地用户数据已清理');
    }
  }


}


Future<UserInfoResp> getUserInfo() async {
  // 1. 先从本地缓存取
  final cache = Kv.decodeString(KEY_USER_INFO);
  if (cache != null && cache.isNotEmpty) {
    try {
      final jsonMap = jsonDecode(cache) as Map<String, dynamic>;
      return UserInfoResp.fromJson(jsonMap);
    } catch (e) {
      // 如果解析失败，继续走网络
      print("cache parse error: $e");
    }
  }

  // 2. 本地没有 -> 走网络
  final resp = await NetworkService.get<UserInfoResp>(
    url: URL_USER_INFO,
    fromJsonT: UserInfoResp.fromJson,
  ).onSuccess((resp) {
    // 3. 保存到本地
    Kv.encodeString(KEY_USER_INFO, jsonEncode(resp.toJson()));
  }).getData();

  return resp;
}
