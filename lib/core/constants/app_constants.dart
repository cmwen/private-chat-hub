class AppConstants {
  static const String appName = 'Private Chat Hub';
  static const String appVersion = '1.0.0';

  static const int defaultPort = 11434;
  static const String defaultHost = 'localhost';
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(minutes: 5);
  static const Duration healthCheckInterval = Duration(seconds: 30);

  static const int messagesPageSize = 50;
  static const int maxImageDimension = 1024;
  static const int imageQuality = 80;

  static const int streamDebounceMs = 16;

  static const String databaseName = 'private_chat_hub.db';
  static const int databaseVersion = 1;
}

class APIEndpoints {
  static const String apiVersion = '/api/version';
  static const String apiTags = '/api/tags';
  static const String apiChat = '/api/chat';
  static const String apiGenerate = '/api/generate';
  static const String apiPull = '/api/pull';
  static const String apiShow = '/api/show';
  static const String apiDelete = '/api/delete';
}

class StorageKeys {
  static const String firstLaunch = 'first_launch';
  static const String defaultModelName = 'default_model';
  static const String themeMode = 'theme_mode';
  static const String lastConnectionHost = 'last_connection_host';
  static const String lastConnectionPort = 'last_connection_port';
}
