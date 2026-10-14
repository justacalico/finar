import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ga.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'GB'),
    Locale('ga'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en_GB, this message translates to:
  /// **'Finar'**
  String get appTitle;

  /// No description provided for @connectToServer.
  ///
  /// In en_GB, this message translates to:
  /// **'Connect to a server'**
  String get connectToServer;

  /// No description provided for @connectSubtitle.
  ///
  /// In en_GB, this message translates to:
  /// **'Enter the address of your Jellyfin server.'**
  String get connectSubtitle;

  /// No description provided for @serverUrl.
  ///
  /// In en_GB, this message translates to:
  /// **'Server address'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en_GB, this message translates to:
  /// **'https://jellyfin.example.com'**
  String get serverUrlHint;

  /// No description provided for @connect.
  ///
  /// In en_GB, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connecting.
  ///
  /// In en_GB, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @couldNotReachServer.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not reach a Jellyfin server at that address.'**
  String get couldNotReachServer;

  /// No description provided for @invalidServerUrl.
  ///
  /// In en_GB, this message translates to:
  /// **'Enter a valid server address.'**
  String get invalidServerUrl;

  /// No description provided for @signIn.
  ///
  /// In en_GB, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signInAs.
  ///
  /// In en_GB, this message translates to:
  /// **'Sign in as {name}'**
  String signInAs(Object name);

  /// No description provided for @quickConnect.
  ///
  /// In en_GB, this message translates to:
  /// **'Quick Connect'**
  String get quickConnect;

  /// No description provided for @username.
  ///
  /// In en_GB, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en_GB, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @usernameRequired.
  ///
  /// In en_GB, this message translates to:
  /// **'Enter your username.'**
  String get usernameRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en_GB, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @signInFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Sign in failed.'**
  String get signInFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en_GB, this message translates to:
  /// **'Invalid username or password.'**
  String get invalidCredentials;

  /// No description provided for @quickConnectCode.
  ///
  /// In en_GB, this message translates to:
  /// **'Quick Connect code'**
  String get quickConnectCode;

  /// No description provided for @waitingForApproval.
  ///
  /// In en_GB, this message translates to:
  /// **'Approve this sign in on another Jellyfin device.'**
  String get waitingForApproval;

  /// No description provided for @quickConnectUnavailable.
  ///
  /// In en_GB, this message translates to:
  /// **'Quick Connect is not enabled on this server.'**
  String get quickConnectUnavailable;

  /// No description provided for @back.
  ///
  /// In en_GB, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en_GB, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en_GB, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In en_GB, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @ok.
  ///
  /// In en_GB, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en_GB, this message translates to:
  /// **'Something went wrong.'**
  String get error;

  /// No description provided for @whoIsWatching.
  ///
  /// In en_GB, this message translates to:
  /// **'Who\'s watching?'**
  String get whoIsWatching;

  /// No description provided for @addAccount.
  ///
  /// In en_GB, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @switchProfile.
  ///
  /// In en_GB, this message translates to:
  /// **'Switch profile'**
  String get switchProfile;

  /// No description provided for @removeProfile.
  ///
  /// In en_GB, this message translates to:
  /// **'Remove profile'**
  String get removeProfile;

  /// No description provided for @home.
  ///
  /// In en_GB, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en_GB, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @libraries.
  ///
  /// In en_GB, this message translates to:
  /// **'Libraries'**
  String get libraries;

  /// No description provided for @search.
  ///
  /// In en_GB, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In en_GB, this message translates to:
  /// **'Favourites'**
  String get favorites;

  /// No description provided for @downloads.
  ///
  /// In en_GB, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @settings.
  ///
  /// In en_GB, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @continueWatching.
  ///
  /// In en_GB, this message translates to:
  /// **'Continue watching'**
  String get continueWatching;

  /// No description provided for @nextUp.
  ///
  /// In en_GB, this message translates to:
  /// **'Next up'**
  String get nextUp;

  /// No description provided for @latest.
  ///
  /// In en_GB, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @latestIn.
  ///
  /// In en_GB, this message translates to:
  /// **'Latest in {name}'**
  String latestIn(Object name);

  /// No description provided for @myMedia.
  ///
  /// In en_GB, this message translates to:
  /// **'My media'**
  String get myMedia;

  /// No description provided for @seeAll.
  ///
  /// In en_GB, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @play.
  ///
  /// In en_GB, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @resume.
  ///
  /// In en_GB, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @markPlayed.
  ///
  /// In en_GB, this message translates to:
  /// **'Mark as watched'**
  String get markPlayed;

  /// No description provided for @markUnplayed.
  ///
  /// In en_GB, this message translates to:
  /// **'Mark as unwatched'**
  String get markUnplayed;

  /// No description provided for @favourite.
  ///
  /// In en_GB, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @unfavourite.
  ///
  /// In en_GB, this message translates to:
  /// **'Remove from favourites'**
  String get unfavourite;

  /// No description provided for @download.
  ///
  /// In en_GB, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloaded.
  ///
  /// In en_GB, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloading.
  ///
  /// In en_GB, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @share.
  ///
  /// In en_GB, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @moreOptions.
  ///
  /// In en_GB, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @seasons.
  ///
  /// In en_GB, this message translates to:
  /// **'Seasons'**
  String get seasons;

  /// No description provided for @seasonNumber.
  ///
  /// In en_GB, this message translates to:
  /// **'Season {number}'**
  String seasonNumber(Object number);

  /// No description provided for @episodes.
  ///
  /// In en_GB, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// No description provided for @episodeCount.
  ///
  /// In en_GB, this message translates to:
  /// **'{count} episodes'**
  String episodeCount(Object count);

  /// No description provided for @cast.
  ///
  /// In en_GB, this message translates to:
  /// **'Cast'**
  String get cast;

  /// No description provided for @similar.
  ///
  /// In en_GB, this message translates to:
  /// **'More like this'**
  String get similar;

  /// No description provided for @overview.
  ///
  /// In en_GB, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @genres.
  ///
  /// In en_GB, this message translates to:
  /// **'Genres'**
  String get genres;

  /// No description provided for @tracks.
  ///
  /// In en_GB, this message translates to:
  /// **'Tracks'**
  String get tracks;

  /// No description provided for @album.
  ///
  /// In en_GB, this message translates to:
  /// **'Album'**
  String get album;

  /// No description provided for @artist.
  ///
  /// In en_GB, this message translates to:
  /// **'Artist'**
  String get artist;

  /// No description provided for @series.
  ///
  /// In en_GB, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @movie.
  ///
  /// In en_GB, this message translates to:
  /// **'Movie'**
  String get movie;

  /// No description provided for @episode.
  ///
  /// In en_GB, this message translates to:
  /// **'Episode'**
  String get episode;

  /// No description provided for @music.
  ///
  /// In en_GB, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @noResults.
  ///
  /// In en_GB, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @searchHint.
  ///
  /// In en_GB, this message translates to:
  /// **'Search your libraries'**
  String get searchHint;

  /// No description provided for @emptyLibrary.
  ///
  /// In en_GB, this message translates to:
  /// **'This library is empty.'**
  String get emptyLibrary;

  /// No description provided for @emptyFavourites.
  ///
  /// In en_GB, this message translates to:
  /// **'No favourites yet. Tap the heart on something you love.'**
  String get emptyFavourites;

  /// No description provided for @emptyDownloads.
  ///
  /// In en_GB, this message translates to:
  /// **'No downloads yet.'**
  String get emptyDownloads;

  /// No description provided for @startSearch.
  ///
  /// In en_GB, this message translates to:
  /// **'Type to search your Jellyfin libraries.'**
  String get startSearch;

  /// No description provided for @appearance.
  ///
  /// In en_GB, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In en_GB, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @system.
  ///
  /// In en_GB, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en_GB, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en_GB, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @oled.
  ///
  /// In en_GB, this message translates to:
  /// **'OLED'**
  String get oled;

  /// No description provided for @accentColour.
  ///
  /// In en_GB, this message translates to:
  /// **'Accent colour'**
  String get accentColour;

  /// No description provided for @language.
  ///
  /// In en_GB, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemDefault.
  ///
  /// In en_GB, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @account.
  ///
  /// In en_GB, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signedInAs.
  ///
  /// In en_GB, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(Object name);

  /// No description provided for @server.
  ///
  /// In en_GB, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @serverVersion.
  ///
  /// In en_GB, this message translates to:
  /// **'Server version {version}'**
  String serverVersion(Object version);

  /// No description provided for @signOut.
  ///
  /// In en_GB, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @about.
  ///
  /// In en_GB, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en_GB, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @checkForUpdates.
  ///
  /// In en_GB, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en_GB, this message translates to:
  /// **'Checking…'**
  String get checkingForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en_GB, this message translates to:
  /// **'You\'re up to date.'**
  String get upToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en_GB, this message translates to:
  /// **'Version {version} is available.'**
  String updateAvailable(Object version);

  /// No description provided for @updateCheckFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Could not check for updates.'**
  String get updateCheckFailed;

  /// No description provided for @viewRelease.
  ///
  /// In en_GB, this message translates to:
  /// **'View release'**
  String get viewRelease;

  /// No description provided for @allReleases.
  ///
  /// In en_GB, this message translates to:
  /// **'All releases'**
  String get allReleases;

  /// No description provided for @pause.
  ///
  /// In en_GB, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @seekBack.
  ///
  /// In en_GB, this message translates to:
  /// **'Back 10 seconds'**
  String get seekBack;

  /// No description provided for @seekForward.
  ///
  /// In en_GB, this message translates to:
  /// **'Forward 10 seconds'**
  String get seekForward;

  /// No description provided for @subtitles.
  ///
  /// In en_GB, this message translates to:
  /// **'Subtitles'**
  String get subtitles;

  /// No description provided for @audio.
  ///
  /// In en_GB, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @playbackSpeed.
  ///
  /// In en_GB, this message translates to:
  /// **'Playback speed'**
  String get playbackSpeed;

  /// No description provided for @queue.
  ///
  /// In en_GB, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @nowPlaying.
  ///
  /// In en_GB, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @noSubtitles.
  ///
  /// In en_GB, this message translates to:
  /// **'No subtitles'**
  String get noSubtitles;

  /// No description provided for @off.
  ///
  /// In en_GB, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @filter.
  ///
  /// In en_GB, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filterAll.
  ///
  /// In en_GB, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @unwatched.
  ///
  /// In en_GB, this message translates to:
  /// **'Unwatched'**
  String get unwatched;

  /// No description provided for @watched.
  ///
  /// In en_GB, this message translates to:
  /// **'Watched'**
  String get watched;

  /// No description provided for @sortBy.
  ///
  /// In en_GB, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortName.
  ///
  /// In en_GB, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortDateAdded.
  ///
  /// In en_GB, this message translates to:
  /// **'Date added'**
  String get sortDateAdded;

  /// No description provided for @sortRating.
  ///
  /// In en_GB, this message translates to:
  /// **'Rating'**
  String get sortRating;

  /// No description provided for @sortReleaseDate.
  ///
  /// In en_GB, this message translates to:
  /// **'Release date'**
  String get sortReleaseDate;

  /// No description provided for @ascending.
  ///
  /// In en_GB, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en_GB, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @items.
  ///
  /// In en_GB, this message translates to:
  /// **'{count} items'**
  String items(Object count);

  /// No description provided for @deleteDownload.
  ///
  /// In en_GB, this message translates to:
  /// **'Delete download'**
  String get deleteDownload;

  /// No description provided for @cancelDownload.
  ///
  /// In en_GB, this message translates to:
  /// **'Cancel download'**
  String get cancelDownload;

  /// No description provided for @unknownArtist.
  ///
  /// In en_GB, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @minimize.
  ///
  /// In en_GB, this message translates to:
  /// **'Minimise'**
  String get minimize;

  /// No description provided for @maximise.
  ///
  /// In en_GB, this message translates to:
  /// **'Maximise'**
  String get maximise;

  /// No description provided for @restore.
  ///
  /// In en_GB, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @close.
  ///
  /// In en_GB, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @privacyPolicy.
  ///
  /// In en_GB, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @sourceCode.
  ///
  /// In en_GB, this message translates to:
  /// **'Source code'**
  String get sourceCode;

  /// No description provided for @licenses.
  ///
  /// In en_GB, this message translates to:
  /// **'Licences'**
  String get licenses;

  /// No description provided for @played.
  ///
  /// In en_GB, this message translates to:
  /// **'Watched'**
  String get played;

  /// No description provided for @notPlayed.
  ///
  /// In en_GB, this message translates to:
  /// **'Unwatched'**
  String get notPlayed;

  /// No description provided for @loading.
  ///
  /// In en_GB, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @offline.
  ///
  /// In en_GB, this message translates to:
  /// **'You\'re offline. Check your connection.'**
  String get offline;

  /// No description provided for @featured.
  ///
  /// In en_GB, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @playFromStart.
  ///
  /// In en_GB, this message translates to:
  /// **'Play from start'**
  String get playFromStart;

  /// No description provided for @downloadComplete.
  ///
  /// In en_GB, this message translates to:
  /// **'Download finished'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en_GB, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @clearQueue.
  ///
  /// In en_GB, this message translates to:
  /// **'Clear queue'**
  String get clearQueue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ga', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'GB':
            return AppLocalizationsEnGb();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ga':
      return AppLocalizationsGa();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
