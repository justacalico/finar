import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Top-level sections of the main shell.
///
/// The same enum drives the mobile bottom navigation and the desktop
/// sidebar. Because the selection lives in [shellNavProvider] instead of
/// inside the layout widgets, resizing the window across the
/// mobile/desktop breakpoint keeps the user on the same section instead of
/// jumping back to home.
enum ShellSection { home, search, favorites, library, downloads, settings }

class ShellNavState {
  const ShellNavState({this.section = ShellSection.home, this.libraryId});

  /// The selected top-level section.
  final ShellSection section;

  /// The open library while [section] is [ShellSection.library], else null.
  final String? libraryId;
}

class ShellNavNotifier extends StateNotifier<ShellNavState> {
  ShellNavNotifier() : super(const ShellNavState());

  /// Selects a top-level section and leaves any open library.
  void goTo(ShellSection section) {
    if (state.section == section && state.libraryId == null) return;
    state = ShellNavState(section: section);
  }

  /// Opens a library inside the shell instead of pushing a route.
  void openLibrary(String libraryId) {
    state = ShellNavState(
      section: ShellSection.library,
      libraryId: libraryId,
    );
  }

  /// Leaves the open library and returns to the library browser.
  void closeLibrary() {
    if (state.libraryId == null) return;
    state = const ShellNavState(section: ShellSection.library);
  }
}

final shellNavProvider =
    StateNotifierProvider<ShellNavNotifier, ShellNavState>(
      (ref) => ShellNavNotifier(),
    );
