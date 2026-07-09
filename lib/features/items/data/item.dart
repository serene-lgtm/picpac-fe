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

  String get bestImageUrl {
    final urls = imageUrls;
    return urls.isEmpty ? '' : urls.first;
  }

  List<String> get imageUrls {
    final urls = <String>[];
    for (final url in [imageThumbnailUrl, sourceImageUrl, aiRenderedImageUrl]) {
      if (url.isNotEmpty && !urls.contains(url)) {
        urls.add(url);
      }
    }
    return urls;
  }

  Item normalizeImageUrls(String Function(String url) normalize) {
    return Item(
      id: id,
      userId: userId,
      name: name,
      description: description,
      sourceImageUrl: normalize(sourceImageUrl),
      imageThumbnailUrl: normalize(imageThumbnailUrl),
      aiRenderedImageUrl: normalize(aiRenderedImageUrl),
      status: status,
    );
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'];
    final nestedImage = imageJson is Map<String, dynamic>
        ? imageJson
        : const <String, dynamic>{};
    final deepUrls = _deepImageStrings(json);
    return Item(
      id: _stringFrom(json, const ['id', '_id']) ?? '',
      userId: _stringFrom(json, const ['user_id', 'userId']) ?? '',
      name: _stringFrom(json, const ['name']) ?? '',
      description: _stringFrom(json, const ['description']) ?? '',
      sourceImageUrl:
          _stringFrom(json, const [
            'source_image_url',
            'sourceImageUrl',
            'sourceImageURL',
            'SourceImageUrl',
            'SourceImageURL',
            'source_url',
            'sourceUrl',
            'sourceURL',
            'SourceUrl',
            'SourceURL',
            'image_url',
            'imageUrl',
            'imageURL',
            'ImageUrl',
            'ImageURL',
            'url',
            'Url',
            'URL',
            'image',
            'Image',
          ]) ??
          _stringFrom(nestedImage, const [
            'source_image_url',
            'sourceImageUrl',
            'sourceImageURL',
            'SourceImageUrl',
            'SourceImageURL',
            'source_url',
            'sourceUrl',
            'sourceURL',
            'SourceUrl',
            'SourceURL',
            'image_url',
            'imageUrl',
            'imageURL',
            'ImageUrl',
            'ImageURL',
            'url',
            'Url',
            'URL',
          ]) ??
          _firstImageString(deepUrls) ??
          '',
      imageThumbnailUrl:
          _stringFrom(json, const [
            'image_thumbnail_url',
            'imageThumbnailUrl',
            'imageThumbnailURL',
            'ImageThumbnailUrl',
            'ImageThumbnailURL',
            'thumbnail_url',
            'thumbnailUrl',
            'thumbnailURL',
            'ThumbnailUrl',
            'ThumbnailURL',
          ]) ??
          _stringFrom(nestedImage, const [
            'image_thumbnail_url',
            'imageThumbnailUrl',
            'imageThumbnailURL',
            'ImageThumbnailUrl',
            'ImageThumbnailURL',
            'thumbnail_url',
            'thumbnailUrl',
            'thumbnailURL',
            'ThumbnailUrl',
            'ThumbnailURL',
          ]) ??
          _firstImageString(deepUrls, preferredTerms: const ['thumb']) ??
          '',
      aiRenderedImageUrl:
          _stringFrom(json, const [
            'ai_rendered_image_url',
            'aiRenderedImageUrl',
            'aiRenderedImageURL',
            'AIRenderedImageUrl',
            'AIRenderedImageURL',
            'rendered_image_url',
            'renderedImageUrl',
            'renderedImageURL',
            'RenderedImageUrl',
            'RenderedImageURL',
          ]) ??
          _stringFrom(nestedImage, const [
            'ai_rendered_image_url',
            'aiRenderedImageUrl',
            'aiRenderedImageURL',
            'AIRenderedImageUrl',
            'AIRenderedImageURL',
            'rendered_image_url',
            'renderedImageUrl',
            'renderedImageURL',
            'RenderedImageUrl',
            'RenderedImageURL',
          ]) ??
          _firstImageString(deepUrls, preferredTerms: const ['render', 'ai']) ??
          '',
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

List<String> _deepImageStrings(Object? value, [String keyPath = '']) {
  final results = <String>[];
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final nextPath = keyPath.isEmpty ? key : '$keyPath.$key';
      results.addAll(_deepImageStrings(entry.value, nextPath));
    }
    return results;
  }
  if (value is Iterable) {
    var index = 0;
    for (final item in value) {
      results.addAll(_deepImageStrings(item, '$keyPath.$index'));
      index += 1;
    }
    return results;
  }
  if (value is String && _isImageCandidate(keyPath, value)) {
    results.add(value.trim());
  }
  return results;
}

String? _firstImageString(
  List<String> values, {
  List<String> preferredTerms = const [],
}) {
  for (final term in preferredTerms) {
    for (final value in values) {
      if (value.toLowerCase().contains(term)) return value;
    }
  }
  return values.isEmpty ? null : values.first;
}

bool _isImageCandidate(String keyPath, String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final lowerKey = keyPath.toLowerCase();
  final keyLooksRelevant =
      lowerKey.contains('image') ||
      lowerKey.contains('photo') ||
      lowerKey.contains('picture') ||
      lowerKey.contains('thumb') ||
      lowerKey.contains('avatar') ||
      lowerKey.endsWith('url') ||
      lowerKey.endsWith('uri') ||
      lowerKey.endsWith('path');
  if (!keyLooksRelevant) return false;

  final lowerValue = trimmed.toLowerCase();
  return lowerValue.startsWith('http://') ||
      lowerValue.startsWith('https://') ||
      lowerValue.startsWith('//') ||
      lowerValue.startsWith('/') ||
      lowerValue.endsWith('.png') ||
      lowerValue.endsWith('.jpg') ||
      lowerValue.endsWith('.jpeg') ||
      lowerValue.endsWith('.webp') ||
      lowerValue.endsWith('.gif');
}
