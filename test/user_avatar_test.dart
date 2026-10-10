import 'package:cached_network_image/cached_network_image.dart';
import 'package:finar/core/api/models/user.dart';
import 'package:finar/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildSubject(User? user, {String serverUrl = 'https://server'}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: UserAvatar(user: user, serverUrl: serverUrl),
        ),
      ),
    );
  }

  testWidgets('UserAvatar scales the image to fit instead of cropping it', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(
        const User(id: '1', name: 'Http', primaryImageTag: 'tag123'),
      ),
    );
    await tester.pump();

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.fit, BoxFit.contain);
    expect(
      image.imageUrl,
      'https://server/Users/1/Images/Primary?tag=tag123',
    );
  });

  testWidgets('UserAvatar shows the first letter of the name without an image', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSubject(const User(id: '1', name: 'http')),
    );
    await tester.pump();

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('H'), findsOneWidget);
  });

  testWidgets('UserAvatar falls back to a placeholder letter for guests', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(null));
    await tester.pump();

    expect(find.text('?'), findsOneWidget);
  });
}
