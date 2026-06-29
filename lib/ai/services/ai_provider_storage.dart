import 'dart:convert';

import 'package:mmkv/mmkv.dart';

import '../core/logger.dart';
import '../models/ai_provider_config.dart';

class AIProviderStorage {
  AIProviderStorage({MMKV? mmkv}) : _mmkv = mmkv ?? MMKV.defaultMMKV();

  final MMKV? _mmkv;

  static const String providersKey = 'ai_providers_v2';
  static const String activeProviderKey = 'active_provider_id';
  static const String apiKeyPrefix = 'ai_provider_api_key_';

  List<AIProviderConfig> loadProviders() {
    final jsonStr = _mmkv?.decodeString(providersKey);
    final activeId = _mmkv?.decodeString(activeProviderKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String? ?? '';
      return AIProviderConfig.fromJson(map).copyWith(
        apiKey: _mmkv?.decodeString('$apiKeyPrefix$id') ?? '',
        isActive: id == activeId,
      );
    }).toList();
  }

  void saveProviders(List<AIProviderConfig> providers) {
    final sanitizedProviders = providers.map((provider) {
      _mmkv?.encodeString('$apiKeyPrefix${provider.id}', provider.apiKey);
      return provider.copyWith(apiKey: '');
    }).toList();

    _mmkv?.encodeString(
      providersKey,
      json.encode(sanitizedProviders.map((provider) => provider.toJson()).toList()),
    );

    final activeProvider = providers.where((provider) => provider.isActive).firstOrNull;
    if (activeProvider != null) {
      _mmkv?.encodeString(activeProviderKey, activeProvider.id);
    } else {
      _mmkv?.removeValue(activeProviderKey);
    }

    _cleanupOrphanApiKeys(providers.map((provider) => provider.id).toSet());
  }

  void clear() {
    final providers = loadProviders();
    for (final provider in providers) {
      _mmkv?.removeValue('$apiKeyPrefix${provider.id}');
    }
    _mmkv?.removeValue(providersKey);
    _mmkv?.removeValue(activeProviderKey);
  }

  void migrateLegacyIfNeeded(String legacyProvidersKey) {
    if ((_mmkv?.decodeString(providersKey) ?? '').isNotEmpty) {
      return;
    }

    final legacyJson = _mmkv?.decodeString(legacyProvidersKey);
    if (legacyJson == null || legacyJson.isEmpty) {
      return;
    }

    try {
      final List<dynamic> jsonList = json.decode(legacyJson);
      final providers = jsonList
          .map((item) => AIProviderConfig.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      saveProviders(providers);
      _mmkv?.removeValue(legacyProvidersKey);
      AILogger.info('AI provider storage migrated to separated api-key layout');
    } catch (e) {
      AILogger.warning('AI provider storage migration failed: $e');
    }
  }

  void _cleanupOrphanApiKeys(Set<String> aliveIds) {
    final allKeys = _mmkv?.allKeys ?? const <String>[];
    for (final key in allKeys) {
      if (!key.startsWith(apiKeyPrefix)) {
        continue;
      }
      final providerId = key.substring(apiKeyPrefix.length);
      if (!aliveIds.contains(providerId)) {
        _mmkv?.removeValue(key);
      }
    }
  }
}
