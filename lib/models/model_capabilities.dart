// Model capabilities registry for popular Ollama models.
//
// Since Ollama API doesn't expose capability information,
// we maintain a curated list of known capabilities for popular models.

/// Represents the capabilities of an AI model.
class ModelCapabilities {
  /// Whether the model supports vision/image input.
  final bool supportsVision;

  /// Whether the model supports tool/function calling.
  final bool supportsTools;

  /// Whether the model is suitable for code generation.
  final bool supportsCode;

  /// Context window size in tokens.
  final int contextLength;

  /// Brief description of the model's strengths.
  final String description;

  /// Model family (e.g., llama, qwen, mistral).
  final String family;

  const ModelCapabilities({
    this.supportsVision = false,
    this.supportsTools = false,
    this.supportsCode = false,
    this.contextLength = 4096,
    this.description = '',
    this.family = 'unknown',
  });

  /// Default capabilities for unknown models.
  static const ModelCapabilities unknown = ModelCapabilities(
    supportsVision: false,
    supportsTools: false,
    supportsCode: false,
    contextLength: 4096,
    description: 'Unknown model - capabilities not verified',
    family: 'unknown',
  );
}

/// Registry of model capabilities for popular Ollama models.
///
/// Data sourced from https://ollama.com/search and model documentation.
/// Last updated: January 2026
class ModelCapabilitiesRegistry {
  ModelCapabilitiesRegistry._();

