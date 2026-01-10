import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/tool_models.dart';

/// Settings widget for configuring tool calling features.
class ToolSettingsWidget extends StatefulWidget {
  final ToolConfig config;
  final ValueChanged<ToolConfig> onConfigChanged;

  const ToolSettingsWidget({
    super.key,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<ToolSettingsWidget> createState() => _ToolSettingsWidgetState();
}

class _ToolSettingsWidgetState extends State<ToolSettingsWidget> {
  late TextEditingController _apiKeyController;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: widget.config.jinaApiKey ?? '',
    );
  }

  @override
  void didUpdateWidget(ToolSettingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.jinaApiKey != oldWidget.config.jinaApiKey) {
      _apiKeyController.text = widget.config.jinaApiKey ?? '';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _updateConfig(ToolConfig Function(ToolConfig) updater) {
    widget.onConfigChanged(updater(widget.config));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.build_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Tool Calling',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // Enable tools toggle
        SwitchListTile(
          title: const Text('Enable Tool Calling'),
          subtitle: const Text('Allow AI to use tools like web search'),
          value: widget.config.enabled,
          onChanged: (value) =>
              _updateConfig((c) => c.copyWith(enabled: value)),
        ),

        if (widget.config.enabled) ...[
          const Divider(height: 1),

          // Web search toggle
          SwitchListTile(
            title: const Text('Web Search'),
            subtitle: const Text('Search the internet for current information'),
            value: widget.config.webSearchEnabled,
            onChanged: (value) =>
                _updateConfig((c) => c.copyWith(webSearchEnabled: value)),
          ),

          if (widget.config.webSearchEnabled) ...[
            // Jina API Key
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jina API Key',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get a free API key at jina.ai',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_showApiKey,
                    decoration: InputDecoration(
                      hintText: 'jina_xxxxxxxxxxxx',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showApiKey
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _showApiKey = !_showApiKey),
                            tooltip: _showApiKey
                                ? 'Hide API key'
                                : 'Show API key',
                          ),
                          IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () {
                              final key = _apiKeyController.text.trim();
                              _updateConfig(
                                (c) => c.copyWith(
                                  jinaApiKey: key.isNotEmpty ? key : null,
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('API key saved'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            tooltip: 'Save API key',
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (value) {
                      final key = value.trim();
                      _updateConfig(
                        (c) =>
                            c.copyWith(jinaApiKey: key.isNotEmpty ? key : null),
                      );
                    },
                  ),

                  // API key status
                  if (widget.config.jinaApiKey != null &&
                      widget.config.jinaApiKey!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'API key configured',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Max search results
            ListTile(
              title: const Text('Max Search Results'),
              subtitle: Slider(
                value: widget.config.maxSearchResults.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: widget.config.maxSearchResults.toString(),
                onChanged: (value) => _updateConfig(
                  (c) => c.copyWith(maxSearchResults: value.round()),
                ),
              ),
              trailing: Text(
                '${widget.config.maxSearchResults}',
                style: theme.textTheme.bodyLarge,
              ),
            ),

            // Cache results toggle
            SwitchListTile(
              title: const Text('Cache Search Results'),
              subtitle: const Text(
                'Cache results for 24 hours to save API calls',
              ),
              value: widget.config.cacheSearchResults,
              onChanged: (value) =>
                  _updateConfig((c) => c.copyWith(cacheSearchResults: value)),
            ),
          ],
        ],

        // Max Tool Calls setting
        ListTile(
          title: const Text('Max Tool Calls'),
          subtitle: Text(
            'Maximum iterations for tool calling (currently ${widget.config.maxToolCalls})',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showMaxToolCallsDialog(context),
        ),

        const Divider(height: 1),

        // TTS Speed section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.volume_up_outlined,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Text-to-Speech',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),

        // TTS Speed slider
        ListTile(
          title: const Text('Speech Speed'),
          subtitle: Text(
            '${(widget.config.ttsSpeed * 2).toStringAsFixed(1)}x '
            '(${_getTtsSpeedLabel(widget.config.ttsSpeed)})',
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Slider(
                value: widget.config.ttsSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: '${(widget.config.ttsSpeed * 2).toStringAsFixed(1)}x',
                onChanged: (value) =>
                    _updateConfig((c) => c.copyWith(ttsSpeed: value)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Slow', style: theme.textTheme.labelSmall),
                  Text('Normal', style: theme.textTheme.labelSmall),
                  Text('Fast', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),

        // Info card
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                        'About Tool Calling',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When enabled, AI models that support tool calling can '
                    'automatically search the web for current information. '
                    'This is useful for questions about recent events, facts, '
                    'or topics that may have changed since the model was trained.\n\n'
                    'Note: Not all models support tool calling. Models like '
                    'Llama 3.1+, Qwen 2.5+, and Mistral have tool support.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTtsSpeedLabel(double speed) {
    if (speed < 0.8) return 'Very Slow';
    if (speed < 1.0) return 'Slow';
    if (speed < 1.2) return 'Normal';
    if (speed < 1.5) return 'Fast';
    return 'Very Fast';
  }

  void _showMaxToolCallsDialog(BuildContext context) {
    int tempValue = widget.config.maxToolCalls;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Tool Calls'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '$tempValue',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Slider(
                value: tempValue.toDouble(),
                min: 5,
                max: 50,
                divisions: 45,
                label: '$tempValue',
                onChanged: (value) {
                  setState(() {
                    tempValue = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About max tool calls:',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Controls how many times the model can call tools in a single request. '
                        'Higher values allow more complex reasoning but may take longer. '
                        'Default is 20 (recommended).',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _updateConfig((c) => c.copyWith(maxToolCalls: tempValue));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
