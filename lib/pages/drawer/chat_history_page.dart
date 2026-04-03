import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/ai/services/chat_history_db.dart';
import 'package:notes_app/ai/models/chat_history.dart';
import 'package:notes_app/ai/ui/article_webview_page.dart';
import 'package:notes_app/utils/app_colors.dart';

/// AI 对话历史页面
class ChatHistoryPage extends ConsumerStatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  ConsumerState<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends ConsumerState<ChatHistoryPage> {
  final _db = ChatHistoryDatabase();
  List<ChatHistory> _histories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 365) {
      return '${diff.inDays ~/ 365}年前';
    } else if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}个月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  Future<void> _loadHistories() async {
    setState(() => _isLoading = true);
    try {
      final histories = await _db.getAllChatHistories();
      setState(() {
        _histories = histories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showError('加载失败: $e');
      }
    }
  }

  Future<void> _deleteHistory(ChatHistory history) async {
    try {
      await _db.deleteChatHistory(history.articleUrl);
      await _loadHistories();
      if (mounted) {
        _showSuccess('已删除');
      }
    } catch (e) {
      if (mounted) {
        _showError('删除失败: $e');
      }
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await _showConfirmDialog(
      '确认清空',
      '确定要清空所有对话历史吗？此操作不可恢复。',
    );
    
    if (confirmed != true) return;

    try {
      await _db.clearAllHistory();
      await _loadHistories();
      if (mounted) {
        _showSuccess('已清空所有历史');
      }
    } catch (e) {
      if (mounted) {
        _showError('清空失败: $e');
      }
    }
  }

  void _openArticle(ChatHistory history) {
    // 判断是否为纯对话（占位符URL），纯对话不能打开文章
    if (history.articleUrl.startsWith('plain_chat_')) {
      _showError('这是一个自定义对话，没有关联文章');
      return;
    }
    
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ArticleWebViewPage(
          url: history.articleUrl,
          title: history.articleTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('AI 对话历史'),
        trailing: _histories.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('清空', style: TextStyle(color: CupertinoColors.destructiveRed)),
                onPressed: _clearAll,
              )
            : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _histories.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: _loadHistories,
                    child: ListView.separated(
                      itemCount: _histories.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: AppColors.divider(context),
                      ),
                      itemBuilder: (context, index) {
                        final history = _histories[index];
                        return _buildHistoryItem(history);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 64,
            color: AppColors.secondaryText(context),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无对话历史',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ChatHistory history) {
    final messageCount = history.messages.length;
    final lastMessage = history.messages.isNotEmpty
        ? history.messages.last.content
        : '暂无消息';
    
    // 判断是否为纯对话（不可跳转文章）
    final isPlainChat = history.articleUrl.startsWith('plain_chat_');
    
    return Dismissible(
      key: Key(history.articleUrl),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: CupertinoColors.destructiveRed,
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.white,
        ),
      ),
      confirmDismiss: (direction) => _showConfirmDialog(
        '确认删除',
        '确定要删除这条对话历史吗？',
      ),
      onDismissed: (direction) => _deleteHistory(history),
      child: CupertinoListTile(
        onTap: () => _openArticle(history),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Row(
          children: [
            // 图标：区分文章对话和纯对话
            Icon(
              isPlainChat ? CupertinoIcons.chat_bubble_text : CupertinoIcons.doc_text,
              size: 16,
              color: isPlainChat 
                ? AppColors.tertiaryText(context) 
                : CupertinoColors.activeBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                history.articleTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText(context),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (history.articleAuthor != null && !isPlainChat)
              Text(
                history.articleAuthor!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.tertiaryText(context),
                ),
              ),
            if (history.articleAuthor != null && !isPlainChat)
              const SizedBox(height: 4),
            Text(
              lastMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  CupertinoIcons.chat_bubble,
                  size: 14,
                  color: AppColors.tertiaryText(context),
                ),
                const SizedBox(width: 4),
                Text(
                  '$messageCount 条消息',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.tertiaryText(context),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  CupertinoIcons.time,
                  size: 14,
                  color: AppColors.tertiaryText(context),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(history.updatedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.tertiaryText(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isPlainChat 
          ? null  // 纯对话不显示箭头，表示不可跳转
          : const CupertinoListTileChevron(),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
