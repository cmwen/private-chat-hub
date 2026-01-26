// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ollama_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OllamaModel _$OllamaModelFromJson(Map<String, dynamic> json) {
  return _OllamaModel.fromJson(json);
}

/// @nodoc
mixin _$OllamaModel {
  String get name => throw _privateConstructorUsedError;
  int get size => throw _privateConstructorUsedError;
  DateTime get modifiedAt => throw _privateConstructorUsedError;
  String? get digest => throw _privateConstructorUsedError;
  ModelDetails? get details => throw _privateConstructorUsedError;

  /// Serializes this OllamaModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OllamaModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OllamaModelCopyWith<OllamaModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OllamaModelCopyWith<$Res> {
  factory $OllamaModelCopyWith(
    OllamaModel value,
    $Res Function(OllamaModel) then,
  ) = _$OllamaModelCopyWithImpl<$Res, OllamaModel>;
  @useResult
  $Res call({
    String name,
    int size,
    DateTime modifiedAt,
    String? digest,
    ModelDetails? details,
  });

  $ModelDetailsCopyWith<$Res>? get details;
}

/// @nodoc
class _$OllamaModelCopyWithImpl<$Res, $Val extends OllamaModel>
    implements $OllamaModelCopyWith<$Res> {
  _$OllamaModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OllamaModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? size = null,
    Object? modifiedAt = null,
    Object? digest = freezed,
    Object? details = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as int,
            modifiedAt: null == modifiedAt
                ? _value.modifiedAt
                : modifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            digest: freezed == digest
                ? _value.digest
                : digest // ignore: cast_nullable_to_non_nullable
                      as String?,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as ModelDetails?,
          )
          as $Val,
    );
  }

  /// Create a copy of OllamaModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModelDetailsCopyWith<$Res>? get details {
    if (_value.details == null) {
      return null;
    }

    return $ModelDetailsCopyWith<$Res>(_value.details!, (value) {
      return _then(_value.copyWith(details: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OllamaModelImplCopyWith<$Res>
    implements $OllamaModelCopyWith<$Res> {
  factory _$$OllamaModelImplCopyWith(
    _$OllamaModelImpl value,
    $Res Function(_$OllamaModelImpl) then,
  ) = __$$OllamaModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    int size,
    DateTime modifiedAt,
    String? digest,
    ModelDetails? details,
  });

  @override
  $ModelDetailsCopyWith<$Res>? get details;
}

/// @nodoc
class __$$OllamaModelImplCopyWithImpl<$Res>
    extends _$OllamaModelCopyWithImpl<$Res, _$OllamaModelImpl>
    implements _$$OllamaModelImplCopyWith<$Res> {
  __$$OllamaModelImplCopyWithImpl(
    _$OllamaModelImpl _value,
    $Res Function(_$OllamaModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OllamaModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? size = null,
    Object? modifiedAt = null,
    Object? digest = freezed,
    Object? details = freezed,
  }) {
    return _then(
      _$OllamaModelImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as int,
        modifiedAt: null == modifiedAt
            ? _value.modifiedAt
            : modifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        digest: freezed == digest
            ? _value.digest
            : digest // ignore: cast_nullable_to_non_nullable
                  as String?,
        details: freezed == details
            ? _value.details
            : details // ignore: cast_nullable_to_non_nullable
                  as ModelDetails?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OllamaModelImpl implements _OllamaModel {
  const _$OllamaModelImpl({
    required this.name,
    required this.size,
    required this.modifiedAt,
    this.digest,
    this.details,
  });

  factory _$OllamaModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OllamaModelImplFromJson(json);

  @override
  final String name;
  @override
  final int size;
  @override
  final DateTime modifiedAt;
  @override
  final String? digest;
  @override
  final ModelDetails? details;

  @override
  String toString() {
    return 'OllamaModel(name: $name, size: $size, modifiedAt: $modifiedAt, digest: $digest, details: $details)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OllamaModelImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            (identical(other.digest, digest) || other.digest == digest) &&
            (identical(other.details, details) || other.details == details));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, size, modifiedAt, digest, details);

  /// Create a copy of OllamaModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OllamaModelImplCopyWith<_$OllamaModelImpl> get copyWith =>
      __$$OllamaModelImplCopyWithImpl<_$OllamaModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OllamaModelImplToJson(this);
  }
}

abstract class _OllamaModel implements OllamaModel {
  const factory _OllamaModel({
    required final String name,
    required final int size,
    required final DateTime modifiedAt,
    final String? digest,
    final ModelDetails? details,
  }) = _$OllamaModelImpl;

  factory _OllamaModel.fromJson(Map<String, dynamic> json) =
      _$OllamaModelImpl.fromJson;

  @override
  String get name;
  @override
  int get size;
  @override
  DateTime get modifiedAt;
  @override
  String? get digest;
  @override
  ModelDetails? get details;

  /// Create a copy of OllamaModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OllamaModelImplCopyWith<_$OllamaModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModelDetails _$ModelDetailsFromJson(Map<String, dynamic> json) {
  return _ModelDetails.fromJson(json);
}

/// @nodoc
mixin _$ModelDetails {
  String? get format => throw _privateConstructorUsedError;
  String? get family => throw _privateConstructorUsedError;
  String? get parameterSize => throw _privateConstructorUsedError;
  String? get quantizationLevel => throw _privateConstructorUsedError;
  List<String>? get capabilities => throw _privateConstructorUsedError;

  /// Serializes this ModelDetails to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelDetailsCopyWith<ModelDetails> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelDetailsCopyWith<$Res> {
  factory $ModelDetailsCopyWith(
    ModelDetails value,
    $Res Function(ModelDetails) then,
  ) = _$ModelDetailsCopyWithImpl<$Res, ModelDetails>;
  @useResult
  $Res call({
    String? format,
    String? family,
    String? parameterSize,
    String? quantizationLevel,
    List<String>? capabilities,
  });
}

/// @nodoc
class _$ModelDetailsCopyWithImpl<$Res, $Val extends ModelDetails>
    implements $ModelDetailsCopyWith<$Res> {
  _$ModelDetailsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? format = freezed,
    Object? family = freezed,
    Object? parameterSize = freezed,
    Object? quantizationLevel = freezed,
    Object? capabilities = freezed,
  }) {
    return _then(
      _value.copyWith(
            format: freezed == format
                ? _value.format
                : format // ignore: cast_nullable_to_non_nullable
                      as String?,
            family: freezed == family
                ? _value.family
                : family // ignore: cast_nullable_to_non_nullable
                      as String?,
            parameterSize: freezed == parameterSize
                ? _value.parameterSize
                : parameterSize // ignore: cast_nullable_to_non_nullable
                      as String?,
            quantizationLevel: freezed == quantizationLevel
                ? _value.quantizationLevel
                : quantizationLevel // ignore: cast_nullable_to_non_nullable
                      as String?,
            capabilities: freezed == capabilities
                ? _value.capabilities
                : capabilities // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ModelDetailsImplCopyWith<$Res>
    implements $ModelDetailsCopyWith<$Res> {
  factory _$$ModelDetailsImplCopyWith(
    _$ModelDetailsImpl value,
    $Res Function(_$ModelDetailsImpl) then,
  ) = __$$ModelDetailsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? format,
    String? family,
    String? parameterSize,
    String? quantizationLevel,
    List<String>? capabilities,
  });
}

/// @nodoc
class __$$ModelDetailsImplCopyWithImpl<$Res>
    extends _$ModelDetailsCopyWithImpl<$Res, _$ModelDetailsImpl>
    implements _$$ModelDetailsImplCopyWith<$Res> {
  __$$ModelDetailsImplCopyWithImpl(
    _$ModelDetailsImpl _value,
    $Res Function(_$ModelDetailsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModelDetails
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? format = freezed,
    Object? family = freezed,
    Object? parameterSize = freezed,
    Object? quantizationLevel = freezed,
    Object? capabilities = freezed,
  }) {
    return _then(
      _$ModelDetailsImpl(
        format: freezed == format
            ? _value.format
            : format // ignore: cast_nullable_to_non_nullable
                  as String?,
        family: freezed == family
            ? _value.family
            : family // ignore: cast_nullable_to_non_nullable
                  as String?,
        parameterSize: freezed == parameterSize
            ? _value.parameterSize
            : parameterSize // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantizationLevel: freezed == quantizationLevel
            ? _value.quantizationLevel
            : quantizationLevel // ignore: cast_nullable_to_non_nullable
                  as String?,
        capabilities: freezed == capabilities
            ? _value._capabilities
            : capabilities // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelDetailsImpl implements _ModelDetails {
  const _$ModelDetailsImpl({
    this.format,
    this.family,
    this.parameterSize,
    this.quantizationLevel,
    final List<String>? capabilities,
  }) : _capabilities = capabilities;

  factory _$ModelDetailsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelDetailsImplFromJson(json);

  @override
  final String? format;
  @override
  final String? family;
  @override
  final String? parameterSize;
  @override
  final String? quantizationLevel;
  final List<String>? _capabilities;
  @override
  List<String>? get capabilities {
    final value = _capabilities;
    if (value == null) return null;
    if (_capabilities is EqualUnmodifiableListView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ModelDetails(format: $format, family: $family, parameterSize: $parameterSize, quantizationLevel: $quantizationLevel, capabilities: $capabilities)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelDetailsImpl &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.family, family) || other.family == family) &&
            (identical(other.parameterSize, parameterSize) ||
                other.parameterSize == parameterSize) &&
            (identical(other.quantizationLevel, quantizationLevel) ||
                other.quantizationLevel == quantizationLevel) &&
            const DeepCollectionEquality().equals(
              other._capabilities,
              _capabilities,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    format,
    family,
    parameterSize,
    quantizationLevel,
    const DeepCollectionEquality().hash(_capabilities),
  );

  /// Create a copy of ModelDetails
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelDetailsImplCopyWith<_$ModelDetailsImpl> get copyWith =>
      __$$ModelDetailsImplCopyWithImpl<_$ModelDetailsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelDetailsImplToJson(this);
  }
}

abstract class _ModelDetails implements ModelDetails {
  const factory _ModelDetails({
    final String? format,
    final String? family,
    final String? parameterSize,
    final String? quantizationLevel,
    final List<String>? capabilities,
  }) = _$ModelDetailsImpl;

  factory _ModelDetails.fromJson(Map<String, dynamic> json) =
      _$ModelDetailsImpl.fromJson;

  @override
  String? get format;
  @override
  String? get family;
  @override
  String? get parameterSize;
  @override
  String? get quantizationLevel;
  @override
  List<String>? get capabilities;

  /// Create a copy of ModelDetails
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelDetailsImplCopyWith<_$ModelDetailsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PullProgress _$PullProgressFromJson(Map<String, dynamic> json) {
  return _PullProgress.fromJson(json);
}

/// @nodoc
mixin _$PullProgress {
  String get status => throw _privateConstructorUsedError;
  String? get digest => throw _privateConstructorUsedError;
  int? get total => throw _privateConstructorUsedError;
  int? get completed => throw _privateConstructorUsedError;

  /// Serializes this PullProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PullProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PullProgressCopyWith<PullProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PullProgressCopyWith<$Res> {
  factory $PullProgressCopyWith(
    PullProgress value,
    $Res Function(PullProgress) then,
  ) = _$PullProgressCopyWithImpl<$Res, PullProgress>;
  @useResult
  $Res call({String status, String? digest, int? total, int? completed});
}

/// @nodoc
class _$PullProgressCopyWithImpl<$Res, $Val extends PullProgress>
    implements $PullProgressCopyWith<$Res> {
  _$PullProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PullProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? digest = freezed,
    Object? total = freezed,
    Object? completed = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            digest: freezed == digest
                ? _value.digest
                : digest // ignore: cast_nullable_to_non_nullable
                      as String?,
            total: freezed == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                      as int?,
            completed: freezed == completed
                ? _value.completed
                : completed // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PullProgressImplCopyWith<$Res>
    implements $PullProgressCopyWith<$Res> {
  factory _$$PullProgressImplCopyWith(
    _$PullProgressImpl value,
    $Res Function(_$PullProgressImpl) then,
  ) = __$$PullProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, String? digest, int? total, int? completed});
}

/// @nodoc
class __$$PullProgressImplCopyWithImpl<$Res>
    extends _$PullProgressCopyWithImpl<$Res, _$PullProgressImpl>
    implements _$$PullProgressImplCopyWith<$Res> {
  __$$PullProgressImplCopyWithImpl(
    _$PullProgressImpl _value,
    $Res Function(_$PullProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PullProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? digest = freezed,
    Object? total = freezed,
    Object? completed = freezed,
  }) {
    return _then(
      _$PullProgressImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        digest: freezed == digest
            ? _value.digest
            : digest // ignore: cast_nullable_to_non_nullable
                  as String?,
        total: freezed == total
            ? _value.total
            : total // ignore: cast_nullable_to_non_nullable
                  as int?,
        completed: freezed == completed
            ? _value.completed
            : completed // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PullProgressImpl extends _PullProgress {
  const _$PullProgressImpl({
    required this.status,
    this.digest,
    this.total,
    this.completed,
  }) : super._();

  factory _$PullProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$PullProgressImplFromJson(json);

  @override
  final String status;
  @override
  final String? digest;
  @override
  final int? total;
  @override
  final int? completed;

  @override
  String toString() {
    return 'PullProgress(status: $status, digest: $digest, total: $total, completed: $completed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PullProgressImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.digest, digest) || other.digest == digest) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.completed, completed) ||
                other.completed == completed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, status, digest, total, completed);

  /// Create a copy of PullProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PullProgressImplCopyWith<_$PullProgressImpl> get copyWith =>
      __$$PullProgressImplCopyWithImpl<_$PullProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PullProgressImplToJson(this);
  }
}

abstract class _PullProgress extends PullProgress {
  const factory _PullProgress({
    required final String status,
    final String? digest,
    final int? total,
    final int? completed,
  }) = _$PullProgressImpl;
  const _PullProgress._() : super._();

  factory _PullProgress.fromJson(Map<String, dynamic> json) =
      _$PullProgressImpl.fromJson;

  @override
  String get status;
  @override
  String? get digest;
  @override
  int? get total;
  @override
  int? get completed;

  /// Create a copy of PullProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PullProgressImplCopyWith<_$PullProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
