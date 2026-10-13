import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/library_providers.dart';
import '../../providers/session_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_card.dart';
import '../../widgets/media_image.dart';
import '../../widgets/section_row.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final libraries = ref.watch(librariesProvider).valueOrNull ?? [];
    final resume = ref.watch(resumeItemsProvider);
    final nextUp = ref.watch(nextUpProvider);
    final client = ref.watch(jellyfinClientProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(librariesProvider);
        ref.invalidate(resumeItemsProvider);
        ref.invalidate(nextUpProvider);
      },
      child: ListView(
        padding: const EdgeInsets.only(top: 12),
        children: [
          _Featured(libraries: libraries),
          resume.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) => SectionRow(
              title: l10n.continueWatching,
              children: [
                for (final item in items)
                  MediaCard(
                    item: item,
                    width: 250,
                    imageUrl: _backdropOrPrimary(client, item),
                    subtitle: _subtitle(item),
                    onTap: () => context.push('/item/${item.id}'),
                  ),
              ],
            ),
          ),
          nextUp.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) => SectionRow(
              title: l10n.nextUp,
              children: [
                for (final item in items)
                  MediaCard(
                    item: item,
                    width: 160,
                    imageUrl: client?.primaryImageUrl(item,
                        maxWidth: 320),
                    subtitle: item.seriesName,
                    onTap: () => context.push('/item/${item.id}'),
                  ),
              ],
            ),
          ),
          for (final library in libraries)
            _LatestSection(library: library),
          if (resume.hasValue &&
              (resume.valueOrNull?.isEmpty ?? true) &&
              (nextUp.valueOrNull?.isEmpty ?? true) &&
              libraries.isEmpty)
            EmptyState(
                icon: Icons.video_library_outlined,
                message: l10n.emptyLibrary),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Uri? _backdropOrPrimary(dynamic client, BaseItem item) {
    return client?.backdropImageUrl(item, maxWidth: 500) ??
        client?.primaryImageUrl(item, maxWidth: 500);
  }

  static String? _subtitle(BaseItem item) {
    if (item.seriesName != null) {
      final ep = item.indexNumber != null
          ? 'E${item.indexNumber}'
          : '';
      final season = item.parentIndexNumber != null
          ? 'S${item.parentIndexNumber}:'
          : '';
      return '${item.seriesName} $season$ep'.trim();
    }
    return item.productionYear?.toString();
  }
}

class _Featured extends ConsumerWidget {
  const _Featured({required this.libraries});

  final List<BaseItem> libraries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = libraries.isEmpty
        ? null
        : ref
            .watch(latestMediaProvider(libraries.first.id))
            .valueOrNull;
    if (latest == null || latest.isEmpty) {
      return const SizedBox.shrink();
    }
    final item = latest.first;
    final client = ref.watch(jellyfinClientProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaImage(
                url: client?.backdropImageUrl(item, maxWidth: 1200) ??
                    client?.primaryImageUrl(item, maxWidth: 1200),
                icon: Icons.movie_outlined,
                borderRadius: 0,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 28,
                bottom: 24,
                right: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.featured.toUpperCase(),
                        style: TextStyle(
                            color: scheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6)),
                    const SizedBox(height: 6),
                    Text(item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.productionYear != null)
                          _MetaChip(label: '${item.productionYear}'),
                        if (item.communityRating != null)
                          _MetaChip(
                              icon: Icons.star,
                              label: item.communityRating!
                                  .toStringAsFixed(1)),
                        if (item.runTimeTicks != null)
                          _MetaChip(
                              label: formatTicks(item.runTimeTicks!)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () =>
                          context.push('/item/${item.id}'),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(item.userData.playbackPositionTicks >
                              0
                          ? l10n.resume
                          : l10n.play),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LatestSection extends ConsumerWidget {
  const _LatestSection({required this.library});

  final BaseItem library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final latest = ref.watch(latestMediaProvider(library.id));
    final client = ref.watch(jellyfinClientProvider);
    return latest.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => SectionRow(
        title: l10n.latestIn(library.name),
        seeAllLabel: l10n.seeAll,
        onSeeAll: () => context.go('/library/${library.id}'),
        children: [
          for (final item in items)
            MediaCard(
              item: item,
              width: 160,
              imageUrl:
                  client?.primaryImageUrl(item, maxWidth: 320),
              subtitle: item.seriesName ??
                  item.productionYear?.toString(),
              onTap: () => context.push('/item/${item.id}'),
            ),
        ],
      ),
    );
  }
}
