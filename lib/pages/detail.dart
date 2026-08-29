import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/widgets/adaptive_layout.dart';
import 'detail/widgets/detail_desktop.dart';
import 'detail/widgets/detail_mobile.dart';

class DetailPage extends ConsumerWidget {
  final String itemId;
  final String? initialSeasonId;
  final String? initialEpisodeId;

  const DetailPage({
    super.key,
    required this.itemId,
    this.initialSeasonId,
    this.initialEpisodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => DetailDesktop(
        itemId: itemId,
        initialSeasonId: initialSeasonId,
        initialEpisodeId: initialEpisodeId,
      ),
      mobileBuilder: () => DetailMobile(
        itemId: itemId,
        initialSeasonId: initialSeasonId,
        initialEpisodeId: initialEpisodeId,
      ),
    );
  }
}
