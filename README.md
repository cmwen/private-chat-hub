# Private Chat Hub 🤖

[![Flutter](https://img.shields.io/badge/Flutter-3.10.1+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-192%20Passing-brightgreen.svg)](test/)

**Universal AI Chat Platform** - One app for all your AI models. Chat with on-device models (privacy), self-hosted Ollama or LM Studio servers (control), or cloud APIs (power). You choose your balance of privacy, performance, and cost.

## ✨ What Makes Us Different

Unlike single-provider apps (ChatGPT, Claude) or desktop-only tools (Jan.ai, LM Studio), **Private Chat Hub** gives you:

- 📱 **Mobile-First**: Native Android app, not a web wrapper
- 🌍 **Universal Access**: Local models + Self-hosted + Cloud APIs (OpenAI, Anthropic, Google)
- 🔒 **Privacy by Choice**: Use 100% local models, or cloud when you need them
- 💰 **Cost Flexible**: Free local models, pay-per-use cloud APIs, or your own Ollama or LM Studio server
- ⚡ **Full Offline**: Chat with on-device models anywhere, no internet required
- 🎯 **Smart Fallbacks**: Auto-switch to available providers when one fails

**Position:** The only mobile app supporting the full spectrum from on-device privacy to cloud convenience.

## ✨ Key Features

### v1.0 (Current)
- 🔒 **Hybrid Architecture**: Local on-device models (LiteRT) + self-hosted Ollama or LM Studio
- 📱 **Offline Mode**: Full functionality with local models, queue messages for remote
- 🤖 **Multiple AI Models**: Access self-hosted Ollama or LM Studio models + on-device Gemini/Gemma
- 🔍 **Web Search**: LLMs can search the internet with real-time progress
- 📚 **Source References**: Clickable links to web search sources
- 💬 **Conversation Management**: Organize chats, view history, export conversations
- 📁 **Project Workspaces**: Group related conversations by topic
- 🖼️ **Vision Support**: Share images with vision-capable models
- 🔄 **Model Comparison**: Compare responses from two models side-by-side
- 🎨 **Material Design 3**: Beautiful, accessible UI
- ⚡ **Tool Calling**: Advanced AI capabilities with function calling

### v1.5 (In Progress) - Cloud API Integration 🆕
- ☁️ **OpenAI Integration**: GPT-4o, GPT-4o-mini, GPT-3.5-turbo, o1-preview
- ☁️ **Anthropic Integration**: Claude 3.5 Sonnet, Opus, Haiku
- ☁️ **Google AI Integration**: Gemini 1.5 Pro, Flash
- 💰 **Cost Tracking**: Track token usage and costs per provider
- 🎯 **Smart Routing**: Auto-fallback between cloud, Ollama, and local models
- 🔐 **Secure API Keys**: Encrypted storage for all credentials
- 📊 **Usage Analytics**: Monitor costs, set limits, get suggestions

## 🚀 Quick Start

### Prerequisites

**For Users:**
- Android device (7.0+, API 24+)
- Optional: Ollama or LM Studio server for self-hosted models ([Get Ollama](https://ollama.ai), [Get LM Studio](https://lmstudio.ai/))
- Optional: API keys for cloud providers (OpenAI, Anthropic, Google AI)

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

Choose your preferred setup:

#### Option A: 100% Local (Privacy-First) 🔒
1. Open Private Chat Hub
2. Download a local model (Settings → Local Models)
3. Chat completely offline with on-device AI
4. **No internet required after download**

#### Option B: Self-Hosted (Control + Power) 🖥️
1. Install Ollama on your server or install LM Studio on your desktop/server
2. Download a model in Ollama or LM Studio
3. In app: Settings → Self-Hosted Servers → connect Ollama or LM Studio
4. Chat with powerful models on your infrastructure

See [docs/GUIDE_LM_STUDIO_SETUP.md](docs/GUIDE_LM_STUDIO_SETUP.md) for a focused LM Studio walkthrough.

#### Option C: Cloud APIs (Convenience + Latest Models) ☁️
1. Get API keys from [OpenAI](https://platform.openai.com/api-keys), [Anthropic](https://console.anthropic.com/), or [Google AI](https://makersuite.google.com/app/apikey)
2. In app: Settings → Providers → Add API keys
3. Access GPT-4, Claude 3.5, Gemini from your phone
4. **Costs tracked automatically**

#### Option D: Best of All Worlds (Recommended) 🌟
1. Set up local models for privacy (free)
2. Set up Ollama for power (free, your hardware)
3. Add cloud API keys for latest models (pay-per-use)
4. Let smart routing choose the best option automatically

**See [GETTING_STARTED.md](GETTING_STARTED.md) for detailed setup guide.**

## 🎯 Use Cases

### Privacy-Conscious Users
- Chat with 100% local models - conversations never leave your device
- No cloud dependencies or data collection
- Full control over your AI infrastructure
- Air-gapped option for maximum security

### Cost-Conscious Developers
- Use free local models for simple tasks
- Pay-per-use cloud APIs only when needed
- Track costs transparently - no surprise bills
- Smart suggestions for cheaper alternatives

### Power Users
- Access every AI model from one app
- Compare responses across providers
- Smart fallbacks when providers fail
- Organize conversations by project
- Full offline capability with local models

### AI Experimenters
- Test same prompt across multiple models
- Compare quality, speed, and cost
- Access latest cloud models (GPT-4, Claude 3.5, Gemini)
- Run local models for experimentation
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
