import 'dart:io' show Platform;

bool get isDesktopOs => Platform.isLinux || Platform.isWindows || Platform.isMacOS;
