import 'dart:io' show Platform;

bool get isDesktopOs => Platform.isLinux || Platform.isWindows || Platform.isMacOS;
bool get isMobileOs => Platform.isAndroid || Platform.isIOS;
