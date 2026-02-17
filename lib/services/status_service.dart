import 'dart:async';

enum StatusSeverity { info, warning, error }

class StatusService {
  StatusService._private();
  static final StatusService _instance = StatusService._private();
  factory StatusService() => _instance;

  final StreamController<String> _transientController =
      StreamController<String>.broadcast();
  final StreamController<String?> _persistentController =
      StreamController<String?>.broadcast();

  Stream<String> get transientStream => _transientController.stream;
  Stream<String?> get persistentStream => _persistentController.stream;

  /// Show a one-off transient message (e.g., SnackBar).
  void showTransient(String message) {
    _transientController.add(message);
  }

  /// Set a persistent status message shown in the banner. Pass `null` to clear.
  void setPersistent(String? message) {
    _persistentController.add(message);
  }

  void dispose() {
    _transientController.close();
    _persistentController.close();
  }
}
