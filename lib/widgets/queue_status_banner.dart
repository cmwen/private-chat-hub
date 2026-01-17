import 'package:flutter/material.dart';

/// Banner widget to display queue status when offline or processing queued messages.
class QueueStatusBanner extends StatelessWidget {
  final int queuedCount;
  final bool isProcessing;
  final int? processingIndex;
  final int? totalProcessing;
  final VoidCallback? onRetryNow;
  final VoidCallback? onViewQueue;
  final VoidCallback? onDismiss;

  const QueueStatusBanner({
    super.key,
    required this.queuedCount,
    this.isProcessing = false,
    this.processingIndex,
    this.totalProcessing,
    this.onRetryNow,
    this.onViewQueue,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine banner content based on state
    Widget content;
    Color backgroundColor;
    Color textColor;

    if (isProcessing) {
      // Processing queue state
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;

      final progress = processingIndex != null && totalProcessing != null
          ? ' ($processingIndex of $totalProcessing)'
          : '';

      content = Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sending queued messages$progress...',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    } else if (queuedCount > 0) {
      // Offline with queued messages
      backgroundColor = colorScheme.tertiaryContainer;
      textColor = colorScheme.onTertiaryContainer;

      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                'Offline • $queuedCount ${queuedCount == 1 ? 'message' : 'messages'} queued',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Messages will send automatically when connection is restored',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          if (onRetryNow != null || onViewQueue != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRetryNow != null)
                  TextButton(
                    onPressed: onRetryNow,
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Retry Now'),
                  ),
                if (onViewQueue != null) ...[
                  if (onRetryNow != null) const SizedBox(width: 8),
                  TextButton(
                    onPressed: onViewQueue,
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('View Queue'),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    } else {
      // No queued messages - don't show banner
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: textColor.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: content),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: textColor),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Dismiss',
            ),
          ],
        ],
      ),
    );
  }
}
