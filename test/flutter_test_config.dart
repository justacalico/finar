import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_http_client.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  HttpOverrides.global = FakeImageHttpOverrides();

  for (final entry in {
    'Roboto': [
      'assets/fonts/Roboto-Regular.ttf',
      'assets/fonts/Roboto-Medium.ttf',
      'assets/fonts/Roboto-Bold.ttf',
    ],
    'MaterialIcons': ['test/fonts/MaterialIcons-Regular.otf'],
    'CupertinoIcons': ['test/fonts/CupertinoIcons.ttf'],
  }.entries) {
    final loader = FontLoader(entry.key);
    for (final path in entry.value) {
      loader.addFont(File(path)
          .readAsBytes()
          .then((v) => v.buffer.asByteData()));
    }
    await loader.load();
  }
  await testMain();
}
