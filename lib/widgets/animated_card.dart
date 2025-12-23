import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/theme/app_theme.dart';
import '../core/services/controller_service.dart';
import 'blur_backdrop.dart';

/// Animated media card with hover, tap, and controller/focus support
class AnimatedCard extends StatefulWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final double? progress;
  final bool showProgress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double aspectRatio;
  final bool isLandscape;
  final Widget? badge;
  final Widget? overlay;
  final int animationIndex;
  final double? width;
  final double? height;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool isWatched;

  const AnimatedCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.progress,
    this.showProgress = false,
    this.onTap,
    this.onLongPress,
    this.aspectRatio = 2 / 3,
    this.isLandscape = false,
    this.badge,
    this.overlay,
    this.animationIndex = 0,
    this.width,
    this.height,
    this.autofocus = false,
    this.focusNode,
    this.isWatched = false,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isHovered = false;
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
      // Ensure the focused item is visible in scrollable containers
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
    if (action == ControllerAction.select) {
      setState(() => _isPressed = true);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        }
      });
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAspectRatio = widget.isLandscape
        ? 16 / 9
        : widget.aspectRatio;
    final isHighlighted = _isHovered || _isFocused;

    Widget cardContent = Stack(
      fit: StackFit.expand,
      children: [
        // Image
        _buildImage(),

        // Gradient overlay
        _buildGradientOverlay(),

        // Content overlay
        _buildContentOverlay(),

        // Progress bar
        if (widget.showProgress && widget.progress != null) _buildProgressBar(),

        // Badge
        if (widget.badge != null)
          Positioned(top: 8, right: 8, child: widget.badge!),

        // Custom overlay
        if (widget.overlay != null) widget.overlay!,

        // Hover/Focus glow effect
        AnimatedOpacity(
          opacity: isHighlighted ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFocused
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.5),
                width: _isFocused ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: widget.width != null
          ? SizedBox(
              width: widget.width,
              child: AspectRatio(
                aspectRatio: effectiveAspectRatio,
                child: cardContent,
              ),
            )
          : AspectRatio(aspectRatio: effectiveAspectRatio, child: cardContent),
    );

    return Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onKeyEvent: _handleKeyEvent,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              onLongPress: widget.onLongPress,
              child: AnimatedScale(
                scale: _isPressed ? 0.95 : (isHighlighted ? 1.03 : 1.0),
                duration: AppTheme.durationFast,
                curve: AppTheme.curveSmooth,
                child: Container(
                  width: widget.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: isHighlighted
                        ? AppTheme.shadowMedium
                        : AppTheme.shadowSmall,
                  ),
                  child: card,
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: widget.animationIndex * 50),
          duration: AppTheme.durationNormal,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: widget.animationIndex * 50),
          duration: AppTheme.durationNormal,
          curve: AppTheme.curveSmooth,
        );
  }

  Widget _buildImage() {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return const _PlaceholderIcon(icon: Icons.movie_outlined);
    }

    return RepaintBoundary(
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 400, // Limit memory cache size for better performance
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => const ShimmerLoading(),
        errorWidget: (context, url, error) =>
            const _PlaceholderIcon(icon: Icons.broken_image_outlined),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              AppColors.black.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContentOverlay() {
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: AppTextStyles.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.subtitle!,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: LinearProgressIndicator(
        value: widget.progress,
        backgroundColor: AppColors.black.withValues(alpha: 0.5),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        minHeight: 3,
      ),
    );
  }
}

/// Hero card for featured content with controller/focus support
class HeroCard extends StatefulWidget {
  final String? imageUrl;
  final String title;
  final String? subtitle;
  final String? description;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onInfo;
  final double height;
  final List<String>? genres;
  final String? rating;
  final String? year;
  final String? runtime;
  final bool autofocus;
  final FocusNode? focusNode;

