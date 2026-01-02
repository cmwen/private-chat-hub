import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:private_chat_hub/models/message.dart';

/// Displays side-by-side or swipeable comparison of two model responses.
class ComparisonMessagePair extends StatefulWidget {
  final Message? model1Message;
  final Message? model2Message;
  final String model1Name;
  final String model2Name;

  const ComparisonMessagePair({
    super.key,
    this.model1Message,
    this.model2Message,
    required this.model1Name,
    required this.model2Name,
  });

  @override
  State<ComparisonMessagePair> createState() => _ComparisonMessagePairState();
}

class _ComparisonMessagePairState extends State<ComparisonMessagePair> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    if (isWideScreen) {
      // Side-by-side layout for desktop/tablet
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildModelResponse(
              context,
              widget.model1Message,
              widget.model1Name,
              'A',
              theme.colorScheme.primary,
              isWideScreen: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildModelResponse(
              context,
              widget.model2Message,
              widget.model2Name,
              'B',
              theme.colorScheme.secondary,
              isWideScreen: true,
            ),
          ),
        ],
      );
    } else {
      // Swipeable cards for mobile
      return Column(
        children: [
          SizedBox(
            height: _calculateCardHeight(context),
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildModelResponse(
                  context,
                  widget.model1Message,
                  widget.model1Name,
                  'A',
                  theme.colorScheme.primary,
                  isWideScreen: false,
                ),
                _buildModelResponse(
                  context,
                  widget.model2Message,
                  widget.model2Name,
                  'B',
                  theme.colorScheme.secondary,
                  isWideScreen: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageIndicator(0, theme),
              const SizedBox(width: 8),
              _buildPageIndicator(1, theme),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildPageIndicator(int index, ThemeData theme) {
    final isActive = _currentPage == index;
    final color = index == 0
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  double _calculateCardHeight(BuildContext context) {
    // Calculate appropriate height for swipeable cards
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.6; // 60% of screen height
    final minHeight = 200.0;

    return maxHeight.clamp(minHeight, 500.0);
  }

  Widget _buildModelResponse(
    BuildContext context,
    Message? message,
    String modelName,
    String label,
    Color accentColor, {
    required bool isWideScreen,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: isWideScreen ? 1 : 2,
      margin: isWideScreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Model header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Model $label',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        modelName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (message?.isStreaming == true)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
              ],
            ),
          ),

          // Message content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildMessageContent(context, message),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Message? message) {
    final theme = Theme.of(context);

    if (message == null) {
      return Center(
        child: Text(
          'Waiting for response...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    if (message.isError) {
      return Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.errorMessage ?? 'An error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      );
    }

    if (message.text.isEmpty && message.isStreaming) {
      return Text(
        'Generating...',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return MarkdownBody(
      data: message.text,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium,
        code: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
