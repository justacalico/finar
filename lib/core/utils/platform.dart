import 'package:flutter/foundation.dart';

bool get isDesktopPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows);

bool get isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Layout breakpoint: compact (phone) vs wide (tablet/desktop).
const double kWideBreakpoint = 840;

bool isWideLayout(double width) => width >= kWideBreakpoint;
