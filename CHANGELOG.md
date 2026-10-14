# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [6.0.0] - 2026-10-13

### Added
- Complete rewrite of the app as a modern Jellyfin client: server connect with URL normalisation, password and Quick Connect sign in, and a saved-profiles picker.
- Home page with a featured hero, continue watching, next up and per-library latest rows.
- Library browser with sort, watch-state filters and genre filtering plus infinite scroll.
- Detail pages for movies, series, episodes, albums and artists with cast, seasons, tracks and similar items.
- Video and music playback via media_kit with subtitle/audio track selection, playback speed, a queue, and Jellyfin playback progress reporting.
- Offline downloads with progress tracking.
- Search, favourites, settings (theme, accent colour, language) and an in-app check-for-updates backed by GitLab Releases.
- Desktop builds get a custom macOS-style title bar and a wide row-list sidebar; mobile gets a bottom navigation bar.
- Full localisation: Traditional English, Simplified Chinese, Russian and Irish.
- Golden screenshot tests for every page plus unit and widget tests.
- A Flutter Web landing page at `landing/` with theme picker, feature showcase and downloads pulled straight from GitLab Releases, deployed by a new `pages` CI job.

### Removed
- Removed the entire old Flutter app: all Dart code under `lib/`, the full test suite, every platform runner (android, ios, linux, macos, web, windows), and the old project's pubspec, lockfile, analysis options, launcher icon, and distribute config.

### Changed
- Server connect screen: an inline https:// / http:// dropdown replaces the server icon in the address field, and Who's watching is now a tonal button that greys out when no accounts are saved.

### Fixed
- Title bar traffic-light buttons no longer crash in debug builds: they used `Tooltip` above the Navigator's Overlay and now expose `Semantics` labels instead.
- Who's watching with no saved accounts no longer dead-ends: stale data from 5.x installs is cleared and the app routes to the server connect screen, where the server URL field lives.

## [5.0.0] - 2026-10-10

### Added
- Golden screenshot tests for every page and screen across desktop and mobile layouts, with vendored test fonts, a fake HTTP layer for image widgets, and committed reference images regenerated via `flutter test --update-goldens`.

### Changed
- Replaced the OS window title bar with a custom in-app title bar on desktop (Linux, Windows, macOS). The new bar shows the app icon and name, supports drag-to-move and double-click to maximize, and provides minimize, maximize/restore and close buttons.
- Redesigned the login page: the form now lives in a centered card over an ambient glow background, the protocol dropdown became an inline https/http toggle inside the server field, fields show prefix icons, errors display in a styled banner, and Sign In uses the theme gradient. The Quick Connect view uses the same card layout.
- Login is now two stages: first enter the server URL and connect to it, then sign in with username and password or Quick Connect. A back button on the second stage returns to change the server.
- Moved the desktop sidebar Settings button out of the scrolling libraries list into the pinned bottom section above the collapse toggle, so it stays visible no matter how long the library list is.
- Split oversized pages into per-section widgets: desktop home, desktop and mobile detail pages, mobile home, the music and general libraries, and downloads. Shared play, trailer, favorite, watchlist, download and share actions now live in `core/utils/media_actions.dart` instead of being copy pasted per page.
- Replaced the deprecated `cacheExtent` parameter with `scrollCacheExtent` and `ReorderableListView.onReorder` with `onReorderItem`, added missing widget keys and const constructors, and wrapped bare if bodies in braces. `flutter analyze` now reports zero issues.
- Replaced the broken lowercase `claude.md` pointer with a `CLAUDE.md` symlink to AGENTS.md.

### Removed
- Removed the redundant subtitle and audio track buttons from the desktop player controls. Both opened the same settings panel as the settings button, so only the settings button remains.
- Removed the fullscreen button from the desktop player top bar. It only toggled a system UI mode that does nothing inside a desktop window, so the button and the dead F key and double-tap fullscreen shortcuts are gone.

