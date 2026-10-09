import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/app/app.dart';
import 'package:picpac_fe/features/auth/data/auth_repository.dart';
import 'package:picpac_fe/features/auth/data/session_store.dart';
import 'package:picpac_fe/features/auth/presentation/pages/login_page.dart';
import 'package:picpac_fe/features/launch_screen/data/launch_screen.dart';
import 'package:picpac_fe/features/launch_screen/data/launch_screen_repository.dart';
import 'package:picpac_fe/features/launch_screen/presentation/pages/launch_screen_page.dart';

void main() {
  for (final skip in [true, false]) {
    testWidgets('launch exits to login with skip=$skip', (tester) async {
      // Exercise the successful remote-image path without external networking.
      final info = await tester.runAsync(() async {
        final bytes = await rootBundle.load('assets/common/me_cover.png');
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(),
        );
        final frame = await codec.getNextFrame();
        codec.dispose();
        return ImageInfo(image: frame.image);
      });
      PaintingBinding.instance.imageCache.putIfAbsent(
        const NetworkImage(_imageUrl),
        () => OneFrameImageStreamCompleter(Future.value(info!)),
      );
      await tester.pumpWidget(
        PicpacApp(
          sessionStore: _Store(),
          launchScreenRepository: _Repository(skip),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LaunchScreenPage), findsOneWidget);
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(LaunchScreenPage),
          matching: find.byType(Image),
        ),
      );
      expect(image.image, isA<NetworkImage>());
      expect(image.fit, BoxFit.cover);
      if (skip) {
        await tester.tap(find.text('跳过'));
      } else {
        await tester.pump(const Duration(seconds: 2));
      }
      await tester.pumpAndSettle();
      expect(find.byType(LaunchScreenPage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

const _imageUrl = 'https://example.com/launch-image.png';

class _Repository implements LaunchScreenRepository {
  _Repository(this.skip);
  final bool skip;
  @override
  Future<LaunchScreen> getLaunchScreen() async => LaunchScreen(
    enabled: true,
    type: 'image',
    mediaUrl: _imageUrl,
    durationMs: 2000,
    skipEnabled: skip,
  );
}

class _Store implements SessionStore {
  @override
  Future<AuthSession?> read() async => null;
  @override
  Future<void> clear() async {}
  @override
  Future<void> write(AuthSession session) async {}
}
