import '../core/logger.dart';
import '../models/article_content.dart';
import 'ai_prompt_manager.dart';
import '../../local/KV.dart';

class AIMessageComposer {
  AIMessageComposer._();

  static List<Map<String, String>> articleChat({
    required ArticleContent article,
    required String userQuestion,
    List<Map<String, String>>? history,
  }) {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': AIPromptManager.buildSystemPrompt(
          channel: kPromptChannelArticleChat,
          scene: 'article_chat',
          sections: [
            '以下是用户正在阅读的文章内容：\n\n${AIContextManager.buildArticleContext(article)}',
          ],
        ),
      },
    ];

    if (history != null && history.isNotEmpty) {
      messages.addAll(AIContextManager.trimHistory(history));
      AILogger.debug('添加历史对话: ${history.length} 条', tag: 'AIMessageComposer');
    }

    messages.add({
      'role': 'user',
      'content': AIContextManager.compactText(userQuestion, maxChars: 2000),
    });
    return messages;
  }

  static List<Map<String, String>> plainChat({
    required String userQuestion,
    List<Map<String, String>>? history,
  }) {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': AIPromptManager.buildSystemPrompt(
          channel: kPromptChannelArticleChat,
          scene: 'plain_chat',
          sections: const ['当前场景不提供文章上下文，请直接回答用户问题。'],
        ),
      },
    ];

    if (history != null && history.isNotEmpty) {
      messages.addAll(AIContextManager.trimHistory(history));
      AILogger.debug('添加历史对话: ${history.length} 条', tag: 'AIMessageComposer');
    }

    messages.add({
      'role': 'user',
      'content': AIContextManager.compactText(userQuestion, maxChars: 2000),
    });
    return messages;
  }

  static List<Map<String, String>> questionExplain({
    required String title,
    required String description,
    String? userContext,
  }) {
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': AIPromptManager.buildSystemPrompt(
          channel: kPromptChannelQuestionExplain,
          scene: 'question_explain',
          sections: [
            if ((userContext ?? '').trim().isNotEmpty)
              '以下是用户的背景信息，可以据此调整回答的深度和侧重点：\n${AIContextManager.safeContext(userContext)}',
          ],
        ),
      },
    ];

    final userContent = StringBuffer()
      ..writeln('请解答以下技术问题：')
      ..writeln()
      ..writeln('**题目**：$title');
    if (description.isNotEmpty) {
      userContent
        ..writeln()
        ..writeln('**描述**：$description');
    }

    messages.add({
      'role': 'user',
      'content': userContent.toString(),
    });
    return messages;
  }

  static List<Map<String, String>> continueWriting({
    required String existingContent,
    String? selectedText,
  }) {
    return [
      {
        'role': 'system',
        'content': AIPromptManager.buildSystemPrompt(
          channel: kPromptChannelNoteContinue,
          scene: 'note_continue',
        ),
      },
      {
        'role': 'user',
        'content': selectedText != null && selectedText.isNotEmpty
            ? '以下是笔记的完整内容：\n\n${AIContextManager.compactText(existingContent)}\n\n请从以下选中的部分开始续写：\n\n${AIContextManager.compactText(selectedText, maxChars: 1500)}'
            : '以下是笔记的内容，请从末尾继续续写：\n\n${AIContextManager.compactText(existingContent)}',
      },
    ];
  }

  static List<Map<String, String>> polish({
    required String content,
  }) {
    return [
      {
        'role': 'system',
        'content': AIPromptManager.buildSystemPrompt(
          channel: kPromptChannelNotePolish,
          scene: 'note_polish',
        ),
      },
      {
        'role': 'user',
        'content': '请润色以下内容：\n\n${AIContextManager.compactText(content)}',
      },
    ];
  }

  static List<Map<String, String>> dailyReport({
    required String dailyData,
    String? userContext,
  }) {
    const schemaSection = '''**重要**：你必须严格按照以下 JSON 格式返回结果，不要输出任何其他内容（不要输出 markdown 代码块标记）：

{
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
}''';
    const rulesSection = '''规则：
1. 如果某个板块没有数据，对应字段设为 null（不要省略字段）
2. items/completed/pending 数组最多 5 条
3. suggestions 给出 1-2 条具体可执行的建议
4. 语气亲切自然，summary 字段像朋友一样聊天
5. 只输出 JSON，不要有任何其他文字''';

    return [
      {
        'role': 'system',
        'content': AIPromptManager.buildSystemPrompt(
          channel: kPromptChannelDailyReport,
          scene: 'daily_report',
          sections: [
            schemaSection,
            rulesSection,
            if ((userContext ?? '').trim().isNotEmpty)
              '以下是用户的背景信息，可以据此让总结更个性化：\n${AIContextManager.safeContext(userContext)}',
          ],
        ),
      },
      {
        'role': 'user',
        'content':
            '请根据以下今日活动数据，生成我的日报总结：\n\n${AIContextManager.compactText(dailyData, maxChars: 3500)}',
      },
    ];
  }

  static List<Map<String, String>> todoAssistant({
    required String mode,
    String? userInput,
    required String userContext,
  }) {
    final systemPrompt = StringBuffer()
      ..writeln(AIPromptManager.buildSystemPrompt(
        channel: kPromptChannelTodoAssistant,
        scene: 'todo_assistant_$mode',
      ))
      ..writeln()
      ..writeln('**重要**：你必须严格按照以下 JSON 格式返回结果，不要输出任何其他内容（不要输出 markdown 代码块标记）：')
      ..writeln();

    if (mode == 'breakdown') {
      systemPrompt
        ..writeln('''{
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
}''')
        ..writeln()
        ..writeln('priority 取值：0=低优先级, 1=中优先级, 2=高优先级')
        ..writeln('items 数量建议 3-6 个，按执行顺序排列。');
    } else {
      systemPrompt
        ..writeln('''{
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
}''')
        ..writeln()
        ..writeln('priority 取值：0=低优先级, 1=中优先级, 2=高优先级')
        ..writeln('根据用户的收藏文章、笔记、当前待办等信息，给出 3-5 个个性化的任务建议。')
        ..writeln('建议应该具体、可执行，不要太笼统。');
    }

    systemPrompt
      ..writeln()
      ..writeln('以下是用户的上下文信息：')
      ..writeln(AIContextManager.safeContext(userContext));

    return [
      {
        'role': 'system',
        'content': systemPrompt.toString(),
      },
      {
        'role': 'user',
        'content': mode == 'breakdown' && userInput != null && userInput.isNotEmpty
            ? '请帮我将以下目标拆解为具体的子任务：\n\n${AIContextManager.compactText(userInput, maxChars: 2000)}'
            : '请根据我的上下文信息，给出今日任务建议。',
      },
    ];
  }

  static List<Map<String, String>> weeklyReport({
    required String weeklyData,
    required String weekRange,
    String? userContext,
  }) {
    final systemPrompt = StringBuffer()
      ..writeln('你是一个贴心的个人效率助手，负责为用户生成每周学习成长报告。')
      ..writeln('请根据用户本周的活动数据，生成一份结构化的周报。')
      ..writeln()
      ..writeln('**重要**：你必须严格按照以下 JSON 格式返回结果，不要输出任何其他内容（不要输出 markdown 代码块标记）：')
      ..writeln()
      ..writeln('''{
  "overview": "用 2-3 句话总结本周的整体学习情况（必填）",
  "week_range": "$weekRange",
  "reading": {
    "summary": "本周阅读主题和趋势的总结",
    "items": ["重点文章1", "重点文章2"],
    "total_count": 0,
    "total_minutes": 0
  },
  "todos": {
    "summary": "本周任务完成情况总结",
    "completed_count": 0,
    "pending_count": 0,
    "highlights": ["重要完成的任务1", "重要完成的任务2"]
  },
  "notes": {
    "summary": "本周笔记主题总结",
    "total_count": 0,
    "topics": ["笔记主题1", "笔记主题2"]
  },
  "growth": {
    "assessment": "对本周学习成长的整体评价",
    "score": 7,
    "strengths": ["做得好的方面1", "做得好的方面2"],
    "improvements": ["可以改进的方面1"]
  },
  "next_week_goals": ["下周目标1", "下周目标2", "下周目标3"]
}''')
      ..writeln()
      ..writeln('规则：')
      ..writeln('1. 如果某个板块没有数据，对应字段设为 null')
      ..writeln('2. growth.score 范围 1-10，根据活跃度和学习深度评分')
      ..writeln('3. next_week_goals 给出 2-3 条具体可执行的目标')
      ..writeln('4. 语气亲切自然，像朋友一样鼓励用户')
      ..writeln('5. 只输出 JSON，不要有任何其他文字');

    if (userContext != null && userContext.isNotEmpty) {
      systemPrompt
        ..writeln()
        ..writeln('以下是用户的背景信息，可以据此让总结更个性化：')
        ..writeln(AIContextManager.safeContext(userContext));
    }

    return [
      {
        'role': 'system',
        'content': systemPrompt.toString(),
      },
      {
        'role': 'user',
        'content':
            '请根据以下本周活动数据，生成我的周报总结：\n\n${AIContextManager.compactText(weeklyData, maxChars: 4500)}',
      },
    ];
  }
}
