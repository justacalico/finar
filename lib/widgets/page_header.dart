import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/text_styles.dart';
import 'widgets.dart';

/// The single title bar used at the top of every page.
/// Optional back button, a title, and optional trailing controls.
class PageHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  /// Explicit back handler for pages embedded in the shell, where the route
  /// itself cannot be popped.
  final VoidCallback? onBack;

  const PageHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Pushed routes (mobile) need a way back; the embedded shell is the root
    // route so canPop stays false there.
    final canPop = onBack != null || Navigator.canPop(context);

    return GlassContainer(
      blur: AppTheme.blurLight,
      opacity: 0.05,
      borderRadius: 0,
      showBorder: false,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
