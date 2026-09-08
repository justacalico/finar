import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/providers.dart';
import '../../library/library_page.dart';
import 'home_library_list_card.dart';

class MobileLibraryBrowser extends ConsumerWidget {
  const MobileLibraryBrowser();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    final libraries = libraryState.libraries;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Library',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your collections',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (libraryState.isLoading && libraries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (libraryState.error != null && libraries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Couldn\'t load libraries',
                        style: AppTextStyles.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        libraryState.error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final library = libraries[index];
                  final accentColor = _getLibraryAccentColor(
                    library.collectionType,
                  );
                  return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LibraryListCard(
                          library: library,
                          accentColor: accentColor,
                          icon: _getLibraryIcon(library.collectionType),
                          typeLabel: _getLibraryTypeLabel(
                            library.collectionType,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LibraryPage(libraryId: library.id),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50))
                      .slideX(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
                }, childCount: libraries.length),
              ),
            ),
        ],
      ),
    );
  }

  Color _getLibraryAccentColor(String? collectionType) {
    switch (collectionType) {
      case 'movies':
        return const Color(0xFFE53935);
      case 'tvshows':
        return const Color(0xFF1E88E5);
      case 'music':
        return const Color(0xFF43A047);
      case 'photos':
        return const Color(0xFFFF9800);
      default:
        return AppColors.secondary;
    }
  }

  String _getLibraryTypeLabel(String? collectionType) {
    switch (collectionType) {
      case 'movies':
        return 'Movies';
      case 'tvshows':
        return 'TV Shows';
      case 'music':
        return 'Music';
      case 'photos':
        return 'Photos';
      default:
        return 'Collection';
    }
  }

  IconData _getLibraryIcon(String? collectionType) {
    switch (collectionType) {
      case 'movies':
        return Icons.movie_outlined;
      case 'tvshows':
        return Icons.tv_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'photos':
        return Icons.photo_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
