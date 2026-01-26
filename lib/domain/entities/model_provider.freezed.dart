// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ModelProviderConfig _$ModelProviderConfigFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'ollama':
      return OllamaProviderConfig.fromJson(json);
    case 'litert':
      return LiteRTProviderConfig.fromJson(json);
    case 'openai':
      return OpenAIProviderConfig.fromJson(json);

    default:
      throw CheckedFromJsonException(
        json,
        'runtimeType',
        'ModelProviderConfig',
        'Invalid union type "${json['runtimeType']}"!',
      );
  }
}

/// @nodoc
mixin _$ModelProviderConfig {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String host, int port, String modelName) ollama,
    required TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )
    litert,
    required TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )
    openai,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String host, int port, String modelName)? ollama,
    TResult? Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult? Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String host, int port, String modelName)? ollama,
    TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OllamaProviderConfig value) ollama,
    required TResult Function(LiteRTProviderConfig value) litert,
    required TResult Function(OpenAIProviderConfig value) openai,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OllamaProviderConfig value)? ollama,
    TResult? Function(LiteRTProviderConfig value)? litert,
    TResult? Function(OpenAIProviderConfig value)? openai,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OllamaProviderConfig value)? ollama,
    TResult Function(LiteRTProviderConfig value)? litert,
    TResult Function(OpenAIProviderConfig value)? openai,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this ModelProviderConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelProviderConfigCopyWith<$Res> {
  factory $ModelProviderConfigCopyWith(
    ModelProviderConfig value,
    $Res Function(ModelProviderConfig) then,
  ) = _$ModelProviderConfigCopyWithImpl<$Res, ModelProviderConfig>;
}

/// @nodoc
class _$ModelProviderConfigCopyWithImpl<$Res, $Val extends ModelProviderConfig>
    implements $ModelProviderConfigCopyWith<$Res> {
  _$ModelProviderConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$OllamaProviderConfigImplCopyWith<$Res> {
  factory _$$OllamaProviderConfigImplCopyWith(
    _$OllamaProviderConfigImpl value,
    $Res Function(_$OllamaProviderConfigImpl) then,
  ) = __$$OllamaProviderConfigImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String host, int port, String modelName});
}

