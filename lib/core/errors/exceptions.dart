class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalError});
}

class ConnectionException extends NetworkException {
  ConnectionException(super.message, {super.code, super.originalError});
}

class OllamaAPIException extends NetworkException {
  final int? statusCode;

  OllamaAPIException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });
}

class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code, super.originalError});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalError});
}

class ModelNotFoundException extends AppException {
  final String modelName;

  ModelNotFoundException(this.modelName) : super('Model not found: $modelName');
}

class InvalidConfigurationException extends AppException {
  InvalidConfigurationException(super.message);
}
