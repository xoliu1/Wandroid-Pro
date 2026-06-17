import 'dart:convert';
import 'dart:io';

import 'package:mmkv/mmkv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../remote/Api.dart';

const KEY_USER_LOGINED = 'user_logined';

const KEY_COOKIE_EXPIRED = 'cookie_expired';

const KEY_USER_INFO = 'user_info';

const KEY_SKIP_LOGIN = 'skip_login'; // 用户是否选择跳过登录

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

// ─── 桌面端 KV 适配层 ────────────────────────────────────────────────────────
// MMKV 不支持 macOS/Windows/Linux，桌面端用 SharedPreferences 同步包装替代

/// 桌面端 KV 存储（用 SharedPreferences 同步包装）
/// 在 main() 中调用 DesktopKv.init() 预加载后，所有读写均为同步操作
class _DesktopKv {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool encodeBool(String key, bool value) {
    _prefs?.setBool(key, value);
    return true;
  }

  bool decodeBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  bool encodeString(String key, String value) {
    _prefs?.setString(key, value);
    return true;
  }

  String? decodeString(String key) {
    return _prefs?.getString(key);
  }

  bool encodeInt(String key, int value) {
    _prefs?.setInt(key, value);
    return true;
  }

  int decodeInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  bool removeValue(String key) {
    _prefs?.remove(key);
    return true;
  }
}

/// 初始化桌面端 KV（仅桌面平台调用）
Future<void> initDesktopKv() async {
  await _DesktopKv.init();
}

/// 全局 KV 存储实例
/// - 移动端（Android/iOS）：使用 MMKV（高性能）
/// - 桌面端（macOS/Windows/Linux）：使用 SharedPreferences 包装
dynamic get Kv {
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return _desktopKv;
  }
  return MMKV.defaultMMKV();
}

final _desktopKv = _DesktopKv();

void loginLocal(bool logined) {
  Kv.encodeBool(KEY_USER_LOGINED, logined);
}

bool isLogin() {
  return Kv
      .decodeBool(KEY_USER_LOGINED, defaultValue: false);
}

/// 设置跳过登录状态
void setSkipLogin(bool skip) {
  Kv.encodeBool(KEY_SKIP_LOGIN, skip);
}

/// 检查用户是否已选择跳过登录
bool hasSkippedLogin() {
  return Kv.decodeBool(KEY_SKIP_LOGIN, defaultValue: false);
}

/// 检查是否应该显示登录页面（未登录且未跳过登录）
bool shouldShowLogin() {
  return !isLogin() && !hasSkippedLogin();
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

// ─── AI Prompt 自定义配置 ────────────────────────────────────────────────────

/// AI Prompt 渠道 key 常量
/// 对应 ai_service.dart 中各 build*Messages 方法的 system prompt 角色描述部分
const kPromptChannelDailyReport   = 'prompt_daily_report';
const kPromptChannelArticleChat   = 'prompt_article_chat';
const kPromptChannelTodoAssistant = 'prompt_todo_assistant';
const kPromptChannelNoteContinue  = 'prompt_note_continue';
const kPromptChannelNotePolish    = 'prompt_note_polish';
const kPromptChannelQuestionExplain = 'prompt_question_explain';

/// 所有渠道的默认 prompt（角色描述部分）
const Map<String, String> kDefaultPrompts = {
  kPromptChannelDailyReport:
      '你是一个贴心的个人效率助手，负责为用户生成每日总结报告。\n请根据用户今天的活动数据，生成一份结构化的日报。',
  kPromptChannelArticleChat:
      '你是一个专业的技术文章分析助手。请基于用户正在阅读的文章内容回答用户的问题。',
  kPromptChannelTodoAssistant:
      '你是一个智能任务规划助手。你需要根据用户的上下文信息，帮助用户规划和管理待办事项。',
  kPromptChannelNoteContinue:
      '你是一个专业的写作助手。用户正在编辑一篇 Markdown 格式的笔记，请根据已有内容进行续写。\n'  
      '要求：\n'
      '1. 保持与原文一致的写作风格和语气\n'
      '2. 续写内容要自然衔接，逻辑连贯\n'
      '3. 输出纯 Markdown 格式，不要添加额外的解释说明\n'
      '4. 续写长度适中，约 100-300 字',
  kPromptChannelNotePolish:
      '你是一个专业的文字润色助手。请对用户提供的 Markdown 文本进行润色优化。\n'
      '要求：\n'
      '1. 保持原文的核心意思不变\n'
      '2. 优化语句表达，使其更加流畅、专业\n'
      '3. 修正语法错误和不通顺的地方\n'
      '4. 保持 Markdown 格式不变\n'
      '5. 直接输出润色后的完整文本，不要添加任何解释说明',
  kPromptChannelQuestionExplain:
      '你是一位资深 Android/Flutter 技术专家，擅长深入浅出地解答技术问题。\n'
      '用户会给你一道技术问答题，请给出详细、专业的解答。\n'
      '要求：\n'
      '1. 先用一句话简要概括答案要点\n'
      '2. 分点详细解释，每个要点都要有清晰的说明\n'
      '3. 如有必要给出代码示例（使用 Markdown 代码块）\n'
      '4. 使用 Markdown 格式输出\n'
      '5. 语言简洁专业，避免冗余',
};

/// 获取某渠道的自定义 prompt（没有自定义则返回 null）
String? getCustomPrompt(String channel) {
  return Kv.decodeString('custom_$channel');
}

/// 获取某渠道的有效 prompt（优先自定义，否则用默认值）
String getEffectivePrompt(String channel) {
  return getCustomPrompt(channel) ?? kDefaultPrompts[channel] ?? '';
}

/// 保存某渠道的自定义 prompt
void saveCustomPrompt(String channel, String prompt) {
  Kv.encodeString('custom_$channel', prompt);
}

/// 重置某渠道的 prompt 为默认值
void resetCustomPrompt(String channel) {
  Kv.removeValue('custom_$channel');
}

/// 是否有自定义 prompt
bool hasCustomPrompt(String channel) {
  final v = Kv.decodeString('custom_$channel');
  return v != null && v.isNotEmpty;
}