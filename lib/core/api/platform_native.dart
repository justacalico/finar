import 'dart:io';

/// Native platform implementation - returns actual hostname
String getPlatformHostname() => Platform.localHostname;
