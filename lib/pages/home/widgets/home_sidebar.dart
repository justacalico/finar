import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:finar/core/theme/colors.dart';
import 'package:finar/core/theme/text_styles.dart';
import 'package:finar/core/theme/app_theme.dart';
import 'package:finar/core/api/models/library.dart';
import 'package:finar/providers/providers.dart';
import 'package:finar/widgets/widgets.dart';
import '../../whos_watching_page.dart';
import 'home_widgets.dart';

ShellSection shellSectionForIndex(int index) => switch (index) {
  1 => ShellSection.search,
  2 => ShellSection.favorites,
  3 => ShellSection.downloads,
  100 => ShellSection.settings,
  _ => ShellSection.home,
};

class HomeSidebar extends ConsumerWidget {
  static const double widthExpanded = 260;
  static const double widthCollapsed = 72;
  static const double autoCollapseThreshold = 900;

  final AsyncValue<List<Library>> libraries;
  final int selectedIndex;
  final String? selectedLibraryId;
  final bool focused;
  final int focusedNavIndex;
  final bool userToggled;
  final bool userCollapsed;
  final ValueChanged<ShellSection> onSelectSection;
  final ValueChanged<bool> onCollapsedChanged;
  final VoidCallback onSignOut;

  const HomeSidebar({
    super.key,
    required this.libraries,
    required this.selectedIndex,
    required this.selectedLibraryId,
    required this.focused,
    required this.focusedNavIndex,
    required this.userToggled,
    required this.userCollapsed,
    required this.onSelectSection,
    required this.onCollapsedChanged,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final autoCollapsed = screenWidth < autoCollapseThreshold;
    final collapsed = userToggled
        ? userCollapsed
        : (autoCollapsed || userCollapsed);
    final sidebarWidth = collapsed ? widthCollapsed : widthExpanded;

    return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          width: sidebarWidth,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            border: Border(
              right: BorderSide(
                color: AppColors.divider.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: ClipRect(
            child: Column(
              children: [
                // Navigation items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      // App logo as part of sidebar content
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: collapsed ? 12 : 24,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: collapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SvgPicture.asset(
                                'icon.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (!collapsed) ...[
                              const SizedBox(width: 14),
                              Text(
                                'Finar',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      _buildNavItem(
                        context,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                        index: 0,
                        focusIndex: 0,
                        collapsed: collapsed,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.search_outlined,
                        activeIcon: Icons.search_rounded,
                        label: 'Search',
                        index: 1,
                        focusIndex: 1,
                        collapsed: collapsed,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.favorite_outline_rounded,
                        activeIcon: Icons.favorite_rounded,
                        label: 'Favorites',
                        index: 2,
                        focusIndex: 2,
                        collapsed: collapsed,
                      ),
                      if (!kIsWeb)
                        _buildNavItem(
                          context,
                          icon: Icons.download_outlined,
                          activeIcon: Icons.download_rounded,
                          label: 'Downloads',
                          index: 3,
                          focusIndex: 3,
                          collapsed: collapsed,
                        ),

                      if (!collapsed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                          child: Text(
                            'LIBRARIES',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                      libraries.when(
                        data: (libraries) => Column(
                          children: libraries
                              .asMap()
                              .entries
                              .map(
                                (entry) => _buildLibraryItem(
                                  context,
                                  ref,
                                  entry.value,
                                  entry.key + 4,
                                  collapsed: collapsed,
                                ),
                              )
                              .toList(),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: ShimmerLoading(height: 40),
                        ),
                        error: (_, _) => const SizedBox(),
                      ),
                    ],
                  ),
                ),

                if (!collapsed)
                  Divider(
                    color: AppColors.divider.withValues(alpha: 0.5),
                    indent: 16,
                    endIndent: 16,
                    height: 20,
                  ),

                _buildNavItem(
                  context,
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 100,
                  focusIndex: 100,
                  collapsed: collapsed,
                ),

                // Collapse/expand toggle
                _buildToggle(collapsed),

                // User profile
                _buildUserProfile(context, ref, collapsed: collapsed),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppTheme.durationNormal)
        .slideX(begin: -0.05, end: 0, duration: AppTheme.durationNormal);
  }

  Widget _buildToggle(bool collapsed) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 8 : 12,
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onCollapsedChanged(!collapsed),
          child: Tooltip(
            message: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    collapsed
                        ? Icons.keyboard_double_arrow_right_rounded
                        : Icons.keyboard_double_arrow_left_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 14),
                    Text(
                      'Collapse',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int? focusIndex,
    bool collapsed = false,
  }) {
    final isSelected = selectedIndex == index && selectedLibraryId == null;
    final isFocused = focused && focusedNavIndex == (focusIndex ?? index);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 8 : 12,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelectSection(shellSectionForIndex(index)),
          child: Tooltip(
            message: collapsed ? label : '',
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12)
                    : isFocused
                    ? AppColors.glassActive
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isFocused
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : isSelected
                    ? Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    isSelected ? activeIcon : icon,
                    size: 22,
                    color: isSelected || isFocused
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.textSecondary,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected || isFocused
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem(
    BuildContext context,
    WidgetRef ref,
    Library library,
    int focusIndex, {
    bool collapsed = false,
  }) {
    final isSelected = selectedLibraryId == library.id;
    final isFocused = focused && focusedNavIndex == focusIndex;
    final icon = getLibraryIcon(library.icon);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 8 : 12,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ref.read(shellNavProvider.notifier).openLibrary(library.id);
          },
          child: Tooltip(
            message: collapsed ? library.name : '',
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12)
                    : isFocused
                    ? AppColors.glassActive
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isFocused
                    ? Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.5),
                        width: 2,
                      )
                    : isSelected
                    ? Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: collapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.textSecondary,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        library.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(
    BuildContext context,
    WidgetRef ref, {
    bool collapsed = false,
  }) {
    final user = ref.watch(currentUserProvider);
    final serverUrl = ref.read(jellyfinApiProvider).serverUrl ?? '';
    final userName = user?.name.trim();
    final hasUserName = userName != null && userName.isNotEmpty;

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Tooltip(
          message: hasUserName ? userName : 'Guest',
          child: UserAvatar(user: user, serverUrl: serverUrl),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          UserAvatar(user: user, serverUrl: serverUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUserName ? userName : 'Guest',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Signed in',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final message = await Navigator.of(context).push<String?>(
                    MaterialPageRoute<String?>(
                      builder: (_) => const WhosWatchingPage(),
                    ),
                  );
                  if (message != null && messenger.mounted) {
                    messenger.showSnackBar(SnackBar(content: Text(message)));
                  }
                },
                tooltip: 'Switch profile',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  backgroundColor: AppColors.glassWhite,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20),
                onPressed: onSignOut,
                tooltip: 'Sign out',
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  backgroundColor: AppColors.glassWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
