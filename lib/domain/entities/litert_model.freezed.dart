// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'litert_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LiteRTModel _$LiteRTModelFromJson(Map<String, dynamic> json) {
  return _LiteRTModel.fromJson(json);
}

/// @nodoc
mixin _$LiteRTModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get localPath => throw _privateConstructorUsedError;
  LiteRTModelStatus get status => throw _privateConstructorUsedError;
  int? get sizeInBytes => throw _privateConstructorUsedError;
  int? get downloadProgress => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  DateTime? get lastUsed => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this LiteRTModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LiteRTModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiteRTModelCopyWith<LiteRTModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiteRTModelCopyWith<$Res> {
  factory $LiteRTModelCopyWith(
    LiteRTModel value,
    $Res Function(LiteRTModel) then,
  ) = _$LiteRTModelCopyWithImpl<$Res, LiteRTModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String localPath,
    LiteRTModelStatus status,
    int? sizeInBytes,
    int? downloadProgress,
    String? errorMessage,
    DateTime? lastUsed,
    DateTime createdAt,
  });
}

/// @nodoc
class _$LiteRTModelCopyWithImpl<$Res, $Val extends LiteRTModel>
    implements $LiteRTModelCopyWith<$Res> {
  _$LiteRTModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiteRTModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? localPath = null,
    Object? status = null,
    Object? sizeInBytes = freezed,
    Object? downloadProgress = freezed,
    Object? errorMessage = freezed,
    Object? lastUsed = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            localPath: null == localPath
                ? _value.localPath
                : localPath // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as LiteRTModelStatus,
            sizeInBytes: freezed == sizeInBytes
                ? _value.sizeInBytes
                : sizeInBytes // ignore: cast_nullable_to_non_nullable
                      as int?,
            downloadProgress: freezed == downloadProgress
                ? _value.downloadProgress
                : downloadProgress // ignore: cast_nullable_to_non_nullable
                      as int?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastUsed: freezed == lastUsed
                ? _value.lastUsed
                : lastUsed // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LiteRTModelImplCopyWith<$Res>
    implements $LiteRTModelCopyWith<$Res> {
  factory _$$LiteRTModelImplCopyWith(
    _$LiteRTModelImpl value,
    $Res Function(_$LiteRTModelImpl) then,
  ) = __$$LiteRTModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String localPath,
    LiteRTModelStatus status,
    int? sizeInBytes,
    int? downloadProgress,
    String? errorMessage,
    DateTime? lastUsed,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$LiteRTModelImplCopyWithImpl<$Res>
    extends _$LiteRTModelCopyWithImpl<$Res, _$LiteRTModelImpl>
    implements _$$LiteRTModelImplCopyWith<$Res> {
  __$$LiteRTModelImplCopyWithImpl(
    _$LiteRTModelImpl _value,
    $Res Function(_$LiteRTModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LiteRTModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? localPath = null,
    Object? status = null,
    Object? sizeInBytes = freezed,
    Object? downloadProgress = freezed,
    Object? errorMessage = freezed,
    Object? lastUsed = freezed,
    Object? createdAt = null,
  }) {
    return _then(
      _$LiteRTModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        localPath: null == localPath
            ? _value.localPath
            : localPath // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as LiteRTModelStatus,
        sizeInBytes: freezed == sizeInBytes
            ? _value.sizeInBytes
            : sizeInBytes // ignore: cast_nullable_to_non_nullable
                  as int?,
        downloadProgress: freezed == downloadProgress
            ? _value.downloadProgress
            : downloadProgress // ignore: cast_nullable_to_non_nullable
                  as int?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastUsed: freezed == lastUsed
            ? _value.lastUsed
            : lastUsed // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiteRTModelImpl extends _LiteRTModel {
  const _$LiteRTModelImpl({
    required this.id,
    required this.name,
    required this.localPath,
    required this.status,
    this.sizeInBytes,
    this.downloadProgress,
    this.errorMessage,
    this.lastUsed,
    required this.createdAt,
  }) : super._();

  factory _$LiteRTModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiteRTModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String localPath;
  @override
  final LiteRTModelStatus status;
  @override
  final int? sizeInBytes;
  @override
  final int? downloadProgress;
  @override
  final String? errorMessage;
  @override
  final DateTime? lastUsed;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'LiteRTModel(id: $id, name: $name, localPath: $localPath, status: $status, sizeInBytes: $sizeInBytes, downloadProgress: $downloadProgress, errorMessage: $errorMessage, lastUsed: $lastUsed, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiteRTModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sizeInBytes, sizeInBytes) ||
                other.sizeInBytes == sizeInBytes) &&
            (identical(other.downloadProgress, downloadProgress) ||
                other.downloadProgress == downloadProgress) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.lastUsed, lastUsed) ||
                other.lastUsed == lastUsed) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    localPath,
    status,
    sizeInBytes,
    downloadProgress,
    errorMessage,
    lastUsed,
    createdAt,
  );

  /// Create a copy of LiteRTModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiteRTModelImplCopyWith<_$LiteRTModelImpl> get copyWith =>
      __$$LiteRTModelImplCopyWithImpl<_$LiteRTModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LiteRTModelImplToJson(this);
  }
}

abstract class _LiteRTModel extends LiteRTModel {
  const factory _LiteRTModel({
    required final String id,
    required final String name,
    required final String localPath,
    required final LiteRTModelStatus status,
    final int? sizeInBytes,
    final int? downloadProgress,
    final String? errorMessage,
    final DateTime? lastUsed,
    required final DateTime createdAt,
  }) = _$LiteRTModelImpl;
  const _LiteRTModel._() : super._();

  factory _LiteRTModel.fromJson(Map<String, dynamic> json) =
      _$LiteRTModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get localPath;
  @override
  LiteRTModelStatus get status;
  @override
  int? get sizeInBytes;
  @override
  int? get downloadProgress;
  @override
  String? get errorMessage;
  @override
  DateTime? get lastUsed;
  @override
  DateTime get createdAt;

  /// Create a copy of LiteRTModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiteRTModelImplCopyWith<_$LiteRTModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
