import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'core/api/jellyfin_api.dart';
import 'core/api/models/user.dart';
import 'core/api/models/media_item.dart';
import 'core/api/models/library.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(MediaItemAdapter());
  Hive.registerAdapter(MediaTypeAdapter());
  Hive.registerAdapter(LibraryAdapter());
  Hive.registerAdapter(ImageTagsAdapter());
  Hive.registerAdapter(ChapterInfoAdapter());
  Hive.registerAdapter(PersonInfoAdapter());
  Hive.registerAdapter(MediaStreamAdapter());
  Hive.registerAdapter(UserDataAdapter());
  Hive.registerAdapter(MediaSourceInfoAdapter());

  // Open Hive boxes
  await Hive.openBox<User>('users');
  await Hive.openBox<MediaItem>('media_cache');
  await Hive.openBox<Library>('libraries');
  await Hive.openBox('settings');
  await Hive.openBox('playback_state');

  // Initialize media_kit
  MediaKit.ensureInitialized();

  // Load the real app version for Jellyfin API headers
  await JellyfinApi.initialize();

  runApp(
    const ProviderScope(
      child: FinarApp(),
    ),
  );
}