  /// Known model capabilities indexed by model family/name prefix.
  static const Map<String, ModelCapabilities> _knownModels = {
    // === Llama Family ===
    'llama3.3': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Meta Llama 3.3 - Best open source model for reasoning and coding',
      family: 'llama',
    ),
    'llama3.2': ModelCapabilities(
      supportsVision: true,  // 11b and 90b vision variants
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Meta Llama 3.2 - Multimodal with vision support',
      family: 'llama',
    ),
    'llama3.1': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Meta Llama 3.1 - Strong general purpose model',
      family: 'llama',
    ),
    'llama3': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'Meta Llama 3 - General purpose model',
      family: 'llama',
    ),
    'llama2': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'Meta Llama 2 - Previous generation',
      family: 'llama',
    ),

    // === Qwen Family ===
    'qwen3': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Alibaba Qwen 3 - Excellent reasoning and multilingual',
      family: 'qwen',
    ),
    'qwen2.5': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Alibaba Qwen 2.5 - Strong coding and math',
      family: 'qwen',
    ),
    'qwen2.5-coder': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Qwen 2.5 Coder - Specialized for code generation',
      family: 'qwen',
    ),
    'qwen2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Alibaba Qwen 2 - General purpose model',
      family: 'qwen',
    ),
    'qwq': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Qwen QwQ - Specialized for reasoning tasks',
      family: 'qwen',
    ),

    // === Mistral Family ===
    'mistral': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 32768,
      description: 'Mistral 7B - Efficient and capable base model',
      family: 'mistral',
    ),
    'mistral-nemo': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Mistral Nemo - 12B with extended context',
      family: 'mistral',
    ),
    'mistral-large': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Mistral Large - Flagship model for complex tasks',
      family: 'mistral',
    ),
    'mistral-small': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 32768,
      description: 'Mistral Small - Cost-effective for simple tasks',
      family: 'mistral',
    ),
    'mixtral': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 32768,
      description: 'Mixtral MoE - Mixture of experts architecture',
      family: 'mistral',
    ),
    'codestral': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 32768,
      description: 'Codestral - Specialized for code generation',
      family: 'mistral',
    ),

    // === DeepSeek Family ===
    'deepseek-r1': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'DeepSeek R1 - Advanced reasoning model',
      family: 'deepseek',
    ),
    'deepseek-coder': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 65536,
      description: 'DeepSeek Coder - Specialized for programming',
      family: 'deepseek',
    ),
    'deepseek-coder-v2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'DeepSeek Coder V2 - Enhanced code model',
      family: 'deepseek',
    ),
    'deepseek-v2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'DeepSeek V2 - Strong MoE model',
      family: 'deepseek',
    ),

    // === Gemma Family (Google) ===
    'gemma3': ModelCapabilities(
      supportsVision: true,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Google Gemma 3 - Multimodal with vision',
      family: 'gemma',
    ),
    'gemma2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 8192,
      description: 'Google Gemma 2 - Efficient small model',
      family: 'gemma',
    ),
    'gemma': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'Google Gemma - Lightweight model',
      family: 'gemma',
    ),

    // === Phi Family (Microsoft) ===
    'phi4': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 16384,
      description: 'Microsoft Phi-4 - Small but powerful',
      family: 'phi',
    ),
    'phi3': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Microsoft Phi-3 - Efficient reasoning',
      family: 'phi',
    ),
    'phi3.5': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Microsoft Phi-3.5 - Extended context',
      family: 'phi',
    ),

    // === Vision Models ===
    'llava': ModelCapabilities(
      supportsVision: true,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'LLaVA - Visual language model',
      family: 'llava',
    ),
    'llava-llama3': ModelCapabilities(
      supportsVision: true,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'LLaVA Llama 3 - Vision + Llama 3',
      family: 'llava',
    ),
    'llava-phi3': ModelCapabilities(
      supportsVision: true,
      supportsTools: false,
      supportsCode: true,
      contextLength: 131072,
      description: 'LLaVA Phi-3 - Compact vision model',
      family: 'llava',
    ),
    'moondream': ModelCapabilities(
      supportsVision: true,
      supportsTools: false,
      supportsCode: false,
      contextLength: 2048,
      description: 'Moondream - Tiny vision model',
      family: 'moondream',
    ),
    'minicpm-v': ModelCapabilities(
      supportsVision: true,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'MiniCPM-V - Efficient vision model',
      family: 'minicpm',
    ),
    'bakllava': ModelCapabilities(
      supportsVision: true,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'BakLLaVA - Improved LLaVA variant',
      family: 'bakllava',
    ),

    // === Code-Specialized Models ===
    'starcoder2': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 16384,
      description: 'StarCoder 2 - Code generation specialist',
      family: 'starcoder',
    ),
    'codegemma': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'CodeGemma - Google code model',
      family: 'codegemma',
    ),
    'codellama': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 16384,
      description: 'Code Llama - Meta code specialist',
      family: 'codellama',
    ),

    // === Other Popular Models ===
    'command-r': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Cohere Command R - RAG optimized',
      family: 'command',
    ),
    'command-r-plus': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Cohere Command R+ - Enhanced RAG',
      family: 'command',
    ),
    'aya': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 8192,
      description: 'Cohere Aya - Multilingual specialist',
      family: 'aya',
    ),
    'yi': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 200000,
      description: '01.AI Yi - Long context model',
      family: 'yi',
    ),
    'yi-coder': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Yi Coder - Code specialist',
      family: 'yi',
    ),
    'granite3': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'IBM Granite 3 - Enterprise model',
      family: 'granite',
    ),
    'granite-code': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'IBM Granite Code - Enterprise coding',
      family: 'granite',
    ),
    'dolphin': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 16384,
      description: 'Dolphin - Uncensored Mistral finetune',
      family: 'dolphin',
    ),
    'dolphin-mixtral': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 32768,
      description: 'Dolphin Mixtral - Uncensored MoE',
      family: 'dolphin',
    ),
    'neural-chat': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'Intel Neural Chat - Conversational',
      family: 'neural-chat',
    ),
    'openchat': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'OpenChat - Chat-optimized model',
      family: 'openchat',
    ),
    'solar': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'Solar - Upstage efficient model',
      family: 'solar',
    ),
    'wizardlm2': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'WizardLM 2 - Instruction following',
      family: 'wizardlm',
    ),
    'wizard-vicuna': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'Wizard Vicuna - Merged finetune',
      family: 'wizard-vicuna',
    ),
    'vicuna': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'Vicuna - Chat-optimized LLaMA',
      family: 'vicuna',
    ),
    'falcon': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 2048,
      description: 'TII Falcon - Open source model',
      family: 'falcon',
    ),
    'falcon2': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'TII Falcon 2 - Improved version',
      family: 'falcon',
    ),
    'orca-mini': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 4096,
      description: 'Orca Mini - Small chat model',
      family: 'orca',
    ),
    'orca2': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 4096,
      description: 'Orca 2 - Microsoft reasoning model',
      family: 'orca',
    ),
    'tinyllama': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 2048,
      description: 'TinyLlama - Ultra-compact model',
      family: 'tinyllama',
    ),
    'stablelm': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 4096,
      description: 'StableLM - Stability AI model',
      family: 'stablelm',
    ),
    'stablelm2': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 4096,
      description: 'StableLM 2 - Improved version',
      family: 'stablelm',
    ),
    'nous-hermes': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'Nous Hermes - Instruction tuned',
      family: 'nous-hermes',
    ),
    'nous-hermes2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 8192,
      description: 'Nous Hermes 2 - Enhanced version',
      family: 'nous-hermes',
    ),
    'openhermes': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 8192,
      description: 'OpenHermes - Community finetune',
      family: 'openhermes',
    ),
    'zephyr': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 32768,
      description: 'Zephyr - HuggingFace tuned Mistral',
      family: 'zephyr',
    ),
    'starling-lm': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'Starling - RLHF trained model',
      family: 'starling',
    ),
    'internlm2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 32768,
      description: 'InternLM 2 - Shanghai AI Lab',
      family: 'internlm',
    ),
    'glm4': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'GLM-4 - Zhipu AI model',
      family: 'glm',
    ),
    'athene-v2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Athene V2 - Chat optimized',
      family: 'athene',
    ),
    'exaone3': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 32768,
      description: 'LG EXAONE 3 - Korean-English',
      family: 'exaone',
    ),
    'reader-lm': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: false,
      contextLength: 262144,
      description: 'Reader LM - HTML to Markdown',
      family: 'reader-lm',
    ),
    'nemotron': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'NVIDIA Nemotron - Synthetic data',
      family: 'nemotron',
    ),
    'smollm2': ModelCapabilities(
      supportsVision: false,
      supportsTools: false,
      supportsCode: true,
      contextLength: 8192,
      description: 'SmolLM 2 - Ultra efficient',
      family: 'smollm',
    ),
    'marco-o1': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'Marco-o1 - Reasoning specialist',
      family: 'marco',
    ),
    'tulu3': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'AI2 Tulu 3 - Instruction tuned',
      family: 'tulu',
    ),
    'olmo2': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 4096,
      description: 'AI2 OLMo 2 - Open model',
      family: 'olmo',
    ),
    // === Ollama / GPT-OSS ===
    'gpt-oss': ModelCapabilities(
      supportsVision: false,
      supportsTools: true,
      supportsCode: true,
      contextLength: 131072,
      description: 'GPT-OSS (Ollama) - Open-weight models with agentic/function-calling support. See https://ollama.com/library/gpt-oss (128K context)',
      family: 'gpt-oss',
    ),
  };

  /// Gets capabilities for a model by its name.
  ///
  /// Matches against known model family prefixes.
  /// Returns [ModelCapabilities.unknown] if model is not recognized.
  static ModelCapabilities getCapabilities(String modelName) {
    // Normalize model name (lowercase, remove version suffixes)
    final normalized = modelName.toLowerCase().split(':').first;

    // Try exact match first
    if (_knownModels.containsKey(normalized)) {
      return _knownModels[normalized]!;
    }

    // Try prefix matching (e.g., "llama3.2:8b-instruct" -> "llama3.2")
    for (final entry in _knownModels.entries) {
      if (normalized.startsWith(entry.key)) {
        return entry.value;
      }
    }

    // Try family matching (e.g., "custom-llama3" -> "llama3")
    for (final entry in _knownModels.entries) {
      if (normalized.contains(entry.key)) {
        return entry.value;
      }
    }

    return ModelCapabilities.unknown;
  }

  /// Checks if a model supports vision/image input.
  static bool supportsVision(String modelName) {
    return getCapabilities(modelName).supportsVision;
  }

  /// Checks if a model supports tool/function calling.
  static bool supportsTools(String modelName) {
    return getCapabilities(modelName).supportsTools;
  }

  /// Checks if a model is optimized for code generation.
  static bool supportsCode(String modelName) {
    return getCapabilities(modelName).supportsCode;
  }

  /// Gets the context window size for a model.
  static int getContextLength(String modelName) {
    return getCapabilities(modelName).contextLength;
  }

  /// Gets all known model families.
  static List<String> get knownModelFamilies {
    return _knownModels.keys.toList()..sort();
  }

  /// Gets models that support a specific capability.
  static List<String> getModelsWithCapability({
    bool? vision,
    bool? tools,
    bool? code,
  }) {
    return _knownModels.entries
        .where((e) {
          if (vision != null && e.value.supportsVision != vision) return false;
          if (tools != null && e.value.supportsTools != tools) return false;
          if (code != null && e.value.supportsCode != code) return false;
          return true;
        })
        .map((e) => e.key)
        .toList();
  }
}
