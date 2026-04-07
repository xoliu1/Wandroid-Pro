import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter/services.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';
import '../models/article_content.dart';
import '../models/chat_message.dart';
import '../providers/ai_chat_provider.dart';
import '../../utils/mcm_widget.dart';

/// AI 聊天 Overlay 管理器
@deprecated
class AIChatOverlayManager {
  static final AIChatOverlayManager _instance = AIChatOverlayManager._internal();
  factory AIChatOverlayManager() => _instance;
  AIChatOverlayManager._internal();

  OverlayEntry? _overlayEntry;
  bool _isExpanded = false;

  /// 显示 AI 聊天（默认展开）
  void show(BuildContext context, ArticleContent article) {
    if (_overlayEntry != null) {
      // 已存在，展开
      _isExpanded = true;
      _overlayEntry?.markNeedsBuild();
      return;
    }

    _isExpanded = true;

    _overlayEntry = OverlayEntry(
      builder: (context) => _AIChatOverlayWidget(
        article: article,
        onMinimize: minimize,
        onClose: dispose,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 最小化（变成悬浮按钮）
  void minimize() {
    _isExpanded = false;
    _overlayEntry?.markNeedsBuild();
    debugPrint('🔽 [AI] 最小化，对话继续在后台');
  }

  /// 展开
  void expand() {
    _isExpanded = true;
    _overlayEntry?.markNeedsBuild();
    debugPrint('🔼 [AI] 展开对话');
  }

  /// 切换展开/最小化
  void toggle() {
    if (_isExpanded) {
      minimize();
    } else {
      expand();
    }
  }

  /// 完全关闭（清理所有资源）
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isExpanded = false;
    debugPrint('🧹 [AI] 完全关闭');
  }

  bool get isExpanded => _isExpanded;
  bool get isVisible => _overlayEntry != null;
}

/// AI 聊天 Overlay Widget
class _AIChatOverlayWidget extends StatefulWidget {
  final ArticleContent article;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const _AIChatOverlayWidget({
    required this.article,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  State<_AIChatOverlayWidget> createState() => _AIChatOverlayWidgetState();
}

class _AIChatOverlayWidgetState extends State<_AIChatOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleMinimize() {
    _animationController.reverse().then((_) {
      widget.onMinimize();
    });
  }

  void _handleExpand() {
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final manager = AIChatOverlayManager();
    final isExpanded = manager.isExpanded;

    // 最小化时完全隐藏 Overlay（不显示第二个按钮）
    if (!isExpanded) {
      return const SizedBox.shrink();
    }

    // 监听状态变化，触发动画
    if (isExpanded && _animationController.status != AnimationStatus.completed) {
      _handleExpand();
    }

    return Material(
      color: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _animationController,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: SafeArea(
              child: _AIChatContent(
                article: widget.article,
                onMinimize: _handleMinimize,
                onClose: widget.onClose,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AI 对话内容
class _AIChatContent extends ConsumerStatefulWidget {
  final ArticleContent article;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const _AIChatContent({
    required this.article,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  ConsumerState<_AIChatContent> createState() => _AIChatContentState();
}

class _AIChatContentState extends ConsumerState<_AIChatContent> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showPresets = true;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 智能滚动：只在新消息到达时滚动
  void _scrollToBottomIfNeeded(int currentMessageCount) {
    if (currentMessageCount > _lastMessageCount && _scrollController.hasClients) {
      _lastMessageCount = currentMessageCount;
      // 使用 animateTo 替代 jumpTo，更流畅
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider(widget.article));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 智能滚动
    _scrollToBottomIfNeeded(chatState.messages.length);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, isDark),
          Expanded(
            child: chatState.messages.isEmpty && _showPresets
                ? _buildPresetQuestions()
                : _buildMessageList(chatState),
          ),
          _buildInputArea(context, chatState, isDark),
        ],
      ),
    );
  }

  /// 构建头部（最小化按钮）
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 20),
          const SizedBox(width: 8),
          const Text(
            'AI 助手',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            tooltip: '最小化',
            onPressed: widget.onMinimize,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '关闭',
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  /// 构建预设问题
  Widget _buildPresetQuestions() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: PresetQuestion.defaults.length,
      itemBuilder: (context, index) {
        final preset = PresetQuestion.defaults[index];
        return _PresetQuestionCard(
          preset: preset,
          onTap: () {
            setState(() => _showPresets = false);
            _sendMessage(preset.prompt);
          },
        );
      },
    );
  }

  /// 构建消息列表（性能优化版）
  Widget _buildMessageList(AIChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      // 性能优化：禁用自动 keepAlive，减少内存
      addAutomaticKeepAlives: false,
      // 性能优化：禁用语义标签，减少构建开销
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        // 性能优化：为每个消息添加 key，优化列表更新
        return RepaintBoundary(
          key: ValueKey(message.id),
          child: _MessageBubble(
            message: message,
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
            onRegenerate: () => ref.read(aiChatProvider(widget.article).notifier).regenerate(message.id),
          ),
        );
      },
    );
  }

  /// 构建输入区域
  Widget _buildInputArea(BuildContext context, AIChatState state, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: MCMColors.card(context),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: null,
              enabled: !state.isLoading,
              decoration: InputDecoration(
                hintText: '输入你的问题...',
                filled: true,
                fillColor: MCMColors.background(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (value) => _sendMessage(value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: Colors.blue,
            onPressed: state.isLoading ? null : () => _sendMessage(_inputController.text),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    ref.read(aiChatProvider(widget.article).notifier).sendMessage(content);
    _inputController.clear();
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }
}



/// 预设问题卡片
class _PresetQuestionCard extends StatelessWidget {
  final PresetQuestion preset;
  final VoidCallback onTap;

  const _PresetQuestionCard({required this.preset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(preset.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    preset.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 消息气泡（性能优化：流式内容使用 ValueNotifier 局部刷新）
class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onCopy;
  final VoidCallback onLike;
  final VoidCallback onRegenerate;

  const _MessageBubble({
    required this.message,
    required this.onCopy,
    required this.onLike,
    required this.onRegenerate,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  // 性能优化：流式内容使用 ValueNotifier，避免整个气泡重建
  late final ValueNotifier<String> _contentNotifier;

  @override
  void initState() {
    super.initState();
    _contentNotifier = ValueNotifier(widget.message.content);
  }

  @override
  void didUpdateWidget(covariant _MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只在内容变化时更新 notifier
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = widget.message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isDark, isUser),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 性能优化：内容区域用 RepaintBoundary 隔离重绘
                RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (isDark ? Colors.blue[700] : Colors.blue[500])
                          : (isDark ? Colors.grey[800] : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildContent(context, isDark, isUser),
                  ),
                ),
                if (!isUser && widget.message.status == MessageStatus.completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(icon: Icons.copy, onPressed: widget.onCopy, tooltip: '复制'),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: widget.message.isLiked ? Icons.bookmark : Icons.bookmark_outline,
                          onPressed: widget.onLike,
                          isActive: widget.message.isLiked,
                          tooltip: '收藏到笔记',
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(icon: Icons.refresh, onPressed: widget.onRegenerate, tooltip: '重新生成'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(isDark, isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark, bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? (isDark ? Colors.blue[700] : Colors.blue[500])
          : (isDark ? Colors.grey[700] : Colors.grey[300]),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, bool isUser) {
    final textColor = isUser ? Colors.white : (isDark ? Colors.white : Colors.black87);

    if (widget.message.status == MessageStatus.thinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 8),
          Text('思考中...', style: TextStyle(color: textColor)),
        ],
      );
    }

    // 性能优化：使用 ValueListenableBuilder 只刷新内容部分
    return ValueListenableBuilder<String>(
      valueListenable: _contentNotifier,
      builder: (context, content, child) {
        return MarkdownBody(
          data: content,
          selectable: widget.message.status == MessageStatus.completed,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(fontSize: 15, height: 1.6, color: textColor),
            code: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              backgroundColor: isUser ? Colors.black.withValues(alpha: 0.2) : (isDark ? Colors.grey[900]! : Colors.grey[100]!),
              color: textColor,
            ),
          ),
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
  final bool isActive;
  final String? tooltip;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.amber[700] : Colors.amber[100])
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive
              ? (isDark ? Colors.white : Colors.amber[700])
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
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
