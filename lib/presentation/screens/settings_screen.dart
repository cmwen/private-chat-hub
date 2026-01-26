import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsRepository settingsRepo;
  final DatabaseHelper dbHelper;

  const SettingsScreen({
    super.key,
    required this.settingsRepo,
    required this.dbHelper,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _defaultModel;
  String? _defaultHost;
  int? _defaultPort;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final model = await widget.settingsRepo.getDefaultModel();
      final host = await widget.settingsRepo.getLastConnectionHost();
      final port = await widget.settingsRepo.getLastConnectionPort();

      setState(() {
        _defaultModel = model;
        _defaultHost = host;
        _defaultPort = port;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSection('General'),
                ListTile(
                  leading: const Icon(Icons.model_training),
                  title: const Text('Default Model'),
                  subtitle: Text(_defaultModel ?? 'Not set'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showDefaultModelDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.dns),
                  title: const Text('Default Connection'),
                  subtitle: Text(
                    _defaultHost != null
                        ? '$_defaultHost:${_defaultPort ?? 11434}'
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showDefaultConnectionDialog,
                ),
                const Divider(),
                _buildSection('Appearance'),
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  subtitle: const Text('System default'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Theme selection coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(),
                _buildSection('About'),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('App Version'),
                  subtitle: const Text(AppConstants.appVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('App Name'),
                  subtitle: Text(AppConstants.appName),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.tonal(
                    onPressed: _showClearDataDialog,
                    child: const Text('Clear All Data'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showDefaultModelDialog() async {
    final controller = TextEditingController(text: _defaultModel ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Model'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Model Name',
            hintText: 'llama3.2',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final model = controller.text.trim();
      if (model.isNotEmpty) {
        await widget.settingsRepo.setDefaultModel(model);
        setState(() => _defaultModel = model);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Default model updated')),
          );
        }
      }
    }
  }

  Future<void> _showDefaultConnectionDialog() async {
    final hostController = TextEditingController(text: _defaultHost ?? '');
    final portController = TextEditingController(
      text: _defaultPort?.toString() ?? '11434',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                hintText: 'localhost',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '11434',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final host = hostController.text.trim();
      final port = int.tryParse(portController.text.trim()) ?? 11434;

      if (host.isNotEmpty) {
        await widget.settingsRepo.setLastConnectionHost(host);
        await widget.settingsRepo.setLastConnectionPort(port);
        setState(() {
          _defaultHost = host;
          _defaultPort = port;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Default connection updated')),
          );
        }
      }
    }
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all conversations, messages, and reset settings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Clearing all data...'),
              ],
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }

      try {
        // Clear database first
        await widget.dbHelper.clearAllData();

        // Then clear settings
        await widget.settingsRepo.clearAll();

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'All data cleared successfully. Please restart the app.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
