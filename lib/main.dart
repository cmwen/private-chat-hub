import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/comparison_conversation.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/ollama_toolkit/services/ollama_config_service.dart';
import 'package:private_chat_hub/screens/chat_screen.dart';
import 'package:private_chat_hub/screens/comparison_chat_screen.dart';
import 'package:private_chat_hub/screens/conversation_list_screen.dart';
import 'package:private_chat_hub/screens/models_screen.dart';
import 'package:private_chat_hub/screens/projects_screen.dart';
import 'package:private_chat_hub/screens/settings_screen.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/jina_search_service.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/project_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:private_chat_hub/services/tool_config_service.dart';
import 'package:private_chat_hub/services/tool_executor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  // Initialize shared preferences for tool config
  final prefs = await SharedPreferences.getInstance();
  final toolConfigService = ToolConfigService(prefs);

  runApp(
    MyApp(storageService: storageService, toolConfigService: toolConfigService),
  );
}

/// The root widget of the application.
class MyApp extends StatefulWidget {
  final StorageService storageService;
  final ToolConfigService toolConfigService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.toolConfigService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = _themeModeFromString(themeModeString);
    });
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void _updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Chat Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: HomeScreen(
        storageService: widget.storageService,
        toolConfigService: widget.toolConfigService,
        onThemeModeChanged: _updateThemeMode,
        currentThemeMode: _themeMode,
      ),
    );
  }
}

/// Home screen with bottom navigation.
class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final ToolConfigService toolConfigService;
  final Function(ThemeMode) onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.toolConfigService,
    required this.onThemeModeChanged,
    required this.currentThemeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final OllamaConnectionManager _ollamaManager;
  late final ConnectionService _connectionService;
  late final ChatService _chatService;
  late final ProjectService _projectService;

  int _currentIndex = 0;
  Conversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
    _ollamaManager = OllamaConnectionManager();
    _connectionService = ConnectionService(widget.storageService);

    // Initialize tool executor with proper config from settings
    final toolConfig = widget.toolConfigService.getConfig();
    print(
      '[HomeScreen.initState] Tool config: enabled=${toolConfig.enabled}, webSearchEnabled=${toolConfig.webSearchEnabled}, hasJinaKey=${toolConfig.jinaApiKey != null && toolConfig.jinaApiKey!.isNotEmpty}',
    );

    final toolExecutor =
        toolConfig.jinaApiKey != null &&
            toolConfig.jinaApiKey!.isNotEmpty &&
            toolConfig.enabled &&
            toolConfig.webSearchEnabled
        ? ToolExecutorService(
            jinaService: JinaSearchService(apiKey: toolConfig.jinaApiKey!),
            config: toolConfig,
          )
        : null;

    print(
      '[HomeScreen.initState] Tool executor created: ${toolExecutor != null}',
    );

    _chatService = ChatService(
      _ollamaManager,
      widget.storageService,
      toolExecutor: toolExecutor,
      toolConfig: toolConfig,
    );
    _projectService = ProjectService(widget.storageService);

    // Set up Ollama connection if one exists
    _setupConnection();
  }

  void _setupConnection() {
    final connection = _connectionService.getDefaultConnection();
    if (connection != null) {
      _ollamaManager.setConnection(connection);
    }

    // Apply configured timeout
    _applyConfiguredTimeout();
  }

  Future<void> _applyConfiguredTimeout() async {
    final configService = OllamaConfigService();
    final timeout = await configService.getTimeout();
    _ollamaManager.setTimeout(Duration(seconds: timeout));
  }

  @override
  void dispose() {
    // Clean up resources
    _chatService.dispose();
    super.dispose();
  }

  void _onConversationSelected(Conversation conversation) {
    setState(() {
      _selectedConversation = conversation;
      _chatService.setCurrentConversation(conversation.id);
    });
  }

  void _onBackFromChat() {
    setState(() {
      _selectedConversation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If a conversation is selected, show the appropriate chat screen
    if (_selectedConversation != null) {
      return PopScope(
        canPop: false,
        // ignore: deprecated_member_use
        onPopInvoked: (_) {
          // User pressed back button
          _onBackFromChat();
        },
        child: _selectedConversation is ComparisonConversation
            ? ComparisonChatScreen(
                chatService: _chatService,
                conversation: _selectedConversation as ComparisonConversation,
                onBack: _onBackFromChat,
              )
            : ChatScreen(
                chatService: _chatService,
                conversation: _selectedConversation,
                onBack: _onBackFromChat,
                toolConfig: widget.toolConfigService.getConfig(),
              ),
      );
    }

    // Otherwise show the main navigation
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          ConversationListScreen(
            chatService: _chatService,
            connectionService: _connectionService,
            ollamaManager: _ollamaManager,
            onConversationSelected: _onConversationSelected,
            onNewConversation: () {},
          ),
          ProjectsScreen(
            projectService: _projectService,
            chatService: _chatService,
            connectionService: _connectionService,
            ollamaManager: _ollamaManager,
            onConversationSelected: _onConversationSelected,
          ),
          ModelsScreen(
            ollamaManager: _ollamaManager,
            connectionService: _connectionService,
          ),
          SettingsScreen(
            connectionService: _connectionService,
            ollamaManager: _ollamaManager,
            chatService: _chatService,
            toolConfigService: widget.toolConfigService,
            onThemeModeChanged: widget.onThemeModeChanged,
            currentThemeMode: widget.currentThemeMode,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Refresh connection when switching tabs
          if (index == 0 || index == 1 || index == 2) {
            _setupConnection();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Models',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
