import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/launch_screen/data/launch_screen.dart';
import 'package:picpac_fe/features/launch_screen/data/launch_screen_repository.dart';
import 'package:picpac_fe/features/launch_screen/presentation/pages/launch_screen_page.dart';

void main() {
  test('disabled configs use bundled image; video uses poster', () {
    expect(const LaunchScreen(mediaUrl: 'ignored').imageUrl, isEmpty);
    expect(
      const LaunchScreen(
        enabled: true,
        type: 'video',
        mediaUrl: 'video.mp4',
        posterUrl: 'poster.webp',
      ).imageUrl,
      'poster.webp',
    );
  });

  for (final skip in [true, false]) {
    testWidgets('skip=$skip controls button and display duration', (
      tester,
    ) async {
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: LaunchScreenPage(
            repository: FakeLaunchScreenRepository(
              LaunchScreen(enabled: true, durationMs: 2500, skipEnabled: skip),
            ),
            onFinished: () => finished++,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('跳过'), skip ? findsOneWidget : findsNothing);
      await tester.pump(const Duration(milliseconds: 2400));
      expect(finished, 0);
      if (skip) {
        await tester.tap(find.text('跳过'));
        expect(finished, 1);
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(finished, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(finished, 1);
    });
  }

  for (final fails in [true, false]) {
    testWidgets('fallback completes when request fails=$fails', (tester) async {
      var finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LaunchScreenPage(
            repository: FakeLaunchScreenRepository(
              const LaunchScreen(),
              fails: fails,
            ),
            onFinished: () => finished = true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(finished, isTrue);
    });
  }

  testWidgets('broken remote image falls back and keeps skip disabled', (
    tester,
  ) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LaunchScreenPage(
          repository: FakeLaunchScreenRepository(
            const LaunchScreen(
              enabled: true,
              type: 'image',
              mediaUrl: 'https://example.com/broken.webp',
              durationMs: 2500,
              skipEnabled: false,
            ),
          ),
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('跳过'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hanging config times out and ignores late response', (
    tester,
  ) async {
    final completer = Completer<LaunchScreen>();
    var finished = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LaunchScreenPage(
          repository: _PendingRepository(completer.future),
          onFinished: () => finished++,
        ),
      ),
    );
    // Loading must not flash the fallback illustration before the remote image.
    expect(find.byType(Image), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SvgPicture), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(finished, 1);
    completer.complete(const LaunchScreen(enabled: true, skipEnabled: false));
    await tester.pump();
    expect(finished, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}

class FakeLaunchScreenRepository implements LaunchScreenRepository {
  FakeLaunchScreenRepository(this.config, {this.fails = false});
  final LaunchScreen config;
  final bool fails;
  @override
  Future<LaunchScreen> getLaunchScreen() async {
    if (fails) throw const SocketException('offline');
    return config;
  }
}

class _PendingRepository implements LaunchScreenRepository {
  _PendingRepository(this.future);
  final Future<LaunchScreen> future;
  @override
  Future<LaunchScreen> getLaunchScreen() => future;
}
