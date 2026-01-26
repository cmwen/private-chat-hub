# Private Chat Hub

**A feature-rich Android chat client for AI models** - Connect to Ollama, manage conversations, search chat history, and more.

[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## ✨ Features

### 🤖 Core Chat Functionality
- **Real-time Streaming**: See AI responses as they're generated
- **Multiple Conversations**: Organize chats by topic or project
- **System Prompts**: Customize AI behavior per conversation
- **Cancel/Retry**: Stop streaming responses or retry failed messages
- **Offline-First**: All data stored locally in SQLite with FTS5 search

### 🔌 Ollama Integration
- **Connection Profiles**: Save multiple Ollama server configurations
- **Health Checks**: Test connection before chatting
- **Model Management**: Pull, list, and delete models directly from the app
- **Real-time Progress**: Track model downloads with progress bars

### 🔍 Advanced Features
- **Full-Text Search**: Find messages across all conversations (FTS5)
- **Export Conversations**: Save chats as JSON, Markdown, or Plain Text
- **Archive/Delete**: Organize conversations with swipe gestures
- **Settings Persistence**: Configure defaults for model and connection

### 🎨 Modern UI
- **Material Design 3**: Beautiful, accessible interface
- **Light/Dark Theme**: Automatically follows system theme
- **Smooth Animations**: Polished interactions and transitions
- **Empty States**: Helpful guidance when getting started

---

## 📱 Screenshots

*Coming soon*

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.10.1+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: 3.10.0+
- **Ollama Server**: Running locally or on your network ([Install Ollama](https://ollama.ai))
- **Android Device/Emulator**: API level 21+ (Android 5.0+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/private-chat-hub.git
   cd private-chat-hub
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (if needed)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### First-Time Setup

1. **Launch the app** - You'll see the empty conversations screen

2. **Create a connection profile**
   - Tap the **DNS icon** (network settings) in the top-right
   - Tap the **+ button** to add a new profile
   - Enter your Ollama server details:
     - **Name**: e.g., "Local Ollama"
     - **Host**: `http://192.168.1.100` (your Ollama server IP)
     - **Port**: `11434` (default Ollama port)
   - Tap **Test Connection** to verify
   - Tap the **star icon** to set as default
   - Tap **Save**

3. **Pull a model**
   - Tap the **Layers icon** (models) in the top-right
   - Tap the **download icon** in the bottom-right
   - Enter a model name (e.g., `llama3.2`, `mistral`, `phi3`)
   - Watch the download progress
   - Wait for completion

4. **Start chatting**
   - Tap the **+ button** to create a new conversation
   - Enter a title (e.g., "General Chat")
   - Optionally add a system prompt (e.g., "You are a helpful assistant")
   - Tap **Create**
   - Send your first message!

---

## 📖 User Guide

### Managing Conversations

**Create a new conversation:**
- Tap the **+ button** on the conversations screen
- Enter a title and optional system prompt
- Tap **Create**

**Archive a conversation:**
- Swipe **left** on a conversation
- Tap **Undo** in the SnackBar to restore

**Delete a conversation:**
- Swipe **right** on a conversation
- Confirm in the dialog

**Edit system prompt:**
- Open a conversation
- Tap the **3-dot menu** → **System Prompt**
- Edit or clear the prompt
- Tap **Save**

**Export a conversation:**
- Open a conversation
- Tap the **3-dot menu** → **Export Conversation**
- Select format (JSON, Markdown, or Plain Text)
- Preview and copy the exported content

### Searching Messages

1. On the conversations screen, tap the **search icon** (magnifying glass)
2. Enter your search query
3. Press **Enter** or tap the search button
4. Browse results with context and timestamps
5. Tap a result to navigate to that conversation

### Managing Models

**List installed models:**
- Tap the **Layers icon** in the top-right
- View model size, parameter count, and last modified date

**Pull/download a model:**
- Tap the **download icon** in the bottom-right
- Enter the model name (e.g., `llama3.2:latest`)
- Watch real-time progress
- Wait for completion

**Delete a model:**
- Tap the **trash icon** next to a model
- Confirm in the dialog

**Refresh model list:**
- Tap the **refresh icon** in the top-right

### Connection Settings

**During a chat:**
- Tap the **3-dot menu** → **Connection Settings**
- Select a saved profile from the dropdown
- Or enter custom host and model
- Tap **Save**

**Manage profiles:**
- Tap the **DNS icon** on the conversations screen
- Create, edit, or delete profiles
- Test connections with the **test button**
- Star a profile to set it as default

### App Settings

- Tap the **Settings icon** (gear) on the conversations screen
- **Default Model**: Set the model used for new conversations
- **Default Connection**: Set the host and port for Ollama
- **Clear All Data**: Reset the app (deletes all conversations, messages, and settings)

---

## 🏗️ Architecture

Private Chat Hub follows **Clean Architecture** principles:

```
lib/
├── core/               # Constants, errors, utils, extensions
├── domain/             # Entities (Freezed) and repository interfaces
├── data/               # Database, API client, repositories
└── presentation/       # Screens and UI components
```

### Key Technologies

- **State Management**: StatefulWidget with setState() (Riverpod ready for v2.0)
- **Database**: SQLite with FTS5 full-text search
- **HTTP Client**: Dio for Ollama API
- **Serialization**: Freezed + json_serializable
- **Local Storage**: SharedPreferences for settings

### Database Schema

- `conversations` - Chat sessions with title, timestamps, model, system prompt
- `messages` - Individual messages with role, content, timestamps
- `messages_fts` - FTS5 virtual table for full-text search
- `connection_profiles` - Saved Ollama server configurations
- `cached_models` - Model metadata cache

---

## 🛠️ Development

### Project Structure

```
private-chat-hub/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── utils/
│   │   └── extensions/
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── local/
│   │   │   └── remote/
│   │   └── repositories/
│   ├── presentation/
│   │   └── screens/
│   └── main.dart
├── test/
├── android/
├── docs/                 # Product vision, requirements, architecture
└── pubspec.yaml
```

### Commands

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Run tests
flutter test

# Build release APK
flutter build apk --release

# Build app bundle
flutter build appbundle --release

# Generate code (after entity changes)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
dart run build_runner watch
```

### Running Ollama

**On your local machine:**
```bash
ollama serve
```

**On a remote server:**
```bash
# Make sure to bind to 0.0.0.0 to accept external connections
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

**Pull a model:**
```bash
ollama pull llama3.2
ollama pull mistral
ollama pull phi3
```

**List models:**
```bash
ollama list
```

---

## 🧪 Testing

### Current Status

- ✅ **flutter analyze**: 0 errors, 1 harmless warning
- ✅ **Compilation**: Clean builds
- ⚠️ **Widget tests**: Basic test exists (SQLite initialization issue in test environment)

### Future Testing

- [ ] Unit tests for repositories
- [ ] Unit tests for API client
- [ ] Unit tests for database helper
- [ ] Widget tests for screens
- [ ] Integration tests for complete flows

---

## 📚 Documentation

- **[PRODUCT_VISION.md](docs/PRODUCT_VISION.md)** - Product strategy and roadmap (v1.0, v1.5, v2.0)
- **[PRODUCT_REQUIREMENTS.md](docs/PRODUCT_REQUIREMENTS.md)** - Detailed feature requirements
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - MVP implementation details
- **[V1_PROGRESS.md](V1_PROGRESS.md)** - Development progress tracking
- **[RALPH_LOOP_5_COMPLETION.md](RALPH_LOOP_5_COMPLETION.md)** - v1.0 completion report

---

## 🗺️ Roadmap

### ✅ v1.0 - Ollama Client (Current)
- [x] Core chat with streaming responses
- [x] Conversation management (archive, delete)
- [x] Connection profiles
- [x] Model management (pull, list, delete)
- [x] Full-text search (FTS5)
- [x] System prompts per conversation
- [x] Export conversations (JSON/Markdown/Text)
- [x] Settings persistence

### 🚧 v1.5 - Cloud API Integration (Planned)
- [ ] OpenAI API integration
- [ ] Anthropic API integration
- [ ] Google AI API integration
- [ ] Provider abstraction layer
- [ ] Smart routing and fallbacks
- [ ] Cost tracking per provider
- [ ] API key management

### 🔮 v2.0 - Advanced Features (Future)
- [ ] Local models (LiteRT/Gemini Nano)
- [ ] Multi-model comparison
- [ ] Tool calling framework
- [ ] Web search integration
- [ ] Extended reasoning models
- [ ] Android native integration (share, TTS)
- [ ] Projects/spaces organization
- [ ] Custom agents

---

## 🐛 Known Issues

1. **Test Timeout**: Widget tests hang due to SQLite initialization in test environment (not a runtime issue)
2. **Deprecated APIs**: Some Material 3 colors use deprecated names (cosmetic, no impact)
3. **BuildContext Warnings**: Async gaps with mounted checks (properly handled)

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Clean Architecture principles
- Use Freezed for entities
- Add tests for new features
- Run `flutter analyze` before committing
- Update documentation for significant changes

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **[Ollama](https://ollama.ai)** - Local LLM runtime
- **[Flutter](https://flutter.dev)** - UI framework
- **[Material Design 3](https://m3.material.io/)** - Design system
- **[Freezed](https://pub.dev/packages/freezed)** - Code generation for immutable classes

---

## 💡 Tips & Tricks

### Performance

- **Database**: Conversations and messages are indexed for fast queries
- **FTS5 Search**: Full-text search uses SQLite's high-performance FTS5 engine
- **Streaming**: Incremental UI updates minimize memory usage during long responses

### Troubleshooting

**Cannot connect to Ollama:**
- Ensure Ollama is running: `ollama serve`
- Check firewall allows connections to port 11434
- Use correct IP address if Ollama is on another machine
- Test with: `curl http://YOUR_HOST:11434/api/version`

**Model not found:**
- Pull the model first: `ollama pull llama3.2`
- Check available models: `ollama list`
- Use exact model name in app settings

**Slow responses:**
- Check network latency to Ollama server
- Try a smaller model (e.g., `phi3` instead of `llama3.2`)
- Ensure Ollama server has sufficient resources (CPU/GPU)

**App crashes on startup:**
- Clear app data and try again
- Check Android version (requires API 21+)
- Ensure Flutter SDK is up to date

---

## 📧 Contact

**Project Link**: https://github.com/yourusername/private-chat-hub

**Issues**: https://github.com/yourusername/private-chat-hub/issues

---

**Built with ❤️ using Flutter**
