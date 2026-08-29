import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/widgets/widgets.dart';
import 'player/widgets/player_desktop.dart';
import 'player/widgets/player_mobile.dart';

/// Cross-platform video player. Desktop: keyboard/mouse; Mobile: touch gestures, brightness/volume.
class PlayerPage extends ConsumerWidget {
  const PlayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => const PlayerDesktop(),
      mobileBuilder: () => const PlayerMobile(),
    );
  }
}
