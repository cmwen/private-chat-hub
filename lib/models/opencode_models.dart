/// Model cost information from OpenCode provider API.
class OpenCodeModelCost {
  final double input;
  final double output;
  final double? cacheRead;
  final double? cacheWrite;

  const OpenCodeModelCost({
    required this.input,
    required this.output,
    this.cacheRead,
    this.cacheWrite,
  });

  factory OpenCodeModelCost.fromJson(Map<String, dynamic> json) {
    return OpenCodeModelCost(
      input: (json['input'] as num).toDouble(),
      output: (json['output'] as num).toDouble(),
      cacheRead: (json['cache_read'] as num?)?.toDouble(),
      cacheWrite: (json['cache_write'] as num?)?.toDouble(),
    );
  }

  /// Human-readable cost string (per 1M tokens).
  String get displayString {
    final inputStr = '\$${(input * 1000000).toStringAsFixed(2)}';
    final outputStr = '\$${(output * 1000000).toStringAsFixed(2)}';
    return '$inputStr / $outputStr per 1M';
  }
}

/// Model context/output limits from OpenCode provider API.
class OpenCodeModelLimit {
  final int context;
  final int output;

  const OpenCodeModelLimit({required this.context, required this.output});

  factory OpenCodeModelLimit.fromJson(Map<String, dynamic> json) {
    return OpenCodeModelLimit(
      context: json['context'] as int,
      output: json['output'] as int,
    );
  }

  String get contextDisplay {
    if (context >= 1000000) {
      return '${(context / 1000000).toStringAsFixed(1)}M';
    }
    return '${(context / 1000).toStringAsFixed(0)}K';
  }
}

/// A single model definition within an OpenCode provider.
class OpenCodeModelDef {
  final String modelKey;
  final String? id;
  final String? name;
  final String? releaseDate;
  final bool attachment;
  final bool reasoning;
  final bool temperature;
  final bool toolCall;
  final OpenCodeModelCost? cost;
  final OpenCodeModelLimit? limit;
  final List<String> inputModalities;
  final List<String> outputModalities;
  final bool experimental;
  final String? status;

  const OpenCodeModelDef({
    required this.modelKey,
    this.id,
    this.name,
    this.releaseDate,
    this.attachment = false,
    this.reasoning = false,
    this.temperature = false,
    this.toolCall = false,
    this.cost,
    this.limit,
    this.inputModalities = const ['text'],
    this.outputModalities = const ['text'],
    this.experimental = false,
    this.status,
  });

  factory OpenCodeModelDef.fromJson(String key, Map<String, dynamic> json) {
    return OpenCodeModelDef(
      modelKey: key,
      id: json['id'] as String?,
      name: json['name'] as String?,
      releaseDate: json['release_date'] as String?,
      attachment: json['attachment'] as bool? ?? false,
      reasoning: json['reasoning'] as bool? ?? false,
      temperature: json['temperature'] as bool? ?? false,
      toolCall: json['tool_call'] as bool? ?? false,
      cost: json['cost'] != null
          ? OpenCodeModelCost.fromJson(json['cost'] as Map<String, dynamic>)
          : null,
      limit: json['limit'] != null
          ? OpenCodeModelLimit.fromJson(json['limit'] as Map<String, dynamic>)
          : null,
      inputModalities:
          (json['modalities'] as Map<String, dynamic>?)?['input']
              ?.cast<String>() ??
          const ['text'],
      outputModalities:
          (json['modalities'] as Map<String, dynamic>?)?['output']
              ?.cast<String>() ??
          const ['text'],
      experimental: json['experimental'] as bool? ?? false,
      status: json['status'] as String?,
    );
  }

  /// The display name for this model.
  String get displayName => name ?? modelKey;

  /// Whether this model supports vision input.
  bool get supportsVision => inputModalities.contains('image');

  /// Whether this model supports tool calling.
  bool get supportsTools => toolCall;

  /// Whether this model supports reasoning/thinking.
  bool get supportsReasoning => reasoning;

  /// Build a list of capability strings for ModelInfo compatibility.
  List<String> get capabilities {
    final caps = <String>['text'];
    if (supportsVision) caps.add('vision');
    if (supportsTools) caps.add('tools');
    if (supportsReasoning) caps.add('reasoning');
    if (attachment) caps.add('attachment');
    return caps;
  }
}

/// An OpenCode provider (e.g., Anthropic, OpenAI, Google).
class OpenCodeProvider {
  final String id;
  final String? name;
  final Map<String, OpenCodeModelDef> models;

  const OpenCodeProvider({required this.id, this.name, this.models = const {}});

  factory OpenCodeProvider.fromJson(String id, Map<String, dynamic> json) {
    final modelsJson = json['models'] as Map<String, dynamic>? ?? {};
    final models = <String, OpenCodeModelDef>{};
    for (final entry in modelsJson.entries) {
      if (entry.value is Map<String, dynamic>) {
        models[entry.key] = OpenCodeModelDef.fromJson(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return OpenCodeProvider(
      id: id,
      name: json['name'] as String? ?? id,
      models: models,
    );
  }

  /// Display name for this provider.
  String get displayName => name ?? id;
}

/// Response from GET /provider endpoint.
class OpenCodeProviderResponse {
  final List<OpenCodeProvider> providers;
  final Map<String, String> defaults;
  final List<String> connected;

  const OpenCodeProviderResponse({
    required this.providers,
    this.defaults = const {},
    this.connected = const [],
  });

  factory OpenCodeProviderResponse.fromJson(Map<String, dynamic> json) {
    final allList = json['all'] as List<dynamic>? ?? [];
    final providers = <OpenCodeProvider>[];

    for (final item in allList) {
      if (item is Map<String, dynamic>) {
        final id = item['id'] as String? ?? '';
        if (id.isNotEmpty) {
          providers.add(OpenCodeProvider.fromJson(id, item));
        }
      }
    }

    final defaultMap = <String, String>{};
    final defaultJson = json['default'] as Map<String, dynamic>? ?? {};
    for (final entry in defaultJson.entries) {
      if (entry.value is String) {
        defaultMap[entry.key] = entry.value as String;
      }
    }

    final connectedList =
        (json['connected'] as List<dynamic>?)?.cast<String>() ?? [];

    return OpenCodeProviderResponse(
      providers: providers,
      defaults: defaultMap,
      connected: connectedList,
    );
  }

  /// Get all models across all providers.
  List<({String providerId, OpenCodeModelDef model})> get allModels {
    final result = <({String providerId, OpenCodeModelDef model})>[];
    for (final provider in providers) {
      for (final model in provider.models.values) {
        result.add((providerId: provider.id, model: model));
      }
    }
    return result;
  }
}
