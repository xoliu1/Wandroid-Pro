import 'dart:convert';

import 'package:mmkv/mmkv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../remote/Api.dart';

const KEY_USER_LOGINED = 'user_logined';

const KEY_COOKIE_EXPIRED = 'cookie_expired';

const KEY_USER_INFO = 'user_info';

const keyThemeMode = "app_theme_mode";

const KEY_PAGE_LOAD_SIZE = 'page_size';


const KEY_AI_STYLE_MORPHING = 'ai_style_morphing';

const KEY_SHOW_EXTRACT_DEBUG_DIALOG = 'show_extract_debug_dialog';

const KEY_USE_NEW_TODO_UI = 'use_new_todo_ui';

const KEY_LAST_SESSION_CHECK_DATE = 'last_session_check_date';

/// AI 日报：上次生成日期
const KEY_DAILY_REPORT_DATE = 'daily_report_date';
/// AI 日报：上次生成的 JSON 内容
const KEY_DAILY_REPORT_CONTENT = 'daily_report_content';

/// 自定义强调色（存储 Color.value 的 int 值）
const KEY_ACCENT_COLOR = 'accent_color';

final Future<SharedPreferences> SP = SharedPreferences.getInstance();

final Kv = MMKV.defaultMMKV();

void loginLocal(bool logined) {
  Kv.encodeBool(KEY_USER_LOGINED, logined);
}

bool isLogin() {
  return Kv
      .decodeBool(KEY_USER_LOGINED, defaultValue: false);
}

UserInfoResp getUserProfile(){
  final jsonString = Kv.decodeString(KEY_USER_INFO) ?? '';
  if (jsonString.isNotEmpty) {
    return UserInfoResp.fromJson(jsonDecode(jsonString));
  }
  return defaultUserInfo;
}

/// 计划更换作为设置项，更换整个 app 的 pagesize，虽然有设置分页缓存、dio 的LRU缓存，还是有点慢
int getPageSize() {
  return Kv.decodeInt(KEY_PAGE_LOAD_SIZE, defaultValue: 10);
}

bool setPageSize(int size) {
  return Kv.encodeInt(KEY_PAGE_LOAD_SIZE, size);
}


/// 获取是否使用新版 AI 样式（Morphing 科技感）
bool getAIStyleMorphing() {
  return Kv.decodeBool(KEY_AI_STYLE_MORPHING, defaultValue: true);
}

/// 设置 AI 样式
bool setAIStyleMorphing(bool useMorphing) {
  return Kv.encodeBool(KEY_AI_STYLE_MORPHING, useMorphing);
}

/// 获取是否显示提取调试弹窗（仅 Debug 模式有效）
bool getShowExtractDebugDialog() {
  return Kv.decodeBool(KEY_SHOW_EXTRACT_DEBUG_DIALOG, defaultValue: false);
}

/// 设置是否显示提取调试弹窗
bool setShowExtractDebugDialog(bool show) {
  return Kv.encodeBool(KEY_SHOW_EXTRACT_DEBUG_DIALOG, show);
}

/// 获取是否使用新版待办界面
bool getUseNewTodoUI() {
  return Kv.decodeBool(KEY_USE_NEW_TODO_UI, defaultValue: true);
}

/// 设置是否使用新版待办界面
bool setUseNewTodoUI(bool useNew) {
  return Kv.encodeBool(KEY_USE_NEW_TODO_UI, useNew);
}

/// 判断今天是否已经检查过登录态
bool hasCheckedSessionToday() {
  final lastCheck = Kv.decodeString(KEY_LAST_SESSION_CHECK_DATE) ?? '';
  final today = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
  return lastCheck == today;
}

/// 标记今天已检查登录态
void markSessionCheckedToday() {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  Kv.encodeString(KEY_LAST_SESSION_CHECK_DATE, today);
}

/// 清除本地登录数据
void clearLocalLoginData() {
  // 清除登录状态
  loginLocal(false);
  Kv.removeValue(KEY_USER_INFO);  
  Kv.removeValue(KEY_COOKIE_EXPIRED);
}

/// 获取自定义强调色（返回 Color.value 的 int 值，默认 null 表示使用默认蓝色）
int? getAccentColorValue() {
  final value = Kv.decodeInt(KEY_ACCENT_COLOR, defaultValue: 0);
  return value == 0 ? null : value;
}

/// 设置自定义强调色
bool setAccentColorValue(int colorValue) {
  return Kv.encodeInt(KEY_ACCENT_COLOR, colorValue);
}

/// 重置为默认强调色
void resetAccentColor() {
  Kv.removeValue(KEY_ACCENT_COLOR);
}

/// 判断今天是否已经生成过日报
bool hasDailyReportToday() {
  final lastDate = Kv.decodeString(KEY_DAILY_REPORT_DATE) ?? '';
  final today = DateTime.now().toIso8601String().substring(0, 10);
  return lastDate == today;
}

/// 保存今日日报 JSON 内容
void saveDailyReport(String jsonContent) {
  final today = DateTime.now().toIso8601String().substring(0, 10);
  Kv.encodeString(KEY_DAILY_REPORT_DATE, today);
  Kv.encodeString(KEY_DAILY_REPORT_CONTENT, jsonContent);
}

/// 读取今日缓存的日报 JSON（如果不是今天则返回 null）
String? getTodayDailyReport() {
  if (!hasDailyReportToday()) return null;
  return Kv.decodeString(KEY_DAILY_REPORT_CONTENT);
}

/// 清除日报缓存
void clearDailyReport() {
  Kv.removeValue(KEY_DAILY_REPORT_DATE);
  Kv.removeValue(KEY_DAILY_REPORT_CONTENT);
}