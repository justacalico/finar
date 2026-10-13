import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/models.dart';
import 'library_providers.dart';
import 'session_provider.dart';

final itemActionsProvider = Provider<ItemActions>((ref) => ItemActions(ref));

class ItemActions {
  const ItemActions(this._ref);

  final Ref _ref;

  Future<UserData> setFavorite(String itemId, bool favorite) async {
    final client = _ref.read(jellyfinClientProvider);
    if (client == null) throw StateError('not signed in');
    final userData = await client.setFavorite(itemId, favorite);
    _invalidate(itemId);
    return userData;
  }

  Future<UserData> setPlayed(String itemId, bool played) async {
    final client = _ref.read(jellyfinClientProvider);
    if (client == null) throw StateError('not signed in');
    final userData = await client.setPlayed(itemId, played);
    _invalidate(itemId);
    return userData;
  }

  void _invalidate(String itemId) {
    _ref.invalidate(itemProvider(itemId));
    _ref.invalidate(favoritesProvider);
    _ref.invalidate(resumeItemsProvider);
  }
}
