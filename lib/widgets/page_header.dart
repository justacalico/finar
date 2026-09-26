import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shared page title bar used by every section and pushed page so the
/// top of every screen is identical.
class PageHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? below;

  const PageHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.showBack = false,
    this.onBack,
    this.below,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: EdgeInsets.fromLTRB(Insets.sm, Insets.sm, Insets.sm, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack || canPop)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                )
              else
                SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              ...actions,
            ],
          ),
          if (below != null) below!,
        ],
      ),
    );
  }
}
