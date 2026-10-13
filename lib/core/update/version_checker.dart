import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../utils/version_utils.dart';
import 'app_update.dart';

class UpdateChecker {
  const UpdateChecker({required this.client, this.projectEncoded = kGitLabProjectEncoded});

  final http.Client client;
  final String projectEncoded;

  Future<AppUpdate?> check(Version current) async {
    final latest = await latestRelease();
    if (latest == null) return null;
    if (latest.version.isNewerThan(current)) return latest;
    return null;
  }

  Future<AppUpdate?> latestRelease() async {
    final uri = Uri.parse(
        '$kGitLabBase/api/v4/projects/$projectEncoded/releases?per_page=100&order_by=released_at&sort=desc');
    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw const FormatException('release fetch failed');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    AppUpdate? best;
    for (final entry in list.whereType<Map<String, dynamic>>()) {
      final tag = entry['tag_name'] as String? ?? '';
      final version = Version.tryParse(tag);
      if (version == null) continue;
      final update = AppUpdate(
        version: version,
        tag: tag,
        url: Uri.parse('$kGitLabReleases/$tag'),
      );
      if (best == null || update.version.isNewerThan(best.version)) {
        best = update;
      }
    }
    return best;
  }
}