### Fixed
- Fixed the user profile picture in the sidebar being cropped and zoomed in. The avatar now scales the whole image to fit inside the rounded square instead of cutting off the edges.
- Quick Connect timeout timer is now cancelled when leaving the code view instead of firing later.
- Fixed the login page jumping back to the server stage after connecting or after a failed sign in. Connecting and signing in no longer swap the whole app to the splash screen, which unmounted the page and reset its stage.
- A 400 response during sign in now shows "Invalid username or password" instead of "Server returned an error (400)", and error banners show the server's own message when it sends one.
- Fixed login failing with a 400 on Jellyfin 10.11 servers: requests now send the `Authorization` header alongside `X-Emby-Authorization`, which 10.11 no longer accepts.
- Fixed Switch profile in desktop settings navigating with a popped context, which could crash and prevented the result snackbar from ever showing.
- Fixed reordering items in the play queue placing them one slot too high when dragging downwards. Both the queue view and the player provider adjusted the target index, so the correction was applied twice.
- Fixed See All on the desktop home tab doing nothing and leaking the expanded category into Search and Favorites. It now expands into a grid and returns to the previous view.
- Fixed the mobile detail page creating and disposing a TabController that was never used.

## [4.2.0] - 2026-09-29

### Fixed
- Windows CI build failing on the media_kit download checksum.
- Desktop About page showing the OS version wrapped onto a second line.
- About page source code icon not following the theme accent colour.
- Various release pipeline fixes: runner tags, shell runner compatibility, sync refspec and clone depth, and prerelease/restricted trigger handling.

## [4.1.1] - 2025-07-24

### Added
- GitLab -> GitHub -> GitLab release CI: automated builds for Android, Linux, Windows, macOS and iOS, signed Android releases, nightly/versioned GitHub releases, and GitLab release mirroring.
- Coverage filtering and script tests for the release pipeline.
- CI runs now stamp the pubspec version with the run number (e.g. 4.1.1+42) so every artifact reports which CI run built it.

### Changed
- Unified the page title bar: Settings, Downloads, Library, Search and Favorites now share the same `PageHeader` (glass bar, `headlineMedium` title, back button only on pushed routes) on desktop and mobile. `LibraryHeader` was generalised into `PageHeader` under `lib/widgets`.
- Release CI jobs now install `gh`, `glab` and `jq` as binaries under `~/.local/bin` so they work on shell runners without a package manager.
- Made the entire colour palette reactive: `AppColors` now derives background, surface, text, glass and primary colours from the active theme mode, theme style, theme colour and accent colour. Light mode, OLED and Coloured styles now actually change the UI.
- `AppTextStyles` and `AppTheme` now use the reactive `AppColors` so switching theme mode or style updates text and Material theme data.
- `FinarApp` now reads the full appearance settings and syncs `AppColors` before building `MaterialApp`. Theme colour, accent colour, theme style, theme mode and `useSystemAccent` are all wired into the rendered theme.
- Unified LibraryPage so movies, TV shows, music and all other libraries share the same page shell. The header now shows the actual library name with the same style on every topic; only the content body below changes based on collectionType. Music keeps its Albums/Tracks/Artists tabs.
- Library pages now use a single unified top bar: the shared `LibraryHeader` contains the library name and that topic's controls (search, sort, view or refresh). There is no longer a separate second header row.
- Settings is now a proper section of the main navigation instead of a separate pushed page. On desktop it opens in the sidebar content area like Home, Search and Favorites, and on mobile it is a bottom navigation tab. The app bar gear icon now jumps to that tab.
- Downloads is now an in-shell section on desktop: the sidebar Downloads item swaps the main content area instead of pushing a separate route. DownloadsPage still shows a back button when pushed from elsewhere.
- Non-home sections (search, favorites, downloads, settings, libraries) no longer wait for home data to load before rendering.
- Fixed ListTile ink splashes being invisible inside settings cards
- Removed the separate Theme style setting. OLED is now an option inside the Theme dropdown (System / Light / Dark / OLED) and the Coloured style was removed. Saved settings are migrated, so an OLED selection survives the update.
- Updated the mobile Library list to use the same glass card and primary accent styling as the rest of the app. Library list cards and the header now use the active theme's primary colour instead of per-library pastel colours.
- Merged "Use system accent" into the Accent colour dropdown. It is now the first option ("System") alongside the colour choices on both mobile and desktop, instead of a separate switch.

