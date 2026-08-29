import 'package:flutter/material.dart';
import 'package:finar/core/services/controller_service.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/theme/colors.dart';

class DetailFocusableDownloadProgress extends StatefulWidget {
  final double progress;
  final VoidCallback onPressed;

  const DetailFocusableDownloadProgress({
    super.key,
    required this.progress,
    required this.onPressed,
  });

  @override
  State<DetailFocusableDownloadProgress> createState() =>
      _DetailFocusableDownloadProgressState();
}

class _DetailFocusableDownloadProgressState
    extends State<DetailFocusableDownloadProgress> {
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
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!ControllerService.isKeyDown(event)) {
      return KeyEventResult.ignored;
    }

    final action = ControllerService.getAction(event);
    if (action == ControllerAction.select) {
      widget.onPressed();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.durationFast,
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isFocused
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.divider.withValues(alpha: 0.5),
              width: _isFocused ? 2 : 1,
            ),
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  value: widget.progress,
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: AppColors.divider,
                ),
              ),
              Icon(
                Icons.pause_rounded,
                size: 18,
                color: _isFocused
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
