import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/pages/article/search_results_page.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/mcm_widget.dart';

import '../../local/SearchHistoryManager.dart';
import '../../remote/Api.dart';
import '../../remote/CgiArticle.dart';

// 使用Riverpod的FutureProvider来处理网络请求
final hotKeysProvider = FutureProvider<List<HotKeyItem>>((ref) async {
  final data = CgiArticle().fetchHotKey();
  return data;
});

final searchHistoryProvider = FutureProvider<List<String>>((ref) async {
  return await SearchHistoryManager.getSearchHistory();
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) return;

    SearchHistoryManager.addSearchHistory(keyword);
    // 跳转到搜索结果页面
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => SearchResultsPage(keyword: keyword),
      ),
    );
  }

  void _onKeywordTap(String keyword) {
    _unfocus();
    _onSearch(keyword);
    ref.invalidate(searchHistoryProvider);
  }

  void _clearSearchHistory() async {
    await SearchHistoryManager.clearSearchHistory();
    ref.invalidate(searchHistoryProvider);
  }

  void _removeHistoryItem(String keyword) async {
    await SearchHistoryManager.removeSearchHistory(keyword);
    ref.invalidate(searchHistoryProvider);
  }

  //落下键盘
  void _unfocus() {
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final hotKeysAsync = ref.watch(hotKeysProvider);
    final searchHistoryAsync = ref.watch(searchHistoryProvider);

    return Scaffold(
      backgroundColor: MCMColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: hotKeysAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('加载失败: $error')),
                data: (hotKeys) => searchHistoryAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('加载失败: $error')),
                  data: (searchHistory) =>
                      _buildContent(hotKeys, searchHistory),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final bg = MCMColors.background(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: divColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divColor, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '搜索文章',
                  hintStyle: TextStyle(color: subColor.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: MCMColors.orange.withOpacity(0.6)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: subColor),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _onSearch,
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: MCMColors.orange, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<HotKeyItem> hotKeys, List<String> searchHistory) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchHistory.isNotEmpty) ...[
            _buildSectionTitle('搜索历史', onClear: _clearSearchHistory),
            const SizedBox(height: 12),
            _buildHistoryChips(searchHistory),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle('热门搜索'),
          const SizedBox(height: 12),
          _buildHotKeyChips(hotKeys),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onClear}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MCMSectionLabel(title.toUpperCase()),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: Text(
              '清空',
              style: TextStyle(color: MCMColors.coral, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryChips(List<String> searchHistory) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: searchHistory.map((keyword) {
        return PressableScale(
          scaleDown: 0.93,
          onTap: () => _onKeywordTap(keyword),
          child: Chip(
            label: Text(keyword),
            backgroundColor: MCMColors.card(context),
            labelStyle: TextStyle(color: MCMColors.primaryText(context), fontSize: 14),
            side: BorderSide(color: MCMColors.dividerColor(context)),
            deleteIcon: Icon(Icons.close, size: 16, color: MCMColors.secondaryText(context)),
            onDeleted: () => _removeHistoryItem(keyword),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHotKeyChips(List<HotKeyItem> hotKeys) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hotKeys.map((hotKey) {
        return PressableScale(
          scaleDown: 0.93,
          onTap: () => _onKeywordTap(hotKey.name),
          child: ActionChip(
            label: Text(hotKey.name),
            backgroundColor: Colors
                .primaries[hotKey.name.hashCode % Colors.primaries.length]
                .withOpacity(0.12),
            labelStyle: TextStyle(
                color: Colors
                    .primaries[hotKey.name.hashCode % Colors.primaries.length],
                fontSize: 14),
            onPressed: () => _onKeywordTap(hotKey.name),
          ),
        );
      }).toList(),
    );
  }
}
