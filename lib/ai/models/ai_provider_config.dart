import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AIProviderConfig {
  final String id; // 唯一标识
  final String name; // 显示名称
  final String apiUrl; // API 地址
  final String modelId; // 模型 ID
  final String apiKey; // API 密钥
  final String? description; // 描述
  final String? apiKeyUrl; // 获取 API Key 的平台地址
  final String? category; // 所属分类
  final bool isCustom; // 是否自定义
  final bool isActive; // 是否为当前激活的配置

  AIProviderConfig({
    required this.id,
    required this.name,
    required this.apiUrl,
    required this.modelId,
    required this.apiKey,
    this.description,
    this.apiKeyUrl,
    this.category,
    this.isCustom = false,
    this.isActive = false,
  });

  /// 是否已配置（所有必填项都已填写）
  bool get isConfigured {
    return apiUrl.isNotEmpty && modelId.isNotEmpty && apiKey.isNotEmpty;
  }

  /// 复制并修改
  AIProviderConfig copyWith({
    String? id,
    String? name,
    String? apiUrl,
    String? modelId,
    String? apiKey,
    String? description,
    String? apiKeyUrl,
    String? category,
    bool? isCustom,
    bool? isActive,
  }) {
    return AIProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      apiUrl: apiUrl ?? this.apiUrl,
      modelId: modelId ?? this.modelId,
      apiKey: apiKey ?? this.apiKey,
      description: description ?? this.description,
      apiKeyUrl: apiKeyUrl ?? this.apiKeyUrl,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
      isActive: isActive ?? this.isActive,
    );
  }

  /// 转为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiUrl': apiUrl,
      'modelId': modelId,
      'apiKey': apiKey,
      'description': description,
      'apiKeyUrl': apiKeyUrl,
      'category': category,
      'isCustom': isCustom,
      'isActive': isActive,
    };
  }

  factory AIProviderConfig.fromJson(Map<String, dynamic> json) {
    return AIProviderConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      apiUrl: json['apiUrl'] as String,
      modelId: json['modelId'] as String,
      apiKey: (json['apiKey'] as String?) ?? '',
      description: json['description'] as String?,
      apiKeyUrl: json['apiKeyUrl'] as String?,
      category: json['category'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'AIProviderConfig(id: $id, name: $name, modelId: $modelId, isActive: $isActive)';
  }
}

/// AI Provider 预设管理
/// 
/// 预设数据存储在 assets/ai_providers.json 中，
/// 修改 JSON 文件即可增删改预设，无需改代码。
class AIProviderPreset {
  /// 缓存已加载的预设列表
  static List<AIProviderConfig>? _cachedPresets;
  
  /// 缓存已加载的分类数据
  static Map<String, List<AIProviderConfig>>? _cachedCategories;

  /// 从 JSON 文件异步加载预设列表
  static Future<List<AIProviderConfig>> loadPresets() async {
    if (_cachedPresets != null) return _cachedPresets!;
    
    try {
      final jsonStr = await rootBundle.loadString('assets/ai_providers.json');
      final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
      final categories = jsonData['categories'] as List<dynamic>;
      
      final presets = <AIProviderConfig>[];
      for (final cat in categories) {
        final categoryName = cat['name'] as String;
        final providers = cat['providers'] as List<dynamic>;
        for (final p in providers) {
          final map = Map<String, dynamic>.from(p as Map);
          map['category'] = categoryName;
          // JSON 中不存储 apiKey，默认为空
          map['apiKey'] = map['apiKey'] ?? '';
          presets.add(AIProviderConfig.fromJson(map));
        }
      }
      
      _cachedPresets = presets;
      return presets;
    } catch (e) {
      print('加载 AI 预设配置失败: $e，使用内置默认列表');
      _cachedPresets = _fallbackPresets;
      return _fallbackPresets;
    }
  }

  /// 从 JSON 文件异步加载分类预设
  static Future<Map<String, List<AIProviderConfig>>> loadPresetsByCategory() async {
    if (_cachedCategories != null) return _cachedCategories!;
    
    try {
      final jsonStr = await rootBundle.loadString('assets/ai_providers.json');
      final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
      final categories = jsonData['categories'] as List<dynamic>;
      
      final result = <String, List<AIProviderConfig>>{};
      for (final cat in categories) {
        final categoryName = cat['name'] as String;
        final providers = cat['providers'] as List<dynamic>;
        result[categoryName] = providers.map((p) {
          final map = Map<String, dynamic>.from(p as Map);
          map['category'] = categoryName;
          map['apiKey'] = map['apiKey'] ?? '';
          return AIProviderConfig.fromJson(map);
        }).toList();
      }
      
      _cachedCategories = result;
      return result;
    } catch (e) {
      print('加载 AI 预设分类失败: $e，使用内置默认列表');
      return getPresetsByCategory();
    }
  }

  /// 清除缓存（用于热重载或强制刷新）
  static void clearCache() {
    _cachedPresets = null;
    _cachedCategories = null;
  }

  /// 同步获取预设列表（兼容旧代码，优先返回缓存）
  static List<AIProviderConfig> get presets => _cachedPresets ?? _fallbackPresets;

