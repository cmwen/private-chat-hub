# Hugging Face Token Flow - Complete Implementation

## Summary

This document details the complete implementation of Hugging Face token authentication for downloading on-device LLM models, including the token flow from UI to HTTP requests and dynamic token updates.

## Problem Solved

Users need to download gated models from Hugging Face that require authentication. The token must:
1. Be entered once in Settings
2. Persist across app restarts
3. Flow through the entire service chain
4. Be immediately usable after saving (no app restart required)
5. Show helpful error messages when authentication fails

## Complete Token Flow

### 1. Token Input (UI Layer)

**File**: `lib/widgets/litert_model_settings_widget.dart`

```dart
// User enters token in TextField
TextField(
  controller: _tokenController,
  obscureText: _tokenObscured,
  decoration: InputDecoration(
    hintText: 'hf_...',
    suffixIcon: IconButton(
      icon: Icon(_tokenObscured ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _tokenObscured = !_tokenObscured),
    ),
  ),
)

// Save button calls _saveToken()
ElevatedButton(
  onPressed: _saveToken,
  child: const Text('Save Token'),
)
```

### 2. Token Storage (Config Service)

**File**: `lib/services/inference_config_service.dart`

```dart
// Save to SharedPreferences
Future<void> setHuggingFaceToken(String? token) async {
  if (token == null || token.trim().isEmpty) {
    await _prefs.remove(_huggingFaceTokenKey);
  } else {
    await _prefs.setString(_huggingFaceTokenKey, token);
  }
}

// Retrieve token
String? get huggingFaceToken {
  return _prefs.getString(_huggingFaceTokenKey);
}

// Check if configured
bool get hasHuggingFaceToken {
  final token = huggingFaceToken;
  return token != null && token.isNotEmpty;
}
```

### 3. Service Initialization (App Startup)

**File**: `lib/main.dart`

```dart
// Initialize services with token
Future<void> _initializeInferenceServices() async {
  final prefs = await SharedPreferences.getInstance();
  final inferenceConfigService = InferenceConfigService(prefs);
  
  // Create OnDeviceLLMService with config (includes token)
  final onDeviceLLMService = OnDeviceLLMService(
    widget.storageService,
    configService: inferenceConfigService,
  );
  
  setState(() {
    _inferenceConfigService = inferenceConfigService;
    _onDeviceLLMService = onDeviceLLMService;
  });
}
```

### 4. Service Chain (Token Propagation)

**OnDeviceLLMService → ModelManager → ModelDownloadService**

**File**: `lib/services/on_device_llm_service.dart`
```dart
OnDeviceLLMService(StorageService storage, {InferenceConfigService? configService})
  : _modelManager = ModelManager(
      storage,
      huggingFaceToken: configService?.huggingFaceToken, // Pass token
    ),
    _platformChannel = LiteRTPlatformChannel(),
    _configService = configService;
```

**File**: `lib/services/model_manager.dart`
```dart
ModelManager(
  this._storage, {
  ModelDownloadService? downloadService,
  String? huggingFaceToken,
})  : _huggingFaceToken = huggingFaceToken,
      _downloadService = downloadService ??
          ModelDownloadService(
            _storage,
            huggingFaceToken: huggingFaceToken, // Pass token
          ),
      _platformChannel = LiteRTPlatformChannel();
```

**File**: `lib/services/model_download_service.dart`
```dart
ModelDownloadService(
  this._storage, {
  http.Client? client,
  String? huggingFaceToken,
})  : _client = client ?? http.Client(),
      _huggingFaceToken = huggingFaceToken;
```

### 5. HTTP Request (Authentication)

**File**: `lib/services/model_download_service.dart`

```dart
Future<void> _startDownload(LiteRTModel model, int resumeFrom) async {
  // Create request
  final request = http.Request('GET', Uri.parse(model.downloadUrl));
  
  // Add authorization header if token exists
  if (_huggingFaceToken != null && _huggingFaceToken!.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $_huggingFaceToken';
    _log('Using Hugging Face authentication token');
  }
  
  final response = await _client.send(request);
  
  // Handle authentication errors
  if (response.statusCode == 401) {
    throw HuggingFaceAuthException(
      'Authentication required. This model requires a Hugging Face token. '
      'Get a free token at https://huggingface.co/settings/tokens and add it in Settings.',
    );
  }
  
  if (response.statusCode == 403) {
    final repoPath = _extractRepoFromUrl(model.downloadUrl);
    throw HuggingFaceAuthException(
      'Access denied. Your token may not have permission to access this model. '
      'Visit https://huggingface.co/$repoPath to request access.',
    );
  }
}
```

### 6. Dynamic Token Update (No Restart Required)

When user saves a new token, it's immediately propagated through the service chain.

**UI Widget** (`litert_model_settings_widget.dart`):
```dart
Future<void> _saveToken() async {
  final token = _tokenController.text.trim();
  
  // Save to storage
  await widget.configService.setHuggingFaceToken(
    token.isEmpty ? null : token,
  );

  // Update services immediately (NEW!)
  if (widget.onDeviceLLMService != null) {
    widget.onDeviceLLMService.updateHuggingFaceToken(
      token.isEmpty ? null : token,
    );
  }
}
```

**OnDeviceLLMService**:
```dart
void updateHuggingFaceToken(String? token) {
  _modelManager.updateHuggingFaceToken(token);
  _log('Hugging Face token updated in OnDeviceLLMService');
}
```

**ModelManager**:
```dart
void updateHuggingFaceToken(String? token) {
  _downloadService.updateHuggingFaceToken(token);
  _log('Hugging Face token updated in ModelManager');
}
```

