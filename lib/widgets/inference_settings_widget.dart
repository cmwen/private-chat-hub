import 'package:flutter/material.dart';
import 'package:private_chat_hub/services/llm_service.dart';
import 'package:private_chat_hub/services/model_download_service.dart';

/// Widget for selecting inference mode (Remote vs On-Device)
class InferenceModeSelector extends StatelessWidget {
  final InferenceMode currentMode;
  final ValueChanged<InferenceMode> onModeChanged;
  final bool enabled;

  const InferenceModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Inference Mode',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        _buildModeCard(
          context,
          mode: InferenceMode.remote,
          icon: Icons.cloud_outlined,
          selectedIcon: Icons.cloud,
          title: 'Remote (Ollama)',
          subtitle: 'Run models on your Ollama server',
          features: ['30+ models', 'Larger models (70B+)', 'Server-managed'],
          isSelected: currentMode == InferenceMode.remote,
        ),
        const SizedBox(height: 8),
        _buildModeCard(
          context,
          mode: InferenceMode.onDevice,
          icon: Icons.phone_android_outlined,
          selectedIcon: Icons.phone_android,
          title: 'On-Device (LiteRT)',
          subtitle: 'Run models directly on your device',
          features: ['Fully private', 'Works offline', 'No server needed'],
          isSelected: currentMode == InferenceMode.onDevice,
          badge: 'Preview',
        ),
      ],
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required InferenceMode mode,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String subtitle,
    required List<String> features,
    required bool isSelected,
    String? badge,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? () => onModeChanged(mode) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: features.map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary)
              else
                Icon(Icons.circle_outlined, color: colorScheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for backend selection (CPU/GPU/NPU)
class BackendSelector extends StatelessWidget {
  final String currentBackend;
  final ValueChanged<String> onBackendChanged;
  final Map<String, bool> capabilities;
  final bool enabled;

  const BackendSelector({
    super.key,
    required this.currentBackend,
    required this.onBackendChanged,
    required this.capabilities,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Inference Backend',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'cpu',
                label: const Text('CPU'),
                icon: const Icon(Icons.memory),
                enabled: capabilities['cpu'] ?? true,
              ),
              ButtonSegment(
                value: 'gpu',
                label: const Text('GPU'),
                icon: const Icon(Icons.speed),
                enabled: capabilities['gpu'] ?? false,
              ),
              ButtonSegment(
                value: 'npu',
                label: const Text('NPU'),
                icon: const Icon(Icons.developer_board),
                enabled: capabilities['npu'] ?? false,
              ),
            ],
            selected: {currentBackend},
            onSelectionChanged: enabled
                ? (selected) => onBackendChanged(selected.first)
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _getBackendDescription(currentBackend),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  String _getBackendDescription(String backend) {
    switch (backend) {
      case 'cpu':
        return 'Universal compatibility. Works on all devices but slower.';
      case 'gpu':
        return 'Faster inference using GPU acceleration. Recommended for most devices.';
      case 'npu':
        return 'Uses Neural Processing Unit for optimal efficiency. Limited device support.';
      default:
        return '';
    }
  }
}

/// Widget showing a downloadable model with progress
class ModelDownloadTile extends StatelessWidget {
  final ModelInfo model;
  final ModelDownloadProgress? downloadProgress;
  final VoidCallback? onDownload;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;
  final bool isSelected;

  const ModelDownloadTile({
    super.key,
    required this.model,
    this.downloadProgress,
    this.onDownload,
    this.onCancel,
    this.onDelete,
    this.onSelect,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDownloading =
        downloadProgress?.status == DownloadStatus.downloading;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: model.isDownloaded ? onSelect : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              model.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    model.sizeString,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Capabilities row
              Wrap(
                spacing: 4,
                children: model.capabilities.map((cap) {
                  IconData icon;
                  switch (cap) {
                    case 'vision':
                      icon = Icons.image;
                      break;
                    case 'audio':
                      icon = Icons.mic;
                      break;
                    case 'tools':
                      icon = Icons.build;
                      break;
                    default:
                      icon = Icons.text_fields;
                  }
                  return Chip(
                    avatar: Icon(icon, size: 16),
                    label: Text(cap),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Download progress or action button
              if (isDownloading && downloadProgress != null) ...[
                LinearProgressIndicator(value: downloadProgress!.progress),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      downloadProgress!.progressString,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      downloadProgress!.percentString,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Cancel'),
                    ),
                  ],
                ),
              ] else if (model.isDownloaded) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Downloaded',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget showing memory and storage info
class DeviceResourceInfo extends StatelessWidget {
  final Map<String, int> memoryInfo;
  final int storageUsed;

  const DeviceResourceInfo({
    super.key,
    required this.memoryInfo,
    required this.storageUsed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableMemory = memoryInfo['availableMemory'] ?? 0;
    final totalMemory = memoryInfo['totalMemory'] ?? 1;
    final memoryUsedPercent = 1 - (availableMemory / totalMemory);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Resources',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildResourceBar(
              context,
              label: 'Memory',
              used: _formatBytes(totalMemory - availableMemory),
              total: _formatBytes(totalMemory),
              percent: memoryUsedPercent,
              color: memoryUsedPercent > 0.8
                  ? colorScheme.error
                  : colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.storage,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Models: ${_formatBytes(storageUsed)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceBar(
    BuildContext context, {
    required String label,
    required String used,
    required String total,
    required double percent,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              '$used / $total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent.clamp(0, 1),
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
