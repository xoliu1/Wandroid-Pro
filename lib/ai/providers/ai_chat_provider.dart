import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanandroid_pro/model/db/sqflite.dart';
import 'package:wanandroid_pro/model/note.dart';
import '../core/logger.dart';
import '../core/constants.dart';
import '../models/ai_provider_config.dart';
import '../models/article_content.dart';
import '../models/chat_message.dart';
import '../models/chat_history.dart';
import '../services/ai_service.dart';
import '../services/chat_history_db.dart';
import 'ai_provider_manager.dart';

/// AI 对话状态
class AIChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ArticleContent? article;

  const AIChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.article,
  });

  AIChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
    ArticleContent? article,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      article: article ?? this.article,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIChatState &&
          runtimeType == other.runtimeType &&
          messages == other.messages &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => Object.hash(messages, isLoading, error);
}

/// AI 对话 Provider
class AIChatNotifier extends StateNotifier<AIChatState> {
  AIChatNotifier(this._config, this._article, {bool isPlainChat = false}) 
      : _isPlainChat = isPlainChat,
        super(_config == null 
            ? AIChatState(article: _article, error: '请先配置 AI 服务')
            : AIChatState(article: _article)) {
    if (_config != null) {
      AILogger.info('初始化 AIChatNotifier: ${_article.title} (纯对话: $isPlainChat)', tag: AIConstants.tagProvider);
      _loadHistoryFromDB();
    }
  }

  final AIProviderConfig? _config;
  final ArticleContent _article;
  final bool _isPlainChat;
  AIService? _aiService;
  final _db = ChatHistoryDatabase();

  /// 从数据库加载对话历史
  Future<void> _loadHistoryFromDB() async {
    try {
      final history = await _db.getChatHistoryByUrl(_article.url);
      if (history != null && history.messages.isNotEmpty) {
        // 只加载已完成的消息
        final completedMessages = history.messages
            .where((m) => m.status == MessageStatus.completed)
            .toList();
        
        if (completedMessages.isNotEmpty) {
          state = state.copyWith(messages: completedMessages);
          AILogger.info('加载历史对话: ${completedMessages.length} 条', tag: AIConstants.tagProvider);
        }
      }
    } catch (e, stackTrace) {
      AILogger.error('加载对话历史失败', tag: AIConstants.tagProvider, error: e, stackTrace: stackTrace);
    }
  }

