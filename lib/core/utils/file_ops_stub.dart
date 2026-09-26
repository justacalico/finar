/// No-op file operations for platforms without dart:io (web).
Future<String> downloadsDirectory() async => 'downloads';

Future<void> ensureDirectory(String path) async {}

Future<void> deleteFileIfExists(String path) async {}
