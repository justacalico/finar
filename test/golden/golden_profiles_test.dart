import 'package:finar/pages/manage_profiles_page.dart';
import 'package:finar/pages/whos_watching_page.dart';
import 'package:finar/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_fixtures.dart';
import 'golden_helpers.dart';

void main() {
  testWidgets("who's watching page", (tester) async {
    mockGoldenPlatformChannels();
    final container = goldenContainer(
      authState: const AuthState.unauthenticated(),
      profiles: goldenProfiles,
    );
    addTearDown(container.dispose);

    await pumpGolden(tester, const WhosWatchingPage(), container: container);

    await expectGolden(tester, 'whos_watching');
  });

  testWidgets('manage profiles page', (tester) async {
    mockGoldenPlatformChannels();
    final container = goldenContainer(
      authState: const AuthState.unauthenticated(),
      profiles: goldenProfiles,
    );
    addTearDown(container.dispose);

    await pumpGolden(tester, const ManageProfilesPage(), container: container);

    await expectGolden(tester, 'manage_profiles');
  });
}
