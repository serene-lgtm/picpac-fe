import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/items/data/item.dart';
import 'package:picpac_fe/features/items/data/item_repository.dart';
import 'package:picpac_fe/features/items/presentation/widgets/item_detail_sheet.dart';

class _Repository implements ItemRepository {
  _Repository(this.item);
  final Item item;
  @override
  Future<Item> getItem(String id) async => item;
  @override
  Future<List<ItemCategory>> listCategories() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final hasPhotos in [false, true]) {
    testWidgets('detail uses photos only: hasPhotos=$hasPhotos', (
      tester,
    ) async {
      final item = Item(
        id: 'item-1',
        name: '裙子',
        coverImageUrl: 'https://example.com/items/default/cover.jpg',
        photos: hasPhotos
            ? const [
                ItemPhoto(
                  id: 'photo-1',
                  displayImageUrl: 'https://example.com/display.jpg',
                  sourceImageUrl: 'https://example.com/source.jpg',
                ),
              ]
            : const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showItemDetailSheet(
                  context: context,
                  item: item,
                  itemRepository: _Repository(item),
                ),
                child: const Text('打开详情'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开详情'));
      await tester.pumpAndSettle();
      expect(find.text('裙子'), findsOneWidget);
      if (!hasPhotos) {
        expect(find.byType(PageView), findsNothing);
        expect(find.byType(Image), findsNothing);
      } else {
        expect(find.byType(PageView), findsOneWidget);
        expect(find.text('照片加载失败，点击查看原图'), findsOneWidget);
        expect(
          find.byType(Image).evaluate().any((element) {
            final provider = (element.widget as Image).image;
            return provider is NetworkImage &&
                provider.url == item.coverImageUrl;
          }),
          isFalse,
        );
        await tester.tap(find.text('照片加载失败，点击查看原图'));
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(
          find.descendant(
            of: find.byType(InteractiveViewer),
            matching: find.byType(Image),
          ),
        );
        expect(
          (image.image as NetworkImage).url,
          item.photos.first.sourceImageUrl,
        );
      }
    });
  }
}