/// @nodoc
class __$$OllamaProviderConfigImplCopyWithImpl<$Res>
    extends _$ModelProviderConfigCopyWithImpl<$Res, _$OllamaProviderConfigImpl>
    implements _$$OllamaProviderConfigImplCopyWith<$Res> {
  __$$OllamaProviderConfigImplCopyWithImpl(
    _$OllamaProviderConfigImpl _value,
    $Res Function(_$OllamaProviderConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? host = null,
    Object? port = null,
    Object? modelName = null,
  }) {
    return _then(
      _$OllamaProviderConfigImpl(
        host: null == host
            ? _value.host
            : host // ignore: cast_nullable_to_non_nullable
                  as String,
        port: null == port
            ? _value.port
            : port // ignore: cast_nullable_to_non_nullable
                  as int,
        modelName: null == modelName
            ? _value.modelName
            : modelName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OllamaProviderConfigImpl extends OllamaProviderConfig {
  const _$OllamaProviderConfigImpl({
    required this.host,
    this.port = 11434,
    required this.modelName,
    final String? $type,
  }) : $type = $type ?? 'ollama',
       super._();

  factory _$OllamaProviderConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$OllamaProviderConfigImplFromJson(json);

  @override
  final String host;
  @override
  @JsonKey()
  final int port;
  @override
  final String modelName;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ModelProviderConfig.ollama(host: $host, port: $port, modelName: $modelName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OllamaProviderConfigImpl &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.port, port) || other.port == port) &&
            (identical(other.modelName, modelName) ||
                other.modelName == modelName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, host, port, modelName);

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OllamaProviderConfigImplCopyWith<_$OllamaProviderConfigImpl>
  get copyWith =>
      __$$OllamaProviderConfigImplCopyWithImpl<_$OllamaProviderConfigImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String host, int port, String modelName) ollama,
    required TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )
    litert,
    required TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )
    openai,
  }) {
    return ollama(host, port, modelName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String host, int port, String modelName)? ollama,
    TResult? Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult? Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
  }) {
    return ollama?.call(host, port, modelName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String host, int port, String modelName)? ollama,
    TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
    required TResult orElse(),
  }) {
    if (ollama != null) {
      return ollama(host, port, modelName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OllamaProviderConfig value) ollama,
    required TResult Function(LiteRTProviderConfig value) litert,
    required TResult Function(OpenAIProviderConfig value) openai,
  }) {
    return ollama(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OllamaProviderConfig value)? ollama,
    TResult? Function(LiteRTProviderConfig value)? litert,
    TResult? Function(OpenAIProviderConfig value)? openai,
  }) {
    return ollama?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OllamaProviderConfig value)? ollama,
    TResult Function(LiteRTProviderConfig value)? litert,
    TResult Function(OpenAIProviderConfig value)? openai,
    required TResult orElse(),
  }) {
    if (ollama != null) {
      return ollama(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$OllamaProviderConfigImplToJson(this);
  }
}

abstract class OllamaProviderConfig extends ModelProviderConfig {
  const factory OllamaProviderConfig({
    required final String host,
    final int port,
    required final String modelName,
  }) = _$OllamaProviderConfigImpl;
  const OllamaProviderConfig._() : super._();

  factory OllamaProviderConfig.fromJson(Map<String, dynamic> json) =
      _$OllamaProviderConfigImpl.fromJson;

  String get host;
  int get port;
  String get modelName;

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OllamaProviderConfigImplCopyWith<_$OllamaProviderConfigImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LiteRTProviderConfigImplCopyWith<$Res> {
  factory _$$LiteRTProviderConfigImplCopyWith(
    _$LiteRTProviderConfigImpl value,
    $Res Function(_$LiteRTProviderConfigImpl) then,
  ) = __$$LiteRTProviderConfigImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String modelPath, int maxTokens, double temperature, int topK});
}

