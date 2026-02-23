import 'package:flutter/foundation.dart';

import 'models/media_item.dart';
import 'models/items_result.dart';

/// Top-level parse functions for use with [compute].
/// Keeps JSON parsing off the main isolate to avoid UI jank.

MediaItem parseMediaItem(Map<String, dynamic> json) => MediaItem.fromJson(json);

List<MediaItem> parseMediaItemList(List<dynamic> list) => list
    .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
    .toList();

ItemsResult parseItemsResult(Map<String, dynamic> json) => ItemsResult.fromJson(json);
