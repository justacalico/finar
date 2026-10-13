import '../utils/version_utils.dart';

class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.tag,
    required this.url,
  });

  final Version version;
  final String tag;
  final Uri url;
}
