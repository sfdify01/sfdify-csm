# Known Issues

## Flutter Web Trackpad Gesture Error (Non-blocking)

### Issue
When running the app in Chrome on macOS and using a trackpad, you may see console errors:
```
EXCEPTION CAUGHT BY GESTURES LIBRARY
Assertion failed: !identical(kind, PointerDeviceKind.trackpad) is not true
```

### Root Cause
This is a **known Flutter framework limitation** in how Flutter web handles trackpad pointer events on macOS. The issue exists in Flutter's gesture library (`events.dart:1639`).

### Impact
- ⚠️ **Console warnings appear** when scrolling with trackpad
- ✅ **No functional impact** - all features work correctly
- ✅ **Navigation works** perfectly
- ✅ **Data loading** works correctly
- ✅ **User interactions** are not affected

### Official Flutter Issues
- [Issue #174215: GestureDetector throws assertion error with trackpad multi-touch sequence](https://github.com/flutter/flutter/issues/174215)
- [Issue #129447: Flutter web throws exceptions on tap gestures](https://github.com/flutter/flutter/issues/129447)
- [Breaking Change: Trackpad gestures can trigger GestureRecognizer](https://docs.flutter.dev/release/breaking-changes/trackpad-gestures)

### Solutions

#### Option 1: Ignore (Recommended for Development)
The error doesn't affect functionality. Continue development and wait for Flutter framework fix.

#### Option 2: Use Regular Mouse
Using a regular mouse instead of trackpad eliminates the error completely.

#### Option 3: Use Production Build
Run the app in release mode (which we already do) to minimize console output:
```bash
flutter run -d chrome --release
```

#### Option 4: Update Flutter
Keep Flutter updated to the latest version where this issue may be fixed:
```bash
flutter upgrade
flutter --version
```

#### Option 5: Configure GestureDetector (Advanced)
For custom gesture detectors, exclude trackpad from supported devices:
```dart
GestureDetector(
  supportedDevices: {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    // Exclude: PointerDeviceKind.trackpad
  },
  onTap: () { ... },
  child: YourWidget(),
)
```

### Current Status
- **Flutter Version**: 3.38.5 → 3.38.6 (upgrading)
- **Browser**: Chrome
- **Platform**: macOS with trackpad
- **Build Mode**: Release

### Recommendation
**Accept and document this as a known Flutter web limitation.** The app is fully functional and this is a cosmetic console issue only.

---

**Last Updated**: 2026-01-12
**Status**: Open (waiting for Flutter framework fix)
