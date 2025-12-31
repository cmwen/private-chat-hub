import 'package:flutter/material.dart';

/// Status of the connection to Ollama.
enum ConnectionState {
  connected,
  disconnected,
  checking,
  error,
}

/// A widget that displays the current connection status.
class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionState state;
  final String? message;
  final VoidCallback? onTap;

  const ConnectionStatusIndicator({
    super.key,
    required this.state,
    this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, defaultMessage) = switch (state) {
      ConnectionState.connected => (
          Icons.cloud_done,
          Colors.green,
          'Connected',
        ),
      ConnectionState.disconnected => (
          Icons.cloud_off,
          Colors.grey,
          'Disconnected',
        ),
      ConnectionState.checking => (
          Icons.cloud_sync,
          Colors.orange,
          'Connecting...',
        ),
      ConnectionState.error => (
          Icons.error_outline,
          Colors.red,
          'Connection Error',
        ),
    };

    final displayMessage = message ?? defaultMessage;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == ConnectionState.checking)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              displayMessage,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A banner widget for showing connection issues.
class ConnectionBanner extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const ConnectionBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.orange[100],
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
              ),
              child: Text(actionLabel!),
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