  const HeroCard({
    super.key,
    this.imageUrl,
    required this.title,
    this.subtitle,
    this.description,
    this.onTap,
    this.onPlay,
    this.onInfo,
    this.height = 500,
    this.genres,
    this.rating,
    this.year,
    this.runtime,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  bool _isFocused = false;
  late FocusNode _focusNode;
  int _focusedButtonIndex = 0;

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
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);

    switch (action) {
      case ControllerAction.select:
        if (_focusedButtonIndex == 0) {
          widget.onPlay?.call();
        } else {
          widget.onInfo?.call();
        }
        return KeyEventResult.handled;
      case ControllerAction.left:
        if (_focusedButtonIndex > 0) {
          setState(() => _focusedButtonIndex--);
          return KeyEventResult.handled;
        }
        break;
      case ControllerAction.right:
        final buttonCount =
            (widget.onPlay != null ? 1 : 0) + (widget.onInfo != null ? 1 : 0);
        if (_focusedButtonIndex < buttonCount - 1) {
          setState(() => _focusedButtonIndex++);
          return KeyEventResult.handled;
        }
        break;
      default:
        break;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          decoration: BoxDecoration(
            border: _isFocused
                ? Border.all(color: AppColors.primary, width: 3)
                : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: SizedBox(
            height: widget.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  if (widget.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: AppColors.surface),
                      errorWidget: (context, url, error) =>
                          Container(color: AppColors.surface),
                    ),

                  // Gradient overlay
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.imageOverlayFull,
                    ),
                  ),

                  // Focus glow effect
                  if (_isFocused)
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),

                  // Content
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Metadata row
                        if (widget.genres != null ||
                            widget.year != null ||
                            widget.runtime != null)
                          Wrap(
                            spacing: 8,
                            children: [
                              if (widget.rating != null)
                                _MetadataBadge(
                                  icon: Icons.star,
                                  text: widget.rating!,
                                  color: AppColors.accentYellow,
                                ),
                              if (widget.year != null)
                                _MetadataBadge(text: widget.year!),
                              if (widget.runtime != null)
                                _MetadataBadge(text: widget.runtime!),
                              if (widget.genres != null)
                                ...widget.genres!
                                    .take(2)
                                    .map((g) => _MetadataBadge(text: g)),
                            ],
                          ),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          widget.title,
                          style: AppTextStyles.hero,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle!,
                            style: AppTextStyles.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        if (widget.description != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.description!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Action buttons with focus indicators
                        Row(
                          children: [
                            if (widget.onPlay != null)
                              _FocusableHeroButton(
                                isFocused:
                                    _isFocused && _focusedButtonIndex == 0,
                                isPrimary: true,
                                icon: Icons.play_arrow,
                                label: 'Play',
                                onPressed: widget.onPlay!,
                              ),
                            if (widget.onPlay != null && widget.onInfo != null)
                              const SizedBox(width: 12),
                            if (widget.onInfo != null)
                              _FocusableHeroButton(
                                isFocused:
                                    _isFocused &&
                                    _focusedButtonIndex ==
                                        (widget.onPlay != null ? 1 : 0),
                                isPrimary: false,
                                icon: Icons.info_outline,
                                label: 'More Info',
                                onPressed: widget.onInfo!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusableHeroButton extends StatelessWidget {
  final bool isFocused;
  final bool isPrimary;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _FocusableHeroButton({
    required this.isFocused,
    required this.isPrimary,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.durationFast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: AnimatedScale(
        scale: isFocused ? 1.05 : 1.0,
        duration: AppTheme.durationFast,
        child: isPrimary
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
                style: ElevatedButton.styleFrom(
                  side: isFocused
                      ? const BorderSide(color: AppColors.white, width: 2)
                      : null,
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isFocused
                        ? AppColors.primary
                        : AppColors.white.withValues(alpha: 0.5),
                    width: isFocused ? 2 : 1,
                  ),
                ),
              ),
      ),
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color? color;

  const _MetadataBadge({this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? AppColors.textPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scroll card row
class CardRow extends StatelessWidget {
  final String title;
  final List<Widget> cards;
  final VoidCallback? onSeeAll;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const CardRow({
    super.key,
    required this.title,
    required this.cards,
    this.onSeeAll,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.headlineSmall),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('See All')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: padding,
            itemCount: cards.length,
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
            separatorBuilder: (_, _) => SizedBox(width: spacing),
            itemBuilder: (context, index) =>
                SizedBox(width: 130, child: cards[index]),
          ),
        ),
      ],
    );
  }
}

/// Optimized placeholder icon widget - const for better performance
class _PlaceholderIcon extends StatelessWidget {
  final IconData icon;

  const _PlaceholderIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(child: Icon(icon, size: 48, color: AppColors.textTertiary)),
    );
  }
}
