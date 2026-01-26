import 'package:freezed_annotation/freezed_annotation.dart';

part 'ollama_model.freezed.dart';
part 'ollama_model.g.dart';

@freezed
class OllamaModel with _$OllamaModel {
  const factory OllamaModel({
    required String name,
    required int size,
    required DateTime modifiedAt,
    String? digest,
    ModelDetails? details,
  }) = _OllamaModel;

  factory OllamaModel.fromJson(Map<String, dynamic> json) =>
      _$OllamaModelFromJson(json);
}

@freezed
class ModelDetails with _$ModelDetails {
  const factory ModelDetails({
    String? format,
    String? family,
    String? parameterSize,
    String? quantizationLevel,
    List<String>? capabilities,
  }) = _ModelDetails;

  factory ModelDetails.fromJson(Map<String, dynamic> json) =>
      _$ModelDetailsFromJson(json);
}

@freezed
class PullProgress with _$PullProgress {
  const factory PullProgress({
    required String status,
    String? digest,
    int? total,
    int? completed,
  }) = _PullProgress;

  const PullProgress._();

  factory PullProgress.fromJson(Map<String, dynamic> json) =>
      _$PullProgressFromJson(json);

  double? get progress {
    if (total == null || completed == null || total == 0) return null;
    return completed! / total!;
  }

  bool get isDone => status == 'success';
}
