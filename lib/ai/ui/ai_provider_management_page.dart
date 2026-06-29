import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_provider_config.dart';
import '../providers/ai_provider_manager.dart';
import '../providers/ai_test_provider.dart';
import '../../utils/platform_utils.dart';
import 'ai_diagnostics_page.dart';
import 'ai_provider_edit_page.dart';

// ─── Mid-Century Modern 色彩体系 ───────────────────────────────────────────
class _MCM {
  static const cream = Color(0xFFF5E6D3);       // 温暖米色
  static const white = Color(0xFFFFFFFF);
  static const darkBrown = Color(0xFF2C2416);    // 深棕色
  static const orange = Color(0xFFD97642);       // 橙红强调色
  static const mustard = Color(0xFFD4A574);      // 芥末黄
  static const olive = Color(0xFF4A7C59);        // 橄榄绿
  static const walnut = Color(0xFF6B5D4F);       // 胡桃木
  static const teak = Color(0xFF8B7355);         // 柚木
  static const grayBlue = Color(0xFF7D9BA8);     // 灰蓝
  static const coral = Color(0xFFE57A77);        // 珊瑚粉
  static const surface = Color(0xFFFAF0E6);      // 卡片背景（亚麻白）
  static const divider = Color(0xFFE8D5C0);      // 分割线
}

/// AI 配置管理页面 — Mid-Century Modern 风格
class AIProviderManagementPage extends ConsumerWidget {
  const AIProviderManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(aiProviderManagerProvider);
    final activeProvider = ref.watch(activeAIProviderProvider);

