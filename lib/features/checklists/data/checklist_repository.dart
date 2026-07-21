import '../../../core/network/api_client.dart';
import 'checklist.dart';

abstract class ChecklistRepository {
  Future<List<Checklist>> listChecklists({String? userId, String? q});

  Future<Checklist> getChecklist(String checklistId);

  Future<Checklist> createChecklist({
    required String name,
    required String targetDate,
    String description = '',
    String? userId,
    List<ChecklistItemInput> items = const [],
  });

  Future<Checklist> updateChecklist({
    required String checklistId,
    required String name,
    required String targetDate,
    String description = '',
  });

  Future<Checklist> addLineItems({
    required String checklistId,
    required List<ChecklistItemInput> items,
  });

  Future<Checklist> removeLineItems({
    required String checklistId,
    required List<String> lineItemIds,
  });

  Future<Checklist> updateLineItemStatus({
    required String checklistId,
    required String lineItemId,
    required String status,
  });

  Future<void> deleteChecklist(String checklistId);
}

class ApiChecklistRepository implements ChecklistRepository {
  ApiChecklistRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Checklist>> listChecklists({String? userId, String? q}) async {
    final response = await _client.getJson(
      '/api/v1/checklist',
      queryParameters: {'user_id': userId, 'q': q?.trim()},
    );
    final checklistsJson = response['checklists'];
    if (checklistsJson is! List) {
      return const [];
    }
    return checklistsJson
        .whereType<Map<String, dynamic>>()
        .map(Checklist.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Checklist> getChecklist(String checklistId) async {
    final response = await _client.getJson('/api/v1/checklist/$checklistId');
    return _checklistFromResponse(response);
  }

  @override
  Future<Checklist> createChecklist({
    required String name,
    required String targetDate,
    String description = '',
    String? userId,
    List<ChecklistItemInput> items = const [],
  }) async {
    final response = await _client.postJson(
      '/api/v1/checklist',
      body: {
        'name': name.trim(),
        'target_date': targetDate,
        'description': description.trim(),
        if (userId != null && userId.trim().isNotEmpty)
          'user_id': userId.trim(),
        if (items.isNotEmpty)
          'items': items.map((item) => item.toJson()).toList(growable: false),
      },
    );
    return _checklistFromResponse(response);
  }

  @override
  Future<Checklist> updateChecklist({
    required String checklistId,
    required String name,
    required String targetDate,
    String description = '',
  }) async {
    final response = await _client.putJson(
      '/api/v1/checklist/$checklistId',
      body: {
        'name': name.trim(),
        'target_date': targetDate,
        'description': description.trim(),
      },
    );
    return _checklistFromResponse(response);
  }

  @override
  Future<Checklist> addLineItems({
    required String checklistId,
    required List<ChecklistItemInput> items,
  }) async {
    final response = await _client.postJson(
      '/api/v1/checklist/$checklistId/items',
      body: {
        'items': items.map((item) => item.toJson()).toList(growable: false),
      },
    );
    return _checklistFromResponse(response);
  }

  @override
  Future<Checklist> removeLineItems({
    required String checklistId,
    required List<String> lineItemIds,
  }) async {
    final response = await _client.deleteJson(
      '/api/v1/checklist/$checklistId/items',
      body: {'line_item_ids': lineItemIds},
    );
    return _checklistFromResponse(response);
  }

  @override
  Future<Checklist> updateLineItemStatus({
    required String checklistId,
    required String lineItemId,
    required String status,
  }) async {
    final response = await _client.patchJson(
      '/api/v1/checklist/$checklistId/items/$lineItemId/status',
      body: {'status': status},
    );
    return Checklist.fromJson(response);
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    await _client.deleteJson('/api/v1/checklist/$checklistId');
  }

  Checklist _checklistFromResponse(Map<String, dynamic> response) {
    final checklistJson = response['checklist'];
    if (checklistJson is Map<String, dynamic>) {
      return Checklist.fromJson(checklistJson);
    }
    final dataJson = response['data'];
    if (dataJson is Map<String, dynamic>) {
      return Checklist.fromJson(dataJson);
    }
    return Checklist.fromJson(response);
  }
}
