import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import 'glass_container.dart';

class WindowTitleBar extends StatelessWidget {
  static const double _height = 44;

  const WindowTitleBar({super.key});

  static Future<void> _toggleMaximize() async {
    final maximized = await windowManager.isMaximized();
    if (maximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: 0,
      showBorder: false,
      height: _height,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: _TrafficLights(onToggleMaximize: _toggleMaximize),
          ),
          Expanded(
            child: DragToMoveArea(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'icon.svg',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Finar',
                      style: AppTextStyles.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 74),
        ],
      ),
    );
  }
}

class _TrafficLights extends StatefulWidget {
  final VoidCallback onToggleMaximize;

  const _TrafficLights({required this.onToggleMaximize});

  @override
  State<_TrafficLights> createState() => _TrafficLightsState();
}

class _TrafficLightsState extends State<_TrafficLights> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        children: [
          _TrafficLight(
            color: const Color(0xFFFF5F57),
            icon: Icons.close,
            tooltip: 'Close',
            showGlyph: _hovered,
            onTap: windowManager.close,
          ),
          _TrafficLight(
            color: const Color(0xFFFEBC2E),
            icon: Icons.remove,
            tooltip: 'Minimize',
            showGlyph: _hovered,
            onTap: windowManager.minimize,
          ),
          _TrafficLight(
            color: const Color(0xFF28C840),
            icon: Icons.add,
            tooltip: 'Zoom',
            showGlyph: _hovered,
            onTap: widget.onToggleMaximize,
          ),
        ],
      ),
    );
  }
}

class _TrafficLight extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String tooltip;
  final bool showGlyph;
  final VoidCallback onTap;

  const _TrafficLight({
    required this.color,
    required this.icon,
    required this.tooltip,
    required this.showGlyph,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.black.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Visibility(
                visible: showGlyph,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Icon(
                  icon,
                  size: 9,
                  color: AppColors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