/// @nodoc
class __$$LiteRTProviderConfigImplCopyWithImpl<$Res>
    extends _$ModelProviderConfigCopyWithImpl<$Res, _$LiteRTProviderConfigImpl>
    implements _$$LiteRTProviderConfigImplCopyWith<$Res> {
  __$$LiteRTProviderConfigImplCopyWithImpl(
    _$LiteRTProviderConfigImpl _value,
    $Res Function(_$LiteRTProviderConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelPath = null,
    Object? maxTokens = null,
    Object? temperature = null,
    Object? topK = null,
  }) {
    return _then(
      _$LiteRTProviderConfigImpl(
        modelPath: null == modelPath
            ? _value.modelPath
            : modelPath // ignore: cast_nullable_to_non_nullable
                  as String,
        maxTokens: null == maxTokens
            ? _value.maxTokens
            : maxTokens // ignore: cast_nullable_to_non_nullable
                  as int,
        temperature: null == temperature
            ? _value.temperature
            : temperature // ignore: cast_nullable_to_non_nullable
                  as double,
        topK: null == topK
            ? _value.topK
            : topK // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LiteRTProviderConfigImpl extends LiteRTProviderConfig {
  const _$LiteRTProviderConfigImpl({
    required this.modelPath,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topK = 40,
    final String? $type,
  }) : $type = $type ?? 'litert',
       super._();

  factory _$LiteRTProviderConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$LiteRTProviderConfigImplFromJson(json);

  @override
  final String modelPath;
  @override
  @JsonKey()
  final int maxTokens;
  @override
  @JsonKey()
  final double temperature;
  @override
  @JsonKey()
  final int topK;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ModelProviderConfig.litert(modelPath: $modelPath, maxTokens: $maxTokens, temperature: $temperature, topK: $topK)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiteRTProviderConfigImpl &&
            (identical(other.modelPath, modelPath) ||
                other.modelPath == modelPath) &&
            (identical(other.maxTokens, maxTokens) ||
                other.maxTokens == maxTokens) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.topK, topK) || other.topK == topK));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, modelPath, maxTokens, temperature, topK);

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiteRTProviderConfigImplCopyWith<_$LiteRTProviderConfigImpl>
  get copyWith =>
      __$$LiteRTProviderConfigImplCopyWithImpl<_$LiteRTProviderConfigImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String host, int port, String modelName) ollama,
    required TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )
    litert,
    required TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )
    openai,
  }) {
    return litert(modelPath, maxTokens, temperature, topK);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String host, int port, String modelName)? ollama,
    TResult? Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult? Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
  }) {
    return litert?.call(modelPath, maxTokens, temperature, topK);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String host, int port, String modelName)? ollama,
    TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
    required TResult orElse(),
  }) {
    if (litert != null) {
      return litert(modelPath, maxTokens, temperature, topK);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OllamaProviderConfig value) ollama,
    required TResult Function(LiteRTProviderConfig value) litert,
    required TResult Function(OpenAIProviderConfig value) openai,
  }) {
    return litert(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OllamaProviderConfig value)? ollama,
    TResult? Function(LiteRTProviderConfig value)? litert,
    TResult? Function(OpenAIProviderConfig value)? openai,
  }) {
    return litert?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OllamaProviderConfig value)? ollama,
    TResult Function(LiteRTProviderConfig value)? litert,
    TResult Function(OpenAIProviderConfig value)? openai,
    required TResult orElse(),
  }) {
    if (litert != null) {
      return litert(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$LiteRTProviderConfigImplToJson(this);
  }
}

abstract class LiteRTProviderConfig extends ModelProviderConfig {
  const factory LiteRTProviderConfig({
    required final String modelPath,
    final int maxTokens,
    final double temperature,
    final int topK,
  }) = _$LiteRTProviderConfigImpl;
  const LiteRTProviderConfig._() : super._();

  factory LiteRTProviderConfig.fromJson(Map<String, dynamic> json) =
      _$LiteRTProviderConfigImpl.fromJson;

  String get modelPath;
  int get maxTokens;
  double get temperature;
  int get topK;

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiteRTProviderConfigImplCopyWith<_$LiteRTProviderConfigImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OpenAIProviderConfigImplCopyWith<$Res> {
  factory _$$OpenAIProviderConfigImplCopyWith(
    _$OpenAIProviderConfigImpl value,
    $Res Function(_$OpenAIProviderConfigImpl) then,
  ) = __$$OpenAIProviderConfigImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    String baseUrl,
    String apiKey,
    String modelName,
    double temperature,
    int maxTokens,
  });
}

