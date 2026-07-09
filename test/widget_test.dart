import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/app/theme.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/features/checklists/data/checklist.dart';
import 'package:picpac_fe/features/checklists/data/checklist_repository.dart';
import 'package:picpac_fe/features/items/data/item.dart';
import 'package:picpac_fe/features/items/data/item_repository.dart';
import 'package:picpac_fe/features/items/presentation/pages/items_page.dart';
import 'package:picpac_fe/features/me/data/me.dart';
import 'package:picpac_fe/features/me/data/me_repository.dart';
import 'package:picpac_fe/features/packs/data/pack.dart';
import 'package:picpac_fe/features/packs/data/pack_repository.dart';

void main() {
  testWidgets('shows items returned by repository', (tester) async {
    await tester.pumpWidget(
      _buildItemsPage(
        itemRepository: _FakeItemRepository(
          initialItems: const [Item(id: '1', name: '手机')],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('物品'), findsAtLeastNWidgets(1));
    expect(find.text('手机'), findsOneWidget);
  });

  testWidgets('shows blank state when item list is empty', (tester) async {
    await tester.pumpWidget(
      _buildItemsPage(
        itemRepository: _FakeItemRepository(initialItems: const []),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('请添加一些物品吧！'), findsOneWidget);
  });
}

Widget _buildItemsPage({required ItemRepository itemRepository}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: PicpacTheme.light(),
    home: ItemsPage(
      repository: itemRepository,
      packRepository: _FakePackRepository(),
      checklistRepository: _FakeChecklistRepository(),
      meRepository: _FakeMeRepository(),
    ),
  );
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

  @override
  Future<Item> getItem(String itemId) async {
    return _items.firstWhere((item) => item.id == itemId);
  }

  @override
  Future<Item> updateItem({
    required String itemId,
    required String name,
    String? description,
    MultipartFilePart? image,
  }) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    final item = Item(id: itemId, name: name, description: description ?? '');
    if (index == -1) {
      _items = [item, ..._items];
    } else {
      _items = [..._items.take(index), item, ..._items.skip(index + 1)];
    }
    return item;
  }

  @override
  Future<void> deleteItem(String itemId) async {
    _items = _items.where((item) => item.id != itemId).toList(growable: false);
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

class _FakeMeRepository implements MeRepository {
  @override
  Future<MeUser> getMe() async {
    return const MeUser(
      id: 'user-1',
      profile: MeProfile(username: '测试用户'),
    );
  }

  @override
  Future<MeUser> updateProfile({
    required String username,
    required String gender,
    String birthday = '',
    MultipartFilePart? avatar,
  }) async {
    return MeUser(
      id: 'user-1',
      profile: MeProfile(
        username: username,
        gender: gender,
        birthday: birthday,
      ),
    );
  }
}
