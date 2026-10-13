import 'package:flutter/material.dart';

import '../core/constants.dart';
import 'platform.dart';

abstract class WindowActions {
  Future<void> minimize();
  Future<void> maximizeOrRestore();
  Future<void> close();
  Future<bool> isMaximized();
  void dragMove();
}

class TitleBar extends StatelessWidget implements PreferredSizeWidget {
  const TitleBar({super.key, this.actions, this.leading});

  final WindowActions? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: preferredSize.height,
      color: scheme.surface,
      child: Row(
        children: [
          const SizedBox(width: 12),
          if (isDesktopPlatform) ...[
            _TrafficLight(
              color: const Color(0xFFFF5F57),
              icon: Icons.close,
              tooltip: 'close',
              onTap: () => actions?.close(),
            ),
            const SizedBox(width: 8),
            _TrafficLight(
              color: const Color(0xFFFEBC2E),
              icon: Icons.remove,
              tooltip: 'minimize',
              onTap: () => actions?.minimize(),
            ),
            const SizedBox(width: 8),
            _TrafficLight(
              color: const Color(0xFF28C840),
              icon: Icons.add,
              tooltip: 'maximize',
              onTap: () => actions?.maximizeOrRestore(),
            ),
            const SizedBox(width: 12),
          ],
          ?leading,
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () => actions?.maximizeOrRestore(),
              onPanStart: (_) => actions?.dragMove(),
              child: Center(
                child: Text(
                  kAppName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 84),
        ],
      ),
    );
  }
}

class _TrafficLight extends StatefulWidget {
  const _TrafficLight(
      {required this.color,
      required this.icon,
      required this.tooltip,
      this.onTap});

  final Color color;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<_TrafficLight> createState() => _TrafficLightState();
}

class _TrafficLightState extends State<_TrafficLight> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Tooltip(
          message: widget.tooltip,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: _hover
                ? Icon(widget.icon, size: 10, color: Colors.black87)
                : null,
          ),
        ),
      ),
    );
  }
}
