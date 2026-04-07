import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:wanandroid_pro/providers/note_provider.dart';
import '../models/article_content.dart';
import '../models/chat_message.dart';
import '../providers/ai_chat_provider.dart';
import '../../utils/platform_utils.dart';
import '../../utils/mcm_widget.dart';

/// AI 对话面板（底部抽屉式）
class AIChatPanel extends ConsumerStatefulWidget {
  final ArticleContent article;

  const AIChatPanel({
    super.key,
    required this.article,
  });

  @override
  ConsumerState<AIChatPanel> createState() => _AIChatPanelState();
}

class _AIChatPanelState extends ConsumerState<AIChatPanel> with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  bool _showPresets = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void deactivate() {
    // ❌ 不在这里取消请求，让对话在后台继续
    super.deactivate();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider(widget.article));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 当有消息时自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && chatState.messages.isNotEmpty) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      )),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: chatState.messages.isEmpty && _showPresets
                  ? _buildPresetQuestions()
                  : _buildMessageList(chatState),
            ),
            _buildInputArea(context, chatState),
          ],
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
          if (PlatformUtils.isIOS)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Icon(CupertinoIcons.xmark_circle_fill, size: 24),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
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

  /// 构建消息列表
  Widget _buildMessageList(AIChatState state) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return _MessageBubble(
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
        );
      },
    );
  }

  /// 构建输入区域
  Widget _buildInputArea(BuildContext context, AIChatState state) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16, // 关键：适配键盘高度
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
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              enabled: !state.isLoading,
              decoration: InputDecoration(
                hintText: '输入你的问题...',
                filled: true,
                fillColor: MCMColors.background(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: (value) => _sendMessage(value),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(state),
        ],
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton(AIChatState state) {
    if (PlatformUtils.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: state.isLoading ? null : () => _sendMessage(_inputController.text),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: state.isLoading ? Colors.grey : CupertinoColors.activeBlue,
            shape: BoxShape.circle,
          ),
          child: state.isLoading
              ? const CupertinoActivityIndicator(color: Colors.white)
              : const Icon(CupertinoIcons.arrow_up, color: Colors.white),
        ),
      );
    }

    return IconButton(
      icon: state.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send),
      color: Colors.blue,
      onPressed: state.isLoading ? null : () => _sendMessage(_inputController.text),
    );
  }

  /// 发送消息
  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    ref.read(aiChatProvider(widget.article).notifier).sendMessage(content);
    _inputController.clear();
  }

  /// 复制消息
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

/// 预设问题卡片
class _PresetQuestionCard extends StatelessWidget {
  final PresetQuestion preset;
  final VoidCallback onTap;

  const _PresetQuestionCard({
    required this.preset,
    required this.onTap,
  });

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
                Text(
                  preset.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    preset.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == ChatRole.user;

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (isDark ? Colors.blue[700] : Colors.blue[500])
                        : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildContent(context),
                ),
                if (!isUser && message.status == MessageStatus.completed)
                  _buildActions(context),
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

  Widget _buildContent(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isUser ? Colors.white : (isDark ? Colors.white : Colors.black87);

    // 显示思考状态
    if (message.status == MessageStatus.thinking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUser ? Colors.white : Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '思考中...',
            style: TextStyle(color: textColor),
          ),
        ],
      );
    }

    // 流式输出时使用 Markdown（支持实时渲染）
    if (message.status == MessageStatus.streaming) {
      return _MarkdownContent(
        content: message.content,
        isUser: isUser,
        isStreaming: true,
      );
    }

    // 完成状态使用 Markdown（完整渲染）
    return _MarkdownContent(
      content: message.content,
      isUser: isUser,
      isStreaming: false,
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButton(
            icon: Icons.copy,
            onPressed: onCopy,
            tooltip: '复制',
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: message.isLiked ? Icons.bookmark : Icons.bookmark_outline,
            onPressed: onLike,
            isActive: message.isLiked,
            tooltip: '收藏到笔记',
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.refresh,
            onPressed: onRegenerate,
            tooltip: '重新生成',
          ),
        ],
      ),
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

/// 打字机效果文本
/// Markdown 内容渲染组件
class _MarkdownContent extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;

  const _MarkdownContent({
    required this.content,
    required this.isUser,
    required this.isStreaming,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // 用户消息使用白色文本，AI 消息根据主题自动调整
    final textColor = isUser ? Colors.white : (isDark ? Colors.white : Colors.black87);
    final codeBackground = isUser 
        ? Colors.black.withValues(alpha: 0.2)
        : (isDark ? Colors.grey[900]! : Colors.grey[100]!);
    
    return MarkdownBody(
      data: content,
      selectable: !isStreaming, // 流式输出时禁用选择（避免闪烁）
      // Markdown 样式配置
      styleSheet: MarkdownStyleSheet(
        // 段落样式
        p: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: textColor,
        ),
        // 标题样式
        h1: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h2: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h4: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h5: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        h6: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.4,
        ),
        // 列表样式
        listBullet: TextStyle(
          fontSize: 15,
          color: textColor,
        ),
        // 代码块样式
        code: TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          backgroundColor: codeBackground,
          color: textColor,
        ),
        codeblockDecoration: BoxDecoration(
          color: codeBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        // 引用样式
        blockquote: TextStyle(
          fontSize: 15,
          color: textColor.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: textColor.withValues(alpha: 0.3),
              width: 4,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        // 强调样式
        em: TextStyle(
          fontStyle: FontStyle.italic,
          color: textColor,
        ),
        strong: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        // 链接样式
        a: TextStyle(
          color: isUser ? Colors.white : Colors.blue,
          decoration: TextDecoration.underline,
        ),
        // 表格样式
        tableHead: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        tableBody: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
        tableBorder: TableBorder.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
        // 水平线样式
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: textColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
      ),
      // 扩展语法支持
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [
          md.EmojiSyntax(), // 支持 emoji :smile:
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
      // 链接点击处理
      onTapLink: (text, href, title) {
        if (href != null) {
          _launchUrl(href);
        }
      },
      // 图片构建器（可选：添加图片加载占位符）
      imageBuilder: (uri, title, alt) {
        return Image.network(
          uri.toString(),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: codeBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image, color: textColor.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      alt ?? '图片加载失败',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7),
                      ),
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

  /// 打开链接
  void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ 打开链接失败: $e');
    }
  }
}
