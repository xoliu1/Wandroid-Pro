import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:notes_app/providers/note_provider.dart';

import '../models/article_content.dart';
import '../models/chat_message.dart';
import '../providers/ai_chat_provider.dart';

/// AI Morphing 聊天组件
/// 科技感交互设计：
/// 1. FAB → 胶囊形输入框（Morphing）
/// 2. 对话面板"生长"动画（与第一阶段同时触发）
/// 3. 输入框与对话面板分离悬浮
class AIMorphingChat extends ConsumerStatefulWidget {
  final ArticleContent article;
  final VoidCallback? onClose;

  const AIMorphingChat({
    super.key,
    required this.article,
    this.onClose,
  });

  @override
  ConsumerState<AIMorphingChat> createState() => _AIMorphingChatState();
}

class _AIMorphingChatState extends ConsumerState<AIMorphingChat>
    with TickerProviderStateMixin {
  // ===== 动画控制器 =====
  late AnimationController _morphController; // FAB → 输入框
  late AnimationController _panelController; // 对话面板生长
  late AnimationController _fabController; // FAB 呼吸效果

  // ===== 动画 =====
  late Animation<double> _morphWidth; // 宽度变形
  late Animation<double> _morphHeight; // 高度变形
  late Animation<double> _morphRadius; // 圆角变形
  late Animation<double> _panelHeight; // 面板高度
  late Animation<double> _panelOpacity; // 面板透明度

  // ===== 状态 =====
  bool _isExpanded = false; // 是否展开
  bool _showPanel = false; // 是否显示对话面板
  bool _showPresets = true; // 是否显示预设问题
  double _collapseOpacity = 1.0; // 收起时的透明度动画

  // ===== 控制器 =====
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // ===== 自动滚动控制 =====
  bool _autoScroll = true; // 是否自动滚动
  bool _userScrolledUp = false; // 用户是否主动上滑

  // ===== 尺寸常量 =====
  static const double _fabSize = 56.0;
  static const double _inputBarHeight = 56.0;
  static const double _inputBarWidthRatio = 0.85;
  static const double _panelMaxHeightRatio = 0.7; // 提高面板高度占比
  static const double _bottomPadding = 100.0;
  static const double _panelGap = 12.0; // 输入框与面板间距

  int _lastMessageCount = 0;
  
  // 锁定展开时的尺寸，避免键盘弹起/收起导致尺寸变化
  double? _lockedInputBarWidth;
  double? _lockedPanelMaxHeight;
  
  // 标记是否正在收起动画中
  bool _isCollapsing = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _focusNode.addListener(_onFocusChange);
    _scrollController.addListener(_onScrollChange);
  }

  void _initAnimations() {
    // FAB 呼吸动画
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Morphing 动画（FAB → 输入框）
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 面板生长动画
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // 宽度动画：0 → 1（作为插值系数）
    _morphWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeOutCubic),
    );

    // 高度动画：56 → 56（保持）
    _morphHeight = Tween<double>(begin: _fabSize, end: _inputBarHeight).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeOutCubic),
    );

    // 圆角动画：28 → 28（胶囊形）
    _morphRadius = Tween<double>(begin: 28.0, end: 28.0).animate(
      CurvedAnimation(parent: _morphController, curve: Curves.easeOutCubic),
    );

    // 面板高度动画
    _panelHeight = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
    );

    // 面板透明度动画
    _panelOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _panelController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _morphController.dispose();
    _panelController.dispose();
    _fabController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 监听输入框焦点变化（键盘弹起/收起）
  void _onFocusChange() {
    // 输入框自己处理键盘，不需要 overlay 监听
    if (_focusNode.hasFocus && !_showPanel) {
      // 获得焦点但面板未显示时，展开面板
      _expandPanel();
    }
  }

  /// 监听滚动变化
  void _onScrollChange() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final isAtBottom = position.pixels >= position.maxScrollExtent - 50; // 允许 50px 误差

    // 用户手动上滑：禁用自动滚动
    if (_autoScroll && !isAtBottom && _userScrolledUp) {
      setState(() => _autoScroll = false);
    }

    // 用户滑到底部：恢复自动滚动
    if (!_autoScroll && isAtBottom) {
      setState(() => _autoScroll = true);
    }

    // 更新上滑标记（通过 pixels 变化判断）
    _userScrolledUp = position.pixels < position.maxScrollExtent - 100;
  }

  /// 点击 FAB / 输入框区域
  void _onTap() {
    if (!_isExpanded) {
      _expand();
    }
  }

  /// 第一阶段：FAB → 输入框（同时触发面板展开）
  void _expand() {
    // 锁定当前尺寸
    final size = MediaQuery.of(context).size;
    _lockedInputBarWidth = size.width * _inputBarWidthRatio;
    _lockedPanelMaxHeight = size.height * _panelMaxHeightRatio;
    
    setState(() {
      _isExpanded = true;
      _showPanel = true; // 同时触发面板
    });
    // 两个动画同时进行
    _morphController.forward();
    _panelController.forward().then((_) {
      // 动画完成后滚动到底部
      _scrollToBottom();
    });
  }

  /// 第二阶段：展开对话面板（仅用于焦点触发）
  void _expandPanel() {
    if (!_showPanel) {
      setState(() => _showPanel = true);
      _panelController.forward().then((_) {
        // 动画完成后滚动到底部
        _scrollToBottom();
      });
    }
  }
  
  /// 立即滚动到底部（用于首次打开）
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  /// 收起（最小化）- 淡出后隐藏，避免宽度跳变
  void _collapse() {
    if (_isCollapsing) return; // 防止重复触发
    _isCollapsing = true;
    _focusNode.unfocus();
    
    // 先播放淡出动画
    setState(() => _collapseOpacity = 0.0);
    
    // 淡出完成后隐藏并重置
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _showPanel = false;
        _isExpanded = false;
        _collapseOpacity = 1.0; // 重置透明度
      });
      
      // 重置动画到初始状态
      _panelController.reset();
      _morphController.reset();
      
      // 释放锁定的尺寸
      _lockedInputBarWidth = null;
      _lockedPanelMaxHeight = null;
      _isCollapsing = false;
    });
  }

  /// 完全关闭
  void _close() {
    _collapse();
    widget.onClose?.call();
  }

  /// 发送消息
  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    setState(() {
      _showPresets = false;
      _autoScroll = true; // 发送新消息时重置为自动滚动
    });
    ref.read(aiChatProvider(widget.article).notifier).sendMessage(content);
    _inputController.clear();
  }

  /// 智能滚动（支持自动跟随开关）
  void _scrollToBottomIfNeeded(List<ChatMessage> messages) {
    // 仅在启用自动滚动时才滚动
    if (!_autoScroll) return;
    
    // 检查消息数量或内容变化
    final currentMessageCount = messages.length;
    final hasNewContent = currentMessageCount > _lastMessageCount ||
        (messages.isNotEmpty && messages.last.status == MessageStatus.streaming);
    
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(aiChatProvider(widget.article));

    // 智能滚动（监听消息列表变化）
    _scrollToBottomIfNeeded(chatState.messages);

    // 计算目标输入框宽度（用于动画插值）
    final targetInputBarWidth = screenWidth * _inputBarWidthRatio;
    // 在展开/收起动画中使用锁定的尺寸，未展开时使用当前计算值
    final inputBarWidth = (_isExpanded || _isCollapsing) 
        ? (_lockedInputBarWidth ?? targetInputBarWidth) 
        : targetInputBarWidth;
    final panelMaxHeight = (_isExpanded || _isCollapsing)
        ? (_lockedPanelMaxHeight ?? screenHeight * _panelMaxHeightRatio)
        : screenHeight * _panelMaxHeightRatio;

    // 未展开时只显示 FAB（使用 Positioned 精确定位，只占 FAB 区域）
    if (!_isExpanded && !_isCollapsing) {
      return Positioned(
        right: 16,
        bottom: _bottomPadding,
        child: RepaintBoundary(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _onTap,
              child: _buildFABContainer(),
            ),
          ),
        ),
      );
    }

    // 展开时显示全屏覆盖层（使用 Positioned.fill 确保填满父级 Stack）
    return Positioned.fill(
      child: RepaintBoundary(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 背景遮罩（展开时显示）
              if (_showPanel)
                AnimatedOpacity(
                  opacity: _collapseOpacity,
                  duration: const Duration(milliseconds: 150),
                  child: GestureDetector(
                    onTap: _collapse,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedBuilder(
                      animation: _panelOpacity,
                      builder: (context, child) {
                        return ColoredBox(
                          color: Colors.black.withValues(alpha: _panelOpacity.value * 0.3),
                        );
                      },
                    ),
                  ),
                ),

            // 对话面板（悬浮在输入框上方）
            if (_showPanel)
              Positioned(
                left: (screenWidth - inputBarWidth) / 2,
                right: (screenWidth - inputBarWidth) / 2,
                bottom: _bottomPadding + _inputBarHeight + _panelGap,
                child: RepaintBoundary(
                  child: AnimatedOpacity(
                    opacity: _collapseOpacity,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedBuilder(
                      animation: _panelController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _panelHeight.value)),
                          child: Opacity(
                            opacity: _panelOpacity.value,
                            child: Container(
                              height: panelMaxHeight * _panelHeight.value,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, -4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      // 将面板内容作为 child 传入，避免每帧重建
                      child: Column(
                        children: [
                          // 头部工具栏
                          _buildPanelHeader(isDark),
                          // 消息列表
                          Expanded(
                            child: chatState.messages.isEmpty && _showPresets
                                ? _buildPresetQuestions(isDark)
                                : _buildMessageList(chatState, isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

          // FAB / 输入框（Morphing）
          Positioned(
            bottom: _bottomPadding,
            left: 0,
            right: 0,
            child: Center(
              child: RepaintBoundary(
                child: AnimatedOpacity(
                  opacity: _isExpanded ? _collapseOpacity : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: AnimatedBuilder(
                    animation: _morphController,
                    builder: (context, child) {
                      final width = _isExpanded
                          ? _fabSize + (_morphWidth.value * (inputBarWidth - _fabSize))
                          : _fabSize;
                      final height = _morphHeight.value;
                      final radius = _morphRadius.value;
                      final primaryColor = Theme.of(context).primaryColor;

                      return GestureDetector(
                        onTap: _onTap,
                        child: Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                            gradient: _isExpanded
                                ? null
                                : LinearGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withValues(alpha: 0.8),
                                    ],
                                  ),
                            color: _isExpanded
                                ? (isDark ? const Color(0xFF2A2A2A) : Colors.white)
                                : null,
                            borderRadius: BorderRadius.circular(radius),
                            boxShadow: [
                              BoxShadow(
                                color: _isExpanded
                                    ? Colors.black.withValues(alpha: 0.1)
                                    : primaryColor.withValues(alpha: 0.4),
                                blurRadius: _isExpanded ? 10 : 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _isExpanded
                              ? _buildInputBar(chatState, isDark)
                              : _buildFAB(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  /// 构建 FAB 容器（带动画）
  Widget _buildFABContainer() {
    final primaryColor = Theme.of(context).primaryColor;
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        final scale = 1.0 + (_fabController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: _fabSize,
            height: _fabSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建 FAB（未展开状态）
  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        final scale = 1.0 + (_fabController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  /// 构建输入框（展开状态）
  Widget _buildInputBar(AIChatState chatState, bool isDark) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _inputController,
            focusNode: _focusNode,
            enabled: !chatState.isLoading,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: '问我关于这篇文章的任何问题...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                fontSize: 15,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            onSubmitted: _sendMessage,
          ),
        ),
        // 发送按钮
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: chatState.isLoading
                ? null
                : () => _sendMessage(_inputController.text),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: chatState.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 构建面板头部
  Widget _buildPanelHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'AI 助手',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          // 最小化按钮
          _HeaderButton(
            icon: Icons.remove,
            onTap: _collapse,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // 关闭按钮
          _HeaderButton(
            icon: Icons.close,
            onTap: _close,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// 构建预设问题
  Widget _buildPresetQuestions(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
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

  /// 构建消息列表
  Widget _buildMessageList(AIChatState state, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: state.messages.length,
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      itemBuilder: (context, index) {
        final message = state.messages[index];

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

/// 头部按钮
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(preset.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    preset.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
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

/// 消息气泡（性能优化：流式内容使用 ValueNotifier 局部刷新）
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
    final isUser = widget.message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(isUser),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Theme.of(context).primaryColor
                        : (widget.isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildContent(isUser),
                ),
                // 操作按钮
                if (!isUser &&
                    widget.message.status == MessageStatus.completed)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
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
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: isUser
          ? Theme.of(context).primaryColor
          : (widget.isDark ? Colors.grey[700] : Colors.grey[300]),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildContent(bool isUser) {
    final textColor =
        isUser ? Colors.white : (widget.isDark ? Colors.white : Colors.black87);

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

    // 性能优化：使用 ValueListenableBuilder 只刷新内容部分
    return ValueListenableBuilder<String>(
      valueListenable: _contentNotifier,
      builder: (context, content, child) {
        return MarkdownBody(
          data: content,
          selectable: widget.message.status == MessageStatus.completed,
          styleSheet: _buildMarkdownStyle(textColor, isUser),
          extensionSet: md.ExtensionSet.gitHubFlavored,
        );
      },
    );
  }

  MarkdownStyleSheet _buildMarkdownStyle(Color textColor, bool isUser) {
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 14, height: 1.5, color: textColor),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        backgroundColor: isUser
            ? Colors.black.withValues(alpha: 0.15)
            : (widget.isDark ? Colors.grey[900]! : Colors.grey[200]!),
        color: textColor,
      ),
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
                ? Colors.amber.withValues(alpha: 0.15)
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
