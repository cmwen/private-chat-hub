import 'package:flutter/material.dart';
import 'package:private_chat_hub/models/comparison_conversation.dart';
import 'package:private_chat_hub/models/conversation.dart';
import 'package:private_chat_hub/screens/chat_screen.dart';
import 'package:private_chat_hub/screens/comparison_chat_screen.dart';
import 'package:private_chat_hub/screens/conversation_list_screen.dart';
import 'package:private_chat_hub/screens/models_screen.dart';
import 'package:private_chat_hub/screens/projects_screen.dart';
import 'package:private_chat_hub/screens/settings_screen.dart';
import 'package:private_chat_hub/services/chat_service.dart';
import 'package:private_chat_hub/services/connection_service.dart';
import 'package:private_chat_hub/services/ollama_service.dart';
import 'package:private_chat_hub/services/project_service.dart';
import 'package:private_chat_hub/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  runApp(MyApp(storageService: storageService));
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  final StorageService storageService;

  const MyApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Chat Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: HomeScreen(storageService: storageService),
    );
  }
}

/// Home screen with bottom navigation.
class HomeScreen extends StatefulWidget {
  final StorageService storageService;

  const HomeScreen({super.key, required this.storageService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final OllamaService _ollamaService;
  late final ConnectionService _connectionService;
  late final ChatService _chatService;
  late final ProjectService _projectService;

  int _currentIndex = 0;
  Conversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
    _ollamaService = OllamaService();
    _connectionService = ConnectionService(widget.storageService);
    _chatService = ChatService(_ollamaService, widget.storageService);
    _projectService = ProjectService(widget.storageService);

    // Set up Ollama connection if one exists
    _setupConnection();
  }

  void _setupConnection() {
    final connection = _connectionService.getDefaultConnection();
    if (connection != null) {
      _ollamaService.setConnection(
        OllamaConnection(
          host: connection.host,
          port: connection.port,
          useHttps: connection.useHttps,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ollamaService.dispose();
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
            ollamaService: _ollamaService,
            onConversationSelected: _onConversationSelected,
            onNewConversation: () {},
          ),
          ProjectsScreen(
            projectService: _projectService,
            chatService: _chatService,
            connectionService: _connectionService,
            ollamaService: _ollamaService,
            onConversationSelected: _onConversationSelected,
          ),
          ModelsScreen(
            ollamaService: _ollamaService,
            connectionService: _connectionService,
          ),
          SettingsScreen(
            connectionService: _connectionService,
            ollamaService: _ollamaService,
            chatService: _chatService,
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
