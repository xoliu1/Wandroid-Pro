import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/local/KV.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/theme.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _useNewTodoUI = true;
  bool _aiStyleMorphing = true;
  bool _showExtractDebugDialog = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _useNewTodoUI = getUseNewTodoUI();
      _aiStyleMorphing = getAIStyleMorphing();
      _showExtractDebugDialog = getShowExtractDebugDialog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentAccent = ref.watch(accentColorProvider);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('界面设置'),
          _buildSection(
            children: [
              SwitchListTile(
                secondary: Icon(Icons.task_alt, color: colorScheme.primary),
                title: const Text('新版待办界面'),
                subtitle: const Text('标准列表展示，支持状态过滤'),
                value: _useNewTodoUI,
                onChanged: (value) {
                  setState(() {
                    _useNewTodoUI = value;
                    setUseNewTodoUI(value);
                  });
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.animation, color: Colors.purple),
                title: const Text('AI 科技感样式'),
                subtitle: const Text('使用 Morphing 动画交互'),
                value: _aiStyleMorphing,
                onChanged: (value) {
                  setState(() {
                    _aiStyleMorphing = value;
                    setAIStyleMorphing(value);
                  });
                },
              ),
            ],
          ),
          _buildSectionHeader('主题设置'),
          _buildSection(
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6, color: Colors.amber),
                title: const Text('夜间模式'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('强调色'),
                subtitle: Text(
                  _getAccentColorName(currentAccent),
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: currentAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _showAccentColorPicker(context, ref),
              ),
            ],
          ),
          _buildSectionHeader('调试选项'),
          _buildSection(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.bug_report_outlined, color: Colors.orange),
                title: const Text('显示提取调试弹窗'),
                subtitle: const Text('Debug 模式下显示内容提取结果'),
                value: _showExtractDebugDialog,
                onChanged: (value) {
                  setState(() {
                    _showExtractDebugDialog = value;
                    setShowExtractDebugDialog(value);
                  });
                },
              ),
            ],
          ),
          _buildSectionHeader('关于'),
          _buildSection(
            children: [
              ListTile(
                leading: Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
                title: const Text('版本'),
                trailing: Text(
                  '1.0.0',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 获取强调色名称
  String _getAccentColorName(Color color) {
    for (final preset in accentColorPresets) {
      if (preset.color.value == color.value) {
        return preset.name;
      }
    }
    return '自定义';
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final themeNotifier = ref.read(themeModeProvider.notifier);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('亮色'),
              onTap: () {
                themeNotifier.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('暗色'),
              onTap: () {
                themeNotifier.setTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('跟随系统'),
              onTap: () {
                themeNotifier.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示强调色选择器
  Future<void> _showAccentColorPicker(BuildContext context, WidgetRef ref) async {
    final accentNotifier = ref.read(accentColorProvider.notifier);
    final currentColor = ref.read(accentColorProvider);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 拖拽指示条
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '选择强调色',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '强调色会影响按钮、链接、标签等元素的颜色',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                // 颜色网格
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                children: accentColorPresets.map((preset) {
                    final isSelected = preset.color.value == currentColor.value;
                    return PressableScale(
                      scaleDown: 0.90,
                      onTap: () {
                        accentNotifier.setAccentColor(preset.color);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: preset.color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                                  : Border.all(color: Colors.transparent, width: 3),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: preset.color.withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 24)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
