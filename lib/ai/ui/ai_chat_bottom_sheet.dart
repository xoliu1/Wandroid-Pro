import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:notes_app/providers/note_provider.dart';

import '../models/article_content.dart';
import '../models/chat_message.dart';
import '../providers/ai_chat_provider.dart';
import '../../utils/mcm_widget.dart';

/// AI 对话 BottomSheet
/// 从底部弹出的对话界面，替代浮窗设计
class AIChatBottomSheet extends ConsumerStatefulWidget {
  final ArticleContent article;

  const AIChatBottomSheet({
    super.key,
    required this.article,
  });

  @override
  ConsumerState<AIChatBottomSheet> createState() => _AIChatBottomSheetState();

  /// 显示 BottomSheet
  static void show(BuildContext context, ArticleContent article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      transitionAnimationController: null,
      builder: (context) => AIChatBottomSheet(article: article),
    );
  }
}

class _AIChatBottomSheetState extends ConsumerState<AIChatBottomSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _showPresets = true;
  bool _autoScroll = true;
  bool _userScrolledUp = false;
  int _lastMessageCount = 0;
  bool _isFirstBuild = true; // 标记首次构建

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollChange);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScrollChange() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 50;

    if (_autoScroll && !isAtBottom && _userScrolledUp) {
      setState(() => _autoScroll = false);
    }

    if (!_autoScroll && isAtBottom) {
      setState(() => _autoScroll = true);
    }

    _userScrolledUp = position.pixels < position.maxScrollExtent - 100;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && mounted) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottomIfNeeded(List<ChatMessage> messages) {
    if (!_autoScroll) return;
    
    // 检查消息数量或内容变化
    final currentMessageCount = messages.length;
    final hasNewContent = currentMessageCount > _lastMessageCount ||
        (messages.isNotEmpty && messages.last.status == MessageStatus.streaming);
    
    if (hasNewContent && _scrollController.hasClients) {
      _lastMessageCount = currentMessageCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted && _autoScroll) {
          _scrollToBottom();
        }
      });
    }
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    setState(() {
      _showPresets = false;
      _autoScroll = true;
    });
    ref.read(aiChatProvider(widget.article).notifier).sendMessage(content);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(aiChatProvider(widget.article));
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // 首次构建完成后滚动到底部（等待 3 帧确保完全渲染）
    if (_isFirstBuild && chatState.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              // 使用 jumpTo 立即滚动，避免动画卡顿
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              setState(() => _isFirstBuild = false);
            }
          });
        });
      });
    } else if (_isFirstBuild) {
      // 如果没有消息，直接标记为已完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isFirstBuild = false);
        }
      });
    }

    // 智能滚动（监听消息列表变化）
    if (!_isFirstBuild) {
      _scrollToBottomIfNeeded(chatState.messages);
    }

    return Container(
      height: screenHeight * 0.85, // 占屏幕 85% 高度
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部拖拽条 + 标题栏
          _buildHeader(isDark),
          
          // 消息列表
          Expanded(
            child: chatState.messages.isEmpty && _showPresets
                ? _buildPresetQuestions(isDark)
                : _buildMessageList(chatState.messages, isDark),
          ),
          
          // 输入框
          _buildInputBar(chatState, isDark, keyboardHeight),
        ],
      ),
    );
  }

  /// 头部（拖拽条 + 标题）
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // 拖拽条
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // 标题栏
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI 助手',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => Navigator.of(context).pop(),
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  size: 24,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 预设问题
  Widget _buildPresetQuestions(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: PresetQuestion.defaults.length,
      itemBuilder: (context, index) {
        final preset = PresetQuestion.defaults[index];
        return _PresetQuestionCard(
          preset: preset,
          isDark: isDark,
          onTap: () => _sendMessage(preset.prompt),
        );
      },
    );
  }

  /// 消息列表
  Widget _buildMessageList(List<ChatMessage> messages, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      addAutomaticKeepAlives: false, // 性能优化：不保持 item 状态
      addRepaintBoundaries: true,    // 性能优化：添加重绘边界
      cacheExtent: 500,                // 缓存 500px 的内容
      itemBuilder: (context, index) {
        final message = messages[index];
        return RepaintBoundary(
          key: ValueKey(message.id),
          child: _MessageBubble(
            message: message,
            isDark: isDark,
            onCopy: () => _copyMessage(message.content),
            onLike: () {
              final notifier = ref.read(aiChatProvider(widget.article).notifier);
              notifier.toggleLike(message.id);
              // 如果是点赞（不是取消点赞），同时保存到笔记
              if (!message.isLiked) {
                final note = notifier.createNoteFromMessage(message);
                if (note != null) {
                  ref.read(noteProvider.notifier).addNote(note);
                }
              }
            },
            onRegenerate: () => ref
                .read(aiChatProvider(widget.article).notifier)
                .regenerate(message.id),
          ),
        );
      },
    );
  }

  /// 输入框
  Widget _buildInputBar(AIChatState chatState, bool isDark, double keyboardHeight) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + (keyboardHeight > 0 ? keyboardHeight : MediaQuery.of(context).padding.bottom),
      ),
      decoration: BoxDecoration(
        color: MCMColors.card(context),
        border: Border(
          top: BorderSide(
            color: MCMColors.dividerColor(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              enabled: !chatState.isLoading,
              maxLines: null,
              style: TextStyle(
                fontSize: 15,
                color: MCMColors.primaryText(context),
              ),
              decoration: InputDecoration(
                hintText: '问我关于这篇文章的任何问题...',
                hintStyle: TextStyle(
                  color: MCMColors.secondaryText(context),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: MCMColors.background(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: MCMColors.dividerColor(context), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: MCMColors.dividerColor(context), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: MCMColors.dividerColor(context), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 12),
          // 发送按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: chatState.isLoading
                ? null
                : () => _sendMessage(_inputController.text),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: chatState.isLoading
                    ? Colors.grey[400]
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

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

// ===== 辅助组件 =====

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
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.arrow_right,
                  size: 16,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
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
class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isDark;
  final VoidCallback onCopy;
  final VoidCallback onLike;
  final VoidCallback onRegenerate;

  const _MessageBubble({
    required this.message,
    required this.isDark,
    required this.onCopy,
    required this.onLike,
    required this.onRegenerate,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  late final ValueNotifier<String> _contentNotifier;
  late final MarkdownStyleSheet _markdownStyleUser;
  late final MarkdownStyleSheet _markdownStyleAI;

  @override
  void initState() {
    super.initState();
    _contentNotifier = ValueNotifier(widget.message.content);
    
    // 预创建 Markdown 样式表，避免每次 build 都创建
    _markdownStyleUser = MarkdownStyleSheet(
      p: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: Colors.black.withOpacity(0.15),
        color: Colors.white,
      ),
    );
    
    _markdownStyleAI = MarkdownStyleSheet(
      p: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: widget.isDark ? Colors.white : Colors.black87,
      ),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: widget.isDark ? Colors.grey[900]! : Colors.grey[200]!,
        color: widget.isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.content != oldWidget.message.content) {
      _contentNotifier.value = widget.message.content;
    }
  }

  @override
  void dispose() {
    _contentNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, isUser),
          if (!isUser) const SizedBox(width: 12),
          
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).primaryColor
                        : (widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildContent(context, isUser),
                ),
                
                // 操作按钮
                if (!isUser && widget.message.status == MessageStatus.completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.copy_rounded,
                          onPressed: widget.onCopy,
                          isDark: widget.isDark,
                          tooltip: '复制',
                        ),
                        const SizedBox(width: 6),
                        _ActionButton(
                          icon: widget.message.isLiked
                              ? Icons.bookmark
                              : Icons.bookmark_outline,
                          onPressed: widget.onLike,
                          isDark: widget.isDark,
                          isActive: widget.message.isLiked,
                          tooltip: '收藏到笔记',
                        ),
                        const SizedBox(width: 6),
                        _ActionButton(
                          icon: Icons.refresh_rounded,
                          onPressed: widget.onRegenerate,
                          isDark: widget.isDark,
                          tooltip: '重新生成',
                        ),
                      ],
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
          : (widget.isDark ? Colors.grey[700] : Colors.grey[300]),
      child: Icon(
        isUser ? CupertinoIcons.person : CupertinoIcons.sparkles,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser) {
    final textColor = isUser
        ? Colors.white
        : (widget.isDark ? Colors.white : Colors.black87);

    if (widget.message.status == MessageStatus.thinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: textColor,
            ),
          ),
          const SizedBox(width: 8),
          Text('思考中...', style: TextStyle(color: textColor, fontSize: 14)),
        ],
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: _contentNotifier,
      builder: (context, content, child) {
        return MarkdownBody(
          data: content,
          selectable: widget.message.status == MessageStatus.completed,
          styleSheet: isUser ? _markdownStyleUser : _markdownStyleAI,
          extensionSet: md.ExtensionSet.gitHubFlavored,
        );
      },
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDark;
  final bool isActive;
  final String? tooltip;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.isDark,
    this.isActive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.amber.withOpacity(0.15)
                : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: isActive
                ? Colors.amber[700]
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
    
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }
    
    return button;
  }
}
