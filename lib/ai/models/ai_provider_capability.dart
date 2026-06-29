import '../core/constants.dart';
import 'ai_provider_config.dart';

class AIProviderCapability {
  final bool supportsStreaming;
  final bool supportsJsonSchema;
  final bool supportsToolCalling;
  final bool supportsImageInput;
  final bool supportsReasoningParameters;

  const AIProviderCapability({
    required this.supportsStreaming,
    required this.supportsJsonSchema,
    required this.supportsToolCalling,
    required this.supportsImageInput,
    required this.supportsReasoningParameters,
  });
}

extension AIProviderConfigCapabilityExtension on AIProviderConfig {
  AIProviderCapability get capability {
    final providerType = AIProviderType.fromUrl(apiUrl);

    switch (providerType) {
      case AIProviderType.openai:
      case AIProviderType.grok:
      case AIProviderType.deepseek:
      case AIProviderType.siliconflow:
        return const AIProviderCapability(
          supportsStreaming: true,
          supportsJsonSchema: true,
          supportsToolCalling: true,
          supportsImageInput: false,
          supportsReasoningParameters: true,
        );
      case AIProviderType.gemini:
      case AIProviderType.qwen:
      case AIProviderType.zhipu:
      case AIProviderType.moonshot:
      case AIProviderType.minimax:
      case AIProviderType.doubao:
      case AIProviderType.anthropic:
        return const AIProviderCapability(
          supportsStreaming: true,
          supportsJsonSchema: false,
          supportsToolCalling: false,
          supportsImageInput: false,
          supportsReasoningParameters: true,
        );
      case AIProviderType.custom:
        return const AIProviderCapability(
          supportsStreaming: true,
          supportsJsonSchema: false,
          supportsToolCalling: false,
          supportsImageInput: false,
          supportsReasoningParameters: true,
        );
    }
  }
}
