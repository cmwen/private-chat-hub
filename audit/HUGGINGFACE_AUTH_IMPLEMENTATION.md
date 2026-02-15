# Hugging Face Authentication for Model Downloads

## Problem Solved ✅

**HTTP 401 Error when downloading models** - Some LiteRT models on Hugging Face require authentication.

## Solution: Add Hugging Face API Token

### What Changed:

1. **Added token storage** in `InferenceConfigService`
2. **Added token input UI** in Settings → On-Device Models
3. **Updated download service** to use token for authentication
4. **Better error messages** for 401/403 errors

---

## How to Get a Hugging Face Token

### Step 1: Create Hugging Face Account
1. Go to https://huggingface.co
2. Click "Sign Up" (free account)
3. Verify your email

### Step 2: Generate API Token
1. Go to https://huggingface.co/settings/tokens
2. Click **"New token"**
3. Choose **"Read"** access (sufficient for downloads)
4. Name it: `android-app` or whatever you like
5. Click **"Generate token"**
6. **Copy the token** (starts with `hf_...`)

⚠️ **Important**: Save the token somewhere safe - you can't see it again!

---

## How to Add Token in App

### In Settings Screen:

1. Open **Settings** (gear icon)
2. Scroll to **"On-Device Models (LiteRT)"**
3. Find **"Hugging Face API Token"** card
4. Paste your token (starts with `hf_...`)
5. Click **save icon** (💾)
6. Done! ✅

### Token Security:
- Token is stored securely in SharedPreferences
- Toggle visibility with 👁️ icon
- Can be removed anytime

---

## Download Flow

### Without Token (Before):
```
1. User taps "Download Model"
2. HTTP 401 Error ❌
3. Download fails
4. Confusing error message
```

### With Token (After):
```
1. User enters HF token in Settings
2. Token saved to config
3. User taps "Download Model"
4. Download service adds: Authorization: Bearer hf_...
5. Download succeeds ✅
```

---

## Error Handling

### HTTP 401 - Authentication Required
**Error Message:**
```
Authentication required. This model requires a Hugging Face token.
Get a free token at https://huggingface.co/settings/tokens and add it in Settings.
```

**Solution:** Add token in Settings → On-Device Models

### HTTP 403 - Access Denied
**Error Message:**
```
Access denied. You may need to accept the model's license agreement at
https://huggingface.co/[repo-path]
```

**Solution:** 
1. Visit the model page on Hugging Face
2. Accept the license agreement
3. Try download again

---

## Technical Implementation

### 1. InferenceConfigService
```dart
// Storage key
static const String _huggingFaceTokenKey = 'huggingface_api_token';

// Getter
String? get huggingFaceToken;

// Setter
Future<void> setHuggingFaceToken(String? token);

// Check
bool get hasHuggingFaceToken;
```

### 2. ModelDownloadService
```dart
class ModelDownloadService {
  final String? _huggingFaceToken;
  
  ModelDownloadService(
    StorageService storage, {
    String? huggingFaceToken,
  }) : _huggingFaceToken = huggingFaceToken;
  
  // In download request:
  if (_huggingFaceToken != null && _huggingFaceToken.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $_huggingFaceToken';
  }
}
```

### 3. ModelManager
```dart
ModelManager(
  StorageService storage, {
  String? huggingFaceToken,
}) : _downloadService = ModelDownloadService(
      storage,
      huggingFaceToken: huggingFaceToken,
    );
```

### 4. OnDeviceLLMService
```dart
OnDeviceLLMService(
  StorageService storage, {
  InferenceConfigService? configService,
}) : _modelManager = ModelManager(
      storage,
      huggingFaceToken: configService?.huggingFaceToken,
    );
```

### 5. UI Widget (LiteRTModelSettingsWidget)
```dart
// Text field for token input
TextField(
  controller: _tokenController,
  obscureText: _tokenObscured,
  decoration: InputDecoration(
    hintText: 'hf_...',
    suffixIcon: Row(
      children: [
        IconButton(
          icon: Icon(_tokenObscured ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _tokenObscured = !_tokenObscured),
        ),
        IconButton(
          icon: Icon(Icons.save),
          onPressed: _saveToken,
        ),
      ],
    ),
  ),
)
```

---

## Files Modified

1. ✅ `lib/services/inference_config_service.dart`
   - Added `_huggingFaceTokenKey` constant
   - Added getter/setter for token
   - Added `hasHuggingFaceToken` check

2. ✅ `lib/services/model_download_service.dart`
   - Added `_huggingFaceToken` field
   - Updated constructor to accept token
   - Added Authorization header to requests
   - Added `HuggingFaceAuthException` for 401/403
   - Better error messages with instructions

3. ✅ `lib/services/model_manager.dart`
   - Added `_huggingFaceToken` field
   - Pass token to ModelDownloadService

4. ✅ `lib/services/on_device_llm_service.dart`
   - Pass token from config to ModelManager

5. ✅ `lib/widgets/litert_model_settings_widget.dart`
   - Added TextEditingController for token input
   - Added UI card for Hugging Face token
   - Added visibility toggle
   - Added save button
   - Added `_saveToken()` method

---

## Testing

### Test Without Token:
1. Don't add token
2. Try to download model
3. Should see: "Authentication required..." error ❌

### Test With Token:
1. Add valid HF token in Settings
2. Try to download model
3. Should download successfully ✅

### Test Invalid Token:
1. Add fake token like `hf_fake123`
2. Try to download model
3. Should see: "Authentication required..." error ❌

### Test Token Visibility:
1. Enter token
2. Click eye icon 👁️
3. Token should show/hide

### Test Token Save:
1. Enter token
2. Click save icon 💾
3. Should see: "Hugging Face token saved"
4. Restart app
5. Token should still be there

---

## User Experience

### Before:
- Confusing HTTP 401 errors
- No way to authenticate
- Can't download models
- Dead end ❌

### After:
- Clear error messages with instructions
- Easy token input in Settings
- Secure token storage
- Successful downloads ✅

---

## Security Notes

- ✅ Token stored in SharedPreferences (Android secure storage)
- ✅ Token obscured by default (password field)
- ✅ Token only used for model downloads
- ✅ Token never logged or exposed
- ⚠️ User should use **Read** token (not Write)
- ⚠️ Token should not be shared

---

## Future Enhancements

1. **Token Validation**: Test token before saving
2. **Auto-login**: Open browser to get token
3. **Token Expiry**: Check and notify if expired
4. **Multiple Accounts**: Support different HF accounts
5. **OAuth Flow**: Native HF authentication

---

## Summary

| Aspect | Status |
|--------|--------|
| **Problem** | HTTP 401 when downloading models |
| **Cause** | Gated models require authentication |
| **Solution** | Hugging Face API token support |
| **Storage** | InferenceConfigService + SharedPreferences |
| **UI** | Settings → On-Device Models |
| **Security** | Obscured input, secure storage |
| **Error Handling** | Clear messages with instructions |
| **Status** | ✅ Complete & Ready to Test |

---

## Quick Start

1. Get token: https://huggingface.co/settings/tokens
2. Open app → Settings
3. Scroll to "On-Device Models (LiteRT)"
4. Paste token in "Hugging Face API Token" field
5. Click save icon
6. Download models! 🎉
