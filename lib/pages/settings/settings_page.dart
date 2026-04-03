import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/local/KV.dart';
import 'package:notes_app/utils/animations.dart';
import 'package:notes_app/utils/mcm_widget.dart';
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
    final currentAccent = ref.watch(accentColorProvider);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);
    final bg = MCMColors.background(context);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MCM Header
            MCMHeader(
              title: 'SETTINGS',
              subtitle: '个性化你的应用体验',
              leading: MCMBackButton(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMCMSectionLabel('界面设置'),
                  _buildMCMCard(
                    context,
                    cardBg: cardBg,
                    divColor: divColor,
                    children: [
                      _buildMCMSwitch(
                        context,
                        icon: Icons.task_alt,
                        iconColor: MCMColors.olive,
                        title: '新版待办界面',
                        subtitle: '标准列表展示，支持状态过滤',
                        value: _useNewTodoUI,
                        textColor: textColor,
                        subColor: subColor,
                        onChanged: (value) {
                          setState(() {
                            _useNewTodoUI = value;
                            setUseNewTodoUI(value);
                          });
                        },
                      ),
                      Container(height: 1, color: divColor, margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _buildMCMSwitch(
                        context,
                        icon: Icons.animation,
                        iconColor: MCMColors.grayBlue,
                        title: 'AI 科技感样式',
                        subtitle: '使用 Morphing 动画交互',
                        value: _aiStyleMorphing,
                        textColor: textColor,
                        subColor: subColor,
                        onChanged: (value) {
                          setState(() {
                            _aiStyleMorphing = value;
                            setAIStyleMorphing(value);
                          });
                        },
                      ),
                    ],
                  ),
                  _buildMCMSectionLabel('主题设置'),
                  _buildMCMCard(
                    context,
                    cardBg: cardBg,
                    divColor: divColor,
                    children: [
                      _buildMCMTile(
                        context,
                        icon: Icons.brightness_6,
                        iconColor: MCMColors.mustard,
                        title: '夜间模式',
                        textColor: textColor,
                        subColor: subColor,
                        onTap: () => _showThemePicker(context, ref),
                      ),
                      Container(height: 1, color: divColor, margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _buildAccentColorTile(context, currentAccent, textColor, subColor, divColor),
                    ],
                  ),
                  _buildMCMSectionLabel('调试选项'),
                  _buildMCMCard(
                    context,
                    cardBg: cardBg,
                    divColor: divColor,
                    children: [
                      _buildMCMSwitch(
                        context,
                        icon: Icons.bug_report_outlined,
                        iconColor: MCMColors.coral,
                        title: '显示提取调试弹窗',
                        subtitle: 'Debug 模式下显示内容提取结果',
                        value: _showExtractDebugDialog,
                        textColor: textColor,
                        subColor: subColor,
                        onChanged: (value) {
                          setState(() {
                            _showExtractDebugDialog = value;
                            setShowExtractDebugDialog(value);
                          });
                        },
                      ),
                    ],
                  ),
                  _buildMCMSectionLabel('关于'),
                  _buildMCMCard(
                    context,
                    cardBg: cardBg,
                    divColor: divColor,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: MCMColors.grayBlue.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline, color: MCMColors.grayBlue, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text('版本', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                            ),
                            Text('1.0.0', style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // MCM 底部装饰
                  Center(
                    child: MCMStarburst(
                      size: 32,
                      color: MCMColors.mustard.withOpacity(0.15),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MCM 风格 Section 标签
  Widget _buildMCMSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: MCMSectionLabel(title.toUpperCase()),
    );
  }

  /// MCM 风格卡片容器
  Widget _buildMCMCard(BuildContext context, {
    required Color cardBg,
    required Color divColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C2416).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  /// MCM 风格开关项
  Widget _buildMCMSwitch(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required Color textColor,
    required Color subColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subColor)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  /// MCM 风格列表项
  Widget _buildMCMTile(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
            ),
            Icon(Icons.chevron_right_rounded, color: MCMColors.mustard.withOpacity(0.6), size: 20),
          ],
        ),
      ),
    );
  }

  /// 强调色选择项
  Widget _buildAccentColorTile(BuildContext context, Color currentAccent, Color textColor, Color subColor, Color divColor) {
    return GestureDetector(
      onTap: () => _showAccentColorPicker(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: currentAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.palette_outlined, color: currentAccent, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('强调色', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                  Text(
                    _getAccentColorName(currentAccent),
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            ),
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: currentAccent,
                shape: BoxShape.circle,
                border: Border.all(color: divColor, width: 2),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: MCMColors.mustard.withOpacity(0.6), size: 20),
          ],
        ),
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

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final themeNotifier = ref.read(themeModeProvider.notifier);

    await showMCMBottomSheet(
      context: context,
      title: '选择主题模式',
      subtitle: '调整应用的明暗风格',
      items: [
        MCMSheetItem(
          icon: Icons.light_mode_rounded,
          label: '亮色模式',
          sublabel: '温暖的 MCM 米色调',
          color: MCMColors.mustard,
          onTap: () {
            themeNotifier.setTheme(ThemeMode.light);
            Navigator.pop(context);
          },
        ),
        MCMSheetItem(
          icon: Icons.dark_mode_rounded,
          label: '暗色模式',
          sublabel: '深沉的胡桃木色调',
          color: MCMColors.grayBlue,
          onTap: () {
            themeNotifier.setTheme(ThemeMode.dark);
            Navigator.pop(context);
          },
        ),
        MCMSheetItem(
          icon: Icons.brightness_auto_rounded,
          label: '跟随系统',
          sublabel: '自动适配系统设置',
          color: MCMColors.olive,
          onTap: () {
            themeNotifier.setTheme(ThemeMode.system);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  /// 显示强调色选择器
  Future<void> _showAccentColorPicker(BuildContext context, WidgetRef ref) async {
    final accentNotifier = ref.read(accentColorProvider.notifier);
    final currentColor = ref.read(accentColorProvider);
    final cardBg = MCMColors.card(context);
    final divColor = MCMColors.dividerColor(context);
    final textColor = MCMColors.primaryText(context);
    final subColor = MCMColors.secondaryText(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 拖拽指示条
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(
                        color: divColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '选择强调色',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '强调色会影响按钮、链接、标签等元素的颜色',
                    style: TextStyle(fontSize: 12, color: subColor),
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
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                color: preset.color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: textColor, width: 3)
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
                                color: isSelected ? preset.color : subColor,
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
          ),
        );
      },
    );
  }
}
