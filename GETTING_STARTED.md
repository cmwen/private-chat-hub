# Getting Started with Private Chat Hub

Welcome! This guide will help you set up and start using Private Chat Hub - your private AI chat application.

## 📋 What You'll Need

### For Users (Running the App)

- ✅ Android device (Android 5.0+) or emulator
- ✅ Ollama server running on your network ([Get Ollama](https://ollama.ai))
- ✅ At least one AI model downloaded (e.g., `ollama pull llama3`)
- ✅ Network connection between your device and Ollama server

### For Developers (Building from Source)

- ✅ Flutter SDK 3.10.1+ ([Install Guide](https://docs.flutter.dev/get-started/install))
- ✅ Dart 3.10.1+
- ✅ Java 17+ (for Android builds)
- ✅ Android Studio or Android SDK
- ✅ Git
- ✅ VS Code with Flutter extension (recommended)

Verify your development setup:
```bash
flutter doctor -v
java -version  # Should show version 17+
```

## 🚀 Quick Start for Users

### Step 1: Set Up Ollama Server

1. **Install Ollama** on your computer or server:
   ```bash
   # Visit https://ollama.ai to download for your OS
   # Or use package manager:
   # macOS: brew install ollama
   # Linux: curl https://ollama.ai/install.sh | sh
   ```

2. **Start Ollama server**:
   ```bash
   ollama serve
   ```
   
   The server will start on `http://localhost:11434` by default.

3. **Download a model**:
   ```bash
   # Download Llama 3 (recommended for general use)
   ollama pull llama3
   
   # Or try other models:
   ollama pull mistral    # Faster, good for quick responses
   ollama pull gemma      # Google's model
   ollama pull llava      # Vision-capable model (can analyze images)
   ```

4. **Verify Ollama is working**:
   ```bash
   ollama list  # Should show your downloaded models
   curl http://localhost:11434/api/tags  # Should return JSON with models
   ```

### Step 2: Install Private Chat Hub

#### Option A: Download APK (Easiest)

1. Go to [Releases](https://github.com/yourusername/private-chat-hub/releases)
2. Download the latest `app-release.apk`
3. Install on your Android device
   - You may need to enable "Install from unknown sources" in Settings

#### Option B: Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/private-chat-hub.git
cd private-chat-hub

# Get dependencies
flutter pub get

# Connect your Android device or start emulator
# Then run:
flutter run

# Or build release APK
flutter build apk --release
# APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

### Step 3: Connect to Your Ollama Server

1. **Open Private Chat Hub** on your Android device

2. **Go to Settings** (tap the gear icon in the bottom navigation)

3. **Configure Connection**:
   - **Host**: Enter your Ollama server IP address
     - Same device: `localhost` or `127.0.0.1`
     - Local network: Your computer's IP (e.g., `192.168.1.100`)
     - Remote: Your server's IP or domain
   - **Port**: `11434` (default)
   - **Use HTTPS**: Enable if using SSL/TLS

4. **Test Connection**:
   - Tap "Test Connection"
   - You should see "✓ Connected successfully"
   - If connection fails, see [Troubleshooting](#troubleshooting) below

### Step 4: Start Chatting!

1. **Select a Model**:
   - Tap "Models" in the bottom navigation
   - You'll see all models available on your Ollama server
   - Tap a model to set it as active

2. **Start a Conversation**:
   - Tap "Chats" in the bottom navigation
   - Tap the "+" button to create a new conversation
   - Enter your message and hit send!

3. **Organize with Projects** (Optional):
   - Tap "Projects" to create workspaces
   - Group related conversations by topic
   - Example: "Work", "Learning", "Creative Writing"

## 🎓 Key Features Guide

### Managing Conversations

**Create a New Conversation**:
- Go to Chats → Tap "+" button
- Optionally assign to a project

**View Conversation History**:
- All messages are saved locally
- Swipe down to scroll through history
- Long-press a message for options

**Export Conversations**:
- Open a conversation
- Tap the menu (⋮) → Export
- Choose format (JSON, Markdown, or Plain Text)
- Share or save to your device

### Working with Models

**Switch Models Mid-Conversation**:
- Tap the current model name at the top
- Select a different model
- Continue chatting with the new model

**Model Information**:
- Tap and hold on a model in the Models screen
- View size, parameters, and capabilities

### Using Vision Models

1. **Select a Vision-Capable Model**:
   - Examples: `llava`, `bakllava`, `llava-phi3`
   
2. **Add an Image**:
   - In the chat, tap the image icon (📷)
   - Choose from gallery or take a photo
   - Image will be attached to your next message

3. **Ask About the Image**:
   - Type your question (e.g., "What's in this image?")
   - The vision model will analyze and respond

### Projects & Organization

**Create a Project**:
- Go to Projects → Tap "+"
- Give it a name and description
- Example: "Python Learning" for coding questions

**Assign Conversations to Projects**:
- When creating a conversation, select a project
- Or edit an existing conversation to move it

**Benefits**:
- Keep conversations organized by topic
- Quickly find related discussions
- Better context management

### Step 3: Create App Icon

You have three options:

#### Option A: AI-Generated Icon (Recommended)

1. Use the provided prompt:
   ```
   @icon-generation.prompt.md
   
   Create an app launcher icon for [describe your app]. 
   Style: [flat/gradient/minimal], 
   Primary color: #[hex], 
   Symbol: [describe icon concept]
   ```

2. Save the generated 1024×1024 PNG to `assets/icon/app_icon.png`

#### Option B: Automated with flutter_launcher_icons

1. Add to `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1
   
   flutter_launcher_icons:
     android: true
     image_path: "assets/icon/app_icon.png"
   ```

2. Run:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

#### Option C: Manual Icon Placement

Place your icons manually in these directories:
- Android: `android/app/src/main/res/mipmap-*/ic_launcher.png` (48, 72, 96, 144, 192 px)

See [icon-generation.prompt.md](.github/prompts/icon-generation.prompt.md) for detailed sizing requirements.

### Step 4: Customize App Theme

Edit `lib/main.dart`:

```dart
MaterialApp(
  title: 'Your App Name',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,  // Change to your brand color
    ),
    useMaterial3: true,
  ),
  home: const MyHomePage(title: 'Your App Home'),
)
```

### Step 5: Set Up GitHub Repository

## 🔧 Troubleshooting

### Cannot Connect to Ollama

**Problem**: "Connection failed" when testing connection

**Solutions**:

1. **Verify Ollama is running**:
   ```bash
   # Check if Ollama is running
   ps aux | grep ollama
   # Or test with curl
   curl http://localhost:11434/api/tags
   ```

2. **Check firewall settings**:
   - Ensure port 11434 is open on your server
   - On Windows: Add firewall rule for port 11434
   - On macOS: System Preferences → Security & Privacy → Firewall

3. **Find correct IP address**:
   ```bash
   # macOS/Linux
   ifconfig | grep "inet "
   # Windows
   ipconfig
   ```
   - Use the local network IP (usually 192.168.x.x or 10.0.x.x)
   - NOT the loopback (127.0.0.1) unless on same device

4. **Test connection manually**:
   ```bash
   # Replace with your server IP
   curl http://192.168.1.100:11434/api/tags
   ```

### App Crashes on Startup

**Solutions**:

1. **Clear app data**:
   - Settings → Apps → Private Chat Hub → Storage → Clear Data

2. **Reinstall the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Check Android version**:
   - Ensure Android 5.0 (API 21) or higher

### Slow Response Times

**Causes & Solutions**:

1. **Model too large for hardware**:
   - Try a smaller model (e.g., `mistral` instead of `llama3:70b`)
   - Check available RAM with `ollama show <model> --modelfile`

2. **Network latency**:
   - Ensure good WiFi connection
   - Consider running Ollama on the same device (if possible)

3. **Ollama server overloaded**:
   - Check CPU/RAM usage on server
   - Reduce model size or upgrade hardware

### Images Not Working with Vision Models

**Solutions**:

1. **Verify model supports vision**:
   - Not all models support images
   - Use: `llava`, `bakllava`, or `llava-phi3`

2. **Check image size**:
   - Large images may be slow or fail
   - Try compressing the image first

3. **Check permissions**:
   - Ensure camera/storage permissions are granted
   - Settings → Apps → Private Chat Hub → Permissions

## 👨‍💻 Developer Guide

### Project Setup for Development

```bash
# Clone the repository
git clone https://github.com/yourusername/private-chat-hub.git
cd private-chat-hub

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run the app
flutter run

# Run with specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

### Project Structure

```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── conversation.dart
│   ├── message.dart
│   ├── connection.dart
│   └── project.dart
├── screens/                       # UI screens
│   ├── chat_screen.dart          # Main chat interface
│   ├── conversation_list_screen.dart
│   ├── models_screen.dart         # Model selection
│   ├── projects_screen.dart       # Project management
│   ├── project_detail_screen.dart
│   ├── search_screen.dart
│   └── settings_screen.dart       # App settings
├── services/                      # Business logic
│   ├── chat_service.dart         # Chat management
│   ├── ollama_service.dart       # Ollama API client
│   ├── storage_service.dart      # Local persistence
│   ├── connection_service.dart   # Connection management
│   └── project_service.dart      # Project management
├── widgets/                       # Reusable UI components
└── utils/                         # Helper functions
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/chat_service_test.dart

# Run with coverage
flutter test --coverage
```

### Building for Production

```bash
# Build release APK
flutter build apk --release

# Build release App Bundle (for Play Store)
flutter build appbundle --release

# Build with specific target
flutter build apk --target lib/main_prod.dart --release
```

### Using GitHub Copilot Agents

This project includes specialized AI agents to accelerate development:

1. **@product-owner** - Define features:
   ```
   @product-owner Plan conversation search feature with fuzzy matching
   ```

2. **@experience-designer** - Design UX:
   ```
   @experience-designer Improve the chat bubble design for better readability
   ```

3. **@architect** - Technical decisions:
   ```
   @architect Should we add state management with Riverpod or Bloc?
   ```

4. **@researcher** - Find solutions:
   ```
   @researcher Best practices for optimizing markdown rendering in Flutter
   ```

5. **@flutter-developer** - Implement features:
   ```
   @flutter-developer Add conversation export to Markdown format
   ```

6. **@doc-writer** - Documentation:
   ```
   @doc-writer Update architecture documentation with new service layer
   ```

**See [AGENTS.md](AGENTS.md) for detailed agent capabilities.**

## 📚 Additional Resources

### Documentation
- [ARCHITECTURE_DECISIONS.md](docs/ARCHITECTURE_DECISIONS.md) - Technical architecture
- [PRODUCT_VISION.md](docs/PRODUCT_VISION.md) - Product roadmap
- [UX_DESIGN.md](docs/UX_DESIGN.md) - Design decisions
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

### External Resources
- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs/api.md) - API reference
- [Flutter Documentation](https://docs.flutter.dev/)
- [Material Design 3](https://m3.material.io/)

## 🆘 Getting Help

- 🐛 [Report Issues](https://github.com/yourusername/private-chat-hub/issues)
- 💬 [Discussions](https://github.com/yourusername/private-chat-hub/discussions)
- 📧 Email: your-email@example.com

## 🎉 You're All Set!

Now you're ready to:
- Chat privately with AI models
- Organize conversations in projects
- Experiment with different models
- Contribute to the project

**Happy chatting! 🚀**

## 🐛 Troubleshooting

### Build Issues

**Java version mismatch**:
```bash
# Check Java version
java -version

# Set JAVA_HOME (macOS/Linux)
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

**Flutter not found**:
```bash
# Add Flutter to PATH
export PATH="$PATH:/path/to/flutter/bin"
```

**Gradle build fails**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Icon Issues

**Icons not updating**:
```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
```

### Import Errors After Renaming

```bash
# Regenerate code
flutter clean
flutter pub get
dart fix --apply
```

## 💡 Pro Tips

1. **Use VS Code snippets** - Type `stless` for StatelessWidget, `stful` for StatefulWidget
2. **Hot reload** - Press `r` in terminal or use VS Code's hot reload button
3. **Extract widgets** - Select code → Right-click → Refactor → Extract Widget
4. **Generate constructors** - Put cursor on class → Quick Fix → Generate constructor
5. **Use AI agents frequently** - They understand the project structure and best practices

## 🆘 Getting Help

- **Flutter Docs**: https://docs.flutter.dev
- **Pub.dev Packages**: https://pub.dev
- **Community**: https://flutter.dev/community
- **Stack Overflow**: Tag [flutter]

## ✅ Setup Complete!

Once you've completed all steps, you should have:
- ✅ App renamed with custom package name
- ✅ Custom app icon
- ✅ GitHub repository configured
- ✅ CI/CD workflows ready
- ✅ AI agents configured for development
- ✅ First build successful

**You're ready to build your app!** 🎉

Start with: `@product-owner What features should I implement first for [your app concept]?`
