// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Irish (`ga`).
class AppLocalizationsGa extends AppLocalizations {
  AppLocalizationsGa([String locale = 'ga']) : super(locale);

  @override
  String get appTitle => 'Finar';

  @override
  String get connectToServer => 'Ceangail le freastalaí';

  @override
  String get connectSubtitle => 'Cuir isteach seoladh do fhreastalaí Jellyfin.';

  @override
  String get serverUrl => 'Seoladh an fhreastalaí';

  @override
  String get serverUrlHint => 'https://jellyfin.example.com';

  @override
  String get connect => 'Ceangail';

  @override
  String get connecting => 'Ag ceangal…';

  @override
  String get couldNotReachServer =>
      'Níorbh fhéidir freastalaí Jellyfin a bhaint amach ag an seoladh sin.';

  @override
  String get invalidServerUrl => 'Cuir isteach seoladh bailí freastalaí.';

  @override
  String get signIn => 'Logáil isteach';

  @override
  String signInAs(Object name) {
    return 'Logáil isteach mar $name';
  }

  @override
  String get quickConnect => 'Quick Connect';

  @override
  String get username => 'Ainm úsáideora';

  @override
  String get password => 'Pasfhocal';

  @override
  String get usernameRequired => 'Cuir isteach d\'ainm úsáideora.';

  @override
  String get passwordRequired => 'Cuir isteach do phasfhocal.';

  @override
  String get signInFailed => 'Theip ar an logáil isteach.';

  @override
  String get invalidCredentials => 'Ainm úsáideora nó pasfhocal mícheart.';

  @override
  String get quickConnectCode => 'Cód Quick Connect';

  @override
  String get waitingForApproval =>
      'Ceadaigh an logáil isteach seo ar ghléas Jellyfin eile.';

  @override
  String get quickConnectUnavailable =>
      'Níl Quick Connect cumasaithe ar an bhfreastalaí seo.';

  @override
  String get back => 'Ar ais';

  @override
  String get cancel => 'Cealaigh';

  @override
  String get retry => 'Bain triail eile';

  @override
  String get done => 'Déanta';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Tharla earráid.';

  @override
  String get whoIsWatching => 'Cé atá ag breathnú?';

  @override
  String get addAccount => 'Cuir cuntas leis';

  @override
  String get switchProfile => 'Athraigh próifíl';

  @override
  String get removeProfile => 'Bain próifíl';

  @override
  String get home => 'Baile';

  @override
  String get library => 'Leabharlann';

  @override
  String get libraries => 'Leabharlanna';

  @override
  String get search => 'Cuardach';

  @override
  String get favorites => 'Ceanáin';

  @override
  String get downloads => 'Íoslódálacha';

  @override
  String get settings => 'Socruithe';

  @override
  String get continueWatching => 'Lean ort ag breathnú';

  @override
  String get nextUp => 'Ar aghaidh';

  @override
  String get latest => 'Is déanaí';

  @override
  String latestIn(Object name) {
    return 'Is déanaí i $name';
  }

  @override
  String get myMedia => 'Mo mheáin';

  @override
  String get seeAll => 'Féach ar fad';

  @override
  String get play => 'Seinn';

  @override
  String get resume => 'Lean ar aghaidh';

  @override
  String get markPlayed => 'Marcáil feicthe';

  @override
  String get markUnplayed => 'Marcáil neamhfheicthe';

  @override
  String get favourite => 'Ceanán';

  @override
  String get unfavourite => 'Bain as ceanáin';

  @override
  String get download => 'Íoslódáil';

  @override
  String get downloaded => 'Íoslódáilte';

  @override
  String get downloading => 'Ag íoslódáil…';

  @override
  String get share => 'Roinn';

  @override
  String get moreOptions => 'Tuilleadh roghanna';

  @override
  String get seasons => 'Séasúir';

  @override
  String seasonNumber(Object number) {
    return 'Séasúr $number';
  }

  @override
  String get episodes => 'Eipeasóid';

  @override
  String episodeCount(Object count) {
    return '$count eipeasóid';
  }

  @override
  String get cast => 'Foireann';

  @override
  String get similar => 'Tuilleadh mar seo';

  @override
  String get overview => 'Forbhreathnú';

  @override
  String get genres => 'Seánraí';

  @override
  String get tracks => 'Traiceanna';

  @override
  String get album => 'Albam';

  @override
  String get artist => 'Ealaíontóir';

  @override
  String get series => 'Sraith';

  @override
  String get movie => 'Scannán';

  @override
  String get episode => 'Eipeasóid';

