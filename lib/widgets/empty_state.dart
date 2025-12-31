import 'package:flutter/material.dart';

/// A widget for showing empty states with illustrations.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Empty state for no conversations.
  factory EmptyState.noConversations({VoidCallback? onNewChat}) {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'No Conversations Yet',
      subtitle: 'Start chatting with your AI assistant',
      actionLabel: 'New Chat',
      onAction: onNewChat,
    );
  }

  /// Empty state for no connection configured.
  factory EmptyState.noConnection({VoidCallback? onSetup}) {
    return EmptyState(
      icon: Icons.cloud_off,
      title: 'No Connection',
      subtitle: 'Connect to your Ollama instance to get started',
      actionLabel: 'Set Up Connection',
      onAction: onSetup,
    );
  }

  /// Empty state for no models available.
  factory EmptyState.noModels({VoidCallback? onDownload}) {
    return EmptyState(
      icon: Icons.psychology_outlined,
      title: 'No Models',
      subtitle: 'Download a model to start chatting',
      actionLabel: 'Browse Models',
      onAction: onDownload,
    );
  }

  /// Empty state for connection error.
  factory EmptyState.connectionError({
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Connection Failed',
      subtitle: errorMessage ?? 'Could not connect to Ollama',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A widget for loading states.
class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
