import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../core/theme/colors.dart';

/// A TV-optimized focusable widget that wraps content with D-pad navigation support.
/// 
/// This widget provides:
/// - Visual focus indicators (glow, scale, border)
/// - Auto-scroll to ensure focused items are visible
/// - Integration with gamepad/TV remote navigation
class TvFocusable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final VoidCallback? onFocus;
  final VoidCallback? onUnfocus;
  final bool autofocus;
  final bool enabled;
  final TvFocusEffect effect;
  final String? region;
  final bool isEntryPoint;
  final bool autoScroll;
  final double scrollPadding;

  const TvFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.onFocus,
    this.onUnfocus,
    this.autofocus = false,
    this.enabled = true,
    this.effect = TvFocusEffect.glowAndScale,
    this.region,
    this.isEntryPoint = false,
    this.autoScroll = true,
    this.scrollPadding = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      onFocus: onFocus,
      region: region,
      isEntryPoint: isEntryPoint,
      autoScroll: autoScroll,
      scrollPadding: scrollPadding,
      builder: _getEffectBuilder(effect),
      child: child,
    );
  }

  FocusEffectBuilder _getEffectBuilder(TvFocusEffect effect) {
    switch (effect) {
      case TvFocusEffect.none:
        return (context, isFocused, child) => child ?? const SizedBox.shrink();
      
      case TvFocusEffect.border:
        return FocusEffects.border(
          focusColor: AppColors.primary,
          width: 3.0,
          borderRadius: BorderRadius.circular(12),
        );
      
      case TvFocusEffect.glow:
        return FocusEffects.glow(
          glowColor: AppColors.primary,
          blurRadius: 16.0,
          spreadRadius: 2.0,
        );
      
      case TvFocusEffect.scale:
        return FocusEffects.scale(
          scale: 1.05,
          duration: const Duration(milliseconds: 150),
        );
      
      case TvFocusEffect.glowAndScale:
        return FocusEffects.combine([
          FocusEffects.scale(scale: 1.03),
          FocusEffects.glow(
            glowColor: AppColors.primary.withValues(alpha: 0.6),
            blurRadius: 20.0,
            spreadRadius: 2.0,
          ),
        ]);
      
      case TvFocusEffect.borderAndScale:
        return FocusEffects.scaleWithBorder(
          scale: 1.03,
          borderColor: AppColors.primary,
          borderWidth: 2.0,
          borderRadius: BorderRadius.circular(12),
        );
      
      case TvFocusEffect.custom:
        return _customGlassFocusEffect;
    }
  }

  /// Custom glass-morphism focus effect matching the app's theme
  Widget _customGlassFocusEffect(BuildContext context, bool isFocused, Widget? child) {
    return AnimatedScale(
      scale: isFocused ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isFocused
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  width: 2,
                )
              : null,
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// Focus effect styles for TV navigation
enum TvFocusEffect {
  /// No visual effect
  none,
  
  /// Border highlight only
  border,
  
  /// Glow effect only
  glow,
  
  /// Scale effect only
  scale,
  
  /// Combined glow and scale (default, most visible)
  glowAndScale,
  
  /// Combined border and scale
  borderAndScale,
  
  /// Custom glass-morphism effect matching app theme
  custom,
}

/// A row of TV-focusable items optimized for horizontal navigation
class TvFocusableRow extends StatelessWidget {
  final List<Widget> children;
  final double height;
  final double itemSpacing;
  final EdgeInsets padding;
  final ScrollController? scrollController;
  final String? region;

  const TvFocusableRow({
    super.key,
    required this.children,
    this.height = 200,
    this.itemSpacing = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.scrollController,
    this.region,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, index) => SizedBox(width: itemSpacing),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

/// A grid of TV-focusable items with proper focus traversal
class TvFocusableGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets padding;
  final String? region;

  const TvFocusableGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 4,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 2 / 3,
    this.padding = const EdgeInsets.all(16),
    this.region,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.builder(
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) {
          return FocusTraversalOrder(
            order: NumericFocusOrder(index.toDouble()),
            child: children[index],
          );
        },
      ),
    );
  }
}

/// Extension for easier TV focus navigation
extension TvNavigationExtension on BuildContext {
  /// Navigate focus in a direction
  void moveFocus(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.up:
        Dpad.navigateUp(this);
        break;
      case TraversalDirection.down:
        Dpad.navigateDown(this);
        break;
      case TraversalDirection.left:
        Dpad.navigateLeft(this);
        break;
      case TraversalDirection.right:
        Dpad.navigateRight(this);
        break;
    }
  }

  /// Navigate to next focusable item
  void focusNext() => Dpad.navigateNext(this);

  /// Navigate to previous focusable item
  void focusPrevious() => Dpad.navigatePrevious(this);
}
