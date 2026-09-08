import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/items/data/item.dart';
import 'package:picpac_fe/features/items/presentation/widgets/item_list_widgets.dart';
import 'package:picpac_fe/features/items/presentation/widgets/item_shared_widgets.dart';

void main() {
  testWidgets('gift without a URL opens item detail', (tester) async {
    var detailOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemListTile(
            item: const Item(id: 'legacy', name: '头灯'),
            onTap: () => detailOpens++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ItemImageFrame));
    await tester.pumpAndSettle();
    expect(detailOpens, 1);
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(find.text('头灯'));
    expect(detailOpens, 2);
  });

  testWidgets('cover and title both open item detail', (tester) async {
    var detailOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ItemListTile(
            item: const Item(
              id: 'item-1',
              name: '衣服',
              coverImageUrl: 'https://example.com/display.jpg',
              photos: [
                ItemPhoto(
                  id: 'photo-1',
                  displayImageUrl: 'https://example.com/display.jpg',
                  sourceImageUrl: 'https://example.com/source.jpg',
                ),
              ],
            ),
            onTap: () => detailOpens++,
          ),
        ),
      ),
    );
    // Failed cover images must still route to item detail.
    await tester.pumpAndSettle();
    final cover = find.byType(ItemImageFrame);
    await tester.tapAt(tester.getTopLeft(cover) + const Offset(2, 25));
    await tester.pumpAndSettle();
    expect(detailOpens, 1);
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(find.text('衣服'));
    await tester.pumpAndSettle();
    expect(detailOpens, 2);
    expect(find.byType(InteractiveViewer), findsNothing);
  });
}
