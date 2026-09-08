import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/responsive.dart';

/// Breakpoint used to switch between mobile (narrow) and desktop (wide) layout.
/// Matches [Responsive.mobileBreakpoint] and the former _AdaptivePage logic.
const double adaptiveMobileMaxWidth = Responsive.mobileBreakpoint;

/// Returns true when the app should use the mobile layout (bottom nav, single column, etc.)
/// and false for desktop layout (sidebar, multi-column).
bool useMobileLayout(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width <= adaptiveMobileMaxWidth;
}

/// Builds either [desktop] or [mobile] based on [useMobileLayout].
/// Use for responsive pages that replace the old desktop/mobile split.
///
/// The swap is a direct child swap, not an AnimatedSwitcher: while a
/// transition runs the outgoing layout is re-laid out at the new window
/// size, which made the desktop layout overflow and flash during a resize.
/// Persistent navigation state lives in shellNavProvider, so nothing is lost
/// when the widget for the other layout replaces this one.
class AdaptiveLayout extends ConsumerWidget {
  final Widget Function() desktopBuilder;
  final Widget Function() mobileBuilder;

  const AdaptiveLayout({
    super.key,
    required this.desktopBuilder,
    required this.mobileBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMobile = useMobileLayout(context);
    return useMobile ? mobileBuilder() : desktopBuilder();
  }
}
