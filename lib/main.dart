import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/app_storage.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final storage = AppStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
      ],
      child: const FinarApp(),
    ),
  );
}
