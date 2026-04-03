import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:notes_app/ai/models/ai_provider_config.dart';
import 'package:notes_app/ai/providers/ai_provider_manager.dart';
import 'package:notes_app/ai/services/ai_service.dart';
import 'package:notes_app/ai/ui/ai_provider_management_page.dart';
import 'package:notes_app/model/note.dart';
import 'package:notes_app/providers/note_provider.dart';
import 'package:notes_app/utils/functions.dart' show randId;
import 'package:notes_app/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// Note 编辑页面 V2
/// 支持 Markdown 预览和编辑模式的平滑切换
class NoteEditorV2 extends ConsumerStatefulWidget {
  final Note? existingNote;

  const NoteEditorV2({super.key, this.existingNote});

  @override
  ConsumerState<NoteEditorV2> createState() => _NoteEditorV2State();
}

class _NoteEditorV2State extends ConsumerState<NoteEditorV2>
    with SingleTickerProviderStateMixin {
  late TextEditingController _contentController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _isAIProcessing = false; // AI 正在处理中
  String? _aiProcessingLabel; // AI 处理中的标签文字
  
  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
    
    // 监听文本变化
    _contentController.addListener(_onTextChanged);
    
    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 默认进入预览模式（如果有内容）
    if (widget.existingNote?.content.isNotEmpty == true) {
      _isEditing = false;
      _animationController.forward();
    } else {
      // 新笔记或空内容，直接进入编辑模式
      _isEditing = true;
    }
  }
  
  @override
  void dispose() {
    _contentController.removeListener(_onTextChanged);
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }
  
  /// 切换编辑/预览模式
  void _toggleMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    
    if (_isEditing) {
      // 进入编辑模式，先反向播放动画
      _animationController.reverse();
    } else {
      // 进入预览模式，播放淡入动画
      _animationController.forward();
    }
  }
  
  /// 保存笔记
  void _saveNote() {
    final content = _contentController.text;
    if (content.isEmpty) {
      _showSnackBar('笔记内容不能为空');
      return;
    }
    
    final note = Note(
      id: widget.existingNote?.id ?? randId(16),
      content: content,
      date: widget.existingNote?.date ?? DateTime.now(),
      lastModified: DateTime.now(),
    );
    
    if (widget.existingNote == null) {
      ref.read(noteProvider.notifier).addNote(note);
    } else {
      ref.read(noteProvider.notifier).updateNote(widget.existingNote!.id, note);
    }
    
    setState(() {
      _hasChanges = false;
    });
    
    _showSnackBar('笔记已保存');
    
    // 如果正在编辑，切换到预览模式
    if (_isEditing) {
      _toggleMode();
    }
  }
  
  /// 显示提示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// 复制内容到剪贴板
  void _copyContent() {
    Clipboard.setData(ClipboardData(text: _contentController.text));
    _showSnackBar('已复制到剪贴板');
  }

  /// 分享内容
  void _shareContent() {
    final content = _contentController.text;
    if (content.isEmpty) {
      _showSnackBar('笔记内容为空，无法分享');
      return;
    }

    // 构建分享文本
    final StringBuffer shareText = StringBuffer();
    if (widget.existingNote != null) {
      shareText.writeln('📒 来自我的笔记');
      shareText.writeln('⏰ ${DateFormat('yyyy-MM-dd HH:mm').format(widget.existingNote!.lastModified)}');
      shareText.writeln('');
    }
    shareText.writeln(content);

    Share.share(
      shareText.toString(),
      subject: widget.existingNote != null ? '笔记分享' : '分享笔记',
    );
  }

  /// 显示更多选项
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制全部内容'),
              onTap: () {
                Navigator.pop(context);
                _copyContent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                _shareContent();
              },
            ),
            if (widget.existingNote != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除笔记', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog();
                },
              ),
          ],
        ),
      ),
    );
  }
  
  /// 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.existingNote != null) {
                ref.read(noteProvider.notifier).deleteNote(widget.existingNote!.id);
                Navigator.pop(context); // 返回上一页
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 获取笔记标题（取内容第一行，限制长度）
  String _getNoteTitle() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      return widget.existingNote == null ? '新建笔记' : '笔记';
    }
    // 取第一行非空内容作为标题
    final firstLine = content
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) {
      return widget.existingNote == null ? '新建笔记' : '笔记';
    }
    // 去掉 Markdown 标题符号（# ## ### 等）
    final cleaned = firstLine.replaceFirst(RegExp(r'^#+\s*'), '');
    // 限制最大 20 个字符
    return cleaned.length > 20 ? '${cleaned.substring(0, 20)}...' : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteDate = widget.existingNote?.lastModified ?? DateTime.now();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getNoteTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(noteDate),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          // AI 助手按钮
          _buildAIMenuButton(),
          // 更多选项
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _isEditing ? _buildEditView() : _buildPreviewView(),
      ),
      floatingActionButton: _isEditing
          ? (_hasChanges
              ? FloatingActionButton.extended(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                )
              : null)
          : FloatingActionButton.extended(
              onPressed: _toggleMode,
              icon: const Icon(Icons.edit),
              label: const Text('编辑'),
            ),
    );
  }
  
  /// 构建编辑视图
  Widget _buildEditView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      key: const ValueKey('edit'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Markdown 工具栏
          _buildMarkdownToolbar(),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // 文本编辑区
          Expanded(
            child: TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: '在此输入 Markdown 格式的笔记内容...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建 Markdown 工具栏
  Widget _buildMarkdownToolbar() {
    final toolbarItems = [
      _ToolbarItem(icon: Icons.format_bold, label: '粗体', insert: '**粗体**'),
      _ToolbarItem(icon: Icons.format_italic, label: '斜体', insert: '*斜体*'),
      _ToolbarItem(icon: Icons.title, label: '标题', insert: '# 标题'),
      _ToolbarItem(icon: Icons.format_list_bulleted, label: '列表', insert: '- 列表项'),
      _ToolbarItem(icon: Icons.check_box, label: '任务', insert: '- [ ] 任务'),
      _ToolbarItem(icon: Icons.code, label: '代码', insert: '```\n代码\n```'),
      _ToolbarItem(icon: Icons.link, label: '链接', insert: '[链接文字](https://)'),
      _ToolbarItem(icon: Icons.image, label: '图片', insert: '![描述](图片链接)'),
      _ToolbarItem(icon: Icons.format_quote, label: '引用', insert: '> 引用'),
      _ToolbarItem(icon: Icons.horizontal_rule, label: '分割线', insert: '\n---\n'),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: toolbarItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final item = toolbarItems[index];
          return Tooltip(
            message: item.label,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _insertMarkdown(item.insert),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Icon(item.icon, size: 20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// 构建 AI 菜单按钮（右上角）
  Widget _buildAIMenuButton() {
    return _isAIProcessing
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                Text(
                  _aiProcessingLabel ?? 'AI',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          )
        : PopupMenuButton<String>(
            icon: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).primaryColor,
            ),
            tooltip: 'AI 助手',
            onSelected: (value) {
              if (value == 'continue') {
                _handleAIContinue();
              } else if (value == 'polish') {
                _handleAIPolish();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'continue',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Text('AI 续写'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'polish',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high,
                        size: 20, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    const Text('AI 润色'),
                  ],
                ),
              ),
            ],
          );
  }

  /// AI 续写
  Future<void> _handleAIContinue() async {
    final config = ref.read(activeAIProviderProvider);
    if (config == null) {
      _showAIConfigDialog();
      return;
    }

    final content = _contentController.text;
    if (content.trim().isEmpty) {
      _showSnackBar('请先输入一些内容再使用 AI 续写');
      return;
    }

    // 预览模式下先切换到编辑模式
    if (!_isEditing) {
      _toggleMode();
    }

    // 获取选中文本
    final selection = _contentController.selection;
    String? selectedText;
    if (selection.isValid && selection.start != selection.end) {
      selectedText = content.substring(selection.start, selection.end);
    }

    setState(() {
      _isAIProcessing = true;
      _aiProcessingLabel = 'AI 续写';
    });

    try {
      final messages = AIService.buildContinueWritingMessages(
        existingContent: content,
        selectedText: selectedText,
      );

      final aiService = AIService(config);
      final responseBuffer = StringBuffer();

      await for (final chunk in aiService.sendChatStream(messages: messages)) {
        responseBuffer.write(chunk);
      }

      final result = responseBuffer.toString().trim();
      if (result.isNotEmpty) {
        // 在光标位置或末尾插入续写内容
        final insertPosition = selection.isValid && selection.end > 0
            ? selection.end
            : content.length;
        final newText = content.substring(0, insertPosition) +
            '\n\n' +
            result +
            content.substring(insertPosition);
        _contentController.text = newText;
        _contentController.selection = TextSelection.collapsed(
          offset: insertPosition + 2 + result.length,
        );
        setState(() => _hasChanges = true);
        _showSnackBar('AI 续写完成');
      }
    } catch (e) {
      _showSnackBar('AI 续写失败: $e');
    } finally {
      setState(() {
        _isAIProcessing = false;
        _aiProcessingLabel = null;
      });
    }
  }

  /// AI 润色
  Future<void> _handleAIPolish() async {
    final config = ref.read(activeAIProviderProvider);
    if (config == null) {
      _showAIConfigDialog();
      return;
    }

    final content = _contentController.text;
    if (content.trim().isEmpty) {
      _showSnackBar('请先输入一些内容再使用 AI 润色');
      return;
    }

    // 预览模式下先切换到编辑模式
    if (!_isEditing) {
      _toggleMode();
    }

    // 获取选中文本或全部文本
    final selection = _contentController.selection;
    String textToPolish;
    bool isPartialPolish = false;
    int replaceStart = 0;
    int replaceEnd = content.length;

    if (selection.isValid && selection.start != selection.end) {
      textToPolish = content.substring(selection.start, selection.end);
      isPartialPolish = true;
      replaceStart = selection.start;
      replaceEnd = selection.end;
    } else {
      textToPolish = content;
    }

    setState(() {
      _isAIProcessing = true;
      _aiProcessingLabel = 'AI 润色';
    });

    try {
      final messages = AIService.buildPolishMessages(content: textToPolish);

      final aiService = AIService(config);
      final responseBuffer = StringBuffer();

      await for (final chunk in aiService.sendChatStream(messages: messages)) {
        responseBuffer.write(chunk);
      }

      final result = responseBuffer.toString().trim();
      if (result.isNotEmpty) {
        if (isPartialPolish) {
          // 替换选中部分
          final newText = content.substring(0, replaceStart) +
              result +
              content.substring(replaceEnd);
          _contentController.text = newText;
          _contentController.selection = TextSelection(
            baseOffset: replaceStart,
            extentOffset: replaceStart + result.length,
          );
        } else {
          // 替换全部内容
          _contentController.text = result;
          _contentController.selection = TextSelection.collapsed(
            offset: result.length,
          );
        }
        setState(() => _hasChanges = true);
        _showSnackBar(isPartialPolish ? '选中内容已润色' : '全文已润色');
      }
    } catch (e) {
      _showSnackBar('AI 润色失败: $e');
    } finally {
      setState(() {
        _isAIProcessing = false;
        _aiProcessingLabel = null;
      });
    }
  }

  /// 显示 AI 配置引导对话框
  void _showAIConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要配置 AI 服务'),
        content: const Text('使用 AI 功能前，请先配置 AI 服务提供商。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (_) => const AIProviderManagementPage(),
                ),
              );
            },
            child: const Text('去配置'),
          ),
        ],
      ),
    );
  }

  /// 插入 Markdown 标记
  void _insertMarkdown(String text) {
    final selection = _contentController.selection;
    final currentText = _contentController.text;
    
    if (selection.isValid) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      _contentController.text = newText;
      // 将光标放在插入文本的末尾
      _contentController.selection = TextSelection.collapsed(
        offset: selection.start + text.length,
      );
    } else {
      // 如果没有选中文本，在末尾插入
      _contentController.text = currentText + text;
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
    }
    
    setState(() {
      _hasChanges = true;
    });
  }
  
  /// 构建预览视图
  Widget _buildPreviewView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final codeBackground = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    
    return Container(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _contentController.text.isEmpty
            ? _buildEmptyPreview()
            : SingleChildScrollView(
                child: MarkdownBody(
                  data: _contentController.text,
                  selectable: true,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                  // 段落样式
                  p: TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: textColor,
                  ),
                  // 标题样式
                  h1: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                  ),
                  h2: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                  ),
                  h3: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                  ),
                  h4: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                  ),
                  h5: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                  ),
                  h6: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.4,
                  ),
                  // 列表样式
                  listBullet: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                  listIndent: 24,
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
                  codeblockPadding: const EdgeInsets.all(16),
                  // 引用样式
                  blockquote: TextStyle(
                    fontSize: 16,
                    color: textColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                        width: 4,
                      ),
                    ),
                  ),
                  blockquotePadding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
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
                    color: Colors.blue,
                    decoration: TextDecoration.none,
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
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 1,
                  ),
                  tableCellsPadding: const EdgeInsets.all(8),
                  // 水平线样式
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    [
                      md.EmojiSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                    ],
                  ),
                ),
              ),
            ),
      );
  }

  /// 构建空预览视图
  Widget _buildEmptyPreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '笔记内容为空',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _toggleMode,
            icon: const Icon(Icons.edit),
            label: const Text('开始编辑'),
          ),
        ],
      ),
    );
  }
}

/// 工具栏项数据类
class _ToolbarItem {
  final IconData icon;
  final String label;
  final String insert;
  
  _ToolbarItem({
    required this.icon,
    required this.label,
    required this.insert,
  });
}