  @override
  String get music => 'Ceol';

  @override
  String get noResults => 'Níor aimsíodh torthaí.';

  @override
  String get searchHint => 'Cuardaigh do leabharlanna';

  @override
  String get emptyLibrary => 'Tá an leabharlann seo folamh.';

  @override
  String get emptyFavourites =>
      'Níl ceanáin ar bith fós. Tapáil an croí ar rud a thaitníonn leat.';

  @override
  String get emptyDownloads => 'Níl íoslódálacha ar bith fós.';

  @override
  String get startSearch =>
      'Scríobh chun cuardach a dhéanamh ar do leabharlanna Jellyfin.';

  @override
  String get appearance => 'Cuma';

  @override
  String get themeMode => 'Téama';

  @override
  String get system => 'Córas';

  @override
  String get light => 'Geal';

  @override
  String get dark => 'Dorcha';

  @override
  String get oled => 'OLED';

  @override
  String get accentColour => 'Dath béime';

  @override
  String get language => 'Teanga';

  @override
  String get systemDefault => 'Córas';

  @override
  String get account => 'Cuntas';

  @override
  String signedInAs(Object name) {
    return 'Logáilte isteach mar $name';
  }

  @override
  String get server => 'Freastalaí';

  @override
  String serverVersion(Object version) {
    return 'Leagan freastalaí $version';
  }

  @override
  String get signOut => 'Logáil amach';

  @override
  String get about => 'Maidir leis';

  @override
  String get version => 'Leagan';

  @override
  String get checkForUpdates => 'Seiceáil le haghaidh nuashonruithe';

  @override
  String get checkingForUpdates => 'Ag seiceáil…';

  @override
  String get upToDate => 'Tá tú suas chun dáta.';

  @override
  String updateAvailable(Object version) {
    return 'Tá leagan $version ar fáil.';
  }

  @override
  String get updateCheckFailed => 'Níorbh fhéidir nuashonruithe a sheiceáil.';

  @override
  String get viewRelease => 'Féach an eisiúint';

  @override
  String get allReleases => 'Gach eisiúint';

  @override
  String get pause => 'Cuir ar sos';

  @override
  String get seekBack => '10 soicind ar ais';

  @override
  String get seekForward => '10 soicind ar aghaidh';

  @override
  String get subtitles => 'Fotheidil';

  @override
  String get audio => 'Fuaim';

  @override
  String get playbackSpeed => 'Luas athsheinm';

  @override
  String get queue => 'Cúlra';

  @override
  String get nowPlaying => 'Á sheinm anois';

  @override
  String get noSubtitles => 'Gan fotheidil';

  @override
  String get off => 'Múchta';

  @override
  String get filter => 'Scag';

  @override
  String get filterAll => 'Uile';

  @override
  String get unwatched => 'Neamhfheicthe';

  @override
  String get watched => 'Feicthe';

  @override
  String get sortBy => 'Sórtáil de réir';

  @override
  String get sortName => 'Ainm';

  @override
  String get sortDateAdded => 'Dáta curtha leis';

  @override
  String get sortRating => 'Rátáil';

  @override
  String get sortReleaseDate => 'Dáta eisiúna';

  @override
  String get ascending => 'Méadúchán';

  @override
  String get descending => 'Laghdúchán';

  @override
  String items(Object count) {
    return '$count mír';
  }

  @override
  String get deleteDownload => 'Scrios an íoslódáil';

  @override
  String get cancelDownload => 'Cealaigh an íoslódáil';

  @override
  String get unknownArtist => 'Ealaíontóir anaithnid';

  @override
  String get minimize => 'Íoslaghdaigh';

  @override
  String get maximise => 'Uasmhéadaigh';

  @override
  String get restore => 'Athchóirigh';

  @override
  String get close => 'Dún';

  @override
  String get privacyPolicy => 'Polasaí príobháideachais';

  @override
  String get sourceCode => 'Cód foinseach';

  @override
  String get licenses => 'Ceadúnais';

  @override
  String get played => 'Feicthe';

  @override
  String get notPlayed => 'Neamhfheicthe';

  @override
  String get loading => 'Ag lódáil…';

  @override
  String get offline => 'Tá tú as líne. Seiceáil do cheangal.';

  @override
  String get featured => 'Réadmhaoin';

  @override
  String get playFromStart => 'Seinn ón tús';

  @override
  String get downloadComplete => 'Íoslódáil críochnaithe';

  @override
  String get downloadFailed => 'Theip ar an íoslódáil';

  @override
  String get clearQueue => 'Glan an ciú';
}
