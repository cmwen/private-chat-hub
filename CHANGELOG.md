# Changelog

All notable changes to Private Chat Hub will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-01-05

### Fixed
- **Tools Toggle Not Respected**: Fixed issue where deselecting Tools option didn't prevent tool calling
  - ChatService now checks `conversation.toolCallingEnabled` flag before using agent-based approach
  - Logs now show tool calling state for debugging
- **Floating Action Button Overlap**: Removed ToolToggleFAB that was covering submit button
  - Tool calling can now be toggled via FilterChip in message input only
  - Cleaner UI without FAB overlap

## [1.0.0] - 2026-01-05

### Added
- **Web Search Progress Indicators**: Real-time status updates during tool execution
  - Shows "🔄 Starting tool execution..." when beginning
  - Updates with specific tool names: "🔍 Web Search", "📖 Reading URL", "🕒 Getting Time"
  - Progress displayed with spinner animation in message bubble
- **Source Reference Links**: Clickable reference chips showing web search sources
  - Displays up to 5 references with domain names
  - "+X more" indicator for additional sources
  - Bottom sheet for full URL viewing and copying
  - Links extracted automatically from SearchResults
- **Enhanced Error Feedback**: Visual indicator when LLM reaches max iterations
  - Red error message display
  - Descriptive error text explaining the failure
  - Clear distinction between errors and normal responses
- **Model Capability System**: Consolidated single source of truth
  - 30+ models in ModelRegistry with accurate capabilities
  - Removed duplicate capability system
  - Added UI compatibility getters (supportsTools, contextLength, family)
- **statusMessage Field**: New field in Message model for progress tracking
- **webSearchReferences Getter**: Automatic URL extraction from tool results

### Fixed
- **setState() After Dispose**: Fixed crash in ComparisonChatScreen during async operations
  - Added proper mounted checks before setState calls
  - Improved lifecycle management in async callbacks
  - Prevents "setState() called after dispose" errors
- **Model Capabilities**: Corrected gemma3 showing incorrect tool support
  - gemma3 now correctly shows supportsToolCalling: false
  - Vision capability properly displayed
  - Consistent capability display across app
- **Duplicate Registry**: Removed lib/models/model_capabilities.dart
  - Consolidated all capability data to ollama_toolkit/models/ollama_model.dart
  - Updated all imports throughout codebase
  - Single source of truth for model information
- **supportsCode Removal**: Removed unused capability field
  - Deleted from UI displays
  - Cleaned up model definitions
  - Removed from capability chips

### Changed
- **Message Model**: Extended with statusMessage and webSearchReferences
  - statusMessage: String? for real-time progress updates
  - webSearchReferences: List<String> getter for source URLs
  - Updated fromJson, toJson, copyWith methods
- **Chat Service**: Enhanced tool execution flow
  - Status updates via _updateStatusMessage helper
  - Stream updates during tool execution
  - Better error handling with AgentResponse.success check
- **Message Bubble Widget**: New display sections
  - Status message area with progress indicator
  - Web references section with clickable chips
  - Improved visual hierarchy
- **Build System**: Optimized for release
  - Java 17 baseline
  - Gradle parallel builds and caching
  - R8 code shrinking
  - Release APK: 52.8MB (99.3% icon tree-shaking)

### Improved
- **Test Coverage**: 192 tests passing
  - Model capabilities tests updated
  - Tool calling tests comprehensive
  - Message model tests extended
  - Zero test failures
- **Code Quality**: Clean compilation
  - Zero errors
  - 27 non-blocking warnings
  - Proper null-safety throughout
  - Better code organization
- **Documentation**: Comprehensive release docs
  - RELEASE_NOTES.md created
  - PRE_RELEASE_CHECKLIST.md added
  - README.md updated with current features
  - Badges added to README

### Technical Details
- Flutter SDK: 3.10.1+
- Dart SDK: 3.10.1+
- Java: 17
- Target Android API: 34
- Minimum Android API: 21
- Tests: 192/192 passing
- Build time: ~115s (release)
- APK size: 52.8MB

## [Unreleased]

### Planned for v1.1.0
- Performance optimizations
- Additional model support
- Enhanced tool calling features
- UI refinements based on user feedback

---

[1.0.0]: https://github.com/yourusername/private-chat-hub/releases/tag/v1.0.0
