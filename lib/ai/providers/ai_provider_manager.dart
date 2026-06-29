import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_provider_config.dart';
import '../services/ai_provider_storage.dart';

/// AI 配置存储 KEY
const _KEY_AI_PROVIDERS = 'ai_providers';
/// AI 提供商管理器 Provider
final aiProviderManagerProvider =
    StateNotifierProvider<AIProviderManager, List<AIProviderConfig>>((ref) {
  return AIProviderManager();
});

/// 当前激活的 AI 配置 Provider
final activeAIProviderProvider = Provider<AIProviderConfig?>((ref) {
  final providers = ref.watch(aiProviderManagerProvider);
  try {
    return providers.firstWhere((p) => p.isActive);
  } catch (e) {
    return null;
  }
});

/// AI 提供商管理器
class AIProviderManager extends StateNotifier<List<AIProviderConfig>> {
  AIProviderManager({
    AIProviderStorage? storage,
  })  : _storage = storage ?? AIProviderStorage(),
        super([]) {
    _loadProviders();
  }

  final AIProviderStorage _storage;

  /// 加载保存的配置
  Future<void> _loadProviders() async {
    try {
      _storage.migrateLegacyIfNeeded(_KEY_AI_PROVIDERS);
      state = _storage.loadProviders();
    } catch (e) {
      print('加载 AI 配置失败: $e');
      state = [];
    }
  }

  /// 保存配置到本地
  Future<void> _saveProviders() async {
    try {
      _storage.saveProviders(state);
    } catch (e) {
      print('保存 AI 配置失败: $e');
    }
  }

  /// 添加新配置
  Future<void> addProvider(AIProviderConfig config) async {
    // 如果是第一个配置，自动设为激活
    final isFirst = state.isEmpty;
    final newConfig = config.copyWith(isActive: isFirst);
    
    state = [...state, newConfig];
    await _saveProviders();
  }

  /// 更新配置
  Future<void> updateProvider(String id, AIProviderConfig config) async {
    state = state.map((p) {
      if (p.id == id) {
        return config.copyWith(isActive: p.isActive);
      }
      return p;
    }).toList();
    await _saveProviders();
  }

  /// 删除配置
  Future<void> deleteProvider(String id) async {
    final wasActive = state.firstWhere((p) => p.id == id).isActive;
    state = state.where((p) => p.id != id).toList();

    // 如果删除的是激活配置，激活第一个
    if (wasActive && state.isNotEmpty) {
      state = state.map((p) {
        if (p.id == state.first.id) {
          return p.copyWith(isActive: true);
        }
        return p;
      }).toList();
    }

    await _saveProviders();
  }

  /// 切换激活的配置
  Future<void> activateProvider(String id) async {
    state = state.map((p) {
      return p.copyWith(isActive: p.id == id);
    }).toList();
    await _saveProviders();
  }

  /// 从预设创建配置
  Future<void> addFromPreset(AIProviderConfig preset, String apiKey) async {
    final config = preset.copyWith(
      id: '${preset.id}_${DateTime.now().millisecondsSinceEpoch}',
      apiKey: apiKey,
      isCustom: false,
    );
    await addProvider(config);
  }

  /// 清空所有配置
  Future<void> clearAll() async {
    state = [];
    _storage.clear();
  }
}
