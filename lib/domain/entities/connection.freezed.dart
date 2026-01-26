// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ConnectionProfile _$ConnectionProfileFromJson(Map<String, dynamic> json) {
  return _ConnectionProfile.fromJson(json);
}

/// @nodoc
mixin _$ConnectionProfile {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get host => throw _privateConstructorUsedError;
  int get port => throw _privateConstructorUsedError;
  bool get isDefault => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ConnectionProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionProfileCopyWith<ConnectionProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionProfileCopyWith<$Res> {
  factory $ConnectionProfileCopyWith(
    ConnectionProfile value,
    $Res Function(ConnectionProfile) then,
  ) = _$ConnectionProfileCopyWithImpl<$Res, ConnectionProfile>;
  @useResult
  $Res call({
    int id,
    String name,
    String host,
    int port,
    bool isDefault,
    DateTime createdAt,
  });
}

/// @nodoc
class _$ConnectionProfileCopyWithImpl<$Res, $Val extends ConnectionProfile>
    implements $ConnectionProfileCopyWith<$Res> {
  _$ConnectionProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? host = null,
    Object? port = null,
    Object? isDefault = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            host: null == host
                ? _value.host
                : host // ignore: cast_nullable_to_non_nullable
                      as String,
            port: null == port
                ? _value.port
                : port // ignore: cast_nullable_to_non_nullable
                      as int,
            isDefault: null == isDefault
                ? _value.isDefault
                : isDefault // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$ConnectionProfileImplCopyWith<$Res>
    implements $ConnectionProfileCopyWith<$Res> {
  factory _$$ConnectionProfileImplCopyWith(
    _$ConnectionProfileImpl value,
    $Res Function(_$ConnectionProfileImpl) then,
  ) = __$$ConnectionProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    String host,
    int port,
    bool isDefault,
    DateTime createdAt,
  });
}

/// @nodoc
class __$$ConnectionProfileImplCopyWithImpl<$Res>
    extends _$ConnectionProfileCopyWithImpl<$Res, _$ConnectionProfileImpl>
    implements _$$ConnectionProfileImplCopyWith<$Res> {
  __$$ConnectionProfileImplCopyWithImpl(
    _$ConnectionProfileImpl _value,
    $Res Function(_$ConnectionProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectionProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? host = null,
    Object? port = null,
    Object? isDefault = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ConnectionProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        host: null == host
            ? _value.host
            : host // ignore: cast_nullable_to_non_nullable
                  as String,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        isDefault: null == isDefault
            ? _value.isDefault
            : isDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$ConnectionProfileImpl extends _ConnectionProfile {
  const _$ConnectionProfileImpl({
    required this.id,
    required this.name,
    required this.host,
    this.port = 11434,
    this.isDefault = false,
    required this.createdAt,
  }) : super._();

  factory _$ConnectionProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionProfileImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final String host;
  @override
  @JsonKey()
  final int port;
  @override
  @JsonKey()
  final bool isDefault;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ConnectionProfile(id: $id, name: $name, host: $host, port: $port, isDefault: $isDefault, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.isDefault, isDefault) ||
                other.isDefault == isDefault) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, host, port, isDefault, createdAt);

  /// Create a copy of ConnectionProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionProfileImplCopyWith<_$ConnectionProfileImpl> get copyWith =>
      __$$ConnectionProfileImplCopyWithImpl<_$ConnectionProfileImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionProfileImplToJson(this);
  }
}

abstract class _ConnectionProfile extends ConnectionProfile {
  const factory _ConnectionProfile({
    required final int id,
    required final String name,
    required final String host,
    final int port,
    final bool isDefault,
    required final DateTime createdAt,
  }) = _$ConnectionProfileImpl;
  const _ConnectionProfile._() : super._();

  factory _ConnectionProfile.fromJson(Map<String, dynamic> json) =
      _$ConnectionProfileImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  String get host;
  @override
  int get port;
  @override
  bool get isDefault;
  @override
  DateTime get createdAt;

  /// Create a copy of ConnectionProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionProfileImplCopyWith<_$ConnectionProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ConnectionHealth _$ConnectionHealthFromJson(Map<String, dynamic> json) {
  return _ConnectionHealth.fromJson(json);
}

