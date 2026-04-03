import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ai_provider_config.dart';
import '../providers/ai_provider_manager.dart';
import '../../utils/platform_utils.dart';

// ─── Mid-Century Modern 色彩（与管理页保持一致）────────────────────────────
class _MCM {
  static const cream = Color(0xFFF5E6D3);
  static const white = Color(0xFFFFFFFF);
  static const darkBrown = Color(0xFF2C2416);
  static const orange = Color(0xFFD97642);
  static const mustard = Color(0xFFD4A574);
  static const olive = Color(0xFF4A7C59);
  static const walnut = Color(0xFF6B5D4F);
  static const teak = Color(0xFF8B7355);
  static const grayBlue = Color(0xFF7D9BA8);
  static const coral = Color(0xFFE57A77);
  static const surface = Color(0xFFFAF0E6);
  static const divider = Color(0xFFE8D5C0);
}

/// AI 配置编辑页面 — Mid-Century Modern 风格
class AIProviderEditPage extends ConsumerStatefulWidget {
  final AIProviderConfig? config;
  final bool isFromPreset;

  const AIProviderEditPage({
    super.key,
    this.config,
    this.isFromPreset = false,
  });

  @override
  ConsumerState<AIProviderEditPage> createState() => _AIProviderEditPageState();
}

class _AIProviderEditPageState extends ConsumerState<AIProviderEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _apiUrlController;
  late TextEditingController _modelIdController;
  late TextEditingController _apiKeyController;
  late TextEditingController _descriptionController;

  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _nameController = TextEditingController(text: config?.name ?? '');
    _apiUrlController = TextEditingController(text: config?.apiUrl ?? '');
    _modelIdController = TextEditingController(text: config?.modelId ?? '');
    _apiKeyController = TextEditingController(text: config?.apiKey ?? '');
    _descriptionController = TextEditingController(text: config?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _apiUrlController.dispose();
    _modelIdController.dispose();
    _apiKeyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.config != null && !widget.isFromPreset;

    return Scaffold(
      backgroundColor: _MCM.cream,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, isEdit),
          ),

          // ── 表单内容 ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API Key 获取链接（预设才有）
                  if (widget.config?.apiKeyUrl != null) ...[
                    _buildApiKeyBanner(),
                    const SizedBox(height: 20),
                  ],

                  // 基本信息
                  _buildSectionLabel('BASIC INFO'),
                  const SizedBox(height: 12),
                  _buildInputCard(children: [
                    _buildField(
                      label: '名称',
                      controller: _nameController,
                      hint: '例如：我的 DeepSeek',
                      icon: Icons.label_outline_rounded,
                    ),
                    _buildDivider(),
                    _buildField(
                      label: '描述',
                      controller: _descriptionController,
                      hint: '可选备注',
                      icon: Icons.notes_rounded,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // API 配置
                  _buildSectionLabel('API CONFIG'),
                  const SizedBox(height: 12),
                  _buildInputCard(children: [
                    _buildField(
                      label: 'API URL',
                      controller: _apiUrlController,
                      hint: 'https://api.xxx.com/v1',
                      icon: Icons.link_rounded,
                      maxLines: 2,
                    ),
                    _buildDivider(),
                    _buildField(
                      label: 'Model ID',
                      controller: _modelIdController,
                      hint: '例如：deepseek-chat',
                      icon: Icons.memory_rounded,
                    ),
                    _buildDivider(),
                    _buildPasswordField(),
                  ]),

                  // URL 格式提示
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'API URL 支持 Base URL（如 .../v1）或完整 Endpoint（如 .../v1/chat/completions）',
                      style: TextStyle(
                        fontSize: 12,
                        color: _MCM.walnut.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 保存按钮
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, bool isEdit) {
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
                decoration: const BoxDecoration(color: _MCM.orange, shape: BoxShape.circle),
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
          Text(
            isEdit ? 'EDIT CONFIG' : 'ADD CONFIG',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _MCM.darkBrown,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEdit ? 'Update your configuration' : 'Set up a new AI provider',
            style: const TextStyle(fontSize: 14, color: _MCM.walnut, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  // ── API Key 获取横幅 ──────────────────────────────────────────────────────
  Widget _buildApiKeyBanner() {
    return GestureDetector(
      onTap: () => _openApiKeyUrl(widget.config!.apiKeyUrl!),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _MCM.mustard.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _MCM.mustard.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _MCM.mustard.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.key_rounded, color: _MCM.teak, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GET API KEY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _MCM.teak,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.config!.apiKeyUrl!,
                    style: const TextStyle(fontSize: 13, color: _MCM.walnut),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: _MCM.mustard, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Section 标签 ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Row(
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
    );
  }

  // ── 输入卡片容器 ──────────────────────────────────────────────────────────
  Widget _buildInputCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _MCM.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MCM.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: _MCM.darkBrown.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 56),
      color: _MCM.divider,
    );
  }

  // ── 普通输入字段 ──────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _MCM.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _MCM.walnut),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 15,
                color: _MCM.darkBrown,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: _MCM.walnut,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: _MCM.walnut.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 密码输入字段 ──────────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _MCM.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.vpn_key_rounded, size: 16, color: _MCM.walnut),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              style: const TextStyle(
                fontSize: 15,
                color: _MCM.darkBrown,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: 'API Key',
                labelStyle: const TextStyle(
                  fontSize: 12,
                  color: _MCM.walnut,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                hintText: '请输入 API Key',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: _MCM.walnut.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscureApiKey = !_obscureApiKey),
                  child: Icon(
                    _obscureApiKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: _MCM.walnut,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 保存按钮 ──────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _save,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _MCM.orange,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _MCM.orange.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'SAVE CONFIG',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _MCM.white,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  // ── 逻辑方法 ──────────────────────────────────────────────────────────────
  void _openApiKeyUrl(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _save() async {
    final name = _nameController.text.trim();
    final apiUrl = _apiUrlController.text.trim();
    final modelId = _modelIdController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (name.isEmpty || apiUrl.isEmpty || modelId.isEmpty || apiKey.isEmpty) {
      _showError('请填写所有必填项（名称、API URL、Model ID、API Key）');
      return;
    }

    final config = AIProviderConfig(
      id: widget.config?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      apiUrl: apiUrl,
      modelId: modelId,
      apiKey: apiKey,
      description: _descriptionController.text.trim(),
      apiKeyUrl: widget.config?.apiKeyUrl,
      isCustom: widget.config == null || widget.isFromPreset,
    );

    final manager = ref.read(aiProviderManagerProvider.notifier);
    if (widget.config != null && !widget.isFromPreset) {
      await manager.updateProvider(widget.config!.id, config);
    } else {
      await manager.addProvider(config);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _MCM.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _MCM.coral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: _MCM.coral, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'INCOMPLETE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _MCM.darkBrown,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _MCM.walnut, height: 1.5),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _MCM.darkBrown,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'OK',
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
