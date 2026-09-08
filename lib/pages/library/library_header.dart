import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../widgets/widgets.dart';

/// Shared header used by every library page.
/// The only thing that changes between libraries is the title (the library name).
class LibraryHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const LibraryHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    // Pushed library routes (mobile) need a way back; the embedded desktop
    // shell is the root route so canPop stays false there.
    final canPop = Navigator.canPop(context);

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
              onPressed: () => Navigator.pop(context),
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
