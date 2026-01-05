# Release Notes - Version 1.0.0

**Release Date:** January 5, 2026

## 🎉 What's New

### Enhanced Web Search Experience
- **Real-time Progress Indicators**: See live status updates when the AI uses web search tools (🔍 Web Search, 📖 Reading URL, 🕒 Getting Time)
- **Reference Links**: Web search results now display clickable source links at the bottom of AI responses
- **Improved Transparency**: Know exactly what the AI is doing during long-running operations

### Better Error Handling
- **Max Iterations Feedback**: Clear visual indicator when AI reaches maximum iteration limit
- **Descriptive Error Messages**: Improved error messages explain what went wrong and why
- **Red Error Display**: Failed responses are clearly marked with red text for easy identification

### Model Capabilities Refinement
- **Accurate Model Information**: Fixed incorrect capability displays (e.g., gemma3 now correctly shows no tool support)
- **Consolidated System**: Single source of truth for model capabilities in `ollama_model.dart`
- **30+ Models Supported**: Comprehensive registry of Ollama models with accurate capabilities

### Stability Improvements
- **Fixed setState() After Dispose**: Resolved crash in comparison chat screen during async operations
- **Better Lifecycle Management**: Proper mounted checks throughout the app prevent state update errors
- **Improved Stream Handling**: More robust handling of async message streams

## 🔧 Technical Improvements

### Architecture
- Deleted duplicate `model_capabilities.dart` file
- Centralized model capabilities in `ollama_toolkit/models/ollama_model.dart`
- Added `statusMessage` field to Message model for progress tracking
- Implemented `webSearchReferences` getter for extracting search result URLs

### UI/UX
- Status messages display with spinner animation during tool execution
- Reference links shown as compact, clickable chips with domain names
- Up to 5 references displayed with "+X more" indicator for additional sources
- Bottom sheet for full URL viewing and copying

### Code Quality
- All tests passing (192 tests)
- Zero compilation errors
- Only minor linter warnings (deprecated RadioGroup APIs in Flutter SDK)
- Proper null-safety throughout

## 🐛 Bug Fixes

- Fixed gemma3 incorrectly showing tool support in UI
- Fixed setState() called after dispose in ComparisonChatScreen
- Fixed duplicate capability registry causing inconsistencies
- Removed unused `supportsCode` capability references

## 📝 Model Capabilities

### Models with Tool Calling Support
- llama3.1, llama3.2, llama3.3
- mistral-nemo, mistral-small
- qwen2.5
- nemotron-mini
- command-r, command-r-plus
- firefunction-v2

### Models with Vision Support
- llama3.2-vision
- llava, llava-llama3, llava-phi3
- minicpm-v
- gemma3

### Models with Extended Context
- gemma3 (16K)
- mistral-nemo (128K)
- qwen2.5 (128K)
- command-r-plus (128K)

## 🚀 Getting Started

### Prerequisites
- Flutter 3.10.1 or higher
- Dart 3.10.1 or higher
- Android device or emulator
- Ollama server running locally or remotely

### Installation
1. Clone the repository
2. Run `flutter pub get`
3. Configure Ollama server URL in Settings
4. Run `flutter run`

### For Developers
```bash
# Run tests
flutter test

# Build release APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release

# Analyze code
flutter analyze
```

## 📚 Documentation

Updated documentation includes:
- `AGENTS.md` - AI agent configuration and workflows
- `BUILD_OPTIMIZATION.md` - Build system optimization guide
- `AI_PROMPTING_GUIDE.md` - Guide for AI-assisted development
- `docs/` - Comprehensive documentation for all skill levels

## 🔐 Release Signing

For signed releases:
1. Generate keystore: `scripts/signing/generate-keystore.sh`
2. Configure GitHub Secrets:
   - `ANDROID_KEYSTORE_BASE64`
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
3. Tag version: `git tag v1.0.0 && git push --tags`

## ⚠️ Known Issues

- RadioGroup deprecation warnings (Flutter SDK 3.32+) - non-blocking
- Some debug print statements remain (for troubleshooting)
- Dead code warnings in ollama_agent.dart (non-blocking)

## 🙏 Acknowledgments

Built with:
- Flutter & Dart
- Ollama for local LLM support
- Jina AI for web search capabilities
- GitHub Copilot for AI-assisted development

## 📞 Support

For issues, questions, or contributions:
- GitHub Issues: [Create an issue](https://github.com/your-repo/issues)
- Documentation: See `docs/` folder
- AI Agents: Use `@flutter-developer` for technical support

---

**Full Changelog**: View all changes in the [commit history](https://github.com/your-repo/commits/main)
