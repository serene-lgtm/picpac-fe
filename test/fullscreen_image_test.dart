import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/shared/widgets/fullscreen_image.dart';

void main() {
  testWidgets('source image is only built after tapping and can be closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ImagePreview(
            sourceUrl: 'https://example.com/source.jpg',
            child: Text('展示图'),
          ),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    await tester.tap(find.text('展示图'));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://example.com/source.jpg');
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip('关闭原图'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('展示图'), findsOneWidget);
  });
}