  /// 保存对话历史到数据库
  Future<void> _saveHistoryToDB() async {
    try {
      // 只保存已完成的消息
      final completedMessages = state.messages
          .where((m) => m.status == MessageStatus.completed)
          .toList();
      
      if (completedMessages.isEmpty) return;

      final now = DateTime.now();
      final history = ChatHistory(
        articleUrl: _article.url,
        articleTitle: _article.title,
        articleAuthor: _article.author,
        messages: completedMessages,
        createdAt: now,
        updatedAt: now,
      );

      await _db.saveChatHistory(history);
      AILogger.info('保存对话历史: ${completedMessages.length} 条', tag: AIConstants.tagProvider);
    } catch (e, stackTrace) {
      AILogger.error('保存对话历史失败', tag: AIConstants.tagProvider, error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    // 取消正在进行的请求
    _aiService?.cancelCurrentRequest();
    AILogger.info('清理 AIChatNotifier 资源', tag: AIConstants.tagProvider);
    super.dispose();
  }

  /// 手动取消请求（供外部调用）
  void cancelRequest() {
    _aiService?.cancelCurrentRequest();
    AILogger.info('手动取消 AI 请求', tag: AIConstants.tagProvider);
  }

  /// 初始化 AI 服务
  void _initService() {
    if (_config == null) return;
    _aiService ??= AIService(_config);
  }

  /// 发送消息
  /// [content] 用户消息内容
  /// [systemContext] 可选的系统上下文，不会显示在聊天记录中，但会发送给 AI
  Future<void> sendMessage(String content, {String? systemContext}) async {
    if (_config == null) {
      state = state.copyWith(error: '请先配置 AI 服务');
      return;
    }
    
    if (content.trim().isEmpty) {
      AILogger.warning('消息为空，取消发送', tag: AIConstants.tagProvider);
      return;
    }

    _initService();
    AILogger.info('开始发送消息: $content', tag: AIConstants.tagProvider);
    if (systemContext != null) {
      AILogger.debug('携带系统上下文: ${systemContext.length} 字符', tag: AIConstants.tagProvider);
    }

    // 添加用户消息（只显示简洁的问题）
    final userMessage = ChatMessage.user(content);
    
    // 延迟 1 微秒，确保 AI 消息 ID 不同
    await Future.delayed(const Duration(microseconds: 1));
    
    // 创建 AI 消息占位符
    final aiMessage = ChatMessage.assistantPlaceholder();
    
    // 一次性添加两条消息
    state = state.copyWith(
      messages: [...state.messages, userMessage, aiMessage],
      isLoading: true,
      clearError: true,
    );

    // 构建消息历史
    final history = _buildHistory();
    AILogger.debug('构建历史消息: ${history.length} 条', tag: AIConstants.tagProvider);

    // 如果有系统上下文，将其组合到用户问题中（对 AI 可见，但不显示在 UI 上）
    String effectiveUserQuestion = content;
    if (systemContext != null && systemContext.isNotEmpty) {
      effectiveUserQuestion = '$systemContext\n\n$content';
    }

    // 根据是否为纯对话选择不同的消息构建方式
    final messages = _isPlainChat
        ? AIService.buildPlainMessages(
            userQuestion: effectiveUserQuestion,
            history: history.isEmpty ? null : history,
          )
        : AIService.buildMessagesWithArticle(
            article: _article,
            userQuestion: effectiveUserQuestion,
            history: history.isEmpty ? null : history,
          );

    // 流式接收响应（性能优化版）
    final responseBuffer = StringBuffer();
    int updateCounter = 0;
    const updateInterval = 3; // 每 3 个 chunk 更新一次（更实时的流式体验）

    try {
      final stream = _aiService!.sendChatStream(messages: messages);

      await for (final chunk in stream) {
        responseBuffer.write(chunk);
        updateCounter++;

        // 性能优化：减少更新频率，降低 UI 重建压力
        if (updateCounter >= updateInterval) {
          _updateAIMessage(aiMessage.id, responseBuffer.toString(), MessageStatus.streaming);
          updateCounter = 0;
        }
      }

      // 最终更新（确保完整内容显示）
      final fullResponse = responseBuffer.toString();
      _updateAIMessage(aiMessage.id, fullResponse, MessageStatus.completed);
      state = state.copyWith(isLoading: false);
      
      // 保存对话历史到数据库
      await _saveHistoryToDB();
      
      AILogger.success('消息发送完成，共 ${fullResponse.length} 字符', tag: AIConstants.tagProvider);
    } catch (e, stackTrace) {
      AILogger.error('消息发送失败', tag: AIConstants.tagProvider, error: e, stackTrace: stackTrace);

      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      _updateAIMessage(aiMessage.id, '抱歉，发生了错误：$e', MessageStatus.error);
    }
  }

  /// 更新 AI 消息内容（性能优化版）
  void _updateAIMessage(String messageId, String content, MessageStatus status) {
    final messageIndex = state.messages.indexWhere((msg) => msg.id == messageId);
    
    if (messageIndex == -1) return;

    final targetMessage = state.messages[messageIndex];
    
    // 安全检查：确保是 AI 消息
    if (targetMessage.role != ChatRole.assistant) return;

    // 性能优化：避免不必要的状态更新
    if (targetMessage.content == content && targetMessage.status == status) {
      return; // 内容和状态都没变，跳过更新
    }

    // 创建新的消息列表，只修改目标消息
    final updatedMessages = List<ChatMessage>.from(state.messages);
    updatedMessages[messageIndex] = targetMessage.copyWith(
      content: content,
      status: status,
    );

    state = state.copyWith(messages: updatedMessages);
  }

  /// 构建对话历史（排除系统消息、当前用户消息、以及未完成的消息）
  List<Map<String, String>> _buildHistory() {
    // 获取除最后一条用户消息外的所有已完成消息
    final completedMessages = state.messages
        .where((msg) => 
            msg.role != ChatRole.system && 
            msg.status == MessageStatus.completed)
        .toList();
    
    // 如果最后一条是用户消息（刚添加的），排除它
    if (completedMessages.isNotEmpty && 
        completedMessages.last.role == ChatRole.user) {
      completedMessages.removeLast();
    }
    
    return completedMessages
        .map((msg) => {
              'role': msg.role == ChatRole.user ? 'user' : 'assistant',
              'content': msg.content,
            })
        .toList();
  }

  /// 点赞/取消点赞，收藏的内容会保存到笔记数据库
  void toggleLike(String messageId) {
    final targetMessage = state.messages.firstWhere(
      (msg) => msg.id == messageId,
      orElse: () => throw Exception('Message not found'),
    );
    
    final newIsLiked = !targetMessage.isLiked;
    
    // 更新消息状态
    final updatedMessages = state.messages.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(isLiked: newIsLiked);
      }
      return msg;
    }).toList();

