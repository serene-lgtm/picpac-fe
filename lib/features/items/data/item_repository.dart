import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'item.dart';

abstract class ItemRepository {
  Future<List<ItemCategory>> listCategories();

  Future<List<Item>> listItems({String? userId, String? q, String? categoryId});

  Future<Item> getItem(String itemId);

  Future<Item> createItem({
    required String name,
    String? description,
    String? categoryId,
    String? userId,
    MultipartFilePart? image,
  });

  Future<Item> updateItem({
    required String itemId,
    required String name,
    String? description,
    String? categoryId,
    MultipartFilePart? image,
  });

  Future<List<ItemDraft>> generateItemDrafts(String text);

  Future<List<Item>> batchCreateItems(List<ItemDraft> drafts);

  Future<void> deleteItem(String itemId);
}

class ApiItemRepository implements ItemRepository {
  ApiItemRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ItemCategory>> listCategories() async {
    final response = await _client.getJson('/api/v1/categories');
    final categoriesJson = response['categories'];
    if (categoriesJson is! List) {
      return const [];
    }
    return categoriesJson
        .whereType<Map<String, dynamic>>()
        .map(ItemCategory.fromJson)
        .where((category) => category.id.isNotEmpty && category.name.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<Item>> listItems({
    String? userId,
    String? q,
    String? categoryId,
  }) async {
    final response = await _client.getJson(
      '/api/v1/item',
      queryParameters: {
        'user_id': userId,
        'q': q?.trim(),
        'category_id': categoryId?.trim(),
      },
    );
    final itemsJson = response['items'];
    if (itemsJson is! List) {
      return const [];
    }
    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(_itemFromJson)
        .toList(growable: false);
  }

  @override
  Future<Item> getItem(String itemId) async {
    final response = await _client.getJson('/api/v1/item/$itemId');
    return _itemFromResponse(response);
  }

  @override
  Future<Item> createItem({
    required String name,
    String? description,
    String? categoryId,
    String? userId,
    MultipartFilePart? image,
  }) async {
    final fields = <String, String>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (categoryId != null && categoryId.trim().isNotEmpty)
        'category_id': categoryId.trim(),
      if (userId != null && userId.trim().isNotEmpty) 'user_id': userId.trim(),
    };
    final response = await _client.postMultipart(
      '/api/v1/item',
      fields: fields,
      file: image,
    );
    return _itemFromResponse(response);
  }

  @override
  Future<Item> updateItem({
    required String itemId,
    required String name,
    String? description,
    String? categoryId,
    MultipartFilePart? image,
  }) async {
    final fields = <String, String>{
      'name': name,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId.trim(),
    };
    final response = await _client.putMultipart(
      '/api/v1/item/$itemId',
      fields: fields,
      file: image,
    );
    return _itemFromResponse(response);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _client.deleteJson('/api/v1/item/$itemId');
  }

  @override
  Future<List<ItemDraft>> generateItemDrafts(String text) async {
    final response = await _client.postJson(
      '/api/v1/ai/item-drafts',
      body: {'text': text.trim()},
    );
    final draftsJson = response['draft_items'];
    if (draftsJson is! List) {
      return const [];
    }
    return draftsJson
        .whereType<Map<String, dynamic>>()
        .map(ItemDraft.fromJson)
        .where((draft) => draft.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<Item>> batchCreateItems(List<ItemDraft> drafts) async {
    final response = await _client.postJson(
      '/api/v1/item/batch',
      body: {
        'items': drafts.map((draft) => draft.toJson()).toList(growable: false),
      },
    );
    final itemsJson = response['items'];
    if (itemsJson is! List) {
      return const [];
    }
    return itemsJson
        .whereType<Map<String, dynamic>>()
        .map(_itemFromJson)
        .toList(growable: false);
  }

  Item _itemFromJson(Map<String, dynamic> json) {
    final item = Item.fromJson(json).normalizeImageUrls(_client.resolveUrl);
    if (kDebugMode) {
      debugPrint(
        '[picpac.item] item=${item.id} name=${item.name} imageUrls=${item.imageUrls}',
      );
    }
    return item;
  }

  Item _itemFromResponse(Map<String, dynamic> response) {
    final itemJson = response['item'];
    if (itemJson is Map<String, dynamic>) {
      return _itemFromJson(itemJson);
    }
    final dataJson = response['data'];
    if (dataJson is Map<String, dynamic>) {
      return _itemFromJson(dataJson);
    }
    return _itemFromJson(response);
  }
}