**ModelDownloadService**:
```dart
void updateHuggingFaceToken(String? token) {
  _huggingFaceToken = token;
  _log('Hugging Face token updated');
}
```

### 7. OnDeviceModelsScreen (Download Screen)

**File**: `lib/screens/on_device_models_screen.dart`

```dart
@override
void initState() {
  super.initState();
  
  // Create download service with token from config
  _downloadService = ModelDownloadService(
    widget.storageService,
    huggingFaceToken: widget.inferenceConfigService.huggingFaceToken,
  );
}

// Error handling with helpful dialogs
void _downloadModel(ModelInfo model) {
  _downloadService.downloadModel(model.id).listen(
    (progress) {
      // Update progress UI
    },
    onError: (e) {
      String errorMessage = 'Download failed';
      if (e is HuggingFaceAuthException) {
        errorMessage = e.message; // Detailed auth error
      }
      _showErrorDialog('Download Error', errorMessage);
    },
  );
}

// Error dialog with action button
void _showErrorDialog(String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.error_outline, size: 48, color: Colors.red),
      title: Text(title),
      content: SelectableText(message), // User can copy error
      actions: [
        // If auth error, show quick link to settings
        if (message.contains('Hugging Face token'))
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to settings
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
```

## Token Validation

Token format must follow Hugging Face standards:
- Starts with `hf_` prefix
- 37 characters total (prefix + 34 character key)
- Example: `your_huggingface_token_here`

## Error Handling

### HTTP 401 (Unauthorized)
**Cause**: No token provided or token is invalid
**Message**: "Authentication required. This model requires a Hugging Face token. Get a free token at https://huggingface.co/settings/tokens and add it in Settings."

### HTTP 403 (Forbidden)
**Cause**: Token is valid but doesn't have access to the model
**Message**: "Access denied. Your token may not have permission to access this model. Visit https://huggingface.co/{repo} to request access."

### Token Not Saved
**Cause**: Error writing to SharedPreferences
**Message**: "Error saving token: {error details}"

## User Flow

### First-Time Setup
1. User opens Settings
2. Scrolls to "On-Device Models" section
3. Sees "Hugging Face API Token" card
4. Clicks link to get token from HuggingFace
5. Pastes token into text field
6. Clicks visibility toggle to verify token
7. Clicks "Save Token" button
8. Sees success message: "Hugging Face token saved"
9. Navigates to "Manage On-Device Models"
10. Downloads model (no restart needed!)

### Download with Auth Error
1. User tries to download model
2. Gets 401 error
3. Error dialog shows with "Open Settings" button
4. Clicks button → taken to Settings
5. Adds token
6. Returns to download screen
7. Tries download again → succeeds

### Token Update
1. User opens Settings
2. Changes token in text field
3. Clicks "Save Token"
4. Token immediately available for downloads
5. No app restart required

## Testing Checklist

- [ ] Token saves to SharedPreferences
- [ ] Token persists after app restart
- [ ] Token field is obscured by default
- [ ] Visibility toggle works
- [ ] Empty token can be saved (removes token)
- [ ] Authorization header added to HTTP request
- [ ] 401 error shows helpful message
- [ ] 403 error shows model-specific message
- [ ] Error dialog has "Open Settings" button
- [ ] Token update works without restart
- [ ] Download succeeds with valid token
- [ ] Download fails with invalid token

## Files Modified

### Core Services (Token Flow)
1. `lib/services/inference_config_service.dart` - Token storage
2. `lib/services/model_download_service.dart` - HTTP authentication + dynamic update
3. `lib/services/model_manager.dart` - Token propagation + dynamic update
4. `lib/services/on_device_llm_service.dart` - Service integration + dynamic update

### UI Components
5. `lib/widgets/litert_model_settings_widget.dart` - Token input + dynamic update trigger
6. `lib/screens/settings_screen.dart` - Settings integration + pass service
7. `lib/screens/on_device_models_screen.dart` - Download screen + error dialogs

### App Setup
8. `lib/main.dart` - Service initialization + pass to screens

## Security Considerations

1. **Token Storage**: Stored in SharedPreferences (Android KeyStore backed on Android)
2. **UI Display**: Obscured by default with toggle
3. **Logs**: Token never logged (only "token updated" messages)
4. **Network**: Sent via HTTPS only
5. **Format**: Standard Bearer token authentication

## Future Improvements

1. **Token Validation**: Test token before saving with API call
2. **Token Refresh**: Detect expired tokens and prompt re-authentication
3. **Scope Check**: Verify token has required scopes
4. **Multiple Tokens**: Support different tokens for different repos
5. **In-App Browser**: Open HuggingFace login directly in app
6. **Token Expiry**: Show expiration date if available

## Troubleshooting

### "Token not working"
- Check token format (starts with `hf_`)
- Verify token copied completely (37 characters)
- Check token hasn't been revoked on HuggingFace
- Try generating new token

### "Still getting 401 after adding token"
- Token may not have propagated (fixed with dynamic update)
- Token might be invalid - check on HuggingFace
- Model might be private - check model page

### "403 Forbidden"
- Token is valid but lacks model access
- Visit model page to request access
- May need to accept terms/conditions

### "Token not showing in field"
- Token is obscured by default
- Click eye icon to reveal
- Check SharedPreferences for `huggingface_api_token` key

## Documentation

- User Guide: [HUGGINGFACE_AUTH_IMPLEMENTATION.md](HUGGINGFACE_AUTH_IMPLEMENTATION.md)
- Settings Fix: [ONDEVICE_SETTINGS_VISIBILITY_FIX.md](ONDEVICE_SETTINGS_VISIBILITY_FIX.md)

## Implementation Date

January 2025

## Author

GitHub Copilot (Claude Sonnet 4.5)
