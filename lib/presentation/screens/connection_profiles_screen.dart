import 'package:flutter/material.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/remote/ollama_api_client.dart';
import '../../domain/entities/connection.dart';
import '../../core/utils/logger.dart';

class ConnectionProfilesScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const ConnectionProfilesScreen({super.key, required this.dbHelper});

  @override
  State<ConnectionProfilesScreen> createState() =>
      _ConnectionProfilesScreenState();
}

class _ConnectionProfilesScreenState extends State<ConnectionProfilesScreen> {
  List<ConnectionProfile> _profiles = [];
  bool _loading = true;
  Map<int, bool> _healthCheckStatus = {};

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    try {
      final profiles = await widget.dbHelper.getAllConnectionProfiles();
      setState(() {
        _profiles = profiles;
        _loading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load connection profiles', e);
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _checkHealth(ConnectionProfile profile) async {
    setState(() => _healthCheckStatus[profile.id] = true);

    try {
      final client = OllamaApiClient(baseUrl: profile.baseUrl);
      final version = await client.getVersion();
      client.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Connected to Ollama $version'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Connection failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _healthCheckStatus.remove(profile.id));
      }
    }
  }

  Future<void> _showAddEditDialog([ConnectionProfile? profile]) async {
    final isEdit = profile != null;
    final nameController = TextEditingController(text: profile?.name ?? '');
    final hostController = TextEditingController(text: profile?.host ?? '');
    final portController = TextEditingController(
      text: profile?.port.toString() ?? '11434',
    );
    bool isDefault = profile?.isDefault ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Connection' : 'New Connection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'My Ollama Server',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hostController,
                  decoration: const InputDecoration(
                    labelText: 'Host',
                    hintText: 'localhost or 192.168.1.100',
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
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Set as default'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() => isDefault = value ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        final name = nameController.text.trim();
        final host = hostController.text.trim();
        final port = int.tryParse(portController.text.trim()) ?? 11434;

        if (name.isEmpty || host.isEmpty) {
          throw Exception('Name and host are required');
        }

        final newProfile = ConnectionProfile(
          id: profile?.id ?? 0,
          name: name,
          host: host,
          port: port,
          isDefault: isDefault,
          createdAt: profile?.createdAt ?? DateTime.now(),
        );

        if (isEdit) {
          await widget.dbHelper.updateConnectionProfile(newProfile);
        } else {
          await widget.dbHelper.insertConnectionProfile(newProfile);
        }

        _loadProfiles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit ? 'Profile updated' : 'Profile added'),
            ),
          );
        }
      } catch (e) {
        AppLogger.error('Failed to save connection profile', e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _deleteProfile(ConnectionProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Delete "${profile.name}"?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.dbHelper.deleteConnectionProfile(profile.id);
        _loadProfiles();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Profile deleted')));
        }
      } catch (e) {
        AppLogger.error('Failed to delete connection profile', e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _setDefault(ConnectionProfile profile) async {
    try {
      final updated = profile.copyWith(isDefault: true);
      await widget.dbHelper.updateConnectionProfile(updated);
      _loadProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default profile updated')),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to set default profile', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connection Profiles')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No connection profiles',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first Ollama server',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final profile = _profiles[index];
                final isChecking = _healthCheckStatus[profile.id] ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: profile.isDefault
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                      child: Icon(
                        profile.isDefault ? Icons.star : Icons.dns,
                        color: profile.isDefault
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(profile.name),
                    subtitle: Text('${profile.host}:${profile.port}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isChecking)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.health_and_safety),
                            tooltip: 'Check connection',
                            onPressed: () => _checkHealth(profile),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _showAddEditDialog(profile);
                                break;
                              case 'delete':
                                _deleteProfile(profile);
                                break;
                              case 'default':
                                _setDefault(profile);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            if (!profile.isDefault)
                              const PopupMenuItem(
                                value: 'default',
                                child: Text('Set as default'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
