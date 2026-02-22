import 'package:flutter/material.dart';
import 'package:private_chat_hub/ollama_toolkit/models/ollama_model.dart';

/// Displays model capability badges with icons.
class CapabilityBadges extends StatelessWidget {
  final ModelCapabilities capabilities;
  final VoidCallback? onInfoTap;

  const CapabilityBadges({
    super.key,
    required this.capabilities,
    this.onInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (capabilities.supportsToolCalling)
          _CapabilityChip(
            icon: Icons.build_circle,
            label: 'Tools',
            color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
          ),
        if (capabilities.supportsVision)
          _CapabilityChip(
            icon: Icons.visibility,
            label: 'Vision',
            color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
          ),
        if (capabilities.supportsAudio)
          _CapabilityChip(
            icon: Icons.mic,
            label: 'Audio',
            color: isDark ? Colors.teal.shade200 : Colors.teal.shade700,
          ),
        if (capabilities.contextWindow >= 100000)
          _CapabilityChip(
            icon: Icons.data_object,
            label: '${(capabilities.contextWindow / 1000).round()}K',
            color: isDark ? Colors.orange.shade200 : Colors.orange.shade700,
          ),
        if (onInfoTap != null)
          InkWell(
            onTap: onInfoTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}

/// Individual capability chip with icon and label.
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating action button for toggling tool calling.
class ToolToggleFAB extends StatelessWidget {
  final bool toolsEnabled;
  final bool modelSupportsTools;
  final ValueChanged<bool> onToggle;

  const ToolToggleFAB({
    super.key,
    required this.toolsEnabled,
    required this.modelSupportsTools,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Tool calling toggle',
      hint: modelSupportsTools
          ? (toolsEnabled
                ? 'Double tap to disable tool calling'
                : 'Double tap to enable tool calling')
          : 'Model does not support tool calling',
      enabled: modelSupportsTools,
      child: FloatingActionButton(
        onPressed: modelSupportsTools ? () => onToggle(!toolsEnabled) : null,
        backgroundColor: modelSupportsTools
            ? (toolsEnabled
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        foregroundColor: modelSupportsTools
            ? (toolsEnabled
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant)
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        disabledElevation: 0,
        elevation: modelSupportsTools ? 4 : 0,
        tooltip: modelSupportsTools
            ? (toolsEnabled ? 'Disable tool calling' : 'Enable tool calling')
            : 'Model doesn\'t support tools',
        child: Icon(
          toolsEnabled ? Icons.build_circle : Icons.build_circle_outlined,
          size: 28,
        ),
      ),
    );
  }
}

/// Bottom sheet showing detailed model capabilities.
class CapabilityInfoPanel extends StatelessWidget {
  final String modelName;
  final ModelCapabilities capabilities;
  final bool toolCallingEnabled;
  final ValueChanged<bool>? onToggleToolCalling;
  final VoidCallback? onConfigureTools;

  const CapabilityInfoPanel({
    super.key,
    required this.modelName,
    required this.capabilities,
    required this.toolCallingEnabled,
    this.onToggleToolCalling,
    this.onConfigureTools,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Model Capabilities',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          modelName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Model info
                  if (capabilities.modelFamily != null)
                    _InfoRow(
                      icon: Icons.family_restroom,
                      label: 'Family',
                      value: capabilities.modelFamily!,
                    ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.memory,
                    label: 'Context',
                    value:
                        '${(capabilities.contextWindow / 1000).round()}K tokens',
                  ),
                  const SizedBox(height: 24),
                  // Tool calling
                  _CapabilityCard(
                    icon: Icons.build_circle,
                    title: 'Tool Calling',
                    description: capabilities.supportsToolCalling
                        ? 'Let the AI use external tools like web search to get current information and facts.'
                        : 'This model does not support tool calling. Try models like Llama 3.1+, Qwen 2.5+, or Mistral.',
                    supported: capabilities.supportsToolCalling,
                    enabled: toolCallingEnabled,
                    onToggle: capabilities.supportsToolCalling
                        ? onToggleToolCalling
                        : null,
                    onConfigure: capabilities.supportsToolCalling
                        ? onConfigureTools
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Vision
                  _CapabilityCard(
                    icon: Icons.visibility,
                    title: 'Vision Support',
                    description: capabilities.supportsVision
                        ? 'Analyze images and understand visual content. Attach images to your messages.'
                        : 'This model cannot process images. Try vision models like Llama 3.2 Vision, LLaVA, or Gemma 3.',
                    supported: capabilities.supportsVision,
                  ),
                  const SizedBox(height: 16),
                  _CapabilityCard(
                    icon: Icons.mic,
                    title: 'Audio Support',
                    description: capabilities.supportsAudio
                        ? 'Accept audio inputs for multimodal interactions.'
                        : 'This model cannot process audio inputs.',
                    supported: capabilities.supportsAudio,
                  ),
                  if (capabilities.description != null &&
                      capabilities.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About this model',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            capabilities.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool supported;
  final bool? enabled;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onConfigure;

  const _CapabilityCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.supported,
    this.enabled,
    this.onToggle,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: supported
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: supported
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: supported
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: supported ? colorScheme.primary : colorScheme.outline,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (supported)
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20)
              else
                Icon(Icons.cancel, color: colorScheme.outline, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (enabled != null && onToggle != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Status: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  enabled! ? 'Enabled' : 'Disabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: enabled!
                        ? Colors.green.shade700
                        : colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (onConfigure != null)
                  TextButton.icon(
                    onPressed: onConfigure,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Configure'),
                  ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () => onToggle!(!enabled!),
                  child: Text(enabled! ? 'Disable' : 'Enable'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Shows the capability info panel as a modal bottom sheet.
void showCapabilityInfo(
  BuildContext context, {
  required String modelName,
  required ModelCapabilities capabilities,
  required bool toolCallingEnabled,
  ValueChanged<bool>? onToggleToolCalling,
  VoidCallback? onConfigureTools,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CapabilityInfoPanel(
      modelName: modelName,
      capabilities: capabilities,
      toolCallingEnabled: toolCallingEnabled,
      onToggleToolCalling: onToggleToolCalling,
      onConfigureTools: onConfigureTools,
    ),
  );
}
