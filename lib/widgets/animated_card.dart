import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import '../core/theme/app_theme.dart';
import 'blur_backdrop.dart';

/// Animated media card with hover and tap effects
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
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveAspectRatio = widget.isLandscape ? 16 / 9 : widget.aspectRatio;

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
        if (widget.showProgress && widget.progress != null)
          _buildProgressBar(),
        
        // Badge
        if (widget.badge != null)
          Positioned(
            top: 8,
            right: 8,
            child: widget.badge!,
          ),
        
        // Custom overlay
        if (widget.overlay != null) widget.overlay!,
        
        // Hover glow effect
        AnimatedOpacity(
          opacity: _isHovered ? 1.0 : 0.0,
          duration: AppTheme.durationFast,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
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
          : AspectRatio(
              aspectRatio: effectiveAspectRatio,
              child: cardContent,
            ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.03 : 1.0),
          duration: AppTheme.durationFast,
          curve: AppTheme.curveSmooth,
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: _isHovered ? AppTheme.shadowMedium : AppTheme.shadowSmall,
            ),
            child: card,
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
      return Container(
        color: AppColors.surface,
        child: const Center(
          child: Icon(
            Icons.movie_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => const ShimmerLoading(),
      errorWidget: (context, url, error) => Container(
        color: AppColors.surface,
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
        ),
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

/// Hero card for featured content
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
  });

  @override
  State<HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<HeroCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (widget.imageUrl != null)
              CachedNetworkImage(
                imageUrl: widget.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.surface,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surface,
                ),
              ),
            
            // Gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.imageOverlayFull,
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
                  if (widget.genres != null || widget.year != null || widget.runtime != null)
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
                          ...widget.genres!.take(2).map(
                                (g) => _MetadataBadge(text: g),
                              ),
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
                  
                  // Action buttons
                  Row(
                    children: [
                      if (widget.onPlay != null)
                        ElevatedButton.icon(
                          onPressed: widget.onPlay,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                        ),
                      if (widget.onPlay != null && widget.onInfo != null)
                        const SizedBox(width: 12),
                      if (widget.onInfo != null)
                        OutlinedButton.icon(
                          onPressed: widget.onInfo,
                          icon: const Icon(Icons.info_outline),
                          label: const Text('More Info'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color? color;

  const _MetadataBadge({
    this.icon,
    required this.text,
    this.color,
  });

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
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('See All'),
                ),
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
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (context, index) => SizedBox(
              width: 130,
              child: cards[index],
            ),
          ),
        ),
      ],
    );
  }
}
