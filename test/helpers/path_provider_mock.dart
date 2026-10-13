import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void mockPathProvider({String documentsDir = '/tmp/finar_test'}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => switch (call.method) {
      'getApplicationDocumentsDirectory' => documentsDir,
      'getTemporaryDirectory' => '/tmp',
      'getDownloadsDirectory' => documentsDir,
      _ => documentsDir,
    },
  );
}

void mockPackageInfo({String version = '6.0.0'}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (call) async => {
      'appName': 'Finar',
      'packageName': 'com.openlyst.finar',
      'version': version,
      'buildNumber': '1',
      'buildSignature': '',
    },
  );
}
