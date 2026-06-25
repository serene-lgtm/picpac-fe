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
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      targetDate: json['target_date'] as String? ?? '',
      items:
          (json['items'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChecklistLineItem.fromJson)
              .toList(growable: false) ??
          const [],
      status: json['status'] as String? ?? '',
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
      id: json['id'] as String? ?? '',
      referenceType: json['reference_type'] as String? ?? '',
      referenceId: json['reference_id'] as String? ?? '',
      snapshotName: snapshot is Map<String, dynamic>
          ? snapshot['name'] as String? ?? ''
          : '',
      status: json['status'] as String? ?? 'unchecked',
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
