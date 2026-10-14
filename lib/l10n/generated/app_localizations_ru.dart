// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Finar';

  @override
  String get connectToServer => 'Подключение к серверу';

  @override
  String get connectSubtitle => 'Введите адрес вашего сервера Jellyfin.';

  @override
  String get serverUrl => 'Адрес сервера';

  @override
  String get serverUrlHint => 'https://jellyfin.example.com';

  @override
  String get connect => 'Подключить';

  @override
  String get connecting => 'Подключение…';

  @override
  String get couldNotReachServer =>
      'Не удалось подключиться к серверу Jellyfin по этому адресу.';

  @override
  String get invalidServerUrl => 'Введите корректный адрес сервера.';

  @override
  String get signIn => 'Войти';

  @override
  String signInAs(Object name) {
    return 'Войти как $name';
  }

  @override
  String get quickConnect => 'Quick Connect';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get usernameRequired => 'Введите имя пользователя.';

  @override
  String get passwordRequired => 'Введите пароль.';

  @override
  String get signInFailed => 'Ошибка входа.';

  @override
  String get invalidCredentials => 'Неверное имя пользователя или пароль.';

  @override
  String get quickConnectCode => 'Код Quick Connect';

  @override
  String get waitingForApproval =>
      'Подтвердите вход на другом устройстве Jellyfin.';

  @override
  String get quickConnectUnavailable =>
      'Quick Connect не включён на этом сервере.';

  @override
  String get back => 'Назад';

  @override
  String get cancel => 'Отмена';

  @override
  String get retry => 'Повторить';

  @override
  String get done => 'Готово';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Что-то пошло не так.';

  @override
  String get whoIsWatching => 'Кто смотрит?';

  @override
  String get addAccount => 'Добавить аккаунт';

  @override
  String get switchProfile => 'Сменить профиль';

  @override
  String get removeProfile => 'Удалить профиль';

  @override
  String get home => 'Главная';

  @override
  String get library => 'Библиотека';

  @override
  String get libraries => 'Библиотеки';

  @override
  String get search => 'Поиск';

  @override
  String get favorites => 'Избранное';

  @override
  String get downloads => 'Загрузки';

  @override
  String get settings => 'Настройки';

  @override
  String get continueWatching => 'Продолжить просмотр';

  @override
  String get nextUp => 'Далее';

  @override
  String get latest => 'Новое';

  @override
  String latestIn(Object name) {
    return 'Новое в $name';
  }

  @override
  String get myMedia => 'Мои медиа';

  @override
  String get seeAll => 'Показать все';

  @override
  String get play => 'Играть';

  @override
  String get resume => 'Продолжить';

  @override
  String get markPlayed => 'Отметить просмотренным';

  @override
  String get markUnplayed => 'Отметить непросмотренным';

  @override
  String get favourite => 'В избранное';

  @override
  String get unfavourite => 'Убрать из избранного';

  @override
  String get download => 'Скачать';

  @override
  String get downloaded => 'Скачано';

  @override
  String get downloading => 'Загрузка…';

  @override
  String get share => 'Поделиться';

  @override
  String get moreOptions => 'Ещё';

  @override
  String get seasons => 'Сезоны';

  @override
  String seasonNumber(Object number) {
    return 'Сезон $number';
  }

  @override
  String get episodes => 'Эпизоды';

  @override
  String episodeCount(Object count) {
    return 'Эпизодов: $count';
  }

  @override
  String get cast => 'Актёры';

  @override
  String get similar => 'Похожее';

  @override
  String get overview => 'Описание';

  @override
  String get genres => 'Жанры';

  @override
  String get tracks => 'Треки';

  @override
  String get album => 'Альбом';

  @override
  String get artist => 'Исполнитель';

  @override
  String get series => 'Сериал';

  @override
  String get movie => 'Фильм';

  @override
  String get episode => 'Эпизод';

  @override
  String get music => 'Музыка';

  @override
  String get noResults => 'Ничего не найдено.';

  @override
  String get searchHint => 'Поиск по библиотекам';

  @override
  String get emptyLibrary => 'Эта библиотека пуста.';

  @override
  String get emptyFavourites =>
      'Пока ничего нет в избранном. Нажмите на сердечко на том, что нравится.';

  @override
  String get emptyDownloads => 'Нет загрузок.';

  @override
  String get startSearch =>
      'Введите запрос для поиска по библиотекам Jellyfin.';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get themeMode => 'Тема';

  @override
  String get system => 'Системная';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Тёмная';

  @override
  String get oled => 'OLED';

  @override
  String get accentColour => 'Цвет акцента';

  @override
  String get language => 'Язык';

  @override
  String get systemDefault => 'Системный';

  @override
  String get account => 'Аккаунт';

  @override
  String signedInAs(Object name) {
    return 'Вы вошли как $name';
  }

  @override
  String get server => 'Сервер';

  @override
  String serverVersion(Object version) {
    return 'Версия сервера $version';
  }

  @override
  String get signOut => 'Выйти';

  @override
  String get about => 'О программе';

  @override
  String get version => 'Версия';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get checkingForUpdates => 'Проверка…';

  @override
  String get upToDate => 'У вас последняя версия.';

  @override
  String updateAvailable(Object version) {
    return 'Доступна версия $version.';
  }

  @override
  String get updateCheckFailed => 'Не удалось проверить обновления.';

  @override
  String get viewRelease => 'Открыть релиз';

  @override
  String get allReleases => 'Все релизы';

  @override
  String get pause => 'Пауза';

  @override
  String get seekBack => 'Назад на 10 секунд';

  @override
  String get seekForward => 'Вперёд на 10 секунд';

  @override
  String get subtitles => 'Субтитры';

  @override
  String get audio => 'Аудио';

  @override
  String get playbackSpeed => 'Скорость';

  @override
  String get queue => 'Очередь';

  @override
  String get nowPlaying => 'Сейчас играет';

  @override
  String get noSubtitles => 'Без субтитров';

  @override
  String get off => 'Выкл.';

  @override
  String get filter => 'Фильтр';

  @override
  String get filterAll => 'Все';

  @override
  String get unwatched => 'Непросмотренные';

  @override
  String get watched => 'Просмотренные';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get sortName => 'Название';

  @override
  String get sortDateAdded => 'Дата добавления';

  @override
  String get sortRating => 'Рейтинг';

  @override
  String get sortReleaseDate => 'Дата выхода';

  @override
  String get ascending => 'По возрастанию';

  @override
  String get descending => 'По убыванию';

  @override
  String items(Object count) {
    return 'Элементов: $count';
  }

  @override
  String get deleteDownload => 'Удалить загрузку';

  @override
  String get cancelDownload => 'Отменить загрузку';

  @override
  String get unknownArtist => 'Неизвестный исполнитель';

  @override
  String get minimize => 'Свернуть';

  @override
  String get maximise => 'Развернуть';

  @override
  String get restore => 'Восстановить';

  @override
  String get close => 'Закрыть';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get licenses => 'Лицензии';

  @override
  String get played => 'Просмотрено';

  @override
  String get notPlayed => 'Не просмотрено';

  @override
  String get loading => 'Загрузка…';

  @override
  String get offline => 'Нет подключения. Проверьте сеть.';

  @override
  String get featured => 'В центре внимания';

  @override
  String get playFromStart => 'С начала';

  @override
  String get downloadComplete => 'Загрузка завершена';

  @override
  String get downloadFailed => 'Ошибка загрузки';

  @override
  String get clearQueue => 'Очистить очередь';
}
