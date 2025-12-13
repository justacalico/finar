import 'package:flutter/widgets.dart';
import 'platform_detector.dart';

/// Responsive layout utilities
class Responsive {
  Responsive._();

  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1800;

  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Check if TV platform
    if (PlatformDetector.isTV) {
      return DeviceType.tv;
    }
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if current screen is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktopBreakpoint;
  }

  /// Get responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
    T? tv,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.tv:
        return tv ?? desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Get number of grid columns based on screen width
  static int gridColumns(BuildContext context) {
    return value(
      context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
      largeDesktop: 6,
      tv: 5,
    );
  }

  /// Get card aspect ratio based on device type
  static double cardAspectRatio(BuildContext context, {bool isLandscape = false}) {
    if (isLandscape) {
      return value(
        context,
        mobile: 16 / 9,
        tablet: 16 / 9,
        desktop: 16 / 9,
        tv: 16 / 9,
      );
    }
    return value(
      context,
      mobile: 2 / 3,
      tablet: 2 / 3,
      desktop: 2 / 3,
      tv: 2 / 3,
    );
  }

  /// Get horizontal padding based on screen size
  static double horizontalPadding(BuildContext context) {
    return value(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
      largeDesktop: 48.0,
      tv: 64.0,
    );
  }

  /// Get sidebar width for desktop layouts
  static double sidebarWidth(BuildContext context) {
    return value(
      context,
      mobile: 0.0,
      tablet: 80.0,
      desktop: 240.0,
      largeDesktop: 280.0,
    );
  }

  /// Check if should show sidebar
  static bool showSidebar(BuildContext context) {
    return isDesktop(context) && !PlatformDetector.isTV;
  }

  /// Check if should use bottom navigation
  static bool useBottomNav(BuildContext context) {
    return isMobile(context) || isTablet(context);
  }

  /// Get safe area padding
  static EdgeInsets safeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get the effective safe area considering device type
  static EdgeInsets effectiveSafeArea(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;
    final deviceType = getDeviceType(context);

    // TV usually needs more padding
    if (deviceType == DeviceType.tv) {
      return EdgeInsets.fromLTRB(
        safeArea.left + 48,
        safeArea.top + 24,
        safeArea.right + 48,
        safeArea.bottom + 24,
      );
    }

    return safeArea;
  }
}

/// Device types
enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
  tv,
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.getDeviceType(context));
  }
}

/// Responsive layout that switches between different layouts
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? tv;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.tv,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);

    switch (deviceType) {
      case DeviceType.tv:
        return tv ?? desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// Responsive visibility widget
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool visibleOnMobile;
  final bool visibleOnTablet;
  final bool visibleOnDesktop;
  final bool visibleOnTV;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOnMobile = true,
    this.visibleOnTablet = true,
    this.visibleOnDesktop = true,
    this.visibleOnTV = true,
    this.replacement,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = Responsive.getDeviceType(context);
    
    bool isVisible;
    switch (deviceType) {
      case DeviceType.tv:
        isVisible = visibleOnTV;
        break;
      case DeviceType.largeDesktop:
      case DeviceType.desktop:
        isVisible = visibleOnDesktop;
        break;
      case DeviceType.tablet:
        isVisible = visibleOnTablet;
        break;
      case DeviceType.mobile:
        isVisible = visibleOnMobile;
        break;
    }

    if (isVisible) {
      return child;
    }
    return replacement ?? const SizedBox.shrink();
  }
}
