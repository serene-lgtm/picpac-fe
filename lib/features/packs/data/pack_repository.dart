import '../../../core/network/api_client.dart';
import 'pack.dart';

abstract class PackRepository {
  Future<List<Pack>> listPacks({String? userId, String? q});

  Future<Pack> getPack(String packId);

  Future<Pack> createPack({
    required String name,
    String? description,
    String? userId,
    List<String> itemIds = const [],
  });

  Future<Pack> updatePack({
    required String packId,
    required String name,
    String description = '',
    List<String> itemIds = const [],
  });

  Future<void> deletePack(String packId);
}

class ApiPackRepository implements PackRepository {
  ApiPackRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Pack>> listPacks({String? userId, String? q}) async {
    final response = await _client.getJson(
      '/api/v1/pack',
      queryParameters: {'user_id': userId, 'q': q?.trim()},
    );
    final packsJson = response['packs'];
    if (packsJson is! List) {
      return const [];
    }
    return packsJson
        .whereType<Map<String, dynamic>>()
        .map(Pack.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Pack> getPack(String packId) async {
    final response = await _client.getJson('/api/v1/pack/$packId');
    return Pack.fromJson(response);
  }

  @override
  Future<Pack> createPack({
    required String name,
    String? description,
    String? userId,
    List<String> itemIds = const [],
  }) async {
    final response = await _client.postJson(
      '/api/v1/pack',
      body: {
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (userId != null && userId.trim().isNotEmpty)
          'user_id': userId.trim(),
        if (itemIds.isNotEmpty) 'items': itemIds,
      },
    );
    return Pack.fromJson(response);
  }

  @override
  Future<Pack> updatePack({
    required String packId,
    required String name,
    String description = '',
    List<String> itemIds = const [],
  }) async {
    final response = await _client.putJson(
      '/api/v1/pack/$packId',
      body: {'name': name.trim(), 'description': description, 'items': itemIds},
    );
    return Pack.fromJson(response);
  }

  @override
  Future<void> deletePack(String packId) async {
    await _client.deleteJson('/api/v1/pack/$packId');
  }
}
