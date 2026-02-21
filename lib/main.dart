import 'dart:async';
import 'dart:ui';
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
import 'package:private_chat_hub/services/inference_config_service.dart';
import 'package:private_chat_hub/services/jina_search_service.dart';
import 'package:private_chat_hub/services/notification_service.dart';
import 'package:private_chat_hub/services/status_service.dart';
import 'package:private_chat_hub/widgets/status_banner.dart';
import 'package:private_chat_hub/services/ollama_connection_manager.dart';
import 'package:private_chat_hub/services/on_device_llm_service.dart';
import 'package:private_chat_hub/services/project_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';
import 'package:private_chat_hub/services/tool_config_service.dart';
import 'package:private_chat_hub/services/tool_executor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _bootstrapApp() async {
  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request notification permissions for Android 13+
  await notificationService.requestPermissions();

  // Initialize shared preferences for tool config
  final prefs = await SharedPreferences.getInstance();
  final toolConfigService = ToolConfigService(prefs);

  runApp(
    MyApp(storageService: storageService, toolConfigService: toolConfigService),
  );
}

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('[FlutterError] ${details.exception}');
        debugPrint('${details.stack}');
      };

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stackTrace) {
            debugPrint('[GlobalError] Unhandled platform error: $error');
            debugPrint('$stackTrace');
            return true;
          };

      await _bootstrapApp();
    },
    (Object error, StackTrace stackTrace) {
      debugPrint('[GlobalError] Unhandled zoned error: $error');
      debugPrint('$stackTrace');
    },
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
  StreamSubscription<String>? _statusTransientSub;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // Listen for transient status messages and show as SnackBars.
    // Use the GlobalKey so we never need a Scaffold ancestor in context.
    _statusTransientSub?.cancel();
    _statusTransientSub = StatusService().transientStream.listen((msg) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(msg)),
      );
    });
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
  void dispose() {
    _statusTransientSub?.cancel();
    super.dispose();
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
      scaffoldMessengerKey: _scaffoldMessengerKey,
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
  InferenceConfigService? _inferenceConfigService;
  OnDeviceLLMService? _onDeviceLLMService;
  late final StreamSubscription<String> _statusTransientSub;

  int _currentIndex = 0;
  Conversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
    _ollamaManager = OllamaConnectionManager();
    _connectionService = ConnectionService(widget.storageService);

    // Initialize tool executor with proper config from settings
    final toolConfig = widget.toolConfigService.getConfig();
    final toolConfigMsg =
        '[HomeScreen.initState] Tool config: enabled=${toolConfig.enabled}, webSearchEnabled=${toolConfig.webSearchEnabled}, hasJinaKey=${toolConfig.jinaApiKey != null && toolConfig.jinaApiKey!.isNotEmpty}';
    print(toolConfigMsg);
    StatusService().showTransient(toolConfigMsg);

    // Initialize project service before creating tool executor
    _projectService = ProjectService(widget.storageService);

    final toolExecutor = toolConfig.enabled
        ? ToolExecutorService(
            jinaService: toolConfig.webSearchAvailable
                ? JinaSearchService(apiKey: toolConfig.jinaApiKey!)
                : null,
            config: toolConfig,
            projectService: _projectService,
          )
        : null;

    final executorMsg =
        '[HomeScreen.initState] Tool executor created: ${toolExecutor != null}';
    print(executorMsg);
    StatusService().showTransient(executorMsg);

    _chatService = ChatService(
      _ollamaManager,
      widget.storageService,
      toolExecutor: toolExecutor,
      toolConfig: toolConfig,
    );

    // Load developer mode preference and sync it to StatusService so all
    // showTransient calls are gated correctly (including service-level ones).
    _syncDeveloperMode();

    // Set up Ollama connection if one exists
    _setupConnection();

    // Initialize inference services asynchronously
    _initializeInferenceServices();

    // Check if app was opened from a notification
    _checkNotificationLaunch();
  }

  Future<void> _syncDeveloperMode() async {
    final devMode = await OllamaConfigService().getDeveloperMode();
    StatusService().developerMode = devMode;
  }

  Future<void> _initializeInferenceServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final inferenceConfigService = InferenceConfigService(prefs);

      // Always set inference config service so the toggle is visible
      if (!mounted) return;
      setState(() {
        _inferenceConfigService = inferenceConfigService;
      });

      // Update chat service with inference config service
      _chatService.setInferenceConfigService(inferenceConfigService);

      // Try to initialize on-device service separately
      try {
        final onDeviceLLMService = OnDeviceLLMService(
          widget.storageService,
          configService: inferenceConfigService,
        );

        if (!mounted) return;
        setState(() {
          _onDeviceLLMService = onDeviceLLMService;
        });

        // Update chat service with on-device service
        _chatService.setOnDeviceLLMService(onDeviceLLMService);

        final onDeviceMsg =
            '[HomeScreen._initializeInferenceServices] On-device service initialized successfully';
        print(onDeviceMsg);
        StatusService().showTransient(onDeviceMsg);
      } catch (e) {
        final warnMsg =
            '[HomeScreen._initializeInferenceServices] WARNING: Failed to initialize on-device service: $e';
        print(warnMsg);
        StatusService().showTransient(warnMsg);
        final hintMsg =
            '[HomeScreen._initializeInferenceServices] The on-device mode toggle will still be available, but on-device inference may not work.';
        print(hintMsg);
        StatusService().setPersistent(
          'On-device initialization failed — some features may be unavailable',
        );
      }
    } catch (e) {
      print(
        '[HomeScreen._initializeInferenceServices] ERROR: Failed to initialize inference services: $e',
      );
      // Still try to continue without these services
    }
  }

  Future<void> _checkNotificationLaunch() async {
    try {
      final notificationService = NotificationService();
      final conversationId = notificationService.conversationIdFromNotification;

      if (conversationId != null) {
        // Clear the notification ID
        notificationService.clearNotificationConversationId();

        // Navigate to the conversation
        final conversation = _chatService.getConversation(conversationId);
        if (conversation != null) {
          setState(() {
            _selectedConversation = conversation;
          });
          await _chatService.setCurrentConversation(conversation.id);
        }
      }
    } catch (e) {
      // Log error but don't crash the app
      // ignore: avoid_print
      debugPrint('[HomeScreen._checkNotificationLaunch] Error: $e');
    }
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
    _statusTransientSub.cancel();
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
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const StatusBanner(),
          Expanded(
            child: IndexedStack(
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
                  onDeviceLLMService: _onDeviceLLMService,
                ),
                SettingsScreen(
                  connectionService: _connectionService,
                  ollamaManager: _ollamaManager,
                  chatService: _chatService,
                  toolConfigService: widget.toolConfigService,
                  inferenceConfigService: _inferenceConfigService,
                  storageService: widget.storageService,
                  onDeviceLLMService: _onDeviceLLMService,
                  onThemeModeChanged: widget.onThemeModeChanged,
                  currentThemeMode: widget.currentThemeMode,
                ),
              ],
            ),
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
