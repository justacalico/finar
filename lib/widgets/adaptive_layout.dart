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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey<bool>(useMobile),
        child: useMobile ? mobileBuilder() : desktopBuilder(),
      ),
    );
  }
}