    return Scaffold(
      backgroundColor: _MCM.cream,
      body: CustomScrollView(
        slivers: [
          // ── 顶部大标题区域 ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, ref),
          ),

          // ── 内容区域 ────────────────────────────────────────────────────
          if (providers.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context, ref),
            )
          else ...[
            // 当前激活配置
            if (activeProvider != null)
              SliverToBoxAdapter(
                child: _buildSection(
                  label: 'ACTIVE',
                  child: _buildActiveCard(context, ref, activeProvider),
                ),
              ),

            // 其他配置列表
            if (providers.where((p) => !p.isActive).isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSection(
                  label: 'SAVED',
                  child: _buildProviderList(context, ref, providers.where((p) => !p.isActive).toList()),
                ),
              ),

            // 使用说明
            SliverToBoxAdapter(
              child: _buildHelpSection(context),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  // ── 顶部 Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      color: _MCM.cream,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 返回 + 操作按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 返回按钮
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _MCM.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _MCM.darkBrown.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _MCM.darkBrown),
                ),
              ),
              // 添加按钮
              GestureDetector(
                onTap: () => _showAddProviderMenu(context, ref),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _MCM.orange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _MCM.orange.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 18, color: _MCM.white),
                      SizedBox(width: 4),
                      Text(
                        'ADD',
                        style: TextStyle(
                          color: _MCM.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // 装饰性几何元素
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _MCM.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: _MCM.mustard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 大标题
          const Text(
            'AI CONFIG',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _MCM.darkBrown,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage your AI providers',
            style: TextStyle(
              fontSize: 14,
              color: _MCM.walnut,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 包装器 ────────────────────────────────────────────────────────
  Widget _buildSection({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 小标签
          Row(
            children: [
              Container(
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: _MCM.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _MCM.walnut,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── 当前激活配置卡片 ──────────────────────────────────────────────────────
  Widget _buildActiveCard(BuildContext context, WidgetRef ref, AIProviderConfig config) {
    return GestureDetector(
      onTap: () => _showProviderActions(context, ref, config),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _MCM.darkBrown,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _MCM.darkBrown.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // 激活指示器
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _MCM.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: _MCM.white, size: 24),
            ),
            const SizedBox(width: 16),
            // 名称 + 模型
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _MCM.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.modelId,
                    style: TextStyle(
                      fontSize: 12,
                      color: _MCM.white.withValues(alpha: 0.6),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            // 状态徽章
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _MCM.olive,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'ON',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _MCM.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 其他配置列表 ──────────────────────────────────────────────────────────
  Widget _buildProviderList(BuildContext context, WidgetRef ref, List<AIProviderConfig> providers) {
    return Column(
      children: providers.asMap().entries.map((entry) {
        final i = entry.key;
        final p = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: i < providers.length - 1 ? 10 : 0),
          child: _buildProviderCard(context, ref, p),
        );
      }).toList(),
    );
  }

  Widget _buildProviderCard(BuildContext context, WidgetRef ref, AIProviderConfig config) {
    return GestureDetector(
      onTap: () => _showProviderActions(context, ref, config),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _MCM.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _MCM.divider, width: 1),
        ),
        child: Row(
          children: [
            // 圆形图标
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _MCM.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hub_outlined, color: _MCM.walnut, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _MCM.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    config.modelId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _MCM.walnut,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _MCM.mustard, size: 20),
          ],
        ),
      ),
    );
  }

  // ── 空状态 ────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 装饰性星爆图案
            _StarburstIcon(size: 80, color: _MCM.mustard),
            const SizedBox(height: 28),
            const Text(
              'NO CONFIG YET',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _MCM.darkBrown,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add your first AI provider\nto get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _MCM.walnut,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _showAddProviderMenu(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: _MCM.orange,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _MCM.orange.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'ADD PROVIDER',
                  style: TextStyle(
                    color: _MCM.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 使用说明 ──────────────────────────────────────────────────────────────
  Widget _buildHelpSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _MCM.grayBlue.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _MCM.grayBlue.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _MCM.grayBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline_rounded, size: 16, color: _MCM.grayBlue),
                ),
                const SizedBox(width: 10),
                const Text(
                  'HOW TO USE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _MCM.grayBlue,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...[
              '点击 ADD 选择预设或自定义配置',
              '填写 API Key（需先注册对应平台）',
              '保存后自动设为当前使用',
              '点击配置可切换、编辑或删除',
              '在 WebView 阅读文章时即可使用 AI',
            ].asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: _MCM.mustard.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _MCM.walnut,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _MCM.darkBrown,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AIDiagnosticsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: const Text('查看 AI Diagnostics'),
            ),
            ],
          ),
        ),
      );
  }

  // ── 添加配置菜单 ──────────────────────────────────────────────────────────
  void _showAddProviderMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MCMBottomSheet(
        title: 'ADD CONFIG',
        subtitle: 'Choose how to configure',
        items: [
          _MCMSheetItem(
            icon: Icons.list_alt_rounded,
            label: '从预设选择',
            sublabel: 'Pick from templates',
            color: _MCM.orange,
            onTap: () {
              Navigator.pop(context);
              _showPresetPicker(context, ref);
            },
          ),
          _MCMSheetItem(
            icon: Icons.tune_rounded,
            label: '自定义配置',
            sublabel: 'Manual setup',
            color: _MCM.grayBlue,
            onTap: () {
              Navigator.pop(context);
              _navigateToEditPage(context, null);
            },
          ),
        ],
      ),
    );
  }

  void _showPresetPicker(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AIProviderPresetPickerPage(ref: ref),
      ),
    );
  }

  // ── 配置操作菜单 ──────────────────────────────────────────────────────────
  void _showProviderActions(BuildContext context, WidgetRef ref, AIProviderConfig config) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MCMBottomSheet(
        title: config.name,
        subtitle: config.modelId,
        items: [
          _MCMSheetItem(
            icon: Icons.network_check_rounded,
            label: '测试配置',
            sublabel: 'Test connection',
            color: _MCM.olive,
            onTap: () {
              Navigator.pop(context);
              _testProvider(context, config);
            },
          ),
          if (!config.isActive)
            _MCMSheetItem(
              icon: Icons.check_circle_outline_rounded,
              label: '设为当前使用',
              sublabel: 'Set as active',
              color: _MCM.orange,
              onTap: () {
                Navigator.pop(context);
                ref.read(aiProviderManagerProvider.notifier).activateProvider(config.id);
              },
            ),
          _MCMSheetItem(
            icon: Icons.edit_outlined,
            label: '编辑',
            sublabel: 'Edit configuration',
            color: _MCM.grayBlue,
            onTap: () {
              Navigator.pop(context);
              _navigateToEditPage(context, config);
            },
          ),
          _MCMSheetItem(
            icon: Icons.delete_outline_rounded,
            label: '删除',
            sublabel: 'Remove this config',
            color: _MCM.coral,
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, ref, config);
            },
          ),
        ],
      ),
    );
  }

  void _testProvider(BuildContext context, AIProviderConfig config) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AITestDialog(config: config),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AIProviderConfig config) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _MCM.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _MCM.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _MCM.coral, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'DELETE CONFIG',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _MCM.darkBrown,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '确定要删除 ${config.name} 吗？',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _MCM.walnut, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _MCM.cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _MCM.divider),
                        ),
                        child: const Center(
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _MCM.walnut,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(aiProviderManagerProvider.notifier).deleteProvider(config.id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _MCM.coral,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'DELETE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _MCM.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditPage(BuildContext context, AIProviderConfig? config) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AIProviderEditPage(config: config),
      ),
    );
  }
}

// ─── MCM 底部弹出菜单 ────────────────────────────────────────────────────────
class _MCMSheetItem {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _MCMSheetItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });
}

class _MCMBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_MCMSheetItem> items;

  const _MCMBottomSheet({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: _MCM.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: _MCM.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题区
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _MCM.darkBrown,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: _MCM.walnut),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _MCM.cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: _MCM.walnut),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _MCM.divider, margin: const EdgeInsets.symmetric(horizontal: 24)),
          const SizedBox(height: 8),
          // 操作项
          ...items.map((item) => GestureDetector(
            onTap: item.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _MCM.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _MCM.darkBrown,
                          ),
                        ),
                        Text(
                          item.sublabel,
                          style: const TextStyle(fontSize: 12, color: _MCM.walnut),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _MCM.mustard.withValues(alpha: 0.6), size: 18),
                ],
              ),
            ),
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

