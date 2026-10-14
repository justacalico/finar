// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Finar';

  @override
  String get connectToServer => 'Connect to a server';

  @override
  String get connectSubtitle => 'Enter the address of your Jellyfin server.';

  @override
  String get serverUrl => 'Server address';

  @override
  String get serverUrlHint => 'https://jellyfin.example.com';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String get couldNotReachServer =>
      'Could not reach a Jellyfin server at that address.';

  @override
  String get invalidServerUrl => 'Enter a valid server address.';

  @override
  String get signIn => 'Sign in';

  @override
  String signInAs(Object name) {
    return 'Sign in as $name';
  }

  @override
  String get quickConnect => 'Quick Connect';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get usernameRequired => 'Enter your username.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get signInFailed => 'Sign in failed.';

  @override
  String get invalidCredentials => 'Invalid username or password.';

  @override
  String get quickConnectCode => 'Quick Connect code';

  @override
  String get waitingForApproval =>
      'Approve this sign in on another Jellyfin device.';

  @override
  String get quickConnectUnavailable =>
      'Quick Connect is not enabled on this server.';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get done => 'Done';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Something went wrong.';

  @override
  String get whoIsWatching => 'Who\'s watching?';

  @override
  String get addAccount => 'Add account';

  @override
  String get switchProfile => 'Switch profile';

  @override
  String get removeProfile => 'Remove profile';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get libraries => 'Libraries';

  @override
  String get search => 'Search';

  @override
  String get favorites => 'Favourites';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Settings';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String get nextUp => 'Next up';

  @override
  String get latest => 'Latest';

  @override
  String latestIn(Object name) {
    return 'Latest in $name';
  }

  @override
  String get myMedia => 'My media';

  @override
  String get seeAll => 'See all';

  @override
  String get play => 'Play';

  @override
  String get resume => 'Resume';

  @override
  String get markPlayed => 'Mark as watched';

  @override
  String get markUnplayed => 'Mark as unwatched';

  @override
  String get favourite => 'Favourite';

  @override
  String get unfavourite => 'Remove from favourites';

  @override
  String get download => 'Download';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloading => 'Downloading…';

  @override
  String get share => 'Share';

  @override
  String get moreOptions => 'More options';

  @override
  String get seasons => 'Seasons';

  @override
  String seasonNumber(Object number) {
    return 'Season $number';
  }

  @override
  String get episodes => 'Episodes';

  @override
  String episodeCount(Object count) {
    return '$count episodes';
  }

  @override
  String get cast => 'Cast';

  @override
  String get similar => 'More like this';

  @override
  String get overview => 'Overview';

  @override
  String get genres => 'Genres';

  @override
  String get tracks => 'Tracks';

  @override
  String get album => 'Album';

  @override
  String get artist => 'Artist';

  @override
  String get series => 'Series';

  @override
  String get movie => 'Movie';

  @override
  String get episode => 'Episode';

  @override
  String get music => 'Music';

  @override
  String get noResults => 'No results found.';

  @override
  String get searchHint => 'Search your libraries';

  @override
  String get emptyLibrary => 'This library is empty.';

  @override
  String get emptyFavourites =>
      'No favourites yet. Tap the heart on something you love.';

  @override
  String get emptyDownloads => 'No downloads yet.';

  @override
  String get startSearch => 'Type to search your Jellyfin libraries.';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get oled => 'OLED';

  @override
  String get accentColour => 'Accent colour';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System';

  @override
  String get account => 'Account';

  @override
  String signedInAs(Object name) {
    return 'Signed in as $name';
  }

  @override
  String get server => 'Server';

  @override
  String serverVersion(Object version) {
    return 'Server version $version';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingForUpdates => 'Checking…';

  @override
  String get upToDate => 'You\'re up to date.';

  @override
  String updateAvailable(Object version) {
    return 'Version $version is available.';
  }

  @override
  String get updateCheckFailed => 'Could not check for updates.';

  @override
  String get viewRelease => 'View release';

  @override
  String get allReleases => 'All releases';

  @override
  String get pause => 'Pause';

  @override
  String get seekBack => 'Back 10 seconds';

  @override
  String get seekForward => 'Forward 10 seconds';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get audio => 'Audio';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get queue => 'Queue';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get noSubtitles => 'No subtitles';

  @override
  String get off => 'Off';

  @override
  String get filter => 'Filter';

  @override
  String get filterAll => 'All';

  @override
  String get unwatched => 'Unwatched';

  @override
  String get watched => 'Watched';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortName => 'Name';

  @override
  String get sortDateAdded => 'Date added';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortReleaseDate => 'Release date';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String items(Object count) {
    return '$count items';
  }

  @override
  String get deleteDownload => 'Delete download';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get minimize => 'Minimise';

  @override
  String get maximise => 'Maximise';

  @override
  String get restore => 'Restore';

  @override
  String get close => 'Close';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get sourceCode => 'Source code';

  @override
  String get licenses => 'Licences';

  @override
  String get played => 'Watched';

  @override
  String get notPlayed => 'Unwatched';

  @override
  String get loading => 'Loading…';

  @override
  String get offline => 'You\'re offline. Check your connection.';

  @override
  String get featured => 'Featured';

  @override
  String get playFromStart => 'Play from start';

  @override
  String get downloadComplete => 'Download finished';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get clearQueue => 'Clear queue';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get appTitle => 'Finar';

  @override
  String get connectToServer => 'Connect to a server';

  @override
  String get connectSubtitle => 'Enter the address of your Jellyfin server.';

  @override
  String get serverUrl => 'Server address';

  @override
  String get serverUrlHint => 'https://jellyfin.example.com';

  @override
  String get connect => 'Connect';

  @override
  String get connecting => 'Connecting…';

  @override
  String get couldNotReachServer =>
      'Could not reach a Jellyfin server at that address.';

  @override
  String get invalidServerUrl => 'Enter a valid server address.';

  @override
  String get signIn => 'Sign in';

  @override
  String signInAs(Object name) {
    return 'Sign in as $name';
  }

  @override
  String get quickConnect => 'Quick Connect';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get usernameRequired => 'Enter your username.';

  @override
  String get passwordRequired => 'Enter your password.';

  @override
  String get signInFailed => 'Sign in failed.';

  @override
  String get invalidCredentials => 'Invalid username or password.';

  @override
  String get quickConnectCode => 'Quick Connect code';

  @override
  String get waitingForApproval =>
      'Approve this sign in on another Jellyfin device.';

  @override
  String get quickConnectUnavailable =>
      'Quick Connect is not enabled on this server.';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get done => 'Done';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Something went wrong.';

  @override
  String get whoIsWatching => 'Who\'s watching?';

  @override
  String get addAccount => 'Add account';

  @override
  String get switchProfile => 'Switch profile';

  @override
  String get removeProfile => 'Remove profile';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get libraries => 'Libraries';

  @override
  String get search => 'Search';

  @override
  String get favorites => 'Favourites';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Settings';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String get nextUp => 'Next up';

  @override
  String get latest => 'Latest';

  @override
  String latestIn(Object name) {
    return 'Latest in $name';
  }

  @override
  String get myMedia => 'My media';

  @override
  String get seeAll => 'See all';

  @override
  String get play => 'Play';

  @override
  String get resume => 'Resume';

  @override
  String get markPlayed => 'Mark as watched';

  @override
  String get markUnplayed => 'Mark as unwatched';

  @override
  String get favourite => 'Favourite';

  @override
  String get unfavourite => 'Remove from favourites';

  @override
  String get download => 'Download';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get downloading => 'Downloading…';

  @override
  String get share => 'Share';

  @override
  String get moreOptions => 'More options';

  @override
  String get seasons => 'Seasons';

  @override
  String seasonNumber(Object number) {
    return 'Season $number';
  }

  @override
  String get episodes => 'Episodes';

  @override
  String episodeCount(Object count) {
    return '$count episodes';
  }

  @override
  String get cast => 'Cast';

  @override
  String get similar => 'More like this';

  @override
  String get overview => 'Overview';

  @override
  String get genres => 'Genres';

  @override
  String get tracks => 'Tracks';

  @override
  String get album => 'Album';

  @override
  String get artist => 'Artist';

  @override
  String get series => 'Series';

  @override
  String get movie => 'Movie';

  @override
  String get episode => 'Episode';

  @override
  String get music => 'Music';

  @override
  String get noResults => 'No results found.';

  @override
  String get searchHint => 'Search your libraries';

  @override
  String get emptyLibrary => 'This library is empty.';

  @override
  String get emptyFavourites =>
      'No favourites yet. Tap the heart on something you love.';

  @override
  String get emptyDownloads => 'No downloads yet.';

  @override
  String get startSearch => 'Type to search your Jellyfin libraries.';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get oled => 'OLED';

  @override
  String get accentColour => 'Accent colour';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System';

  @override
  String get account => 'Account';

  @override
  String signedInAs(Object name) {
    return 'Signed in as $name';
  }

  @override
  String get server => 'Server';

  @override
  String serverVersion(Object version) {
    return 'Server version $version';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checkingForUpdates => 'Checking…';

  @override
  String get upToDate => 'You\'re up to date.';

  @override
  String updateAvailable(Object version) {
    return 'Version $version is available.';
  }

  @override
  String get updateCheckFailed => 'Could not check for updates.';

  @override
  String get viewRelease => 'View release';

  @override
  String get allReleases => 'All releases';

  @override
  String get pause => 'Pause';

  @override
  String get seekBack => 'Back 10 seconds';

  @override
  String get seekForward => 'Forward 10 seconds';

  @override
  String get subtitles => 'Subtitles';

  @override
  String get audio => 'Audio';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get queue => 'Queue';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get noSubtitles => 'No subtitles';

  @override
  String get off => 'Off';

  @override
  String get filter => 'Filter';

  @override
  String get filterAll => 'All';

  @override
  String get unwatched => 'Unwatched';

  @override
  String get watched => 'Watched';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortName => 'Name';

  @override
  String get sortDateAdded => 'Date added';

  @override
  String get sortRating => 'Rating';

  @override
  String get sortReleaseDate => 'Release date';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String items(Object count) {
    return '$count items';
  }

  @override
  String get deleteDownload => 'Delete download';

  @override
  String get cancelDownload => 'Cancel download';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get minimize => 'Minimise';

  @override
  String get maximise => 'Maximise';

  @override
  String get restore => 'Restore';

  @override
  String get close => 'Close';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get sourceCode => 'Source code';

  @override
  String get licenses => 'Licences';

  @override
  String get played => 'Watched';

  @override
  String get notPlayed => 'Unwatched';

  @override
  String get loading => 'Loading…';

  @override
  String get offline => 'You\'re offline. Check your connection.';

  @override
  String get featured => 'Featured';

  @override
  String get playFromStart => 'Play from start';

  @override
  String get downloadComplete => 'Download finished';

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get clearQueue => 'Clear queue';
}
