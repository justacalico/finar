import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finar/widgets/widgets.dart';
import 'home/widgets/home_desktop.dart';
import 'home/widgets/home_mobile.dart';

class HomePage extends ConsumerWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveLayout(
      desktopBuilder: () => const HomeDesktop(),
      mobileBuilder: () => HomeMobile(initialIndex: initialIndex),
    );
  }
}
