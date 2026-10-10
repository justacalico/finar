import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/colors.dart';
import '../core/theme/text_styles.dart';
import 'glass_container.dart';

class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({super.key});

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  static const double _height = 44;

  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _toggleMaximize() async {
    final maximized = await windowManager.isMaximized();
    if (maximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    if (mounted) {
      setState(() => _isMaximized = !maximized);
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
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'icon.svg',
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Finar',
                      style: AppTextStyles.titleSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _WindowCaptionButton(
            icon: Icons.remove_rounded,
            tooltip: 'Minimize',
            onPressed: windowManager.minimize,
          ),
          _WindowCaptionButton(
            icon: _isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            tooltip: _isMaximized ? 'Restore' : 'Maximize',
            onPressed: _toggleMaximize,
          ),
          _WindowCaptionButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            isClose: true,
            onPressed: windowManager.close,
          ),
        ],
      ),
    );
  }
}

class _WindowCaptionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowCaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: isClose
              ? const Color(0xFFC42B1C)
              : AppColors.white.withValues(alpha: 0.08),
          child: SizedBox(
            width: 46,
            height: double.infinity,
            child: Icon(
              icon,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
