class Pack {
  const Pack({
    required this.id,
    required this.name,
    this.userId = '',
    this.description = '',
    this.items = const [],
    this.status = '',
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final List<String> items;
  final String status;

  factory Pack.fromJson(Map<String, dynamic> json) {
    return Pack(
      id: _stringFrom(json, const ['id', '_id']) ?? '',
      userId: _stringFrom(json, const ['user_id', 'userId']) ?? '',
      name: _stringFrom(json, const ['name']) ?? '',
      description: _stringFrom(json, const ['description']) ?? '',
      items: _stringListFrom(json['items']),
      status: _stringFrom(json, const ['status']) ?? '',
    );
  }
}

String? _stringFrom(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

List<String> _stringListFrom(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) {
        if (item is String) return item.trim();
        if (item is Map<String, dynamic>) {
          return _stringFrom(item, const ['id', '_id']);
        }
        return null;
      })
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
