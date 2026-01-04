import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:private_chat_hub/models/connection.dart';
import 'package:private_chat_hub/models/tool_models.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/network_discovery_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/tool_config_service.dart';
import 'package:private_chat_hub/widgets/tool_settings_widget.dart';

/// Settings screen for managing Ollama connections.
class SettingsScreen extends StatefulWidget {
  final ConnectionService connectionService;
  final OllamaConnectionManager ollamaManager;
  final ChatService? chatService;
  final ToolConfigService? toolConfigService;
  final Function(ThemeMode)? onThemeModeChanged;
  final ThemeMode? currentThemeMode;

  const SettingsScreen({
    super.key,
    required this.connectionService,
    required this.ollamaManager,
    this.chatService,
    this.toolConfigService,
    this.onThemeModeChanged,
    this.currentThemeMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Connection> _connections = [];
  bool _isLoading = false;
  ToolConfig _toolConfig = const ToolConfig();
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadConnections();
    _loadToolConfig();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  void _loadConnections() {
    setState(() {
      _connections = widget.connectionService.getConnections();
    });
  }

  void _loadToolConfig() {
    if (widget.toolConfigService != null) {
      setState(() {
        _toolConfig = widget.toolConfigService!.getConfig();
      });
    }
  }

  Future<void> _saveToolConfig(ToolConfig config) async {
    if (widget.toolConfigService != null) {
      await widget.toolConfigService!.saveConfig(config);
      setState(() {
        _toolConfig = config;
      });
    }
  }

  Future<void> _testConnection(Connection connection) async {
    setState(() => _isLoading = true);

    final success = await widget.ollamaManager.testConnection(connection);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connection successful!'
                : 'Connection failed. Check host and port.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        await widget.connectionService.updateLastConnected(connection.id);
        _loadConnections();
      }
    }
  }

