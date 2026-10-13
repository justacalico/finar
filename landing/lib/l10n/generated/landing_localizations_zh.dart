// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'landing_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Finar';

  @override
  String get tagline => '现代化 Jellyfin 客户端';

  @override
  String get heroSubtitle => '来自你自己服务器的电影、剧集和音乐,在任何设备上精美呈现。';

  @override
  String get openWebApp => '打开网页版';

  @override
  String get download => '下载';

  @override
  String get downloads => '下载';

  @override
  String get latestVersion => '最新版本';

  @override
  String get releasesOnGitLab => 'GitLab 上的所有版本';

  @override
  String get screenshots => '截图';

  @override
  String get featureMedia => '你的媒体,井井有条';

  @override
  String get featureMediaBody => '媒体库、继续观看、接下来以及最新内容,打开应用即刻呈现。';

  @override
  String get featurePlay => '随心播放';

  @override
  String get featurePlayBody => '视频和音乐直接播放,支持字幕、音轨、倍速以及服务端播放进度上报。';

  @override
  String get featureEverywhere => '无处不在';

  @override
  String get featureEverywhereBody =>
      'Android、iOS、Linux、Windows、macOS 和网页。一套代码,一致体验。';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeOled => 'OLED';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get loadingReleases => '正在加载版本…';

  @override
  String get releasesUnavailable => '版本可在 GitLab 上获取。';

  @override
  String get builtWith => '为 Jellyfin 打造';

  @override
  String get sourceCode => '源代码';
}
