import 'package:freezed_annotation/freezed_annotation.dart';

part 'litert_model.freezed.dart';
part 'litert_model.g.dart';

enum LiteRTModelStatus { available, downloading, ready, error }

@freezed
class LiteRTModel with _$LiteRTModel {
  const factory LiteRTModel({
    required String id,
    required String name,
    required String localPath,
    required LiteRTModelStatus status,
    int? sizeInBytes,
    int? downloadProgress,
    String? errorMessage,
    DateTime? lastUsed,
    required DateTime createdAt,
  }) = _LiteRTModel;

  const LiteRTModel._();

  factory LiteRTModel.fromJson(Map<String, dynamic> json) =>
      _$LiteRTModelFromJson(json);

  factory LiteRTModel.create({
    required String id,
    required String name,
    required String localPath,
  }) {
    return LiteRTModel(
      id: id,
      name: name,
      localPath: localPath,
      status: LiteRTModelStatus.available,
      createdAt: DateTime.now(),
    );
  }

  bool get isReady => status == LiteRTModelStatus.ready;
  bool get isDownloading => status == LiteRTModelStatus.downloading;
  bool get hasError => status == LiteRTModelStatus.error;

  double? get downloadProgressPercent {
    if (downloadProgress == null || sizeInBytes == null || sizeInBytes == 0) {
      return null;
    }
    return downloadProgress! / sizeInBytes!;
  }
}
