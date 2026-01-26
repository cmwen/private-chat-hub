import 'package:private_chat_hub/core/errors/failures.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success(value: final value) => success(value),
      ResultFailure(failure: final f) => failure(f),
    };
  }

  R maybeWhen<R>({
    R Function(T value)? success,
    R Function(Failure failure)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      Success(value: final value) when success != null => success(value),
      ResultFailure(failure: final f) when failure != null => failure(f),
      _ => orElse(),
    };
  }

  T? get valueOrNull => switch (this) {
    Success(value: final value) => value,
    _ => null,
  };

  Failure? get failureOrNull => switch (this) {
    ResultFailure(failure: final f) => f,
    _ => null,
  };

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ResultFailure<T>;
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';
}

class ResultFailure<T> extends Result<T> {
  final Failure failure;
  const ResultFailure(this.failure);

  @override
  String toString() => 'Failure($failure)';
}
