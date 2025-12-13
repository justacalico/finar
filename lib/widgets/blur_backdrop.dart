import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/app_theme.dart';

/// A backdrop blur widget that can be used behind content
class BlurBackdrop extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? color;
  final double opacity;

  const BlurBackdrop({
    super.key,
    required this.child,
    this.blur = AppTheme.blurMedium,
    this.color,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          color: (color ?? AppColors.black).withValues(alpha: opacity),
          child: child,
        ),
      ),
    );
  }
}

/// Animated blur backdrop with fade transition
class AnimatedBlurBackdrop extends StatelessWidget {
  final Widget child;
  final bool isVisible;
  final double blur;
  final Color? color;
  final double opacity;
  final Duration duration;
  final VoidCallback? onTap;

  const AnimatedBlurBackdrop({
    super.key,
    required this.child,
    required this.isVisible,
    this.blur = AppTheme.blurMedium,
    this.color,
    this.opacity = 0.5,
    this.duration = AppTheme.durationNormal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      child: isVisible
          ? GestureDetector(
              onTap: onTap,
              child: BlurBackdrop(
                blur: blur,
                color: color,
                opacity: opacity,
                child: child,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Gradient blur backdrop for hero sections
class GradientBlurBackdrop extends StatelessWidget {
  final String? imageUrl;
  final Widget child;
  final double blur;
  final List<Color>? gradientColors;
  final List<double>? gradientStops;

  const GradientBlurBackdrop({
    super.key,
    this.imageUrl,
    required this.child,
    this.blur = AppTheme.blurHeavy,
    this.gradientColors,
    this.gradientStops,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image with blur
        if (imageUrl != null && imageUrl!.isNotEmpty)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blur,
                sigmaY: blur,
                tileMode: TileMode.clamp,
              ),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, ___) => Container(
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        
        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors ?? [
                  AppColors.black.withValues(alpha: 0.3),
                  AppColors.black.withValues(alpha: 0.5),
                  AppColors.background,
                ],
                stops: gradientStops ?? const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Content
        child,
      ],
    );
  }
}

/// A frosted glass effect overlay
class FrostedOverlay extends StatelessWidget {
  final double blur;
  final Color tintColor;
  final double tintOpacity;
  final BorderRadius? borderRadius;

  const FrostedOverlay({
    super.key,
    this.blur = AppTheme.blurMedium,
    this.tintColor = AppColors.white,
    this.tintOpacity = 0.1,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = BackdropFilter(
      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        color: tintColor.withValues(alpha: tintOpacity),
      ),
    );

    if (borderRadius != null) {
      content = ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    } else {
      content = ClipRect(child: content);
    }

    return content;
  }
}

/// Vignette effect for images
class VignetteOverlay extends StatelessWidget {
  final double intensity;
  final Color color;

  const VignetteOverlay({
    super.key,
    this.intensity = 0.5,
    this.color = AppColors.black,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.transparent,
              color.withValues(alpha: intensity),
            ],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 100,
    this.borderRadius = AppTheme.radiusMd,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                widget.baseColor ?? AppColors.shimmerBase,
                widget.highlightColor ?? AppColors.shimmerHighlight,
                widget.baseColor ?? AppColors.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Particle effect for special moments
class ParticleEffect extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double maxSize;
  final Duration duration;

  const ParticleEffect({
    super.key,
    this.particleCount = 20,
    this.particleColor = AppColors.primary,
    this.maxSize = 8,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            progress: _controller.value,
            particleCount: widget.particleCount,
            particleColor: widget.particleColor,
            maxSize: widget.maxSize,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final int particleCount;
  final Color particleColor;
  final double maxSize;

  _ParticlePainter({
    required this.progress,
    required this.particleCount,
    required this.particleColor,
    required this.maxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final seed = i / particleCount;
      final particleProgress = (progress + seed) % 1.0;
      
      final x = size.width * ((seed * 3.7) % 1.0);
      final y = size.height * (1 - particleProgress);
      final opacity = (1 - particleProgress) * 0.8;
      final particleSize = maxSize * (1 - particleProgress * 0.5);

      paint.color = particleColor.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