// ─── 星爆装饰图案 ─────────────────────────────────────────────────────────────
class _StarburstIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _StarburstIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarburstPainter(color: color),
    );
  }
}

class _StarburstPainter extends CustomPainter {
  final Color color;
  _StarburstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = size.width / 4.5;
    const points = 12;
    const pi = math.pi;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // 中心圆
    canvas.drawCircle(center, size.width / 8, Paint()..color = color.withValues(alpha: 0.5));
  }

  double _cos(double angle) => math.cos(angle);
  double _sin(double angle) => math.sin(angle);

  @override
  bool shouldRepaint(_StarburstPainter oldDelegate) => oldDelegate.color != color;
}

// ─── 预设选择器页面 ───────────────────────────────────────────────────────────
class AIProviderPresetPickerPage extends StatelessWidget {
  final WidgetRef ref;

  const AIProviderPresetPickerPage({
    super.key,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AIProviderConfig>>(
      future: AIProviderPreset.loadPresets(),
      builder: (context, snapshot) {
        final presets = snapshot.data ?? AIProviderPreset.presets;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          backgroundColor: _MCM.cream,
          body: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),

              if (isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: _MCM.orange),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildPresetItem(context, presets[index]),
                      ),
                      childCount: presets.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _MCM.cream,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _MCM.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _MCM.darkBrown.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _MCM.darkBrown),
            ),
          ),
          const SizedBox(height: 28),
          // 装饰
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: _MCM.mustard, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: _MCM.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'PROVIDERS',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _MCM.darkBrown,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Select a provider to configure',
            style: TextStyle(fontSize: 14, color: _MCM.walnut, letterSpacing: 0.3),
          ),
          const SizedBox(height: 20),
          // 分割线
          Container(height: 1, color: _MCM.divider),
        ],
      ),
    );
  }

  Widget _buildPresetItem(BuildContext context, AIProviderConfig preset) {
    return GestureDetector(
      onTap: () => _selectPreset(context, preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _MCM.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _MCM.divider, width: 1),
        ),
        child: Row(
          children: [
            // 色块图标
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _providerColor(preset.id).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  preset.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _providerColor(preset.id),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // 名称 + 模型
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _MCM.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preset.modelId,
                    style: const TextStyle(fontSize: 12, color: _MCM.walnut),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _MCM.mustard, size: 20),
          ],
        ),
      ),
    );
  }

  // 根据 provider id 返回对应的强调色
  Color _providerColor(String id) {
    if (id.contains('deepseek')) return _MCM.orange;
    if (id.contains('openai') || id.contains('gpt')) return _MCM.olive;
    if (id.contains('claude') || id.contains('anthropic')) return _MCM.coral;
    if (id.contains('gemini') || id.contains('google')) return _MCM.grayBlue;
    if (id.contains('qwen') || id.contains('aliyun')) return _MCM.mustard;
    if (id.contains('kimi') || id.contains('moonshot')) return const Color(0xFF9B7EC8);
    if (id.contains('zhipu') || id.contains('glm')) return _MCM.teak;
    if (id.contains('doubao') || id.contains('volces')) return _MCM.grayBlue;
    if (id.contains('minimax')) return _MCM.coral;
    if (id.contains('siliconflow')) return _MCM.olive;
    if (id.contains('grok')) return _MCM.darkBrown;
    return _MCM.walnut;
  }

  void _selectPreset(BuildContext context, AIProviderConfig preset) {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AIProviderEditPage(
          config: preset,
          isFromPreset: true,
        ),
      ),
    );
  }
}

// ─── AI 测试对话框 ────────────────────────────────────────────────────────────
class _AITestDialog extends ConsumerStatefulWidget {
  final AIProviderConfig config;

  const _AITestDialog({required this.config});

  @override
  ConsumerState<_AITestDialog> createState() => _AITestDialogState();
}

class _AITestDialogState extends ConsumerState<_AITestDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiTestProvider.notifier).testConfig(widget.config);
    });
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(aiTestProvider);

    if (!testState.isTesting && testState.result != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
          _showTestResult(context, testState.result!);
          ref.read(aiTestProvider.notifier).reset();
        }
      });
    }

    return Dialog(
      backgroundColor: _MCM.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 动画指示器
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _MCM.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: _MCM.orange,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'TESTING',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _MCM.darkBrown,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.config.name,
              style: const TextStyle(fontSize: 13, color: _MCM.walnut),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestResult(BuildContext context, result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _MCM.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (result.success ? _MCM.olive : _MCM.coral).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  result.success ? Icons.check_rounded : Icons.close_rounded,
                  color: result.success ? _MCM.olive : _MCM.coral,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.success ? 'SUCCESS' : 'FAILED',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: result.success ? _MCM.olive : _MCM.coral,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.config.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _MCM.darkBrown,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _MCM.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      result.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: _MCM.walnut, height: 1.5),
                    ),
                    if (result.responseTime > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '响应时间 ${result.formattedResponseTime}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _MCM.mustard,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _MCM.darkBrown,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'GOT IT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _MCM.white,
                        letterSpacing: 1.5,
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
}
