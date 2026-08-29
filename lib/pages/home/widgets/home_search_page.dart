import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../providers/providers.dart';
import '../../../widgets/widgets.dart';
import '../../detail.dart';

class MobileSearchPage extends ConsumerStatefulWidget {
  const MobileSearchPage();

  @override
  ConsumerState<MobileSearchPage> createState() => MobileSearchPageState();
}

class MobileSearchPageState extends ConsumerState<MobileSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';

    return SafeArea(
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search movies, shows, people...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(libraryProvider.notifier).clearSearch();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  ref.read(libraryProvider.notifier).search(value);
                }
              },
            ),
          ),

          // Results
          Expanded(
            child: searchResults.isEmpty
                ? _buildEmptySearch()
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2 / 3.3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: false,
                    cacheExtent: 1000,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      return AnimatedCard(
                        imageUrl: item.getDisplayImageUrl(
                          serverUrl,
                          width: 200,
                        ),
                        title: item.name,
                        subtitle: item.productionYear?.toString(),
                        isWatched: item.isPlayed == true,
                        enableEntranceAnimation: false,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailPage(itemId: item.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Search your media',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find movies, TV shows, and more',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
