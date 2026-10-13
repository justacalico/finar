import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void mockSecureStorage() {
  final values = <String, String?>{};
  TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      final args =
          (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      final key = args['key'] as String?;
      if (key == null && call.method != 'readAll' && call.method != 'deleteAll') return null;
      switch (call.method) {
        case 'write':
          values[key!] = args['value'] as String?;
          return null;
        case 'read':
          return values[key!];
        case 'delete':
          values.remove(key!);
          return null;
        case 'deleteAll':
          values.clear();
          return null;
        case 'readAll':
          return Map<String, String?>.from(values);
        case 'containsKey':
          return values.containsKey(key!);
        default:
          return null;
      }
    },
  );
}