### Fixed
- Fixed desktop Settings > About showing the OS Version label and value vertically when the kernel string is too long for a `ListTile.trailing` widget. The value now uses `ListTile.subtitle` so the text wraps normally across the full tile width.
- Fixed the Source Code icon in Settings > About ignoring the accent colour: it was hardcoded to `AppColors.accentOrange` on desktop and mobile while the neighbouring icons follow the theme. It now uses `colorScheme.primary` like the rest.
- Fixed `Color.toARGB32()` serialization so subtitle colours are stored and loaded correctly.
- Fixed theme changes not repainting the whole app: `AppTextStyles` are now evaluated lazily so they pick up the active palette, and `FinarApp` forces a full tree rebuild when the appearance settings change so pages that read `AppColors` directly repaint too.
- Fixed `ThemeMode.system` not following OS brightness changes while the app is running.
- Fixed desktop settings content being vertically centered in the pane instead of starting at the top.
- Fixed unreadable card and hero text in light mode: text drawn over poster artwork now stays white instead of following the light theme's dark text color, and the mobile hero scrim is blended toward black so pale posters keep enough contrast.
- Fixed library pages on mobile having no way back: the shared library header now shows a back button whenever the route was pushed, while it stays hidden inside the desktop shell.
- Fixed mobile settings dropdowns (Sleep Timer and others) showing the selected value left-aligned inside a wide button instead of next to the arrow like the other rows.
- Fixed resizing the window across the mobile/desktop breakpoint resetting the app to home. The selected section and the open library now live in a shared `shellNavProvider`, so switching layouts keeps you exactly where you were. Desktop Favorites falls back to an in-shell mobile favorites view, and leaving a library returns to the library browser instead of home.
- Fixed the desktop layout briefly overflowing during the mobile/desktop swap: `AdaptiveLayout` no longer runs an `AnimatedSwitcher` transition, which forced the outgoing layout to be re-laid out at the new window size.
- Fixed the home feed refetching every time the mobile shell remounted (e.g. after a resize); it now only loads when there is no cached data.
- Fixed build issues for macOS
- Fixed Windows CI builds failing on media_kit's libmpv/ANGLE integrity check: the plugin's CMake download has no retry or HTTP status check, so the workflow now pre-fetches both archives with curl before `flutter build windows` runs.

## [4.1.0]

### Added
- Poster shows a watched icon if a movie or thing was already watched

### Changed
- Updated description
- Updated AI stance

### Removed
- Removed features from login page
- Removed PiP mode

## [4.0.0]

### Added
- OLED theme style with deeper blacks for dark mode
- Coloured theme style with its own theme color, separate from the accent color

### Changed
- Sidebar account card: add spacing between profile action buttons so they don't touch

### Removed
- Interface Mode setting; layout now automatically adapts to screen size

## [3.0.0]

### Added
- Who's watching? screen for multiple Jellyfin accounts (Netflix-style profile picker)
- Multiple accounts: save and switch between several server/user profiles
- Add profile and Manage profiles flows; sign out removes current profile from device
- Watchlist row on home (desktop and mobile); home data includes watchlist, invalidated when toggling from detail
- Sleep timer: Settings > Playback (Off, 15/30/45/60 min, End of current); player overlay shows remaining time and Cancel
- Theme and appearance: Settings > Appearance — Theme (System / Light / Dark), Use system accent, Accent color (Teal, Purple, Blue, Pink, Orange)

