import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/colors.dart';
import '../core/theme/app_theme.dart';
import '../core/services/controller_service.dart';

/// A glassmorphism container widget with blur and transparency effects
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final double borderRadius;
  final Color? color;
  final Gradient? gradient;
  final bool showBorder;
  final double borderWidth;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = AppTheme.blurMedium,
    this.opacity = 0.1,
    this.borderRadius = AppTheme.radiusLg,
    this.color,
    this.gradient,
    this.showBorder = true,
    this.borderWidth = 1.0,
    this.borderColor,
    this.padding,
    this.margin,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: color?.withValues(alpha: opacity) ?? 
                   AppColors.white.withValues(alpha: opacity),
            gradient: gradient ?? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: opacity * 1.5),
                AppColors.white.withValues(alpha: opacity * 0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: showBorder
                ? Border.all(
                    color: borderColor ?? AppColors.glassBorder,
                    width: borderWidth,
                  )
                : null,
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      container = Padding(
        padding: margin!,
        child: container,
      );
    }

    if (onTap != null) {
      container = GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// A glass card with hover effects for desktop
class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool enableHover;
  final double hoverScale;
  final Duration animationDuration;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.blur = AppTheme.blurLight,
    this.opacity = 0.08,
    this.borderRadius = AppTheme.radiusLg,
    this.padding,
    this.margin,
    this.onTap,
    this.enableHover = true,
    this.hoverScale = 1.02,
    this.animationDuration = AppTheme.durationNormal,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: widget.enableHover ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.enableHover ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedScale(
        scale: _isHovered ? widget.hoverScale : 1.0,
        duration: widget.animationDuration,
        curve: AppTheme.curveSmooth,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: AppTheme.curveSmooth,
          margin: widget.margin,
          child: GlassContainer(
            width: widget.width,
            height: widget.height,
            blur: widget.blur,
            opacity: _isHovered ? widget.opacity * 1.5 : widget.opacity,
            borderRadius: widget.borderRadius,
            padding: widget.padding,
            showBorder: true,
            borderColor: _isHovered 
                ? AppColors.primary.withValues(alpha: 0.3) 
                : AppColors.glassBorder,
            shadows: _isHovered ? AppTheme.shadowMedium : null,
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A glass button with press effects
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;
  final bool isDisabled;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.blur = AppTheme.blurLight,
    this.opacity = 0.15,
    this.borderRadius = AppTheme.radiusFull,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingLg,
      vertical: AppTheme.spacingMd,
    ),
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.durationFast,
        curve: AppTheme.curveSmooth,
        child: AnimatedOpacity(
          opacity: isEnabled ? 1.0 : 0.5,
          duration: AppTheme.durationFast,
          child: GlassContainer(
            blur: widget.blur,
            opacity: widget.opacity,
            borderRadius: widget.borderRadius,
            padding: widget.padding,
            color: widget.backgroundColor ?? AppColors.white,
            showBorder: true,
            borderColor: _isPressed 
                ? AppColors.primary.withValues(alpha: 0.5) 
                : AppColors.glassBorder,
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.foregroundColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass icon button with focus support for controller/keyboard navigation
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final double blur;
  final double opacity;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isActive;
  final bool autofocus;
  final FocusNode? focusNode;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconSize = 24,
    this.blur = AppTheme.blurLight,
    this.opacity = 0.1,
    this.iconColor,
    this.backgroundColor,
    this.isActive = false,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _isPressed = false;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);
    if (action == ControllerAction.select && widget.onPressed != null) {
      setState(() => _isPressed = true);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        }
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _isFocused || widget.isActive;
    
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTapDown: widget.onPressed != null 
            ? (_) => setState(() => _isPressed = true) 
            : null,
        onTapUp: widget.onPressed != null 
            ? (_) => setState(() => _isPressed = false) 
            : null,
        onTapCancel: widget.onPressed != null 
            ? () => setState(() => _isPressed = false) 
            : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.9 : 1.0,
          duration: AppTheme.durationFast,
          curve: AppTheme.curveSmooth,
          child: AnimatedContainer(
            duration: AppTheme.durationFast,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: _isFocused
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: GlassContainer(
              width: widget.size,
              height: widget.size,
              blur: widget.blur,
              opacity: isHighlighted ? widget.opacity * 2 : widget.opacity,
              borderRadius: widget.size / 2,
              color: widget.isActive 
                  ? AppColors.primary 
                  : widget.backgroundColor ?? AppColors.white,
              showBorder: !widget.isActive && !_isFocused,
              child: Center(
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: _isFocused 
                      ? AppColors.primary
                      : (widget.iconColor ?? 
                          (widget.isActive ? AppColors.black : AppColors.textPrimary)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass navigation bar item
class GlassNavItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const GlassNavItem({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.durationNormal,
        curve: AppTheme.curveSmooth,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? (activeIcon ?? icon) : icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
