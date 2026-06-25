class Item {
  const Item({
    required this.id,
    required this.name,
    this.userId = '',
    this.description = '',
    this.sourceImageUrl = '',
    this.imageThumbnailUrl = '',
    this.aiRenderedImageUrl = '',
    this.status = '',
  });

  final String id;
  final String userId;
  final String name;
  final String description;
  final String sourceImageUrl;
  final String imageThumbnailUrl;
  final String aiRenderedImageUrl;
  final String status;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      sourceImageUrl: json['source_image_url'] as String? ?? '',
      imageThumbnailUrl: json['image_thumbnail_url'] as String? ?? '',
      aiRenderedImageUrl: json['ai_rendered_image_url'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
