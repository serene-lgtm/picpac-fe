import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'item.dart';

abstract class ItemRepository {
  Future<List<Item>> listItems({String? userId, String? q});

  Future<Item> getItem(String itemId);

  Future<Item> createItem({
    required String name,
    String? description,
    String? userId,
    MultipartFilePart? image,
  });

  Future<Item> updateItem({
    required String itemId,
    required String name,
    String? description,
    MultipartFilePart? image,
  });

  Future<void> deleteItem(String itemId);
}

class ApiItemRepository implements ItemRepository {
  ApiItemRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Item>> listItems({String? userId, String? q}) async {
    final response = await _client.getJson(
      '/api/v1/item',
      queryParameters: {'user_id': userId, 'q': q?.trim()},
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
    String? userId,
    MultipartFilePart? image,
  }) async {
    final fields = <String, String>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
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
    MultipartFilePart? image,
  }) async {
    final fields = <String, String>{
      'name': name,
      if (description != null) 'description': description,
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
