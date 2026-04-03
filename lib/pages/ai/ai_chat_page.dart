import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:notes_app/ai/models/article_content.dart';
import 'package:notes_app/ai/models/chat_history.dart';
import 'package:notes_app/ai/models/chat_message.dart';
import 'package:notes_app/ai/providers/ai_chat_provider.dart';
import 'package:notes_app/ai/services/chat_history_db.dart';
import 'package:notes_app/ai/ui/ai_provider_management_page.dart';
import 'package:notes_app/model/note.dart';
import 'package:notes_app/providers/note_provider.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/app_colors.dart';
import 'package:notes_app/utils/functions.dart';
import 'package:share_plus/share_plus.dart';

/// 主页 AI 对话 Tab
class AIChatPage extends ConsumerStatefulWidget {
  const AIChatPage({super.key});

  @override
  ConsumerState<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends ConsumerState<AIChatPage> {
  final _db = ChatHistoryDatabase();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<ChatHistory> _histories = [];
  ChatHistory? _currentHistory;
  bool _isLoading = true;
  bool _hasLoadedOnce = false; // 标记是否已加载过一次
  int _lastMessageCount = 0; // 记录上次消息数量
  bool _autoScroll = true; // 自动滚动开关
  bool _isPlainChat = false; // 当前对话是否为纯对话模式

  @override
  void initState() {
    super.initState();
    _loadHistories();
    _scrollController.addListener(_onScrollChange);
  }

  void _onScrollChange() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 50;

    // 用户手动上滑：禁用自动滚动
    if (_autoScroll && !isAtBottom) {
      setState(() => _autoScroll = false);
    }

    // 用户滑到底部：恢复自动滚动
    if (!_autoScroll && isAtBottom) {
      setState(() => _autoScroll = true);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistories() async {
    setState(() => _isLoading = true);
    try {
      final histories = await _db.getAllChatHistories();
      final shouldScrollToBottom = !_hasLoadedOnce && histories.isNotEmpty;

      setState(() {
        _histories = histories;
        // 只在首次加载且无当前对话时，自动选择第一个
        if (!_hasLoadedOnce &&
            _histories.isNotEmpty &&
            _currentHistory == null) {
          _currentHistory = _histories.first;
        }
        _isLoading = false;
        _hasLoadedOnce = true; // 标记已加载
      });

      // 首次加载且有历史记录时，滚动到底部
      if (shouldScrollToBottom) {
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 对话切换 key（用于 AnimatedSwitcher 过渡动画）
  Key _chatAreaKey = UniqueKey();

  void _switchHistory(ChatHistory history) {
    setState(() {
      _currentHistory = history;
      // 判断是否为纯对话模式（通过 platform 判断）
      _isPlainChat = history.articleUrl.startsWith('plain_chat_');
      // 更新 key 触发 AnimatedSwitcher 过渡动画
      _chatAreaKey = UniqueKey();
    });
    // 滚动到底部
    _scrollToBottom();
  }

  /// 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 显示历史对话列表（底部弹出）
  void _showHistoryBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // 拖拽指示条
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // 标题栏
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '对话历史',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_histories.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _createNewChat();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.add, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('新建', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.divider(context)),
                  // 历史列表
                  Expanded(
                    child: _histories.isEmpty
                        ? Center(
                            child: Text(
                              '暂无对话历史',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryText(context),
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _histories.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final history = _histories[index];
                              final isSelected = _currentHistory?.articleUrl == history.articleUrl;
                              final isPlainChat = _isPlainChatHistory(history);
                              return AnimatedListItem(
                                index: index,
                                duration: const Duration(milliseconds: 300),
                                slideOffset: 20.0,
                                child: _HistorySheetItem(
                                history: history,
                                isSelected: isSelected,
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _switchHistory(history);
                                },
                                onRename: isPlainChat
                                    ? () {
                                        Navigator.pop(sheetContext);
                                        _renameChat(history);
                                      }
                                    : null,
                                onDelete: () async {
                                  await _db.deleteChatHistory(history.articleUrl);
                                  if (_currentHistory?.articleUrl == history.articleUrl) {
                                    setState(() => _currentHistory = null);
                                  }
                                  await _loadHistories();
                                  if (mounted) Navigator.pop(sheetContext);
                                },
                              ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty || _currentHistory == null) return;

    // 纯对话模式：直接使用 plainChatProvider
    if (_isPlainChat) {
      ref
          .read(plainChatProvider(_currentHistory!.articleUrl).notifier)
          .sendMessage(content);
    } else {
      // 文章对话模式：使用 aiChatProvider
      final article = ArticleContent.create(
        title: _currentHistory!.articleTitle,
        content: '',
        author: _currentHistory!.articleAuthor,
        url: _currentHistory!.articleUrl,
        platform: '对话历史',
      );
      ref.read(aiChatProvider(article).notifier).sendMessage(content);
    }

    _inputController.clear();
    _focusNode.unfocus();

    // 自动滚动到底部（无需刷新历史）
    _scrollToBottom();
  }

  /// 新建对话
  void _createNewChat() {
    final chatId = 'plain_chat_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _currentHistory = ChatHistory(
        articleTitle: '新对话',
        articleAuthor: '',
        articleUrl: chatId,
        createdAt: DateTime.now(),
        messages: [],
        updatedAt: DateTime.now(),
      );
      _isPlainChat = true; // 标记为纯对话模式
    });
  }

  /// 重命名对话
  Future<void> _renameChat(ChatHistory history) async {
    final controller = TextEditingController(text: history.articleTitle);
    final String? newTitle;

    if (Platform.isIOS) {
      // iOS 使用 Cupertino 风格弹窗
      newTitle = await showCupertinoDialog<String>(
        context: context,
        builder: (dialogContext) {
          return CupertinoAlertDialog(
            title: const Text('重命名对话'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: controller,
                placeholder: '输入新名称',
                autofocus: true,
                maxLength: 30,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    Navigator.pop(dialogContext, text);
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    } else {
      // Android 使用 Material 风格弹窗
      newTitle = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('重命名对话'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '输入新名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              maxLength: 30,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    Navigator.pop(dialogContext, text);
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    }

    if (!mounted) return;

    if (newTitle != null && newTitle != history.articleTitle) {
      await _db.updateChatTitle(history.articleUrl, newTitle);
      if (!mounted) return;
      // 更新本地状态
      setState(() {
        if (_currentHistory?.articleUrl == history.articleUrl) {
          _currentHistory = _currentHistory!.copyWith(articleTitle: newTitle);
        }
        final idx = _histories.indexWhere((h) => h.articleUrl == history.articleUrl);
        if (idx != -1) {
          _histories[idx] = _histories[idx].copyWith(articleTitle: newTitle);
        }
      });
    }
    // 注意：不要手动 dispose controller，弹窗退出动画期间 TextField 仍在引用它，
    // GC 会在弹窗完全销毁后自动回收。
  }

  /// 判断对话是否为用户手动创建的（纯对话模式）
  bool _isPlainChatHistory(ChatHistory history) {
    return history.articleUrl.startsWith('plain_chat_');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        color: AppColors.backgroundColor(context),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_histories.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Container(
      color: AppColors.backgroundColor(context),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部工具栏
            _buildTopBar(isDark),

            // 对话区域（带切换过渡动画）
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: _currentHistory == null
                    ? _buildSelectHint(isDark)
                    : KeyedSubtree(
                        key: _chatAreaKey,
                        child: _buildChatArea(isDark),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部工具栏
  Widget _buildTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 历史列表按钮（底部弹出）
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _showHistoryBottomSheet,
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 20,
                  color: AppColors.secondaryText(context),
                ),
                const SizedBox(width: 6),
                Text(
                  '历史',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.secondaryText(context),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 当前对话标题（带切换动画）
          if (_currentHistory != null)
            Expanded(
              flex: 3,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _isPlainChat
                    // 纯对话模式：可点击重命名
                    ? GestureDetector(
                        key: ValueKey('title_${_currentHistory!.articleUrl}'),
                        onTap: () => _renameChat(_currentHistory!),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _currentHistory!.articleTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.pencil,
                              size: 14,
                              color: AppColors.secondaryText(context),
                            ),
                          ],
                        ),
                      )
                    // 文章对话模式：可点击，带下划线样式
                    : GestureDetector(
                        key: ValueKey('title_${_currentHistory!.articleUrl}'),
                        onTap: () => _openArticle(_currentHistory!),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _currentHistory!.articleTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText(context),
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              CupertinoIcons.link,
                              size: 12,
                              color: AppColors.secondaryText(context),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

          const Spacer(),

          // 新建对话按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _createNewChat,
            child: Icon(
              CupertinoIcons.plus_square,
              size: 20,
              color: AppColors.secondaryText(context),
            ),
          ),

          const SizedBox(width: 12),

          // 刷新按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: _loadHistories,
            child: Icon(
              CupertinoIcons.refresh,
              size: 20,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }



  /// 对话区域
  Widget _buildChatArea(bool isDark) {
    // 纯对话模式：使用 plainChatProvider
    if (_isPlainChat) {
      final chatState =
          ref.watch(plainChatProvider(_currentHistory!.articleUrl));

      if (chatState.error != null) {
        return _buildConfigError(isDark, chatState.error!);
      }

      // 智能滚动（监听消息变化）
      _scrollToBottomIfNeeded(chatState.messages);

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: Stack(
            children: [
              chatState.messages.isEmpty
                  ? _buildPlainChatPresets(isDark)
                  : _buildMessageList(chatState.messages, isDark),
              // "回到底部" 浮动按钮
              if (!_autoScroll && chatState.messages.isNotEmpty)
                _buildScrollToBottomButton(),
            ],
          ),
        ),

        // 输入框
        _buildInputBar(chatState, isDark),
      ],
    );
    }

    // 文章对话模式：使用 aiChatProvider
    final article = ArticleContent.create(
      title: _currentHistory!.articleTitle,
      content: '',
      author: _currentHistory!.articleAuthor,
      url: _currentHistory!.articleUrl,
      platform: '对话历史',
    );

    final chatState = ref.watch(aiChatProvider(article));

    if (chatState.error != null) {
      return _buildConfigError(isDark, chatState.error!);
    }

    // 智能滚动（监听消息变化）
    _scrollToBottomIfNeeded(chatState.messages);

    return Column(
      children: [
        // 消息列表
        Expanded(
          child: Stack(
            children: [
              chatState.messages.isEmpty
                  ? _buildPresetQuestions(article, isDark)
                  : _buildMessageList(chatState.messages, isDark),
              // "回到底部" 浮动按钮
              if (!_autoScroll && chatState.messages.isNotEmpty)
                _buildScrollToBottomButton(),
            ],
          ),
        ),

        // 输入框
        _buildInputBar(chatState, isDark),
      ],
    );
  }

  Widget _buildConfigError(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请前往设置配置 AI 服务后使用',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const AIProviderManagementPage(),
                  ),
                );
              },
              child: const Text('去配置'),
            ),
          ],
        ),
      ),
    );
  }

  /// 智能滚动（检测消息变化和流式内容）
  void _scrollToBottomIfNeeded(List<ChatMessage> messages) {
    if (!_autoScroll) return;

    final currentMessageCount = messages.length;
    final hasNewContent = currentMessageCount > _lastMessageCount ||
        (messages.isNotEmpty &&
            messages.last.status == MessageStatus.streaming);

    if (hasNewContent && _scrollController.hasClients) {
      _lastMessageCount = currentMessageCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted && _autoScroll) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  /// 预设问题（文章对话模式）—— 带交错入场动画
  Widget _buildPresetQuestions(ArticleContent article, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: PresetQuestion.defaults.length,
      itemBuilder: (context, index) {
        final preset = PresetQuestion.defaults[index];
        return AnimatedListItem(
          index: index,
          duration: const Duration(milliseconds: 350),
          slideOffset: 25.0,
          child: _PresetQuestionCard(
            preset: preset,
            isDark: isDark,
            onTap: () {
              ref
                  .read(aiChatProvider(article).notifier)
                  .sendMessage(preset.prompt);
              _scrollToBottom();
            },
          ),
        );
      },
    );
  }

  /// 预设问题（纯对话模式）—— 带交错入场动画
  Widget _buildPlainChatPresets(bool isDark) {
    final presets = [
      PresetQuestion(
        icon: '💬',
        title: '开始聊天',
        prompt: '你好，我想和你聊聊天',
      ),
      PresetQuestion(
        icon: '🤔',
        title: '帮我解答问题',
        prompt: '我有一个问题想请教你',
      ),
      PresetQuestion(
        icon: '✍️',
        title: '帮我写点东西',
        prompt: '你能帮我写点内容吗？',
      ),
      PresetQuestion(
        icon: '💡',
        title: '给我一些建议',
        prompt: '我需要一些建议和想法',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        return AnimatedListItem(
          index: index,
          duration: const Duration(milliseconds: 350),
          slideOffset: 25.0,
          child: _PresetQuestionCard(
            preset: preset,
            isDark: isDark,
            onTap: () {
              ref
                  .read(plainChatProvider(_currentHistory!.articleUrl).notifier)
                  .sendMessage(preset.prompt);
              _scrollToBottom();
            },
          ),
        );
      },
    );
  }

  /// "回到底部" 浮动按钮（带淡入+滑入动画）
  Widget _buildScrollToBottomButton() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: GestureDetector(
          onTap: () {
            setState(() => _autoScroll = true);
            _scrollToBottom();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.arrow_down,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// 消息列表
  Widget _buildMessageList(List<ChatMessage> messages, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return AnimatedListItem(
          index: index,
          duration: const Duration(milliseconds: 300),
          slideOffset: 20.0,
          child: _MessageBubble(
          message: message,
          isDark: isDark,
          onCopy: () => _copyMessage(message.content),
          onSaveToNote: message.role == ChatRole.assistant
              ? () => _saveToNote(message)
              : null,
          onShare: message.role == ChatRole.assistant
              ? () => _shareMessage(message)
              : null,
        ),
        );
      },
    );
  }

  /// 保存消息到笔记
  void _saveToNote(ChatMessage message) {
    try {
      final now = DateTime.now();
      final title = _currentHistory?.articleTitle ?? 'AI 对话';
      final url = _currentHistory?.articleUrl ?? '';

      // 构建笔记内容
      final StringBuffer contentBuffer = StringBuffer();
      contentBuffer.writeln('📌 来自：$title');
      contentBuffer.writeln('⏰ 收藏时间：${_formatDateTime(now)}');
      if (url.isNotEmpty && !url.startsWith('plain_chat_')) {
        contentBuffer.writeln('🔗 原文链接：$url');
      }
      contentBuffer.writeln('\n---\n');
      contentBuffer.writeln(message.content);

      final note = Note(
        id: '',
        content: contentBuffer.toString(),
        date: now,
        lastModified: now,
      );

      ref.read(noteProvider.notifier).addNote(note);

      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已剪藏到笔记'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('剪藏失败: $e')),
      );
    }
  }

  /// 分享消息
  void _shareMessage(ChatMessage message) {
    final title = _currentHistory?.articleTitle ?? 'AI 对话';
    final url = _currentHistory?.articleUrl ?? '';

    final StringBuffer shareText = StringBuffer();
    shareText.writeln('💬 $title');
    if (url.isNotEmpty && !url.startsWith('plain_chat_')) {
      shareText.writeln('🔗 $url');
    }
    shareText.writeln('\n${message.content}');

    Share.share(
      shareText.toString(),
      subject: 'AI 对话分享',
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 输入框
  Widget _buildInputBar(AIChatState chatState, bool isDark) {
    // 计算底部安全区域：SafeArea 底部 + TabBar 高度
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + 70; // TabBar 约 70px 高度

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: bottomPadding, // 确保不被 TabBar 遮挡
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        border: Border(
          top: BorderSide(
            color: AppColors.divider(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _focusNode,
                enabled: !chatState.isLoading,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.primaryText(context),
                ),
                decoration: InputDecoration(
                  hintText: '问我任何问题...',
                  hintStyle: TextStyle(
                    color: AppColors.secondaryText(context),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 发送按钮（带按压缩放反馈）
          PressableScale(
            onTap: chatState.isLoading
                ? null
                : () => _sendMessage(_inputController.text),
            scaleDown: 0.9,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: chatState.isLoading
                    ? AppColors.secondaryText(context)
                    : Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: chatState.isLoading
                  ? const CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 10,
                    )
                  : const Icon(
                      CupertinoIcons.arrow_up,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState(bool isDark) {
    return Container(
      color: AppColors.backgroundColor(context),
      child: Center(
        child: FadeSlideIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulseAnimation(
                child: Icon(
                  CupertinoIcons.chat_bubble_2,
                  size: 80,
                  color: AppColors.secondaryText(context),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              '暂无对话历史',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在文章中与 AI 对话后\n历史记录会显示在这里',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 32),
            // 新建对话按钮
            CupertinoButton(
              onPressed: _createNewChat,
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(CupertinoIcons.add, size: 20),
                  SizedBox(width: 8),
                  Text('新建对话', style: TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
  /// 未选择对话时的提示
  Widget _buildSelectHint(bool isDark) {
    return Center(
      child: FadeSlideIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulseAnimation(
              child: Icon(
                CupertinoIcons.chat_bubble_2,
                size: 64,
                color: AppColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '选择一个对话开始',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方「历史」查看对话记录',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText(context),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              onPressed: _createNewChat,
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text('新建对话', style: TextStyle(fontSize: 14, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// 打开文章页面
  void _openArticle(ChatHistory history) {
    launchInApp(context, Uri.parse(history.articleUrl));
  }
}

/// BottomSheet 中的历史对话项
class _HistorySheetItem extends StatelessWidget {
  final ChatHistory history;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onRename;

  const _HistorySheetItem({
    required this.history,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final isPlainChat = history.articleUrl.startsWith('plain_chat_');
    final primaryColor = Theme.of(context).primaryColor;

    return PressableScale(
      onTap: onTap,
      onLongPress: isPlainChat && onRename != null ? onRename : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.08)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? primaryColor.withOpacity(0.3)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 左侧图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPlainChat
                    ? primaryColor.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPlainChat
                    ? CupertinoIcons.chat_bubble_fill
                    : CupertinoIcons.doc_text_fill,
                size: 18,
                color: isPlainChat ? primaryColor : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            // 中间内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.articleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.bubble_left,
                        size: 11,
                        color: AppColors.secondaryText(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${history.messages.length} 条消息',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                      if (isPlainChat) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '自由对话',
                            style: TextStyle(
                              fontSize: 10,
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '文章',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 右侧操作
            if (isSelected)
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 20,
                color: primaryColor,
              )
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: onDelete,
                child: Icon(
                  CupertinoIcons.trash,
                  size: 16,
                  color: AppColors.secondaryText(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 预设问题卡片
class _PresetQuestionCard extends StatelessWidget {
  final PresetQuestion preset;
  final bool isDark;
  final VoidCallback onTap;

  const _PresetQuestionCard({
    required this.preset,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(preset.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    preset.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.arrow_right,
                  size: 16,
                  color: AppColors.secondaryText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息气泡
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;
  final VoidCallback onCopy;
  final VoidCallback? onSaveToNote;
  final VoidCallback? onShare;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.onCopy,
    this.onSaveToNote,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, isUser),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).primaryColor
                          : (isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _buildContent(context, isUser),
                  ),
                ),

                // 操作按钮（仅 AI 消息）—— 带延迟淡入动画
                if (!isUser && message.status == MessageStatus.completed)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 350),
                    slideOffset: 10.0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 复制按钮
                        _buildActionButton(
                          context: context,
                          icon: CupertinoIcons.doc_on_doc,
                          label: '复制',
                          onPressed: onCopy,
                        ),
                        const SizedBox(width: 16),
                        // 剪藏按钮（收藏到笔记）
                        if (onSaveToNote != null)
                          _buildActionButton(
                            context: context,
                            icon: message.isLiked
                                ? CupertinoIcons.bookmark_fill
                                : CupertinoIcons.bookmark,
                            label: '剪藏',
                            onPressed: onSaveToNote!,
                            isActive: message.isLiked,
                          ),
                        if (onSaveToNote != null) const SizedBox(width: 16),
                        // 分享按钮
                        if (onShare != null)
                          _buildActionButton(
                            context: context,
                            icon: CupertinoIcons.share,
                            label: '分享',
                            onPressed: onShare!,
                          ),
                      ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildAvatar(context, isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? Theme.of(context).primaryColor
          : (isDark ? Colors.grey[700] : Colors.grey[300]),
      child: Icon(
        isUser ? CupertinoIcons.person : CupertinoIcons.sparkles,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
                isActive ? Colors.amber[700] : AppColors.secondaryText(context),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive
                  ? Colors.amber[700]
                  : AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser) {
    final textColor = isUser ? Colors.white : AppColors.primaryText(context);

    if (message.status == MessageStatus.thinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('思考中', style: TextStyle(color: textColor, fontSize: 14)),
          const SizedBox(width: 8),
          TypingIndicator(color: textColor, dotSize: 6.0, spacing: 3.0),
        ],
      );
    }

    return MarkdownBody(
      data: message.content,
      selectable: message.status == MessageStatus.completed,
      fitContent: isUser, // 用户消息靠右收缩，AI 消息撑满可用宽度防止溢出
      shrinkWrap: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(fontSize: 15, height: 1.6, color: textColor),
        code: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          backgroundColor: isUser
              ? Colors.black.withOpacity(0.15)
              : (isDark ? Colors.grey[900]! : Colors.grey[200]!),
          color: textColor,
        ),
        codeblockDecoration: BoxDecoration(
          color: isUser
              ? Colors.black.withOpacity(0.15)
              : (isDark ? Colors.grey[900]! : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        // 约束表格列宽，防止表格溢出
        tableColumnWidth: const IntrinsicColumnWidth(),
      ),
      extensionSet: md.ExtensionSet.gitHubFlavored,
    );
  }
}
