import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'landing_localizations_en.dart';
import 'landing_localizations_ga.dart';
import 'landing_localizations_ru.dart';
import 'landing_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/landing_localizations.dart';
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

  /// No description provided for @tagline.
  ///
  /// In en_GB, this message translates to:
  /// **'A modern Jellyfin client'**
  String get tagline;

  /// No description provided for @heroSubtitle.
  ///
  /// In en_GB, this message translates to:
  /// **'Films, series and music from your own server — beautifully presented on every device.'**
  String get heroSubtitle;

  /// No description provided for @openWebApp.
  ///
  /// In en_GB, this message translates to:
  /// **'Open web app'**
  String get openWebApp;

  /// No description provided for @download.
  ///
  /// In en_GB, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloads.
  ///
  /// In en_GB, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @latestVersion.
  ///
  /// In en_GB, this message translates to:
  /// **'Latest release'**
  String get latestVersion;

  /// No description provided for @releasesOnGitLab.
  ///
  /// In en_GB, this message translates to:
  /// **'All releases on GitLab'**
  String get releasesOnGitLab;

  /// No description provided for @screenshots.
  ///
  /// In en_GB, this message translates to:
  /// **'Screenshots'**
  String get screenshots;

  /// No description provided for @featureMedia.
  ///
  /// In en_GB, this message translates to:
  /// **'Your media, organised'**
  String get featureMedia;

  /// No description provided for @featureMediaBody.
  ///
  /// In en_GB, this message translates to:
  /// **'Libraries, continue watching, next up and the latest additions — surfaced the moment you open the app.'**
  String get featureMediaBody;

  /// No description provided for @featurePlay.
  ///
  /// In en_GB, this message translates to:
  /// **'Play anything'**
  String get featurePlay;

  /// No description provided for @featurePlayBody.
  ///
  /// In en_GB, this message translates to:
  /// **'Direct-play video and music with subtitles, audio tracks, playback speed and server-side progress reporting.'**
  String get featurePlayBody;

  /// No description provided for @featureEverywhere.
  ///
  /// In en_GB, this message translates to:
  /// **'Everywhere'**
  String get featureEverywhere;

  /// No description provided for @featureEverywhereBody.
  ///
  /// In en_GB, this message translates to:
  /// **'Android, iOS, Linux, Windows, macOS and the web. One codebase, one consistent experience.'**
  String get featureEverywhereBody;

  /// No description provided for @themeSystem.
  ///
  /// In en_GB, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en_GB, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en_GB, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeOled.
  ///
  /// In en_GB, this message translates to:
  /// **'OLED'**
  String get themeOled;

  /// No description provided for @language.
  ///
  /// In en_GB, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en_GB, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @loadingReleases.
  ///
  /// In en_GB, this message translates to:
  /// **'Loading releases…'**
  String get loadingReleases;

  /// No description provided for @releasesUnavailable.
  ///
  /// In en_GB, this message translates to:
  /// **'Releases are on GitLab.'**
  String get releasesUnavailable;

  /// No description provided for @builtWith.
  ///
  /// In en_GB, this message translates to:
  /// **'Built for Jellyfin'**
  String get builtWith;

  /// No description provided for @sourceCode.
  ///
  /// In en_GB, this message translates to:
  /// **'Source code'**
  String get sourceCode;
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
