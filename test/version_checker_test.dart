import 'package:finar/core/constants.dart';
import 'package:finar/core/update/version_checker.dart';
import 'package:finar/core/utils/version_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  http.Client clientFor(int status, String body) =>
      MockClient((_) async => http.Response(body, status));

  test('returns newer release', () async {
    final checker = UpdateChecker(
        client: clientFor(200, '''
      [{"tag_name":"v6.2.0"},{"tag_name":"v6.0.0"},{"tag_name":"nightly"}]
    '''));
    final update = await checker.check(const Version(6, 0, 0));
    expect(update, isNotNull);
    expect(update!.version, const Version(6, 2, 0));
    expect(update.tag, 'v6.2.0');
    expect(update.url.toString(),
        '$kGitLabReleases/v6.2.0');
  });

  test('null when current is latest', () async {
    final checker = UpdateChecker(
        client: clientFor(200, '[{"tag_name":"v5.9.0"}]'));
    expect(await checker.check(const Version(6, 0, 0)), isNull);
  });

  test('throws on http failure', () async {
    final checker = UpdateChecker(client: clientFor(500, ''));
    expect(() => checker.check(const Version(6, 0, 0)),
        throwsA(anything));
  });

  test('null when no semver tags', () async {
    final checker = UpdateChecker(
        client: clientFor(200, '[{"tag_name":"nightly"}]'));
    expect(await checker.latestRelease(), isNull);
  });
}
