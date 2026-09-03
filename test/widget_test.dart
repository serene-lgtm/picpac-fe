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
          initialItems: const [
            Item(
              id: '1',
              name: '手机',
              categoryId: 'category-1',
              categoryKey: 'electronics',
              categoryName: '电子产品',
            ),
          ],
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

  testWidgets('category tab filters items locally by name fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildItemsPage(
        itemRepository: _FakeItemRepository(
          initialItems: const [
            Item(id: '1', name: '护照', categoryName: '其他'),
            Item(
              id: '2',
              name: '手机',
              categoryId: 'category-1',
              categoryKey: 'electronics',
              categoryName: '电子产品',
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('护照'), findsOneWidget);
    expect(find.text('手机'), findsOneWidget);

    final otherTab = find.byKey(const ValueKey('item-category-tab-category-2'));

    await tester.tap(otherTab);
    await tester.pumpAndSettle();

    expect(find.text('护照'), findsOneWidget);
    expect(find.text('手机'), findsNothing);

    await tester.tap(otherTab);
    await tester.pumpAndSettle();

    expect(find.text('护照'), findsOneWidget);
    expect(find.text('手机'), findsOneWidget);
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
  static const _categories = [
    ItemCategory(id: 'category-1', key: 'electronics', name: '电子产品'),
    ItemCategory(id: 'category-2', key: 'other', name: '其他'),
  ];

  @override
  Future<List<ItemCategory>> listCategories() async => _categories;

  @override
  Future<Item> createItem({
    required String name,
    String? description,
    String? categoryId,
    String? userId,
    MultipartFilePart? image,
  }) async {
    final category = _categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => _categories.first,
    );
    final item = Item(
      id: '${_items.length + 1}',
      name: name,
      description: description ?? '',
      userId: userId ?? '',
      categoryId: category.id,
      categoryKey: category.key,
      categoryName: category.name,
    );
    _items = [item, ..._items];
    return item;
  }

  @override
  Future<List<ItemDraft>> generateItemDrafts(String text) async {
    return const [
      ItemDraft(
        name: '护照夹',
        categoryId: 'category-2',
        categoryKey: 'other',
        categoryName: '其他',
      ),
    ];
  }

  @override
  Future<List<Item>> batchCreateItems(List<ItemDraft> drafts) async {
    final created = <Item>[];
    for (final draft in drafts) {
      final category = _categories.firstWhere(
        (category) => category.id == draft.categoryId,
        orElse: () => _categories.first,
      );
      created.add(
        Item(
          id: '${_items.length + created.length + 1}',
          name: draft.name,
          description: draft.description,
          categoryId: category.id,
          categoryKey: category.key,
          categoryName: category.name,
        ),
      );
    }
    _items = [...created, ..._items];
    return created;
  }

  @override
  Future<List<Item>> listItems({
    String? userId,
    String? q,
    String? categoryId,
  }) async {
    final categoryItems = categoryId == null || categoryId.isEmpty
        ? _items
        : _items
              .where((item) => item.categoryId == categoryId)
              .toList(growable: false);
    final keyword = q?.trim().toLowerCase();
    if (keyword == null || keyword.isEmpty) return categoryItems;
    return categoryItems
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
    String? categoryId,
    MultipartFilePart? image,
  }) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    final category = _categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => _categories.first,
    );
    final item = Item(
      id: itemId,
      name: name,
      description: description ?? '',
      categoryId: category.id,
      categoryKey: category.key,
      categoryName: category.name,
    );
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
    List<String> itemIds = const [],
  }) async {
    return Pack(
      id: 'pack-1',
      name: name,
      description: description ?? '',
      items: itemIds,
      status: 'created',
    );
  }

  @override
  Future<Pack> updatePackProfile({
    required String packId,
    required String name,
    String description = '',
  }) async {
    return Pack(
      id: packId,
      name: name,
      description: description,
      items: const [],
      status: 'created',
    );
  }

  @override
  Future<Pack> addPackItems({
    required String packId,
    required List<String> itemIds,
  }) async {
    return Pack(id: packId, name: '测试套组', items: itemIds, status: 'created');
  }

  @override
  Future<Pack> removePackItems({
    required String packId,
    required List<String> itemIds,
  }) async {
    return Pack(id: packId, name: '测试套组', status: 'created');
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
