import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';

/// Top-level sections inside the app shell.
enum ShellSection { home, search, favorites, downloads, libraries, settings }

extension ShellSectionData on ShellSection {
  String get label => switch (this) {
    ShellSection.home => 'Home',
    ShellSection.search => 'Search',
    ShellSection.favorites => 'Favorites',
    ShellSection.downloads => 'Downloads',
    ShellSection.libraries => 'Libraries',
    ShellSection.settings => 'Settings',
  };
}

/// Which shell section is visible plus which library (if any) is open
/// inside the Libraries section. Lives above the app so a layout swap
/// (resize across the breakpoint) never loses the user's place.
class ShellNav {
  final ShellSection section;
  final String? libraryId;
  final String? libraryName;
  final String? libraryCollectionType;

  /// Open detail pages, innermost last. Detail lives in the shell so
  /// the sidebar and bottom nav stay visible.
  final List<MediaItem> detailStack;

  const ShellNav({
    this.section = ShellSection.home,
    this.libraryId,
    this.libraryName,
    this.libraryCollectionType,
    this.detailStack = const [],
  });

  MediaItem? get detailItem => detailStack.isEmpty ? null : detailStack.last;

  ShellNav copyWith({
    ShellSection? section,
    String? Function()? libraryId,
    String? Function()? libraryName,
    List<MediaItem>? detailStack,
  }) => ShellNav(
    section: section ?? this.section,
    libraryId: libraryId != null ? libraryId() : this.libraryId,
    libraryName: libraryName != null ? libraryName() : this.libraryName,
    libraryCollectionType: libraryCollectionType,
    detailStack: detailStack ?? this.detailStack,
  );
}

class ShellNavNotifier extends Notifier<ShellNav> {
  @override
  ShellNav build() => const ShellNav();

  void select(ShellSection section) {
    state = state.copyWith(
      section: section,
      libraryId: () => null,
      libraryName: () => null,
      detailStack: const [],
    );
  }

  void openLibrary(String id, String name, {String? collectionType}) {
    state = ShellNav(
      section: ShellSection.libraries,
      libraryId: id,
      libraryName: name,
      libraryCollectionType: collectionType,
    );
  }

  void closeLibrary() {
    state = state.copyWith(libraryId: () => null, libraryName: () => null);
  }

  void openDetail(MediaItem item) {
    state = state.copyWith(detailStack: [...state.detailStack, item]);
  }

  /// Pop the current detail. With nothing left the previous section
  /// shows again.
  void closeDetail() {
    if (state.detailStack.isEmpty) return;
    state = state.copyWith(
      detailStack: state.detailStack.sublist(0, state.detailStack.length - 1),
    );
  }
}

final shellNavProvider = NotifierProvider<ShellNavNotifier, ShellNav>(
  ShellNavNotifier.new,
);
