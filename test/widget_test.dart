import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/app/app.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/features/checklists/data/checklist.dart';
import 'package:picpac_fe/features/checklists/data/checklist_repository.dart';
import 'package:picpac_fe/features/items/data/item.dart';
import 'package:picpac_fe/features/items/data/item_repository.dart';
import 'package:picpac_fe/features/packs/data/pack.dart';
import 'package:picpac_fe/features/packs/data/pack_repository.dart';

void main() {
  testWidgets('shows items returned by repository', (tester) async {
    await tester.pumpWidget(
      PicpacApp(
        itemRepository: _FakeItemRepository(
          initialItems: const [Item(id: '1', name: '手机')],
        ),
        packRepository: _FakePackRepository(),
        checklistRepository: _FakeChecklistRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('物品'), findsAtLeastNWidgets(1));
    expect(find.text('手机'), findsOneWidget);
  });

  testWidgets('shows blank state when item list is empty', (tester) async {
    await tester.pumpWidget(
      PicpacApp(
        itemRepository: _FakeItemRepository(initialItems: const []),
        packRepository: _FakePackRepository(),
        checklistRepository: _FakeChecklistRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('请添加一些物品吧！'), findsOneWidget);
  });
}

class _FakeItemRepository implements ItemRepository {
  _FakeItemRepository({required List<Item> initialItems})
    : _items = initialItems;

  List<Item> _items;

  @override
  Future<Item> createItem({
    required String name,
    String? description,
    String? userId,
    MultipartFilePart? image,
  }) async {
    final item = Item(
      id: '${_items.length + 1}',
      name: name,
      description: description ?? '',
      userId: userId ?? '',
    );
    _items = [item, ..._items];
    return item;
  }

  @override
  Future<List<Item>> listItems({String? userId, String? q}) async {
    final keyword = q?.trim().toLowerCase();
    if (keyword == null || keyword.isEmpty) return _items;
    return _items
        .where(
          (item) =>
              item.name.toLowerCase().contains(keyword) ||
              item.description.toLowerCase().contains(keyword),
        )
        .toList(growable: false);
  }
}

class _FakePackRepository implements PackRepository {
  @override
  Future<List<Pack>> listPacks({String? userId, String? q}) async => const [];

  @override
  Future<Pack> getPack(String packId) async {
    return Pack(id: packId, name: '测试套组');
  }

  @override
  Future<Pack> createPack({
    required String name,
    String? description,
    String? userId,
    List<String> itemIds = const [],
  }) async {
    return Pack(
      id: 'pack-1',
      name: name,
      description: description ?? '',
      userId: userId ?? '',
      items: itemIds,
      status: 'created',
    );
  }

  @override
  Future<Pack> updatePack({
    required String packId,
    required String name,
    String description = '',
    List<String> itemIds = const [],
  }) async {
    return Pack(
      id: packId,
      name: name,
      description: description,
      items: itemIds,
      status: 'created',
    );
  }

  @override
  Future<void> deletePack(String packId) async {}
}

class _FakeChecklistRepository implements ChecklistRepository {
  @override
  Future<List<Checklist>> listChecklists({String? userId, String? q}) async {
    return const [];
  }

  @override
  Future<Checklist> getChecklist(String checklistId) async {
    return Checklist(id: checklistId, name: '测试清单', targetDate: '2026-07-01');
  }

  @override
  Future<Checklist> createChecklist({
    required String name,
    required String targetDate,
    String description = '',
    String? userId,
    List<ChecklistItemInput> items = const [],
  }) async {
    return Checklist(
      id: 'checklist-1',
      name: name,
      targetDate: targetDate,
      description: description,
      status: 'created',
      items: [
        for (var index = 0; index < items.length; index++)
          ChecklistLineItem(
            id: 'line-$index',
            referenceType: items[index].referenceType,
            referenceId: items[index].itemId,
            snapshotName: items[index].snapshotName,
          ),
      ],
    );
  }

  @override
  Future<Checklist> updateChecklist({
    required String checklistId,
    required String name,
    required String targetDate,
    String description = '',
  }) async {
    return Checklist(
      id: checklistId,
      name: name,
      targetDate: targetDate,
      description: description,
    );
  }

  @override
  Future<Checklist> addLineItems({
    required String checklistId,
    required List<ChecklistItemInput> items,
  }) async {
    return createChecklist(
      name: '测试清单',
      targetDate: '2026-07-01',
      items: items,
    );
  }

  @override
  Future<Checklist> removeLineItems({
    required String checklistId,
    required List<String> lineItemIds,
  }) async {
    return Checklist(id: checklistId, name: '测试清单', targetDate: '2026-07-01');
  }

  @override
  Future<Checklist> updateLineItemStatus({
    required String checklistId,
    required String lineItemId,
    required String status,
  }) async {
    return Checklist(
      id: checklistId,
      name: '测试清单',
      targetDate: '2026-07-01',
      items: [
        ChecklistLineItem(
          id: lineItemId,
          referenceType: 'item',
          referenceId: 'item-1',
          status: status,
        ),
      ],
    );
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {}
}
