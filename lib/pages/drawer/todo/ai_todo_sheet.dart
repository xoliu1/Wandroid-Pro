import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/ai/models/ai_todo_suggestion.dart';
import 'package:notes_app/ai/providers/ai_todo_provider.dart';
import 'package:notes_app/model/Todo.dart';
import 'package:notes_app/providers/task_provider.dart';
import 'package:notes_app/remote/CgiTodo.dart';
import 'package:notes_app/utils/app_colors.dart';
import 'package:toastification/toastification.dart';

/// AI TODO 智能助手 BottomSheet
/// 
/// 提供两种功能：
/// 1. 智能拆解：输入大目标，AI 拆解为子任务
/// 2. 每日建议：根据用户画像推荐任务
class AITodoSheet extends ConsumerStatefulWidget {
  const AITodoSheet({super.key});

  @override
  ConsumerState<AITodoSheet> createState() => _AITodoSheetState();
}

class _AITodoSheetState extends ConsumerState<AITodoSheet> {
  final _goalController = TextEditingController();
  int _selectedMode = 0; // 0: 智能拆解, 1: 每日建议

  @override
  void dispose() {
    _goalController.dispose();
    // 不在这里 reset，让用户返回后还能看到结果
    super.dispose();
  }

  void _onSubmit() {
    if (_selectedMode == 0) {
      final goal = _goalController.text.trim();
      if (goal.isEmpty) {
        toastification.show(
          context: context,
          title: const Text('请输入你的目标'),
          primaryColor: Colors.orange,
          showProgressBar: false,
          autoCloseDuration: const Duration(seconds: 2),
        );
        return;
      }
      ref.read(aiTodoProvider.notifier).breakdownGoal(goal);
    } else {
      ref.read(aiTodoProvider.notifier).getDailySuggestions();
    }
  }

  Future<void> _createTodo(AISuggestionItem item, int index) async {
    try {
      final todo = Todo(
        id: -1,
        title: item.title,
        content: item.content,
        date: DateTime.now().millisecondsSinceEpoch,
        priority: item.priority,
        status: 0,
      );

      // 调用 API 创建
      final resp = await CgiTodo().addTodo(todo).getData();
      
      // 将 AddTodoResp 转为 Todo
      final createdTodo = Todo(
        id: resp.id,
        title: resp.title,
        content: resp.content,
        date: resp.date,
        priority: resp.priority,
        status: resp.status,
        type: resp.type,
        userId: resp.userId,
      );

      // 更新本地列表
      ref.read(todoNotifierProvider.notifier).addTodo(createdTodo);

      // 标记已创建
      ref.read(aiTodoProvider.notifier).markCreated(index);

      if (mounted) {
        toastification.show(
          context: context,
          title: Text('已创建: ${item.title}'),
          primaryColor: Colors.green,
          showProgressBar: false,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          title: Text('创建失败: $e'),
          primaryColor: Colors.red,
          showProgressBar: false,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _createAll(AITodoSuggestion suggestion) async {
    final state = ref.read(aiTodoProvider);
    for (int i = 0; i < suggestion.items.length; i++) {
      if (!state.createdIndices.contains(i)) {
        await _createTodo(suggestion.items[i], i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiState = ref.watch(aiTodoProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                const Icon(CupertinoIcons.sparkles, size: 20, color: CupertinoColors.activeBlue),
                const SizedBox(width: 8),
                Text(
                  'AI 智能助手',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(CupertinoIcons.xmark_circle_fill, size: 24, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 功能选择
          _buildModeSelector(isDark),
          const SizedBox(height: 16),
          // 内容区域
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 智能拆解模式：输入框
                  if (_selectedMode == 0) _buildGoalInput(isDark),
                  // 提交按钮
                  if (!aiState.isLoading && !aiState.isCompleted)
                    _buildSubmitButton(),
                  // AI 结果区域
                  if (aiState.isLoading || aiState.isCompleted || aiState.error != null)
                    _buildResultArea(aiState, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildModeButton(0, '🎯 智能拆解', isDark),
            _buildModeButton(1, '📋 每日建议', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(int mode, String title, bool isDark) {
    final isSelected = _selectedMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedMode != mode) {
            setState(() => _selectedMode = mode);
            // 切换模式时重置状态
            ref.read(aiTodoProvider.notifier).reset();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.grey[700] : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.link(context)
                  : AppColors.secondaryText(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '输入你的大目标：',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryText(context),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _goalController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '例如：学习 Flutter 动画、准备面试...',
            hintStyle: TextStyle(
              color: AppColors.tertiaryText(context),
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppColors.inputBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.activeBlue,
        borderRadius: BorderRadius.circular(12),
        onPressed: _onSubmit,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.sparkles, size: 18),
            const SizedBox(width: 8),
            Text(
              _selectedMode == 0 ? 'AI 拆解' : 'AI 建议',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea(AITodoState aiState, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // 加载中
        if (aiState.isLoading && aiState.suggestion == null)
          _buildLoadingView(),
        // 错误
        if (aiState.error != null && aiState.suggestion == null)
          _buildErrorView(aiState.error!),
        // 结果
        if (aiState.suggestion != null)
          _buildSuggestionCards(aiState, isDark),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 12),
          Text(
            'AI 正在思考...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.destructiveRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            error,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.destructiveRed,
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoColors.destructiveRed,
            borderRadius: BorderRadius.circular(8),
            onPressed: _onSubmit,
            child: const Text('重试', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCards(AITodoState aiState, bool isDark) {
    final suggestion = aiState.suggestion!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 概述
        if (suggestion.summary.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(isDark ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.lightbulb_fill, size: 16, color: CupertinoColors.activeBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.summary,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText(context),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // 建议卡片列表
        ...List.generate(suggestion.items.length, (index) {
          final item = suggestion.items[index];
          final isCreated = aiState.createdIndices.contains(index);
          return _buildSuggestionCard(item, index, isCreated, isDark);
        }),
        // 全部创建按钮
        if (suggestion.items.length > 1 &&
            aiState.createdIndices.length < suggestion.items.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.activeGreen,
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _createAll(suggestion),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.tray_arrow_down_fill, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '全部创建',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(AISuggestionItem item, int index, bool isCreated, bool isDark) {
    final priorityColor = item.priority >= 2
        ? CupertinoColors.destructiveRed
        : item.priority == 1
            ? CupertinoColors.systemOrange
            : CupertinoColors.activeBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCreated
            ? CupertinoColors.activeGreen.withOpacity(isDark ? 0.1 : 0.05)
            : AppColors.inputBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCreated
              ? CupertinoColors.activeGreen.withOpacity(0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 优先级标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.priorityLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 标题
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCreated
                        ? AppColors.tertiaryText(context)
                        : AppColors.primaryText(context),
                    decoration: isCreated ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // 创建按钮
              if (!isCreated)
                GestureDetector(
                  onTap: () => _createTodo(item, index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.add, size: 14, color: CupertinoColors.activeBlue),
                        SizedBox(width: 4),
                        Text(
                          '创建',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Icon(CupertinoIcons.checkmark_circle_fill, size: 20, color: CupertinoColors.activeGreen),
            ],
          ),
          if (item.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.content,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondaryText(context),
                height: 1.4,
              ),
            ),
          ],
          if (item.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.lightbulb,
                  size: 12,
                  color: CupertinoColors.systemOrange.withOpacity(0.8),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.reason,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.tertiaryText(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 显示 AI TODO 智能助手 BottomSheet
void showAITodoSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const AITodoSheet(),
  );
}