/// @nodoc
class __$$OpenAIProviderConfigImplCopyWithImpl<$Res>
    extends _$ModelProviderConfigCopyWithImpl<$Res, _$OpenAIProviderConfigImpl>
    implements _$$OpenAIProviderConfigImplCopyWith<$Res> {
  __$$OpenAIProviderConfigImplCopyWithImpl(
    _$OpenAIProviderConfigImpl _value,
    $Res Function(_$OpenAIProviderConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseUrl = null,
    Object? apiKey = null,
    Object? modelName = null,
    Object? temperature = null,
    Object? maxTokens = null,
  }) {
    return _then(
      _$OpenAIProviderConfigImpl(
        baseUrl: null == baseUrl
            ? _value.baseUrl
            : baseUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        apiKey: null == apiKey
            ? _value.apiKey
            : apiKey // ignore: cast_nullable_to_non_nullable
                  as String,
        modelName: null == modelName
            ? _value.modelName
            : modelName // ignore: cast_nullable_to_non_nullable
                  as String,
        temperature: null == temperature
            ? _value.temperature
            : temperature // ignore: cast_nullable_to_non_nullable
                  as double,
        maxTokens: null == maxTokens
            ? _value.maxTokens
            : maxTokens // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OpenAIProviderConfigImpl extends OpenAIProviderConfig {
  const _$OpenAIProviderConfigImpl({
    required this.baseUrl,
    required this.apiKey,
    required this.modelName,
    this.temperature = 0.7,
    this.maxTokens = 2000,
    final String? $type,
  }) : $type = $type ?? 'openai',
       super._();

  factory _$OpenAIProviderConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpenAIProviderConfigImplFromJson(json);

  @override
  final String baseUrl;
  @override
  final String apiKey;
  @override
  final String modelName;
  @override
  @JsonKey()
  final double temperature;
  @override
  @JsonKey()
  final int maxTokens;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'ModelProviderConfig.openai(baseUrl: $baseUrl, apiKey: $apiKey, modelName: $modelName, temperature: $temperature, maxTokens: $maxTokens)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpenAIProviderConfigImpl &&
            (identical(other.baseUrl, baseUrl) || other.baseUrl == baseUrl) &&
            (identical(other.apiKey, apiKey) || other.apiKey == apiKey) &&
            (identical(other.modelName, modelName) ||
                other.modelName == modelName) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature) &&
            (identical(other.maxTokens, maxTokens) ||
                other.maxTokens == maxTokens));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    baseUrl,
    apiKey,
    modelName,
    temperature,
    maxTokens,
  );

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OpenAIProviderConfigImplCopyWith<_$OpenAIProviderConfigImpl>
  get copyWith =>
      __$$OpenAIProviderConfigImplCopyWithImpl<_$OpenAIProviderConfigImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String host, int port, String modelName) ollama,
    required TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )
    litert,
    required TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )
    openai,
  }) {
    return openai(baseUrl, apiKey, modelName, temperature, maxTokens);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String host, int port, String modelName)? ollama,
    TResult? Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult? Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
  }) {
    return openai?.call(baseUrl, apiKey, modelName, temperature, maxTokens);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String host, int port, String modelName)? ollama,
    TResult Function(
      String modelPath,
      int maxTokens,
      double temperature,
      int topK,
    )?
    litert,
    TResult Function(
      String baseUrl,
      String apiKey,
      String modelName,
      double temperature,
      int maxTokens,
    )?
    openai,
    required TResult orElse(),
  }) {
    if (openai != null) {
      return openai(baseUrl, apiKey, modelName, temperature, maxTokens);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OllamaProviderConfig value) ollama,
    required TResult Function(LiteRTProviderConfig value) litert,
    required TResult Function(OpenAIProviderConfig value) openai,
  }) {
    return openai(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OllamaProviderConfig value)? ollama,
    TResult? Function(LiteRTProviderConfig value)? litert,
    TResult? Function(OpenAIProviderConfig value)? openai,
  }) {
    return openai?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OllamaProviderConfig value)? ollama,
    TResult Function(LiteRTProviderConfig value)? litert,
    TResult Function(OpenAIProviderConfig value)? openai,
    required TResult orElse(),
  }) {
    if (openai != null) {
      return openai(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$OpenAIProviderConfigImplToJson(this);
  }
}

abstract class OpenAIProviderConfig extends ModelProviderConfig {
  const factory OpenAIProviderConfig({
    required final String baseUrl,
    required final String apiKey,
    required final String modelName,
    final double temperature,
    final int maxTokens,
  }) = _$OpenAIProviderConfigImpl;
  const OpenAIProviderConfig._() : super._();

  factory OpenAIProviderConfig.fromJson(Map<String, dynamic> json) =
      _$OpenAIProviderConfigImpl.fromJson;

  String get baseUrl;
  String get apiKey;
  String get modelName;
  double get temperature;
  int get maxTokens;

  /// Create a copy of ModelProviderConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OpenAIProviderConfigImplCopyWith<_$OpenAIProviderConfigImpl>
  get copyWith => throw _privateConstructorUsedError;
}
