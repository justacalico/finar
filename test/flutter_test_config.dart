import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden/fake_http_client.dart';

Future<ByteData> _fontBytes(String name) async {
  final bytes = await File('test/fonts/$name').readAsBytes();
  return ByteData.view(bytes.buffer);
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The app references the Inter family without bundling it, so tests get no
  // glyphs at all and goldens render Ahem boxes. Register Roboto under the
  // Inter name (and monospace for the Quick Connect code) to draw real text.
  await (FontLoader('Inter')
        ..addFont(_fontBytes('Roboto-Regular.ttf'))
        ..addFont(_fontBytes('Roboto-Medium.ttf'))
        ..addFont(_fontBytes('Roboto-Bold.ttf')))
      .load();
  await (FontLoader('monospace')
        ..addFont(_fontBytes('Roboto-Regular.ttf')))
      .load();
  await (FontLoader('MaterialIcons')
        ..addFont(_fontBytes('MaterialIcons-Regular.otf')))
      .load();
  await (FontLoader('packages/cupertino_icons/CupertinoIcons')
        ..addFont(_fontBytes('CupertinoIcons.ttf')))
      .load();

  HttpOverrides.global = FakeHttpOverrides();

  await testMain();
}
