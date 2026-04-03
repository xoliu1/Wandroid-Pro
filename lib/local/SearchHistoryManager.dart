
import 'KV.dart';

class SearchHistoryManager {
  static const String _keyPrefix = 'search_history_';
  static const int _maxHistory = 10;

  // 添加搜索历史
  static Future<void> addSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;

    final histories = await getSearchHistory();

    // 移除已存在的相同关键词
    histories.removeWhere((item) => item.toLowerCase() == keyword.toLowerCase());

    // 添加到最前面
    histories.insert(0, keyword);

    // 限制历史记录数量
    if (histories.length > _maxHistory) {
      histories.removeLast();
    }

    // 保存到MMKV
    final jsonString = histories.join('|');
    Kv.encodeString(_keyPrefix, jsonString);
  }

  // 获取搜索历史
  static Future<List<String>> getSearchHistory() async {
    final jsonString = Kv.decodeString(_keyPrefix) ?? '';
    if (jsonString.isEmpty) return [];

    return jsonString.split('|').where((item) => item.isNotEmpty).toList();
  }

  // 清除搜索历史
  static Future<void> clearSearchHistory() async {
    Kv.removeValue(_keyPrefix);
  }

  // 删除单个搜索历史
  static Future<void> removeSearchHistory(String keyword) async {
    final histories = await getSearchHistory();
    histories.removeWhere((item) => item == keyword);

    final jsonString = histories.join('|');
    Kv.encodeString(_keyPrefix, jsonString);
  }
}