### Changed
- Unified UI: removed separate desktop/ and mobile/ page folders; single responsive pages (home, settings, detail, player, library, music_library, downloads) with sidebar on wide screens and bottom nav/single column on narrow
- Library page (mobile): list-style cards with icon, type label, and item count instead of large gradient grid
- Upgraded dependencies: dio, riverpod, flutter_riverpod, intl, package_info_plus, share_plus, gamepads; Riverpod 3 migration with legacy imports; share_plus 12 SharePlus API; AsyncValue.when for null fallbacks
- App startup: with 2+ saved profiles, Who's watching is shown instead of auto-restoring; with 1 profile, behavior unchanged
- Sidebar and Settings: Switch profile opens Who's watching; Sign out removes current profile (with confirmation)

### Fixed
- Theme and accent: theme mode (System/Light/Dark) and accent color now apply across the app; settings load before first frame so stored theme is used on launch; "Use system accent" is persisted via setUseSystemAccent
- Detail more-options sheet: Download, Share, and Media Info now work; Add to Playlist / Report Issue show "Coming soon"
- Home media card Add button adds/removes item from watchlist with SnackBar feedback
- Music library track row: favorite button toggles favorite and refreshes list
- Music player bar: Shuffle shuffles playlist and plays from start; Repeat cycles off → one → all; More shows "Coming soon" SnackBar
- Queue "Now Playing" tap triggers play/pause; library sort button no longer appears disabled
- Who's watching: show current session as a profile when saved list was empty (recovery); avoid row overflow with horizontal scroll or wrap
- Login page: hide scrollbar on form scrollables; fix contrast (solid dark form card so white text is readable); Quick Connect tip uses textSecondary for readability

## [2.0.0]

### Added
- Show TV show name - episode for header
- Span the search bar on desktop view
- Working "See All" buttons
- Move your mouse over the screen to see on-screen controls
- Hide on-screen controls after some time
- Seamless desktop/mobile view switching on resize while keeping users on the same page context (detail/player/library/downloads/settings)
- Hid server URL from the desktop sidebar profile card and show user avatar (with initials fallback)
- Made focused/hovered media card outlines adapt to each item's artwork colors instead of a fixed accent
- Implemented working trailer playback flow: play local trailers in-app, and open remote trailers via URL launcher (with robust URL normalization)

### Changed
- Don't open episode views; instead, open the TV show with the season open
- Remove extra season selector for TV shows
- Updated desktop detail "Details" panel to use liquid glass styling instead of a flat container
- Updated the desktop detail Trailer action button to use the same liquid-glass styling as other controls

### Fixed
- Fixed clipping on cards
- Fixed desktop detail clipping/overflow by making action controls wrap on smaller widths
- Fixed desktop detail action bar overflow by using a single-row horizontal action strip on narrow widths

## [1.1.0]

### Added
- Home header (logo and settings bar) scales with screen width on larger desktops

### Changed
- Offload Jellyfin API JSON parsing to background isolates (compute) to keep UI responsive
- Virtualize detail page lists: album tracks and episodes use SliverList.builder so only visible items are built
- Detail similar section is a separate widget so only that section rebuilds when similar items load
- RepaintBoundary around similar section and track list header to isolate repaints

### Fixed
- Auth screen shows error message when login, server connect, or Quick Connect fails (including errors from auth provider)
- Who's watching: when switching account fails (e.g. expired token), revert to previous session and return to Home with error SnackBar instead of staying on Who's watching
- Fixed controller input in steamOS
- Resolved RepeatMode name collision with Flutter (use finar.RepeatMode in music_player_bar)
- Home and detail headers for albums now show album art instead of artist image
- Replaced removed flutter_riverpod/legacy.dart import with flutter_riverpod.dart
- Share: use Share.share() for share_plus 10.x (SharePlus/ShareParams not in 10.1.4)
- Lint: unnecessary null check on overview, use single underscore in ref.listen callbacks

### Removed
- Legacy React app (Finar/ folder) and default iOS launch asset README

### Documentation
- README: corrected license badge to AGPL v3, clone URL to GitLab, added Privacy policy link
