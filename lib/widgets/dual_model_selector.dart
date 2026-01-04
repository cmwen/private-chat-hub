import 'package:flutter/material.dart';
import 'package:private_chat_hub/ollama_toolkit/ollama_toolkit.dart';

/// Widget for selecting two models for comparison.
class DualModelSelector extends StatefulWidget {
  final List<OllamaModelInfo> models;
  final String? initialModel1;
  final String? initialModel2;
  final Function(String model1, String model2) onModelsSelected;

  const DualModelSelector({
    super.key,
    required this.models,
    this.initialModel1,
    this.initialModel2,
    required this.onModelsSelected,
  });

  @override
  State<DualModelSelector> createState() => _DualModelSelectorState();
}

class _DualModelSelectorState extends State<DualModelSelector> {
  String? _selectedModel1;
  String? _selectedModel2;

  @override
  void initState() {
    super.initState();
    _selectedModel1 = widget.initialModel1;
    _selectedModel2 = widget.initialModel2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canConfirm =
        _selectedModel1 != null &&
        _selectedModel2 != null &&
        _selectedModel1 != _selectedModel2;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Compare Models',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select two models to compare their responses side-by-side',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),

            // Model 1 Selector
            Text(
              'Model A',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildModelDropdown(
              value: _selectedModel1,
              onChanged: (value) => setState(() => _selectedModel1 = value),
              hint: 'Select first model',
              disabledValue: _selectedModel2,
            ),

            const SizedBox(height: 20),

            // Model 2 Selector
            Text(
              'Model B',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildModelDropdown(
              value: _selectedModel2,
              onChanged: (value) => setState(() => _selectedModel2 = value),
              hint: 'Select second model',
              disabledValue: _selectedModel1,
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: canConfirm
                      ? () {
                          widget.onModelsSelected(
                            _selectedModel1!,
                            _selectedModel2!,
                          );
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: const Text('Compare'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    String? disabledValue,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: widget.models.map((model) {
            final isDisabled =
                disabledValue != null && model.name == disabledValue;
            return DropdownMenuItem<String>(
              value: model.name,
              enabled: !isDisabled,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          model.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDisabled
                                ? theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  )
                                : null,
                          ),
                        ),
                        Text(
                          '${model.family} • ${model.sizeFormatted}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: isDisabled ? 0.2 : 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDisabled)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
