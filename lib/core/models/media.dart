class MediaStream {
  const MediaStream({
    required this.index,
    required this.type,
    this.codec,
    this.language,
    this.displayTitle,
    this.isDefault = false,
    this.isExternal = false,
  });

  final int index;
  final String type;
  final String? codec;
  final String? language;
  final String? displayTitle;
  final bool isDefault;
  final bool isExternal;

  bool get isSubtitle => type == 'Subtitle';
  bool get isAudio => type == 'Audio';
  bool get isVideo => type == 'Video';

  String get label {
    final title = displayTitle;
    if (title != null && title.isNotEmpty) return title;
    final parts =
        [language, codec].whereType<String>().join(' ');
    return parts.isNotEmpty ? parts : 'Track $index';
  }

  factory MediaStream.fromJson(Map<String, dynamic> json) => MediaStream(
        index: json['Index'] as int? ?? -1,
        type: json['Type'] as String? ?? '',
        codec: json['Codec'] as String?,
        language: json['Language'] as String?,
        displayTitle: json['DisplayTitle'] as String?,
        isDefault: json['IsDefault'] as bool? ?? false,
        isExternal: json['IsExternal'] as bool? ?? false,
      );
}

class MediaSource {
  const MediaSource({
    required this.id,
    this.container,
    this.size,
    this.mediaStreams = const [],
  });

  final String id;
  final String? container;
  final int? size;
  final List<MediaStream> mediaStreams;

  factory MediaSource.fromJson(Map<String, dynamic> json) => MediaSource(
        id: json['Id'] as String? ?? '',
        container: json['Container'] as String?,
        size: json['Size'] as int?,
        mediaStreams: (json['MediaStreams'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MediaStream.fromJson)
            .toList(),
      );
}