  Future<void> _deleteConnection(Connection connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Connection'),
        content: Text('Are you sure you want to delete "${connection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.connectionService.deleteConnection(connection.id);
      _loadConnections();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connection deleted')));
      }
    }
  }

  Future<void> _setAsDefault(Connection connection) async {
    await widget.connectionService.setDefaultConnection(connection.id);
    _loadConnections();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${connection.name} set as default')),
      );
    }
  }

  void _showAddConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AddConnectionDialog(
        onAdd: (name, host, port, useHttps) async {
          await widget.connectionService.addConnection(
            name: name,
            host: host,
            port: port,
            useHttps: useHttps,
          );
          _loadConnections();
        },
        ollamaManager: widget.ollamaManager,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Ollama Connections',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_connections.isEmpty)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No connections configured',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add an Ollama server to get started',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddConnectionDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Connection'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._connections.map(
                    (connection) => _ConnectionCard(
                      connection: connection,
                      onTest: () => _testConnection(connection),
                      onDelete: () => _deleteConnection(connection),
                      onSetDefault: () => _setAsDefault(connection),
                    ),
                  ),
                const SizedBox(height: 16),
                if (_connections.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: OutlinedButton.icon(
                      onPressed: _showAddConnectionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Connection'),
                    ),
                  ),
                const SizedBox(height: 32),
                const Divider(),
                if (widget.chatService != null) ...[
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'AI Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.toolConfigService != null)
                    ToolSettingsWidget(
                      config: _toolConfig,
                      onConfigChanged: _saveToolConfig,
                    ),
                  const Divider(),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_getThemeModeLabel(widget.currentThemeMode ?? ThemeMode.system)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showThemeModeDialog,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: Text('Private Chat Hub v$_appVersion'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Private Chat Hub',
                      applicationVersion: _appVersion,
                      applicationLegalese: '© 2025',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'A private, secure chat application for personal '
                          'conversations with your self-hosted AI models.',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeModeDialog() {
    final currentMode = widget.currentThemeMode ?? ThemeMode.system;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: null,
              ),
              onTap: () {
                if (widget.onThemeModeChanged != null) {
                  widget.onThemeModeChanged!(ThemeMode.light);
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: null,
              ),
              onTap: () {
                if (widget.onThemeModeChanged != null) {
                  widget.onThemeModeChanged!(ThemeMode.dark);
                  Navigator.pop(context);
                }
              },
            ),
            ListTile(
              title: const Text('System Default'),
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: null,
              ),
              onTap: () {
                if (widget.onThemeModeChanged != null) {
                  widget.onThemeModeChanged!(ThemeMode.system);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final Connection connection;
  final VoidCallback onTest;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _ConnectionCard({
    required this.connection,
    required this.onTest,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: connection.isDefault
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300],
              child: Icon(
                Icons.cloud,
                color: connection.isDefault ? Colors.white : Colors.grey[600],
              ),
            ),
            title: Row(
              children: [
                Text(connection.name),
                if (connection.isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Default',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(connection.url),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'test':
                    onTest();
                    break;
                  case 'default':
                    onSetDefault();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'test',
                  child: ListTile(
                    leading: Icon(Icons.wifi_tethering),
                    title: Text('Test Connection'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (!connection.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: ListTile(
                      leading: Icon(Icons.star),
                      title: Text('Set as Default'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (connection.lastConnectedAt != null)
            Padding(
              padding: const EdgeInsets.only(left: 72, right: 16, bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Last connected: ${_formatDate(connection.lastConnectedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Dialog for adding a new Ollama connection.
class AddConnectionDialog extends StatefulWidget {
  final Future<void> Function(String name, String host, int port, bool useHttps)
  onAdd;
  final OllamaConnectionManager ollamaManager;

  const AddConnectionDialog({
    super.key,
    required this.onAdd,
    required this.ollamaManager,  });

  @override
  State<AddConnectionDialog> createState() => _AddConnectionDialogState();}

class _AddConnectionDialogState extends State<AddConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Home Server');
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '11434');
  bool _useHttps = false;
  bool _isTesting = false;
  bool? _testResult;
  bool _isDiscovering = false;
  List<DiscoveredOllama> _discoveredInstances = [];

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _autoDiscover() async {
    setState(() {
      _isDiscovering = true;
      _discoveredInstances = [];
    });

    final discoveryService = NetworkDiscoveryService();

    try {
      await for (final instance in discoveryService.scanNetwork()) {
        if (!mounted) break;
        setState(() {
          _discoveredInstances.add(instance);
        });
      }
    } finally {
      discoveryService.dispose();
      if (mounted) {
        setState(() => _isDiscovering = false);
      }
    }
  }

  void _selectDiscoveredInstance(DiscoveredOllama instance) {
    setState(() {
      _hostController.text = instance.host;
      _portController.text = instance.port.toString();
      if (instance.name != null) {
        _nameController.text = instance.name!;
      }
    });
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final connection = Connection(
      id: 'temp',
      name: 'temp',
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 11434,
      useHttps: _useHttps,
      createdAt: DateTime.now(),
    );

    final success = await widget.ollamaManager.testConnection(connection);

    setState(() {
      _isTesting = false;
      _testResult = success;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.onAdd(
      _nameController.text.trim(),
      _hostController.text.trim(),
      int.tryParse(_portController.text) ?? 11434,
      _useHttps,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ollama Connection'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Auto-discover section
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.wifi_find, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Auto-Discover',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          if (_isDiscovering)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            TextButton(
                              onPressed: _autoDiscover,
                              child: const Text('Scan'),
                            ),
                        ],
                      ),
                      if (_discoveredInstances.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Found:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        ...(_discoveredInstances.map(
                          (instance) => InkWell(
                            onTap: () => _selectDiscoveredInstance(instance),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.cloud, size: 16),
                                  const SizedBox(width: 8),
                                  Text(instance.displayName),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${instance.address})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                      ] else if (_isDiscovering)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Scanning local network...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Connection Name',
                  hintText: 'e.g., Home Server, Office',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'Host / IP Address',
                  hintText: 'e.g., 192.168.1.100 or localhost',
                  prefixIcon: Icon(Icons.dns),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a host';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '11434',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a port';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port < 1 || port > 65535) {
                    return 'Invalid port (1-65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Use HTTPS'),
                subtitle: const Text('Enable for secure connections'),
                value: _useHttps,
                onChanged: (value) => setState(() => _useHttps = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('Test'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_testResult != null)
                    Icon(
                      _testResult! ? Icons.check_circle : Icons.error,
                      color: _testResult! ? Colors.green : Colors.red,
                    ),
                ],
              ),
              if (_testResult == false)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Connection failed. Check host and port.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
