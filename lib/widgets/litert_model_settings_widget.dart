import 'package:flutter/material.dart';
import 'package:private_chat_hub/services/inference_config_service.dart';

/// Settings widget for configuring LiteRT model parameters.
///
/// Provides UI to adjust:
/// - Temperature: Controls randomness (0.0-2.0)
/// - Top-K: Token selection limit (0-1000)
/// - Top-P: Nucleus sampling (0.0-1.0)
/// - Max Tokens: Response length (1-4096)
/// - Repetition Penalty: Reduce repetition (0.5-2.0)
class LiteRTModelSettingsWidget extends StatefulWidget {
  final InferenceConfigService configService;
  final dynamic onDeviceLLMService; // OnDeviceLLMService
  final ValueChanged<void>? onSettingsChanged;

  const LiteRTModelSettingsWidget({
    super.key,
    required this.configService,
    this.onDeviceLLMService,
    this.onSettingsChanged,
  });

  @override
  State<LiteRTModelSettingsWidget> createState() =>
      _LiteRTModelSettingsWidgetState();
}

class _LiteRTModelSettingsWidgetState extends State<LiteRTModelSettingsWidget> {
  late double _temperature;
  late int _topK;
  late double _topP;
  late int _maxTokens;
  late double _repetitionPenalty;
  bool _isExpanded = false;
  late TextEditingController _tokenController;
  bool _tokenObscured = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.configService.huggingFaceToken ?? '',
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _temperature = widget.configService.temperature;
      _topK = widget.configService.topK;
      _topP = widget.configService.topP;
      _maxTokens = widget.configService.maxTokens;
      _repetitionPenalty = widget.configService.repetitionPenalty;
    });
  }

  Future<void> _saveSettings() async {
    try {
      await Future.wait([
        widget.configService.setTemperature(_temperature),
        widget.configService.setTopK(_topK),
        widget.configService.setTopP(_topP),
        widget.configService.setMaxTokens(_maxTokens),
        widget.configService.setRepetitionPenalty(_repetitionPenalty),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model parameters saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      widget.onSettingsChanged?.call(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToken() async {
    try {
      final token = _tokenController.text.trim();
      await widget.configService.setHuggingFaceToken(
        token.isEmpty ? null : token,
      );

      // Update the token in the service immediately
      if (widget.onDeviceLLMService != null) {
        widget.onDeviceLLMService.updateHuggingFaceToken(
          token.isEmpty ? null : token,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              token.isEmpty
                  ? 'Hugging Face token removed'
                  : 'Hugging Face token saved',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Model Parameters'),
        content: const Text('Reset all parameters to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.configService.resetModelParameters();
      _loadSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parameters reset to defaults'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
              Icon(Icons.tune_outlined, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Model Parameters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LiteRT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Hugging Face Token Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.key, size: 16, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Hugging Face API Token',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Required for downloading models. Get a free token at huggingface.co/settings/tokens',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    obscureText: _tokenObscured,
                    decoration: InputDecoration(
                      hintText: 'hf_...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _tokenObscured
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _tokenObscured = !_tokenObscured;
                              });
                            },
                          ),
                          if (_tokenController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: _saveToken,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Current settings summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Settings',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 20,
                        ),
                      ],
                    ),
                    if (_isExpanded) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.configService.modelParametersDescription,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        const Divider(height: 1),

        // Temperature slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temperature',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Control randomness (lower = deterministic, higher = creative)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _temperature.toStringAsFixed(2),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _temperature,
                min: 0.0,
                max: 2.0,
                divisions: 40,
                label: _temperature.toStringAsFixed(2),
                onChanged: (value) => setState(() => _temperature = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deterministic',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Creative',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Top-K slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top-K',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Only consider top K tokens',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_topK',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _topK.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: '$_topK',
                onChanged: (value) => setState(() => _topK = value.toInt()),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Top-P slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top-P (Nucleus Sampling)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Cumulative probability threshold',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _topP.toStringAsFixed(2),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _topP,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: _topP.toStringAsFixed(2),
                onChanged: (value) => setState(() => _topP = value),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Max Tokens slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Tokens',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Maximum response length',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_maxTokens',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _maxTokens.toDouble(),
                min: 1,
                max: 2048,
                divisions: 100,
                label: '$_maxTokens',
                onChanged: (value) => setState(() => _maxTokens = value.toInt()),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Repetition Penalty slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repetition Penalty',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Reduce repeated text (> 1.0 penalizes)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _repetitionPenalty.toStringAsFixed(2),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Slider(
                value: _repetitionPenalty,
                min: 0.5,
                max: 2.0,
                divisions: 30,
                label: _repetitionPenalty.toStringAsFixed(2),
                onChanged: (value) =>
                    setState(() => _repetitionPenalty = value),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Less penalty',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'More penalty',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About These Settings',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These parameters control how the on-device model generates text. '
                    'Lower temperature produces more predictable responses, '
                    'while higher values make it more creative. '
                    'Adjust based on your use case.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
