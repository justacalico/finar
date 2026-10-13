import 'package:flutter/material.dart';

class SectionRow extends StatelessWidget {
  const SectionRow({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel,
    required this.children,
    this.trailing,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              ?trailing,
              if (onSeeAll != null && seeAllLabel != null)
                TextButton(
                    onPressed: onSeeAll, child: Text(seeAllLabel!)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 235,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (_, i) => children[i],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
