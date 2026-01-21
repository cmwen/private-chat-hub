import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/ai_provider.dart';
import 'package:private_chat_hub/models/provider_models.dart';

class ProviderModelsModal extends StatelessWidget {
  final AiProviderType providerType;
  final List<ProviderModelInfo> models;
  final String? selectedModel;
  final bool isLoading;
  final VoidCallback onRefresh;
  final ValueChanged<ProviderModelInfo> onSelect;

  const ProviderModelsModal({
    super.key,
    required this.providerType,
    required this.models,
    required this.selectedModel,
    required this.isLoading,
    required this.onRefresh,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${providerType.label} Models',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (models.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No models found for ${providerType.label}.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  final isSelected = model.name == selectedModel;
                  return ListTile(
                    title: Text(model.name),
                    subtitle: Text(_buildSubtitle(model)),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => onSelect(model),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _buildSubtitle(ProviderModelInfo model) {
    final parts = <String>[];
    if (model.parameterCount != null) {
      parts.add(model.parameterCount!);
    }
    if (model.capabilities?.supportsTools == true) {
      parts.add('Tools');
    }
    if (model.capabilities?.supportsVision == true) {
      parts.add('Vision');
    }
    return parts.isEmpty ? 'Available' : parts.join(' • ');
  }
}
