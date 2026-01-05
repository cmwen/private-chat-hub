import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/tool_models.dart';

/// Badge widget to indicate a tool was used in generating a message.
class ToolBadge extends StatelessWidget {
  final ToolCall toolCall;
  final VoidCallback? onTap;

  const ToolBadge({super.key, required this.toolCall, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (icon, color, label) = _getToolDisplay();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(colorScheme),
            const SizedBox(width: 6),
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (toolCall.executionTimeMs != null) ...[
              const SizedBox(width: 6),
              Text(
                '${toolCall.executionTimeMs}ms',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    switch (toolCall.status) {
      case ToolCallStatus.pending:
      case ToolCallStatus.executing:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: colorScheme.primary,
          ),
        );
      case ToolCallStatus.success:
        return Icon(
          Icons.check_circle_outline,
          size: 12,
          color: Colors.green.shade600,
        );
      case ToolCallStatus.failed:
        return Icon(Icons.error_outline, size: 12, color: Colors.red.shade600);
    }
  }

  (IconData, Color, String) _getToolDisplay() {
    switch (toolCall.toolName) {
      case 'web_search':
        return (Icons.search, Colors.blue, 'Web Search');
      case 'get_current_datetime':
        return (Icons.access_time, Colors.orange, 'Date/Time');
      case 'read_url':
        return (Icons.link, Colors.purple, 'Read URL');
      default:
        return (Icons.extension, Colors.grey, toolCall.toolName);
    }
  }
}

/// Widget to display search results from a web search tool call.
class SearchResultsCard extends StatelessWidget {
  final SearchResults results;
  final VoidCallback? onViewMore;

  const SearchResultsCard({super.key, required this.results, this.onViewMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Search: "${results.query}"',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (results.isCached)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Cached',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Results list
          ...results.results
              .take(3)
              .map((result) => _SearchResultTile(result: result)),

          // View more button
          if (results.results.length > 3)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: onViewMore,
                child: Text('View all ${results.results.length} results'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;

  const _SearchResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        // TODO: Open URL or show full content
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              result.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // URL
            Text(
              result.url,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Snippet
            Text(
              result.snippet,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable section showing tool call details.
class ToolCallDetails extends StatefulWidget {
  final ToolCall toolCall;

  const ToolCallDetails({super.key, required this.toolCall});

  @override
  State<ToolCallDetails> createState() => _ToolCallDetailsState();
}

class _ToolCallDetailsState extends State<ToolCallDetails> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ToolBadge(toolCall: widget.toolCall),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arguments
                  _buildSection(
                    theme,
                    'Arguments',
                    widget.toolCall.arguments.toString(),
                  ),

                  if (widget.toolCall.result != null) ...[
                    const SizedBox(height: 12),
                    _buildSection(
                      theme,
                      'Result',
                      widget.toolCall.result!.summary ?? 'No summary',
                    ),
                  ],

                  if (widget.toolCall.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildSection(
                      theme,
                      'Error',
                      widget.toolCall.errorMessage!,
                      isError: true,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    String content, {
    bool isError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isError ? theme.colorScheme.error : null,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isError
                  ? theme.colorScheme.error.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: isError ? theme.colorScheme.error : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget showing model capabilities (vision, tools).
class ModelCapabilitiesChips extends StatelessWidget {
  final bool supportsVision;
  final bool supportsTools;

  const ModelCapabilitiesChips({
    super.key,
    required this.supportsVision,
    required this.supportsTools,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (supportsVision)
          _CapabilityChip(
            icon: Icons.image_outlined,
            label: 'Vision',
            color: Colors.purple,
          ),
        if (supportsTools)
          _CapabilityChip(
            icon: Icons.build_outlined,
            label: 'Tools',
            color: Colors.blue,
          ),
      ],
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _CapabilityChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
