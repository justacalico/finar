import 'package:finar/core/api/jellyfin_api.dart';
import 'package:finar/core/services/download_service.dart';
import 'package:finar/pages/downloads.dart';
import 'package:finar/providers/download_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDownloadService extends DownloadService {
  _FakeDownloadService() : super(JellyfinApi());

  @override
  Future<void> init() async {}

  @override
  List<DownloadTask> get downloads => const [];

  @override
  Stream<DownloadTask> get progressStream => const Stream<DownloadTask>.empty();

  @override
  void dispose() {}
}

class _FakeDownloadNotifier extends DownloadNotifier {
  _FakeDownloadNotifier() : super(_FakeDownloadService());
}

Widget _wrap(Widget child) => ProviderScope(
  overrides: [downloadProvider.overrideWith((ref) => _FakeDownloadNotifier())],
  child: MaterialApp(home: child),
);

void main() {
  testWidgets(
    'DownloadsPage embedded at root shows header without back button',
    (tester) async {
      await tester.pumpWidget(_wrap(const DownloadsPage()));
      await tester.pumpAndSettle();

      expect(find.text('Downloads'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    },
  );

  testWidgets('DownloadsPage pushed from another route shows a back button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const DownloadsPage()));
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Downloads'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });
}
