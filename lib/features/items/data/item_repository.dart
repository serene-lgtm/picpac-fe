import '../../../core/network/api_client.dart';
import 'item.dart';

abstract class ItemRepository {
  Future<List<Item>> listItems({String? userId, String? q});

  Future<Item> createItem({
    required String name,
    String? description,
    String? userId,
    MultipartFilePart? image,
  });
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
        .map(Item.fromJson)
        .toList(growable: false);
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
    return Item.fromJson(response);
  }
}
