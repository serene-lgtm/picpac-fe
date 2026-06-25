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
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      items: (json['items'] as List?)?.whereType<String>().toList() ?? const [],
      status: json['status'] as String? ?? '',
    );
  }
}
