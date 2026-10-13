// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'landing_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Finar';

  @override
  String get tagline => 'Современный клиент Jellyfin';

  @override
  String get heroSubtitle =>
      'Фильмы, сериалы и музыка с вашего сервера — красиво на любом устройстве.';

  @override
  String get openWebApp => 'Открыть веб-версию';

  @override
  String get download => 'Скачать';

  @override
  String get downloads => 'Загрузки';

  @override
  String get latestVersion => 'Последний релиз';

  @override
  String get releasesOnGitLab => 'Все релизы на GitLab';

  @override
  String get screenshots => 'Скриншоты';

  @override
  String get featureMedia => 'Ваши медиа в порядке';

  @override
  String get featureMediaBody =>
      'Библиотеки, продолжение просмотра, далее и новинки — сразу при открытии.';

  @override
  String get featurePlay => 'Играйте что угодно';

  @override
  String get featurePlayBody =>
      'Прямое воспроизведение видео и музыки: субтитры, аудиодорожки, скорость и отчёт о прогрессе.';

  @override
  String get featureEverywhere => 'Везде';

  @override
  String get featureEverywhereBody =>
      'Android, iOS, Linux, Windows, macOS и веб. Одна кодовая база, одинаковый опыт.';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get loadingReleases => 'Загрузка релизов…';

  @override
  String get releasesUnavailable => 'Релизы доступны на GitLab.';

  @override
  String get builtWith => 'Создано для Jellyfin';

  @override
  String get sourceCode => 'Исходный код';
}
