class Checklist {
  const Checklist({
    required this.id,
    required this.name,
    required this.targetDate,
    this.userId = '',
    this.description = '',
    this.items = const [],
    this.status = '',
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final String targetDate;
  final List<ChecklistLineItem> items;
  final String status;

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: _stringFrom(json, const ['id', '_id']) ?? '',
      userId: _stringFrom(json, const ['user_id', 'userId']) ?? '',
      name: _stringFrom(json, const ['name']) ?? '',
      description: _stringFrom(json, const ['description']) ?? '',
      targetDate: _stringFrom(json, const ['target_date', 'targetDate']) ?? '',
      items:
          (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChecklistLineItem.fromJson)
              .toList(growable: false) ??
          const [],
      status: _stringFrom(json, const ['status']) ?? '',
    );
  }
}

class ChecklistLineItem {
  const ChecklistLineItem({
    required this.id,
    required this.referenceType,
    this.referenceId = '',
    this.snapshotName = '',
    this.status = 'unchecked',
  });

  final String id;
  final String referenceType;
  final String referenceId;
  final String snapshotName;
  final String status;

  bool get checked => status == 'checked';

  factory ChecklistLineItem.fromJson(Map<String, dynamic> json) {
    final snapshot = json['snapshot'];
    return ChecklistLineItem(
      id: _stringFrom(json, const ['id', '_id']) ?? '',
      referenceType:
          _stringFrom(json, const ['reference_type', 'referenceType']) ?? '',
      referenceId:
          _stringFrom(json, const ['reference_id', 'referenceId']) ?? '',
      snapshotName: snapshot is Map<String, dynamic>
          ? _stringFrom(snapshot, const ['name']) ?? ''
          : '',
      status: _stringFrom(json, const ['status']) ?? 'unchecked',
    );
  }
}

class ChecklistItemInput {
  const ChecklistItemInput.item(this.itemId)
    : referenceType = 'item',
      snapshotName = '';

  const ChecklistItemInput.snapshot(this.snapshotName)
    : referenceType = 'snapshot',
      itemId = '';

  final String referenceType;
  final String itemId;
  final String snapshotName;

  Map<String, dynamic> toJson() {
    if (referenceType == 'item') {
      return {'reference_type': 'item', 'reference_id': itemId};
    }
    return {
      'reference_type': 'snapshot',
      'reference_id': '',
      'snapshot': {'name': snapshotName},
    };
  }
}

String? _stringFrom(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}