  static AIProviderConfig? getPresetById(String id) {
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 同步获取分类（兼容旧代码，优先返回缓存）
  static Map<String, List<AIProviderConfig>> getPresetsByCategory() {
    if (_cachedCategories != null) return _cachedCategories!;
    
    // 如果有缓存的 presets，按 category 字段分组
    if (_cachedPresets != null) {
      final result = <String, List<AIProviderConfig>>{};
      for (final p in _cachedPresets!) {
        final cat = p.category ?? '其他';
        result.putIfAbsent(cat, () => []).add(p);
      }
      return result;
    }
    
    // 最终 fallback：按 id 前缀分类
    return {
      '推荐': _fallbackPresets.where((p) => 
        p.id == 'deepseek-chat' || p.id == 'siliconflow-qwen'
      ).toList(),
      '国内厂商': _fallbackPresets.where((p) => 
        p.id.startsWith('qwen-') || 
        p.id.startsWith('kimi-') || 
        p.id.startsWith('zhipu-') ||
        p.id.startsWith('doubao-') ||
        p.id.startsWith('minimax-')
      ).toList(),
      '国际厂商': _fallbackPresets.where((p) => 
        p.id.startsWith('openai-') || 
        p.id.startsWith('claude-') || 
        p.id.startsWith('gemini-') ||
        p.id.startsWith('grok-')
      ).toList(),
      '聚合平台': _fallbackPresets.where((p) => 
        p.id.startsWith('siliconflow-')
      ).toList(),
    };
  }

  /// 内置 fallback 预设（当 JSON 加载失败时使用）
  static final List<AIProviderConfig> _fallbackPresets = [
    AIProviderConfig(
      id: 'deepseek-chat',
      name: 'DeepSeek (推荐)',
      apiUrl: 'https://api.deepseek.com/v1',
      modelId: 'deepseek-chat',
      apiKey: '',
      description: '高性价比，代码能力强，国产之光',
      apiKeyUrl: 'https://platform.deepseek.com',
      category: '推荐',
    ),
    AIProviderConfig(
      id: 'siliconflow-qwen',
      name: '硅基流动 (聚合平台)',
      apiUrl: 'https://api.siliconflow.cn/v1',
      modelId: 'Qwen/Qwen2.5-72B-Instruct',
      apiKey: '',
      description: '聚合多家模型，有免费额度',
      apiKeyUrl: 'https://cloud.siliconflow.cn',
      category: '推荐',
    ),
    AIProviderConfig(
      id: 'qwen-plus',
      name: '通义千问 (Qwen)',
      apiUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      modelId: 'qwen-plus',
      apiKey: '',
      description: '阿里云大模型，中文能力优秀',
      apiKeyUrl: 'https://bailian.console.aliyun.com',
      category: '国内厂商',
    ),
    AIProviderConfig(
      id: 'kimi-k2',
      name: 'Kimi / 月之暗面',
      apiUrl: 'https://api.moonshot.cn/v1',
      modelId: 'kimi-k2.5',
      apiKey: '',
      description: '超长上下文，适合阅读理解',
      apiKeyUrl: 'https://platform.moonshot.cn',
      category: '国内厂商',
    ),
    AIProviderConfig(
      id: 'minimax-text',
      name: 'MiniMax / 海螺 AI',
      apiUrl: 'https://api.minimax.chat/v1',
      modelId: 'MiniMax-Text-01',
      apiKey: '',
      description: '多模态能力强',
      apiKeyUrl: 'https://platform.minimaxi.com',
      category: '国内厂商',
    ),
    AIProviderConfig(
      id: 'doubao-pro',
      name: '豆包 (字节跳动)',
      apiUrl: 'https://ark.cn-beijing.volces.com/api/v3',
      modelId: 'doubao-pro-32k',
      apiKey: '',
      description: '字节跳动大模型，响应快速',
      apiKeyUrl: 'https://console.volcengine.com/ark',
      category: '国内厂商',
    ),
    AIProviderConfig(
      id: 'zhipu-glm4-flash',
      name: '智谱 GLM (ChatGLM)',
      apiUrl: 'https://open.bigmodel.cn/api/paas/v4',
      modelId: 'glm-4-flash',
      apiKey: '',
      description: '免费额度，中文友好',
      apiKeyUrl: 'https://open.bigmodel.cn',
      category: '国内厂商',
    ),
    AIProviderConfig(
      id: 'openai-gpt4o',
      name: 'OpenAI (GPT)',
      apiUrl: 'https://api.openai.com/v1',
      modelId: 'gpt-4o',
      apiKey: '',
      description: '最流行的 AI 模型，综合能力强',
      apiKeyUrl: 'https://platform.openai.com',
      category: '国际厂商',
    ),
    AIProviderConfig(
      id: 'claude-sonnet',
      name: 'Claude (Anthropic)',
      apiUrl: 'https://api.anthropic.com/v1',
      modelId: 'claude-sonnet-4-20250514',
      apiKey: '',
      description: '擅长长文分析和代码生成',
      apiKeyUrl: 'https://console.anthropic.com',
      category: '国际厂商',
    ),
    AIProviderConfig(
      id: 'gemini-flash',
      name: 'Gemini (Google)',
      apiUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      modelId: 'gemini-2.0-flash',
      apiKey: '',
      description: 'Google 多模态模型，速度快',
      apiKeyUrl: 'https://aistudio.google.com',
      category: '国际厂商',
    ),
    AIProviderConfig(
      id: 'grok-2',
      name: 'Grok (xAI)',
      apiUrl: 'https://api.x.ai/v1',
      modelId: 'grok-2-latest',
      apiKey: '',
      description: 'xAI 出品，实时信息能力强',
      apiKeyUrl: 'https://console.x.ai',
      category: '国际厂商',
    ),
    AIProviderConfig(
      id: 'siliconflow-qwen72b',
      name: '硅基流动 - Qwen2.5-72B',
      apiUrl: 'https://api.siliconflow.cn/v1',
      modelId: 'Qwen/Qwen2.5-72B-Instruct',
      apiKey: '',
      description: '通义千问大杯，免费额度',
      apiKeyUrl: 'https://cloud.siliconflow.cn',
      category: '聚合平台',
    ),
  ];
}