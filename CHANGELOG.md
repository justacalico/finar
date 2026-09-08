# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.1.1] - 2025-07-24

### Changed
- Unified LibraryPage so movies, TV shows, music and all other libraries share the same page shell. The header now shows the actual library name with the same style on every topic; only the content body below changes based on collectionType. Music keeps its Albums/Tracks/Artists tabs.
- Settings is now a proper section of the main navigation instead of a separate pushed page. On desktop it opens in the sidebar content area like Home, Search and Favorites, and on mobile it is a bottom navigation tab. The app bar gear icon now jumps to that tab.
- Downloads is now an in-shell section on desktop: the sidebar Downloads item swaps the main content area instead of pushing a separate route. DownloadsPage still shows a back button when pushed from elsewhere.
- Non-home sections (search, favorites, downloads, settings, libraries) no longer wait for home data to load before rendering.
- Fixed ListTile ink splashes being invisible inside settings cards

### Fixed
- Fixed build issues for macOS

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