    state = state.copyWith(messages: updatedMessages);
    
    // 如果是点赞（收藏），保存到笔记数据库
    if (newIsLiked) {
      saveMessageToNote(targetMessage);
    }
  }
  
  /// 将消息保存为笔记 - 通过回调方式让 UI 层处理
  void saveMessageToNote(ChatMessage message) {
    _saveMessageToNoteInternal(message);
  }
  
  /// 内部方法：将消息保存为笔记（供外部调用）
  Note? createNoteFromMessage(ChatMessage message) {
    try {
      final now = DateTime.now();
      final articleTitle = _article.title.isNotEmpty ? _article.title : 'AI 对话';
      final articleUrl = _article.url.isNotEmpty ? '\n\n原文链接：${_article.url}' : '';
      
      // 构建笔记内容
      final StringBuffer contentBuffer = StringBuffer();
      contentBuffer.writeln('📌 来自文章：$articleTitle');
      contentBuffer.writeln('⏰ 收藏时间：${_formatDateTime(now)}');
      if (articleUrl.isNotEmpty) {
        contentBuffer.writeln(articleUrl);
      }
      contentBuffer.writeln('\n---\n');
      contentBuffer.writeln(message.content);
      
      return Note(
        id: '', // 由 noteProvider 生成
        content: contentBuffer.toString(),
        date: now,
        lastModified: now,
      );
    } catch (e) {
      AILogger.error('创建笔记失败', tag: AIConstants.tagProvider, error: e);
      return null;
    }
  }
  
  void _saveMessageToNoteInternal(ChatMessage message) {
    try {
      final now = DateTime.now();
      final articleTitle = _article.title.isNotEmpty ? _article.title : 'AI 对话';
      final articleUrl = _article.url.isNotEmpty ? '\n\n原文链接：${_article.url}' : '';
      
      // 构建笔记内容
      final StringBuffer contentBuffer = StringBuffer();
      contentBuffer.writeln('📌 来自文章：$articleTitle');
      contentBuffer.writeln('⏰ 收藏时间：${_formatDateTime(now)}');
      if (articleUrl.isNotEmpty) {
        contentBuffer.writeln(articleUrl);
      }
      contentBuffer.writeln('\n---\n');
      contentBuffer.writeln(message.content);
      
      final note = Note(
        id: '', // 由 noteProvider 生成
        content: contentBuffer.toString(),
        date: now,
        lastModified: now,
      );
      
      // 直接操作数据库，不通过 Provider
      Db.insertNote(note.toMap());
      
      AILogger.success('已收藏对话内容到笔记: ${message.id}', tag: AIConstants.tagProvider);
    } catch (e, stackTrace) {
      AILogger.error('收藏到笔记失败', tag: AIConstants.tagProvider, error: e, stackTrace: stackTrace);
    }
  }
  
  /// 格式化日期时间
  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 重新生成回答
  Future<void> regenerate(String messageId) async {
    final messageIndex = state.messages.indexWhere((msg) => msg.id == messageId);
    if (messageIndex == -1 || messageIndex == 0) return;

    // 找到对应的用户问题
    final userMessage = state.messages[messageIndex - 1];
    if (userMessage.role != ChatRole.user) return;

    // 删除旧的 AI 回答
    final newMessages = state.messages.sublist(0, messageIndex);
    state = state.copyWith(messages: newMessages);

    // 重新发送
    await sendMessage(userMessage.content);
  }

  /// 清空对话
  void clear() {
    state = AIChatState(article: _article);
    // 同时清空数据库中的记录
    _db.deleteChatHistory(_article.url);
    AILogger.info('清空对话历史', tag: AIConstants.tagProvider);
  }
}

/// AI 对话 Provider（需要文章内容和配置）
final aiChatProvider = StateNotifierProvider.family<AIChatNotifier, AIChatState, ArticleContent>(
  (ref, article) {
    final config = ref.watch(activeAIProviderProvider);
    return AIChatNotifier(config, article);
  },
);

/// 纯对话 Provider（不需要文章上下文，用于新建对话）
final plainChatProvider = StateNotifierProvider.family<AIChatNotifier, AIChatState, String>(
  (ref, chatId) {
    final config = ref.watch(activeAIProviderProvider);
    final article = ArticleContent.create(
      title: '新对话',
      content: '',
      url: chatId,
      platform: '纯对话',
    );
    return AIChatNotifier(config, article, isPlainChat: true);
  },
);
