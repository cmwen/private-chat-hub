import 'package:flutter/foundation.dart';

/// Breakpoint (dp) at which the app switches to a wide/desktop layout.
const double desktopNavigationBreakpoint = 960;

/// Returns true when running on a desktop OS (macOS, Windows, Linux).
bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux =>
      true,
    _ => false,
  };
}

/// Returns true when the viewport is wide enough to use the desktop layout.
bool isWideLayout(double width) => width >= desktopNavigationBreakpoint;
