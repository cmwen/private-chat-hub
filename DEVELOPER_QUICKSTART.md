# Private Chat Hub - Developer Quick Start

**Status:** ✅ MVP Working - Basic Ollama Chat Implemented  
**Branch:** main (rework)  
**Date:** January 26, 2026

---

## 🚀 Quick Start (5 Minutes)

### 1. Prerequisites
- Flutter 3.10.1+ installed
- Ollama running (download from [ollama.ai](https://ollama.ai))
- Android device/emulator OR desktop for testing

### 2. Install & Run
```bash
# Clone and setup
cd private-chat-hub
flutter pub get

# Run on Android
flutter run

# OR run on Linux/macOS (desktop)
flutter run -d linux
flutter run -d macos
```

### 3. Configure in App
1. Open the app
2. Create a new conversation (tap + button)
3. In chat screen, tap menu (⋮) → "Connection Settings"
4. Set Ollama host:
   - **Local:** `http://localhost:11434`
   - **Network:** `http://192.168.1.X:11434`
5. Set model name (e.g., `llama3.2`, `phi3`, `mistral`)
6. Start chatting!

---

## 🎯 What Works Right Now

✅ **Core Functionality:**
- Create conversations
- Send text messages
- Stream responses from Ollama
- Persistent storage (SQLite)
- Material 3 UI with dark mode

✅ **Technical:**
- Clean Architecture (domain, data, presentation)
- Freezed entities with code generation
- Ollama API client with streaming
- SQLite with FTS5 full-text search
- Proper error handling

---

## 📁 Project Structure

```
lib/
├── core/                    # Shared utilities
│   ├── constants/           # App constants
│   ├── errors/              # Exceptions & failures
│   ├── utils/               # Logger, Result type
│   └── extensions/          # String, DateTime extensions
│
├── domain/                  # Business logic (pure Dart)
│   ├── entities/            # Freezed models
│   │   ├── message.dart
│   │   ├── conversation.dart
│   │   ├── ollama_model.dart
│   │   └── connection.dart
│   └── repositories/        # Interfaces only
│
├── data/                    # Data layer
│   └── datasources/
│       ├── local/           # SQLite database
│       │   └── database_helper.dart
│       └── remote/          # API clients
│           └── ollama_api_client.dart
│
└── main.dart                # App entry + UI screens
```

---

## 🔧 Development Commands

```bash
# Code generation (after changing entities)
dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate on save)
dart run build_runner watch

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Build APK
flutter build apk --release

# Build for desktop
flutter build linux --release
flutter build macos --release
```

---

## 🐛 Troubleshooting

### "Cannot connect to Ollama"
```bash
# Check Ollama is running
ollama serve

# Test API
curl http://localhost:11434/api/version

# Pull a model if needed
ollama pull llama3.2
```

### "Database not initialized" in tests
- Tests need `sqflite_common_ffi` for desktop
- Add to `test_helper.dart`:
```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

### Build errors after git pull
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

---

## 📝 Next Tasks (Priority Order)

### P0 - Critical for v1.0
1. **Connection Profiles**
   - CRUD UI for profiles
   - Profile switching
   - Persist selected profile

2. **Model Management**
   - List models from Ollama
   - Pull models with progress bar
   - Delete models

3. **Settings Screen**
   - Theme selection
   - Default connection
   - Default model
   - About page

### P1 - Important
4. **Repository Layer**
   - Implement proper repositories
   - Add Riverpod providers
   - State management

5. **Advanced Chat**
   - Image attachments (vision models)
   - File attachments
   - Message retry
   - Cancel streaming

6. **Conversation Management**
   - Archive/unarchive
   - Delete conversations
   - Edit titles
   - Full-text search UI

---

## 📚 Documentation

- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - What's implemented, what's not
- **[docs/ARCHITECTURE_DECISIONS.md](docs/ARCHITECTURE_DECISIONS.md)** - Technical decisions
- **[docs/PRODUCT_VISION.md](docs/PRODUCT_VISION.md)** - Product strategy
- **[docs/PRODUCT_REQUIREMENTS.md](docs/PRODUCT_REQUIREMENTS.md)** - Feature requirements

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Current Test Status:**
- ✅ Basic widget test passes
- ⚠️ Database tests need FFI setup
- ❌ No unit tests for business logic yet

---

## 🎨 UI/UX Notes

### Material 3 Theme
- **Seed Color:** `#6750A4` (purple)
- **Dynamic Color:** Adapts to system wallpaper (Android 12+)
- **Dark Mode:** Automatic based on system settings

### Key Screens
1. **Conversations List** (`ConversationsScreen`)
   - Shows all conversations
   - FAB to create new
   - Tap to open chat

2. **Chat Screen** (`ChatScreen`)
   - Message history (scrollable)
   - Input field with send button
   - Settings in app bar menu

---

## 🔐 Security Notes

- **No Cloud Storage:** All data stored locally in SQLite
- **No Telemetry:** Zero analytics or tracking
- **No API Keys Stored:** For now (v1.5 will add secure storage)
- **HTTP Allowed:** Local Ollama typically uses HTTP (no TLS)
- **Network Access:** Only to configured Ollama host

---

## 🚢 Deployment

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Desktop
```bash
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

---

## 💡 Pro Tips

1. **Fast Iteration:** Use hot reload (`r` in flutter run)
2. **Debug Prints:** Check `AppLogger` for debug logs
3. **Database Inspection:** Use DB Browser for SQLite on `databases/private_chat_hub.db`
4. **API Testing:** Use Postman/curl to test Ollama endpoints first
5. **Code Gen:** Keep `build_runner watch` running during development

---

## 🤝 Contributing

Currently in MVP phase. Major refactoring expected when adding:
- Riverpod state management
- Repository implementations
- Cloud API support (v1.5)

Before contributing:
1. Read `ARCHITECTURE_DECISIONS.md`
2. Follow existing code style
3. Run `flutter analyze` before committing
4. Add tests for new features

---

## 📊 Project Stats

- **Lines of Code:** ~4,500
- **Files:** 28
- **Test Coverage:** ~5% (MVP phase)
- **Target:** 70%+ for v1.0

---

## 🎯 Vision

**Goal:** Universal AI chat hub supporting:
- ✅ Local models (future: LiteRT/Gemini Nano)
- ✅ Self-hosted (Ollama) - **Working now**
- 🚧 Cloud APIs (OpenAI, Anthropic, Google) - v1.5

**Why:** One app for all AI models, with full privacy control.

---

**Ready to start coding?** Run `flutter run` and start hacking! 🚀

For questions, check the docs/ folder or implementation summary.
