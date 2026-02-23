import 'media_item.dart';

/// Result of items query from Jellyfin API
class ItemsResult {
  final List<MediaItem> items;
  final int totalCount;
  final int startIndex;

  const ItemsResult({
    required this.items,
    required this.totalCount,
    required this.startIndex,
  });

  factory ItemsResult.fromJson(Map<String, dynamic> json) {
    return ItemsResult(
      items: (json['Items'] as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['TotalRecordCount'] as int? ?? 0,
      startIndex: json['StartIndex'] as int? ?? 0,
    );
  }
}
