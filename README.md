# Private Chat Hub 🤖

A privacy-first Android app for chatting with self-hosted AI models via Ollama. Keep your conversations private, switch between models instantly, and organize chats in projects - all with a beautiful Material Design 3 interface.

## ✨ Key Features

- 🔒 **Privacy First**: All conversations stay on your devices and infrastructure
- 🤖 **Multiple AI Models**: Connect to any Ollama model (Llama, Mistral, Gemma, etc.)
- 🔍 **Web Search**: LLMs can search the internet for current information (tool calling)
- 💬 **Conversation Management**: Organize chats, view history, export conversations
- 📁 **Project Workspaces**: Group related conversations by topic or context
- 🖼️ **Vision Support**: Share images with vision-capable models
- 📱 **Native Android**: Built with Flutter, optimized for Android
- 🎨 **Material Design 3**: Beautiful, accessible UI
- 🔄 **Auto-sync**: Seamless connection to your Ollama server

## 🚀 Quick Start

### Prerequisites

**For Users:**
- Android device (5.0+)
- Ollama server running on your network ([Get Ollama](https://ollama.ai))
- At least one model downloaded on Ollama (e.g., `ollama pull llama3`)

**For Developers:**
- Flutter SDK 3.10.1+
- Dart 3.10.1+
- Java 17+
- Android SDK

Verify: `flutter doctor -v && java -version`

### Installation

#### Option 1: Download APK (Coming Soon)
Download the latest release from [GitHub Releases](https://github.com/yourusername/private-chat-hub/releases)

#### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/private-chat-hub.git
cd private-chat-hub

# Get dependencies
flutter pub get

# Run on Android device/emulator
flutter run

# Or build release APK
flutter build apk --release
```

### First-Time Setup

1. **Start Ollama Server**
   ```bash
   ollama serve
   ```

2. **Open Private Chat Hub**
   - Launch the app on your Android device

3. **Connect to Ollama**
   - Go to Settings → Connection
   - Enter your Ollama server IP and port (default: http://localhost:11434)
   - Tap "Test Connection"

4. **Select a Model**
   - Go to Models tab
   - Choose from available models
   - Start chatting!

**See [GETTING_STARTED.md](GETTING_STARTED.md) for detailed setup guide.**

## 🎯 Use Cases

### Privacy-Conscious Users
- Keep sensitive conversations completely private
- No data sent to cloud services
- Full control over your AI infrastructure
- Export and backup your chat history

### AI Enthusiasts & Developers
- Test and compare different models locally
- Experiment with vision models and multimodal AI
- Develop and test AI integrations
- Learn about LLMs in a safe environment

### Power Users
- Organize conversations by project or topic
- Switch models based on task requirements
- Access chat history for context and reference
- Integrate with other local services

## 🤖 Developer Workflow with AI Agents

This project includes 6 specialized GitHub Copilot agents to accelerate development:

| Agent | Purpose | Example |
|-------|---------|-------|
| **@product-owner** | Define features | `@product-owner Plan conversation export feature` |
| **@experience-designer** | Design UX | `@experience-designer Improve chat bubble design` |
| **@architect** | Technical planning | `@architect How should we handle model switching?` |
| **@researcher** | Find solutions | `@researcher Best practices for markdown rendering` |
| **@flutter-developer** | Implementation | `@flutter-developer Add image attachment support` |
| **@doc-writer** | Documentation | `@doc-writer Update API documentation` |

**See [AGENTS.md](AGENTS.md) for detailed agent documentation.**

## ⚡ Build Performance

This template includes **comprehensive build optimizations**:

- **Java 17 baseline** for modern Android development
- **Parallel builds** with 4 workers (local) / 2 workers (CI)
- **Multi-level caching**: Gradle, Flutter SDK, pub packages
- **R8 code shrinking**: 40-60% smaller release APKs
- **Concurrency control**: Cancels duplicate CI runs
- **CI-optimized Gradle properties**: Separate config for CI vs local

### Expected Build Times

| Environment | Build Type | Time |
|------------|-----------|------|
| Local (cached) | Debug APK | 30-60s |
| Local | Release APK | 1-2 min |
| CI (cached) | Full workflow | 3-5 min |

**See [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) for details.**

## 🔄 CI/CD Workflows

### Automated Workflows

- **build.yml**: Auto-formats code, runs tests, lints, and builds on every push (30min timeout)
- **release.yml**: Signed releases on version tags (45min timeout)
- **pre-release.yml**: Manual beta/alpha releases (workflow_dispatch)
- **deploy-website.yml**: Deploys GitHub Pages website

> **Note**: The build workflow automatically formats code using `dart format` and applies lint fixes with `dart fix --apply`. Any formatting changes are committed automatically, so you don't need to worry about code style.

### Setup Signed Releases

```bash
# 1. Generate keystore
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release

# 2. Add GitHub Secrets
- ANDROID_KEYSTORE_BASE64: `base64 -i release.jks | pbcopy`
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS: release
- ANDROID_KEY_PASSWORD

# 3. Tag and push
git tag v1.0.0 && git push --tags
```

## 📂 Project Structure

```
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models (Conversation, Message, etc.)
│   ├── screens/               # UI screens
│   │   ├── chat_screen.dart   # Main chat interface
│   │   ├── conversation_list_screen.dart
│   │   ├── models_screen.dart # Model selection
│   │   ├── projects_screen.dart
│   │   └── settings_screen.dart
│   ├── services/              # Business logic
│   │   ├── chat_service.dart  # Chat management
│   │   ├── ollama_service.dart # Ollama API client
│   │   ├── storage_service.dart # Local persistence
│   │   └── connection_service.dart
│   ├── widgets/               # Reusable UI components
│   └── utils/                 # Helper functions
├── test/                      # Unit & widget tests
├── android/                   # Android platform files
├── docs/                      # Documentation
└── pubspec.yaml               # Dependencies
```

## 📚 Documentation

### User Guides
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Setup guide for first-time users ⭐
- **[WEB_SEARCH_FEATURE.md](WEB_SEARCH_FEATURE.md)** - Web search and tool calling guide 🔍
- [PREREQUISITES.md](PREREQUISITES.md) - System requirements
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions

### Technical Documentation
- [docs/ARCHITECTURE_DECISIONS.md](docs/ARCHITECTURE_DECISIONS.md) - Architecture overview
- [docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md) - Product vision and roadmap
- [docs/UX_DESIGN.md](docs/UX_DESIGN.md) - Design decisions
- [TESTING.md](TESTING.md) - Testing guide

### Development
- [AGENTS.md](AGENTS.md) - AI agent configuration reference
- [AI_PROMPTING_GUIDE.md](AI_PROMPTING_GUIDE.md) - AI agent best practices
- [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) - Build performance details
- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
- [SIGNING.md](SIGNING.md) - App signing guide

## �️ Roadmap

### Current Version (1.0.0)
- ✅ Connect to Ollama server
- ✅ Chat with any Ollama model
- ✅ Conversation management
- ✅ Project workspaces
- ✅ Vision model support (image input)
- ✅ Export conversations
- ✅ Connection settings

### Planned Features
- 🔄 Multi-server support
- 📎 File attachments
- 🎯 Custom agents/personas
- 🔍 Advanced search
- 📊 Conversation analytics
- 🔗 Context chaining
- 🌐 Network discovery
- 📱 Tablet/landscape optimization

**See [docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md) for full roadmap.**

## 💡 Tips & Best Practices

### For Users
1. **Organize with Projects** - Group related conversations
2. **Try Different Models** - Switch models for different tasks
3. **Export Regularly** - Back up important conversations
4. **Use Vision Models** - Share images for visual tasks

### For Developers
1. **Follow Architecture** - Review [ARCHITECTURE_DECISIONS.md](docs/ARCHITECTURE_DECISIONS.md)
2. **Use AI Agents** - Leverage GitHub Copilot agents for development
3. **Write Tests** - Maintain test coverage
4. **Document Changes** - Update docs when adding features

## 🛠️ Technology Stack

- **Framework**: Flutter 3.10.1+
- **Language**: Dart 3.10.1+
- **Platform**: Android (iOS support planned)
- **State Management**: Manual state management (Riverpod planned)
- **Storage**: shared_preferences (SQLite planned)
- **HTTP Client**: http package
- **Markdown**: flutter_markdown
- **Image Picker**: image_picker
- **File Picker**: file_picker

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start for Contributors
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Write/update tests
5. Run tests: `flutter test`
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Acknowledgments

- [Ollama](https://ollama.ai) - Local LLM runtime
- Flutter team for the amazing framework
- All contributors and users

## 📞 Support

- 🐛 [Report Issues](https://github.com/yourusername/private-chat-hub/issues)
- 💬 [Discussions](https://github.com/yourusername/private-chat-hub/discussions)
- 📧 Email: your-email@example.com

---

**Built with ❤️ for privacy-conscious AI enthusiasts**
