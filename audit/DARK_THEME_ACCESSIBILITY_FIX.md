# Dark Theme Accessibility Improvements

## Overview

Fixed critical accessibility (a11y) issues in dark theme where text and input fields were difficult to read due to insufficient contrast ratios.

## Problem Statement

In dark theme mode:
- **Message input field**: Using `Colors.grey[100]` (very light) made text hard to read against dark background
- **Assistant messages**: Using `Colors.grey[300]` (light) had poor contrast
- **Text colors**: Hardcoded `Colors.black87` for assistant message text and `Colors.black54` for timestamps
- **UI elements**: Various hardcoded colors (Colors.grey[X]) didn't adapt to theme brightness

## Solution

Replaced all hardcoded colors with theme-aware Material Design 3 color scheme tokens that automatically adapt to light/dark theme brightness:

### Color Replacements

| Previous | New | Reason |
|----------|-----|--------|
| `Colors.grey[100]` | `colorScheme.surfaceContainer` | Input field background adapts to theme |
| `Colors.grey[300]` | `colorScheme.surfaceContainer` | Assistant message bubble background |
| `Colors.black87` | `colorScheme.onSurface` | Message text adapts to theme |
| `Colors.black54` | `colorScheme.onSurfaceVariant` | Secondary text (timestamps) |
| `Colors.grey[600]` | `colorScheme.onSurfaceVariant` | Tertiary text throughout app |
| `Colors.grey[700]` | `colorScheme.onSurface` | Icon/text colors |
| `Colors.grey[400]` | `colorScheme.onSurfaceVariant` | Placeholder/empty state icons |
| `Colors.grey[200]` | `colorScheme.surfaceContainer` | Background containers |
| `Colors.grey[300]` | `colorScheme.surfaceContainerHighest` | Elevated containers |
| `Colors.surfaceVariant` (deprecated) | `colorScheme.surfaceContainerHighest` | Use non-deprecated token |

## Files Modified

### 1. **lib/widgets/message_bubble.dart**
   - Line 62: Assistant message bubble background
   - Lines 80-85: Message text color
   - Lines 88-92: Timestamp color
   - Lines 206-210: File attachment background
   - Lines 216-228: File attachment text colors
   - Lines 408-425: Status message indicator
   - Lines 446-468: Web reference links styling
   - Lines 533-537: "More results" text color

### 2. **lib/widgets/message_input.dart**
   - Line 453: Input field background
   - Lines 489-500: Send button styling
   - Lines 610-645: Attachment preview styling

### 3. **lib/utils/snackbar_helper.dart**
   - Line 108: Snackbar background color

### 4. **lib/screens/settings_screen.dart**
   - Lines 390-398: Connection status indicator colors
   - Lines 481-483: Last connected timestamp text
   - Lines 658-700: Discovery UI text colors

### 5. **lib/screens/search_screen.dart**
   - Lines 159-199: Empty state icons and text
   - Lines 228-236: Search result group headers
   - Lines 291-303: Search result tiles

## Technical Details

### Material Design 3 Color Tokens Used

**For backgrounds:**
- `colorScheme.surfaceContainer` - Default container background (adapts to theme)
- `colorScheme.surfaceContainerHighest` - Elevated/highlighted backgrounds

**For text:**
- `colorScheme.onSurface` - Primary text (high contrast)
- `colorScheme.onSurfaceVariant` - Secondary/tertiary text (medium contrast)

### Why This Approach?

Material Design 3's semantic color system:
1. **Automatically adapts** to light/dark theme
2. **Ensures WCAG AA contrast** ratios are met
3. **Respects user wallpaper** color preferences (on supported devices)
4. **Future-proof**: Works with dynamic theming

## Testing Recommendations

### Manual Testing Checklist

- [ ] **Dark Theme**
  - [ ] Message input text is readable
  - [ ] LLM message text is readable
  - [ ] All timestamps are readable
  - [ ] Tool badges and attachment indicators are visible
  - [ ] Web search source links are readable
  - [ ] Settings screen text is readable
  - [ ] Search results are readable

- [ ] **Light Theme**
  - [ ] Verify light theme still works properly
  - [ ] No regressions in color appearance

### Accessibility Testing

- [ ] Check contrast ratios with accessibility tools:
  - Chrome DevTools Lighthouse
  - WAVE Web Accessibility Evaluation Tool
  - Color Contrast Analyzer
- [ ] Test with screen readers to verify text is properly rendered
- [ ] Test on different devices (phones, tablets, different resolutions)

### Device-Specific Testing

- [ ] Android with dark theme enabled
- [ ] Android with light theme enabled
- [ ] Test with Material You dynamic colors (if available)

## Deployment Notes

- ✅ All changes are backward compatible
- ✅ No breaking changes to APIs
- ✅ No new dependencies added
- ✅ Existing user preferences preserved
- ✅ All tests pass

## Future Improvements

1. **Add accessibility testing** to CI/CD pipeline
2. **Create design tokens documentation** for consistent color usage
3. **Add contrast ratio testing** to automated checks
4. **Consider adding high-contrast mode** for users with visual impairments
5. **Test with different font sizes** for readability

## References

- [Material Design 3 - Color System](https://m3.material.io/styles/color/overview)
- [WCAG 2.1 Contrast (Minimum)](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Flutter Material Colors](https://api.flutter.dev/flutter/material/ColorScheme-class.html)
- [Accessibility in Flutter](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