/// @nodoc
mixin _$ConnectionHealth {
  ConnectionStatus get status => throw _privateConstructorUsedError;
  DateTime get lastCheck => throw _privateConstructorUsedError;
  double get successRate => throw _privateConstructorUsedError;
  Duration? get avgLatency => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  DateTime? get nextAvailableAt => throw _privateConstructorUsedError;

  /// Serializes this ConnectionHealth to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionHealth
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionHealthCopyWith<ConnectionHealth> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionHealthCopyWith<$Res> {
  factory $ConnectionHealthCopyWith(
    ConnectionHealth value,
    $Res Function(ConnectionHealth) then,
  ) = _$ConnectionHealthCopyWithImpl<$Res, ConnectionHealth>;
  @useResult
  $Res call({
    ConnectionStatus status,
    DateTime lastCheck,
    double successRate,
    Duration? avgLatency,
    String? errorMessage,
    DateTime? nextAvailableAt,
  });
}

/// @nodoc
class _$ConnectionHealthCopyWithImpl<$Res, $Val extends ConnectionHealth>
    implements $ConnectionHealthCopyWith<$Res> {
  _$ConnectionHealthCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionHealth
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? lastCheck = null,
    Object? successRate = null,
    Object? avgLatency = freezed,
    Object? errorMessage = freezed,
    Object? nextAvailableAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ConnectionStatus,
            lastCheck: null == lastCheck
                ? _value.lastCheck
                : lastCheck // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            successRate: null == successRate
                ? _value.successRate
                : successRate // ignore: cast_nullable_to_non_nullable
                      as double,
            avgLatency: freezed == avgLatency
                ? _value.avgLatency
                : avgLatency // ignore: cast_nullable_to_non_nullable
                      as Duration?,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
            nextAvailableAt: freezed == nextAvailableAt
                ? _value.nextAvailableAt
                : nextAvailableAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConnectionHealthImplCopyWith<$Res>
    implements $ConnectionHealthCopyWith<$Res> {
  factory _$$ConnectionHealthImplCopyWith(
    _$ConnectionHealthImpl value,
    $Res Function(_$ConnectionHealthImpl) then,
  ) = __$$ConnectionHealthImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ConnectionStatus status,
    DateTime lastCheck,
    double successRate,
    Duration? avgLatency,
    String? errorMessage,
    DateTime? nextAvailableAt,
  });
}

/// @nodoc
class __$$ConnectionHealthImplCopyWithImpl<$Res>
    extends _$ConnectionHealthCopyWithImpl<$Res, _$ConnectionHealthImpl>
    implements _$$ConnectionHealthImplCopyWith<$Res> {
  __$$ConnectionHealthImplCopyWithImpl(
    _$ConnectionHealthImpl _value,
    $Res Function(_$ConnectionHealthImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectionHealth
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? lastCheck = null,
    Object? successRate = null,
    Object? avgLatency = freezed,
    Object? errorMessage = freezed,
    Object? nextAvailableAt = freezed,
  }) {
    return _then(
      _$ConnectionHealthImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ConnectionStatus,
        lastCheck: null == lastCheck
            ? _value.lastCheck
            : lastCheck // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        successRate: null == successRate
            ? _value.successRate
            : successRate // ignore: cast_nullable_to_non_nullable
                  as double,
        avgLatency: freezed == avgLatency
            ? _value.avgLatency
            : avgLatency // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
        nextAvailableAt: freezed == nextAvailableAt
            ? _value.nextAvailableAt
            : nextAvailableAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ConnectionHealthImpl extends _ConnectionHealth {
  const _$ConnectionHealthImpl({
    required this.status,
    required this.lastCheck,
    this.successRate = 1.0,
    this.avgLatency,
    this.errorMessage,
    this.nextAvailableAt,
  }) : super._();

  factory _$ConnectionHealthImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConnectionHealthImplFromJson(json);

  @override
  final ConnectionStatus status;
  @override
  final DateTime lastCheck;
  @override
  @JsonKey()
  final double successRate;
  @override
  final Duration? avgLatency;
  @override
  final String? errorMessage;
  @override
  final DateTime? nextAvailableAt;

  @override
  String toString() {
    return 'ConnectionHealth(status: $status, lastCheck: $lastCheck, successRate: $successRate, avgLatency: $avgLatency, errorMessage: $errorMessage, nextAvailableAt: $nextAvailableAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionHealthImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastCheck, lastCheck) ||
                other.lastCheck == lastCheck) &&
            (identical(other.successRate, successRate) ||
                other.successRate == successRate) &&
            (identical(other.avgLatency, avgLatency) ||
                other.avgLatency == avgLatency) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.nextAvailableAt, nextAvailableAt) ||
                other.nextAvailableAt == nextAvailableAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    lastCheck,
    successRate,
    avgLatency,
    errorMessage,
    nextAvailableAt,
  );

  /// Create a copy of ConnectionHealth
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionHealthImplCopyWith<_$ConnectionHealthImpl> get copyWith =>
      __$$ConnectionHealthImplCopyWithImpl<_$ConnectionHealthImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ConnectionHealthImplToJson(this);
  }
}

abstract class _ConnectionHealth extends ConnectionHealth {
  const factory _ConnectionHealth({
    required final ConnectionStatus status,
    required final DateTime lastCheck,
    final double successRate,
    final Duration? avgLatency,
    final String? errorMessage,
    final DateTime? nextAvailableAt,
  }) = _$ConnectionHealthImpl;
  const _ConnectionHealth._() : super._();

  factory _ConnectionHealth.fromJson(Map<String, dynamic> json) =
      _$ConnectionHealthImpl.fromJson;

  @override
  ConnectionStatus get status;
  @override
  DateTime get lastCheck;
  @override
  double get successRate;
  @override
  Duration? get avgLatency;
  @override
  String? get errorMessage;
  @override
  DateTime? get nextAvailableAt;

  /// Create a copy of ConnectionHealth
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionHealthImplCopyWith<_$ConnectionHealthImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
