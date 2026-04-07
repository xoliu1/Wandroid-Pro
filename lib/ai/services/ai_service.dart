import 'dart:async';
import '../core/logger.dart';
import '../core/constants.dart';
import '../models/ai_provider_config.dart';
import '../models/article_content.dart';
import '../repositories/ai_repository.dart';
import '../../local/KV.dart';

/// AI 服务 - 业务逻辑层
/// 
/// 职责：
/// - 构建消息上下文
/// - 管理对话历史
/// - Token 估算
/// - 委托具体请求给 Repository
class AIService {
  final AIProviderConfig config;
  final AIRepository _repository;

  AIService(this.config) : _repository = AIRepositoryFactory.create(config) {
    AILogger.info('初始化 AI 服务: ${config.name}', tag: AIConstants.tagService);
  }

  /// 发送聊天消息（流式响应）
  Stream<String> sendChatStream({
    required List<Map<String, String>> messages,
    int? maxTokens,
    double? temperature,
  }) async* {
    AILogger.info('发送流式聊天请求', tag: AIConstants.tagService);
    AILogger.debug('消息数量: ${messages.length}', tag: AIConstants.tagService);

    try {
      yield* _repository.sendMessageStream(
        messages: messages,
        maxTokens: maxTokens,
        temperature: temperature,
      );
    } catch (e, stackTrace) {
      AILogger.error('流式请求失败', tag: AIConstants.tagService, error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 取消当前请求
  void cancelCurrentRequest() {
    AILogger.info('取消当前请求', tag: AIConstants.tagService);
    _repository.cancelCurrentRequest();
  }

  /// 构建包含文章内容的完整消息列表
  static List<Map<String, String>> buildMessagesWithArticle({
    required ArticleContent article,
    required String userQuestion,
    List<Map<String, String>>? history,
  }) {
    final messages = <Map<String, String>>[];

    // 系统消息：文章内容
    final articleContext = _buildArticleContext(article);
    final rolePrompt = getEffectivePrompt(kPromptChannelArticleChat);
    messages.add({
      'role': 'system',
      'content': '$rolePrompt\n\n以下是用户正在阅读的文章内容：\n\n$articleContext',
    });

    // 添加历史对话
    if (history != null && history.isNotEmpty) {
      messages.addAll(history);
      AILogger.debug('添加历史对话: ${history.length} 条', tag: AIConstants.tagService);
    }

    // 用户问题
    messages.add({
      'role': 'user',
      'content': userQuestion,
    });

    AILogger.debug('构建消息完成: ${messages.length} 条', tag: AIConstants.tagService);
    return messages;
  }

  /// 构建纯对话消息列表（不包含文章上下文）
  static List<Map<String, String>> buildPlainMessages({
    required String userQuestion,
    List<Map<String, String>>? history,
  }) {
    final messages = <Map<String, String>>[];

    // 系统消息：纯对话助手
    messages.add({
      'role': 'system',
      'content': '你是一个智能助手，可以回答各种问题。请保持友好、专业、准确。',
    });

    // 添加历史对话
    if (history != null && history.isNotEmpty) {
      messages.addAll(history);
      AILogger.debug('添加历史对话: ${history.length} 条', tag: AIConstants.tagService);
    }

    // 用户问题
    messages.add({
      'role': 'user',
      'content': userQuestion,
    });

    AILogger.debug('构建消息完成: ${messages.length} 条', tag: AIConstants.tagService);
    return messages;
  }

  /// 构建 AI 续写消息列表（用于笔记编辑器）
  static List<Map<String, String>> buildContinueWritingMessages({
    required String existingContent,
    String? selectedText,
  }) {
    final messages = <Map<String, String>>[];

    final rolePrompt = getEffectivePrompt(kPromptChannelNoteContinue);
    messages.add({
      'role': 'system',
      'content': rolePrompt,
    });

    final userContent = selectedText != null && selectedText.isNotEmpty
        ? '以下是笔记的完整内容：\n\n$existingContent\n\n请从以下选中的部分开始续写：\n\n$selectedText'
        : '以下是笔记的内容，请从末尾继续续写：\n\n$existingContent';

    messages.add({
      'role': 'user',
      'content': userContent,
    });

    return messages;
  }

  /// 构建 AI 润色消息列表（用于笔记编辑器）
  static List<Map<String, String>> buildPolishMessages({
    required String content,
  }) {
    final messages = <Map<String, String>>[];

    final rolePrompt = getEffectivePrompt(kPromptChannelNotePolish);
    messages.add({
      'role': 'system',
      'content': rolePrompt,
    });

    messages.add({
      'role': 'user',
      'content': '请润色以下内容：\n\n$content',
    });

    return messages;
  }

  /// 构建每日问答 AI 解析消息列表
  static List<Map<String, String>> buildQuestionExplanationMessages({
    required String title,
    required String description,
    String? userContext,
  }) {
    final messages = <Map<String, String>>[];

    final systemPrompt = StringBuffer();
    // 使用自定义 prompt（如果有）或默认值
    systemPrompt.writeln(getEffectivePrompt(kPromptChannelQuestionExplain));

    if (userContext != null && userContext.isNotEmpty) {
      systemPrompt.writeln('\n以下是用户的背景信息，可以据此调整回答的深度和侧重点：');
      systemPrompt.writeln(userContext);
    }

    messages.add({
      'role': 'system',
      'content': systemPrompt.toString(),
    });

    final userContent = StringBuffer();
    userContent.writeln('请解答以下技术问题：');
    userContent.writeln();
    userContent.writeln('**题目**：$title');
    if (description.isNotEmpty) {
      userContent.writeln();
      userContent.writeln('**描述**：$description');
    }

    messages.add({
      'role': 'user',
      'content': userContent.toString(),
    });

    return messages;
  }

  /// 构建 AI 日报总结消息列表
  /// 
  /// [dailyData] 今日活动数据（浏览记录、完成的 TODO、笔记变更等）
  /// [userContext] 用户画像上下文
  static List<Map<String, String>> buildDailyReportMessages({
    required String dailyData,
    String? userContext,
  }) {
    final messages = <Map<String, String>>[];

    final systemPrompt = StringBuffer();
    // 角色描述：使用自定义 prompt 或默认值
    systemPrompt.writeln(getEffectivePrompt(kPromptChannelDailyReport));
    systemPrompt.writeln();
    systemPrompt.writeln('**重要**：你必须严格按照以下 JSON 格式返回结果，不要输出任何其他内容（不要输出 markdown 代码块标记）：');
    systemPrompt.writeln();
    systemPrompt.writeln('''{
  "overview": "用一句话总结今天的整体情况（必填，即使没有数据也要写）",
  "reading": {
    "summary": "阅读主题倾向的一句话总结",
    "items": ["文章标题1", "文章标题2"]
  },
  "todos": {
    "completed_summary": "今日完成任务的一句话总结",
    "completed": ["已完成任务1", "已完成任务2"],
    "pending_summary": "待完成任务的一句话说明",
    "pending": ["待完成任务1", "待完成任务2"]
  },
  "notes": {
    "summary": "笔记动态的一句话总结",
    "items": ["笔记摘要1", "笔记摘要2"]
  },
  "suggestions": ["明日建议1", "明日建议2"]
}''');
    systemPrompt.writeln();
    systemPrompt.writeln('规则：');
    systemPrompt.writeln('1. 如果某个板块没有数据，对应字段设为 null（不要省略字段）');
    systemPrompt.writeln('2. items/completed/pending 数组最多 5 条');
    systemPrompt.writeln('3. suggestions 给出 1-2 条具体可执行的建议');
    systemPrompt.writeln('4. 语气亲切自然，summary 字段像朋友一样聊天');
    systemPrompt.writeln('5. 只输出 JSON，不要有任何其他文字');

    if (userContext != null && userContext.isNotEmpty) {
      systemPrompt.writeln('\n以下是用户的背景信息，可以据此让总结更个性化：');
      systemPrompt.writeln(userContext);
    }

    messages.add({
      'role': 'system',
      'content': systemPrompt.toString(),
    });

    messages.add({
      'role': 'user',
      'content': '请根据以下今日活动数据，生成我的日报总结：\n\n$dailyData',
    });

    return messages;
  }

  /// 构建 AI TODO 智能助手消息列表
  /// 
  /// [mode] 功能模式：'breakdown' 智能拆解, 'daily' 每日建议
  /// [userInput] 用户输入（智能拆解模式下为大目标）
  /// [userContext] 用户画像上下文
  static List<Map<String, String>> buildTodoAssistantMessages({
    required String mode,
    String? userInput,
    required String userContext,
  }) {
    final messages = <Map<String, String>>[];

    final systemPrompt = StringBuffer();
    systemPrompt.writeln('你是一个智能任务规划助手。你需要根据用户的上下文信息，帮助用户规划和管理待办事项。');
    systemPrompt.writeln();
    systemPrompt.writeln('**重要**：你必须严格按照以下 JSON 格式返回结果，不要输出任何其他内容（不要输出 markdown 代码块标记）：');
    systemPrompt.writeln();

    if (mode == 'breakdown') {
      systemPrompt.writeln('''{
  "type": "goal_breakdown",
  "summary": "对目标的简要分析（一句话）",
  "items": [
    {
      "title": "子任务标题（简洁明确）",
      "content": "子任务的详细描述",
      "priority": 0,
      "reason": "为什么建议这个任务（一句话）"
    }
  ]
}''');
      systemPrompt.writeln();
      systemPrompt.writeln('priority 取值：0=低优先级, 1=中优先级, 2=高优先级');
      systemPrompt.writeln('items 数量建议 3-6 个，按执行顺序排列。');
    } else {
      systemPrompt.writeln('''{
  "type": "daily_suggestions",
  "summary": "今日建议概述（一句话）",
  "items": [
    {
      "title": "建议的任务标题",
      "content": "任务的详细描述",
      "priority": 0,
      "reason": "推荐理由（基于用户画像的个性化说明）"
    }
  ]
}''');
      systemPrompt.writeln();
      systemPrompt.writeln('priority 取值：0=低优先级, 1=中优先级, 2=高优先级');
      systemPrompt.writeln('根据用户的收藏文章、笔记、当前待办等信息，给出 3-5 个个性化的任务建议。');
      systemPrompt.writeln('建议应该具体、可执行，不要太笼统。');
    }

    systemPrompt.writeln();
    systemPrompt.writeln('以下是用户的上下文信息：');
    systemPrompt.writeln(userContext);

    messages.add({
      'role': 'system',
      'content': systemPrompt.toString(),
    });

    if (mode == 'breakdown' && userInput != null && userInput.isNotEmpty) {
      messages.add({
        'role': 'user',
        'content': '请帮我将以下目标拆解为具体的子任务：\n\n$userInput',
      });
    } else {
      messages.add({
        'role': 'user',
        'content': '请根据我的上下文信息，给出今日任务建议。',
      });
    }

    return messages;
  }

  /// 构建文章上下文
  static String _buildArticleContext(ArticleContent article) {
    final buffer = StringBuffer();
    
    buffer.writeln('文章标题：${article.title}');
    
    if (article.author != null) {
      buffer.writeln('作者：${article.author}');
    }
    
    buffer.writeln('来源：${article.platform}');
    
    if (article.publishTime != null) {
      buffer.writeln('发布时间：${article.publishTime}');
    }
    
    buffer.writeln();
    buffer.writeln('正文内容：');
    buffer.writeln(article.content);
    
    return buffer.toString();
  }

  /// 估算 Token 数量（粗略估算：中文约1.5字符/token，英文约4字符/token）
  static int estimateTokens(String text) {
    final chineseCount = text.runes.where((r) => r > 0x4E00 && r < 0x9FA5).length;
    final otherCount = text.length - chineseCount;
    return (chineseCount * 1.5 + otherCount / 4).ceil();
  }

  /// 压缩消息历史（当 Token 超过限制时）
  static List<Map<String, String>> compressHistory(
    List<Map<String, String>> messages,
    int maxTokens,
  ) {
    AILogger.debug('开始压缩消息历史', tag: AIConstants.tagService);
    
    int totalTokens = messages.fold(0, (sum, msg) => sum + estimateTokens(msg['content'] ?? ''));
    
    if (totalTokens <= maxTokens) {
      AILogger.debug('无需压缩', tag: AIConstants.tagService);
      return messages;
    }

    // 保留系统消息和最近的对话
    final systemMessages = messages.where((m) => m['role'] == 'system').toList();
    final userMessages = messages.where((m) => m['role'] != 'system').toList();

    // 从最新的消息开始保留
    final compressed = <Map<String, String>>[...systemMessages];
    var currentTokens = systemMessages.fold(0, (sum, msg) => sum + estimateTokens(msg['content'] ?? ''));

    for (var i = userMessages.length - 1; i >= 0; i--) {
      final msg = userMessages[i];
      final tokens = estimateTokens(msg['content'] ?? '');
      
      if (currentTokens + tokens > maxTokens) {
        break;
      }
      
      compressed.insert(systemMessages.length, msg);
      currentTokens += tokens;
    }

    AILogger.info('消息历史已压缩: ${messages.length} -> ${compressed.length}', tag: AIConstants.tagService);
    return compressed;
  }
}
