// coverage:ignore-file
// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Finar';

  @override
  String get connectToServer => '连接服务器';

  @override
  String get connectSubtitle => '输入你的 Jellyfin 服务器地址。';

  @override
  String get serverUrl => '服务器地址';

  @override
  String get serverUrlHint => 'https://jellyfin.example.com';

  @override
  String get connect => '连接';

  @override
  String get connecting => '正在连接…';

  @override
  String get couldNotReachServer => '无法连接到该地址的 Jellyfin 服务器。';

  @override
  String get invalidServerUrl => '请输入有效的服务器地址。';

  @override
  String get signIn => '登录';

  @override
  String signInAs(Object name) {
    return '以 $name 登录';
  }

  @override
  String get quickConnect => '快速连接';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get usernameRequired => '请输入用户名。';

  @override
  String get passwordRequired => '请输入密码。';

  @override
  String get signInFailed => '登录失败。';

  @override
  String get invalidCredentials => '用户名或密码错误。';

  @override
  String get quickConnectCode => '快速连接码';

  @override
  String get waitingForApproval => '请在另一台 Jellyfin 设备上批准此登录。';

  @override
  String get quickConnectUnavailable => '此服务器未启用快速连接。';

  @override
  String get back => '返回';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get done => '完成';

  @override
  String get ok => '确定';

  @override
  String get error => '出现问题。';

  @override
  String get whoIsWatching => '谁在观看?';

  @override
  String get addAccount => '添加账户';

  @override
  String get switchProfile => '切换用户';

  @override
  String get removeProfile => '移除用户';

  @override
  String get home => '首页';

  @override
  String get library => '媒体库';

  @override
  String get libraries => '媒体库';

  @override
  String get search => '搜索';

  @override
  String get favorites => '收藏';

  @override
  String get downloads => '下载';

  @override
  String get settings => '设置';

  @override
  String get continueWatching => '继续观看';

  @override
  String get nextUp => '接下来';

  @override
  String get latest => '最新';

  @override
  String latestIn(Object name) {
    return '$name 最新内容';
  }

  @override
  String get myMedia => '我的媒体';

  @override
  String get seeAll => '查看全部';

  @override
  String get play => '播放';

  @override
  String get resume => '继续播放';

  @override
  String get markPlayed => '标记为已观看';

  @override
  String get markUnplayed => '标记为未观看';

  @override
  String get favourite => '收藏';

  @override
  String get unfavourite => '取消收藏';

  @override
  String get download => '下载';

  @override
  String get downloaded => '已下载';

  @override
  String get downloading => '正在下载…';

  @override
  String get share => '分享';

  @override
  String get moreOptions => '更多选项';

  @override
  String get seasons => '季';

  @override
  String seasonNumber(Object number) {
    return '第 $number 季';
  }

  @override
  String get episodes => '剧集';

  @override
  String episodeCount(Object count) {
    return '$count 集';
  }

  @override
  String get cast => '演员';

  @override
  String get similar => '相似推荐';

  @override
  String get overview => '简介';

  @override
  String get genres => '类型';

  @override
  String get tracks => '曲目';

  @override
  String get album => '专辑';

  @override
  String get artist => '艺术家';

  @override
  String get series => '剧集';

  @override
  String get movie => '电影';

  @override
  String get episode => '单集';

  @override
  String get music => '音乐';

  @override
  String get noResults => '未找到结果。';

  @override
  String get searchHint => '搜索你的媒体库';

  @override
  String get emptyLibrary => '此媒体库为空。';

  @override
  String get emptyFavourites => '还没有收藏。点击喜欢的内容上的心形图标即可收藏。';

  @override
  String get emptyDownloads => '还没有下载内容。';

  @override
  String get startSearch => '输入关键词搜索 Jellyfin 媒体库。';

  @override
  String get appearance => '外观';

  @override
  String get themeMode => '主题';

  @override
  String get system => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get oled => 'OLED';

  @override
  String get accentColour => '主题色';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get account => '账户';

  @override
  String signedInAs(Object name) {
    return '已登录为 $name';
  }

  @override
  String get server => '服务器';

  @override
  String serverVersion(Object version) {
    return '服务器版本 $version';
  }

  @override
  String get signOut => '退出登录';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get checkingForUpdates => '正在检查…';

  @override
  String get upToDate => '已是最新版本。';

  @override
  String updateAvailable(Object version) {
    return '版本 $version 可用。';
  }

  @override
  String get updateCheckFailed => '无法检查更新。';

  @override
  String get viewRelease => '查看发布';

  @override
  String get allReleases => '所有发布';

  @override
  String get pause => '暂停';

  @override
  String get seekBack => '后退 10 秒';

  @override
  String get seekForward => '前进 10 秒';

  @override
  String get subtitles => '字幕';

  @override
  String get audio => '音频';

  @override
  String get playbackSpeed => '播放速度';

  @override
  String get queue => '播放队列';

  @override
  String get nowPlaying => '正在播放';

  @override
  String get noSubtitles => '无字幕';

  @override
  String get off => '关';

  @override
  String get filter => '筛选';

  @override
  String get filterAll => '全部';

  @override
  String get unwatched => '未观看';

  @override
  String get watched => '已观看';

  @override
  String get sortBy => '排序方式';

  @override
  String get sortName => '名称';

  @override
  String get sortDateAdded => '添加日期';

  @override
  String get sortRating => '评分';

  @override
  String get sortReleaseDate => '上映日期';

  @override
  String get ascending => '升序';

  @override
  String get descending => '降序';

  @override
  String items(Object count) {
    return '$count 个项目';
  }

  @override
  String get deleteDownload => '删除下载';

  @override
  String get cancelDownload => '取消下载';

  @override
  String get unknownArtist => '未知艺术家';

  @override
  String get minimize => '最小化';

  @override
  String get maximise => '最大化';

  @override
  String get restore => '还原';

  @override
  String get close => '关闭';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get sourceCode => '源代码';

  @override
  String get licenses => '许可证';

  @override
  String get played => '已观看';

  @override
  String get notPlayed => '未观看';

  @override
  String get loading => '加载中…';

  @override
  String get offline => '你已离线,请检查网络连接。';

  @override
  String get featured => '推荐';

  @override
  String get playFromStart => '从头播放';

  @override
  String get downloadComplete => '下载完成';

  @override
  String get downloadFailed => '下载失败';

  @override
  String get clearQueue => '清空队列';
}
