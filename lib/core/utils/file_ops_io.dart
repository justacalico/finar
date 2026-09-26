import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> downloadsDirectory() async {
  final dir = await getApplicationSupportDirectory();
  return p.join(dir.path, 'downloads');
}

Future<void> ensureDirectory(String path) =>
    Directory(path).create(recursive: true);

Future<void> deleteFileIfExists(String path) async {
  final file = File(path);
  if (file.existsSync()) await file.delete();
}
