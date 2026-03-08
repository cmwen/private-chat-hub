class LmStudioQuantization {
  final String? name;
  final num? bitsPerWeight;

  const LmStudioQuantization({this.name, this.bitsPerWeight});

  factory LmStudioQuantization.fromJson(Map<String, dynamic> json) {
    return LmStudioQuantization(
      name: json['name'] as String?,
      bitsPerWeight: json['bits_per_weight'] as num?,
    );
  }
}

class LmStudioCapabilities {
  final bool vision;
  final bool trainedForToolUse;

  const LmStudioCapabilities({
    required this.vision,
    required this.trainedForToolUse,
  });

  factory LmStudioCapabilities.fromJson(Map<String, dynamic> json) {
    return LmStudioCapabilities(
      vision: json['vision'] as bool? ?? false,
      trainedForToolUse: json['trained_for_tool_use'] as bool? ?? false,
    );
  }
}

class LmStudioLoadedInstance {
  final String id;
  final Map<String, dynamic> config;

  const LmStudioLoadedInstance({required this.id, required this.config});

  factory LmStudioLoadedInstance.fromJson(Map<String, dynamic> json) {
    return LmStudioLoadedInstance(
      id: json['id'] as String,
      config: Map<String, dynamic>.from(
        json['config'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class LmStudioModel {
  final String type;
  final String publisher;
  final String key;
  final String displayName;
  final String? architecture;
  final LmStudioQuantization? quantization;
  final int sizeBytes;
  final String? paramsString;
  final List<LmStudioLoadedInstance> loadedInstances;
  final int? maxContextLength;
  final String? format;
  final LmStudioCapabilities? capabilities;
  final String? description;

  const LmStudioModel({
    required this.type,
    required this.publisher,
    required this.key,
    required this.displayName,
    this.architecture,
    this.quantization,
    required this.sizeBytes,
    this.paramsString,
    this.loadedInstances = const [],
    this.maxContextLength,
    this.format,
    this.capabilities,
    this.description,
  });

  bool get isLlm => type == 'llm';

  bool get isLoaded => loadedInstances.isNotEmpty;

  factory LmStudioModel.fromJson(Map<String, dynamic> json) {
    return LmStudioModel(
      type: json['type'] as String? ?? 'llm',
      publisher: json['publisher'] as String? ?? 'unknown',
      key: json['key'] as String,
      displayName: json['display_name'] as String? ?? json['key'] as String,
      architecture: json['architecture'] as String?,
      quantization: json['quantization'] is Map<String, dynamic>
          ? LmStudioQuantization.fromJson(
              json['quantization'] as Map<String, dynamic>,
            )
          : null,
      sizeBytes: json['size_bytes'] as int? ?? 0,
      paramsString: json['params_string'] as String?,
      loadedInstances: (json['loaded_instances'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LmStudioLoadedInstance.fromJson)
          .toList(),
      maxContextLength: json['max_context_length'] as int?,
      format: json['format'] as String?,
      capabilities: json['capabilities'] is Map<String, dynamic>
          ? LmStudioCapabilities.fromJson(
              json['capabilities'] as Map<String, dynamic>,
            )
          : null,
      description: json['description'] as String?,
    );
  }
}

class LmStudioModelsResponse {
  final List<LmStudioModel> models;

  const LmStudioModelsResponse({required this.models});

  factory LmStudioModelsResponse.fromJson(Map<String, dynamic> json) {
    final models = (json['models'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LmStudioModel.fromJson)
        .toList();

    return LmStudioModelsResponse(models: models);
  }
}

class LmStudioChatResult {
  final List<Map<String, dynamic>> output;
  final String? responseId;

  const LmStudioChatResult({required this.output, this.responseId});

  factory LmStudioChatResult.fromJson(Map<String, dynamic> json) {
    return LmStudioChatResult(
      output: (json['output'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Map<String, dynamic>.from)
          .toList(),
      responseId: json['response_id'] as String?,
    );
  }
}

class LmStudioChatStreamEvent {
  final String type;
  final Map<String, dynamic> data;

  const LmStudioChatStreamEvent({required this.type, required this.data});
}
