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
}
