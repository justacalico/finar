import 'package:flutter/material.dart';
import 'package:finar/core/services/controller_service.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/widgets/widgets.dart';

class DetailFocusableActionButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final bool autofocus;

  const DetailFocusableActionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height = 54,
    this.backgroundColor,
    this.autofocus = false,
  });

  @override
  State<DetailFocusableActionButton> createState() =>
      _DetailFocusableActionButtonState();
}

class _DetailFocusableActionButtonState
    extends State<DetailFocusableActionButton> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
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
    if (action == ControllerAction.select) {
      widget.onPressed?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final hasBgColor = widget.backgroundColor != null;
    final borderRadius = BorderRadius.circular(14);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: hasBgColor
              ? Container(
                  width: widget.width,
                  height: widget.height,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: _isFocused
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: _isFocused ? 2 : 1,
                    ),
                  ),
                  child: Center(child: widget.child),
                )
              : GlassContainer(
                  blur: AppTheme.blurLight,
                  opacity: _isFocused ? 0.16 : 0.1,
                  borderRadius: 14,
                  borderColor: _isFocused
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.9)
                      : AppColors.glassBorder.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: Center(child: widget.child),
                  ),
                ),
        ),
      ),
    );
  }
}
