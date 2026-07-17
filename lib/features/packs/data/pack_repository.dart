import '../../../core/network/api_client.dart';
import 'pack.dart';

abstract class PackRepository {
  Future<List<Pack>> listPacks({String? userId, String? q});

  Future<Pack> getPack(String packId);

  Future<Pack> createPack({
    required String name,
    String? description,
    List<String> itemIds = const [],
  });

  Future<Pack> updatePackProfile({
    required String packId,
    required String name,
    String description = '',
  });

  Future<Pack> addPackItems({
    required String packId,
    required List<String> itemIds,
  });

  Future<Pack> removePackItems({
    required String packId,
    required List<String> itemIds,
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
    List<String> itemIds = const [],
  }) async {
    final response = await _client.postJson(
      '/api/v1/pack',
      body: {
        'name': name.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (itemIds.isNotEmpty) 'items': itemIds,
      },
    );
    return _packFromResponse(response);
  }

  @override
  Future<Pack> updatePackProfile({
    required String packId,
    required String name,
    String description = '',
  }) async {
    final response = await _client.patchJson(
      '/api/v1/pack/$packId/profile',
      body: {'name': name.trim(), 'description': description.trim()},
    );
    return _packFromResponse(response);
  }

  @override
  Future<Pack> addPackItems({
    required String packId,
    required List<String> itemIds,
  }) async {
    final response = await _client.postJson(
      '/api/v1/pack/$packId/items',
      body: {'items': itemIds},
    );
    return _packFromResponse(response);
  }

  @override
  Future<Pack> removePackItems({
    required String packId,
    required List<String> itemIds,
  }) async {
    final response = await _client.deleteJson(
      '/api/v1/pack/$packId/items',
      body: {'items': itemIds},
    );
    return _packFromResponse(response);
  }

  @override
  Future<void> deletePack(String packId) async {
    await _client.deleteJson('/api/v1/pack/$packId');
  }

  Pack _packFromResponse(Map<String, dynamic> response) {
    final packJson = response['pack'];
    if (packJson is Map<String, dynamic>) {
      return Pack.fromJson(packJson);
    }
    final dataJson = response['data'];
    if (dataJson is Map<String, dynamic>) {
      return Pack.fromJson(dataJson);
    }
    return Pack.fromJson(response);
  }
}
