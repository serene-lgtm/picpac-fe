import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/checklists/data/checklist.dart';
import 'package:picpac_fe/features/items/data/item.dart';

void main() {
  test('OSS default cover displays without becoming an uploaded photo', () {
    const cover =
        'https://picpac.oss-cn-shanghai.aliyuncs.com/items/default/cover.jpg'
        '?Expires=1783588103&OSSAccessKeyId=test&Signature=test%2Bsignature';
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '无照片物品',
      'cover_image_url': cover,
      'photos': [],
    });

    expect(item.bestImageUrl, cover);
    expect(item.displayImageUrls, [cover]);
    expect(item.sourceImageUrls, [cover]);
    expect(item.photos, isEmpty);
  });

  test('fromJson reads top-level url image field', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'url': 'https://cdn.example.com/items/item-1.png',
    });

    expect(item.bestImageUrl, 'https://cdn.example.com/items/item-1.png');
  });

  test('fromJson reads nested image url field', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'image': {'url': 'https://cdn.example.com/items/item-1.png'},
    });

    expect(item.bestImageUrl, 'https://cdn.example.com/items/item-1.png');
  });

  test('fromJson reads cover and photo source/display URLs', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'cover_image_url': 'https://cdn.example.com/items/cover.png',
      'photos': [
        {
          'id': 'photo-1',
          'source_image_url': 'https://cdn.example.com/items/source-1.png',
          'image_url': 'https://cdn.example.com/items/display-1.png',
        },
        {
          'id': 'photo-2',
          'source_image_url': 'https://cdn.example.com/items/source-2.png',
          'image_url': 'https://cdn.example.com/items/display-2.png',
        },
      ],
    });

    expect(item.bestImageUrl, 'https://cdn.example.com/items/cover.png');
    expect(item.imageUrls, [
      'https://cdn.example.com/items/cover.png',
      'https://cdn.example.com/items/display-1.png',
      'https://cdn.example.com/items/display-2.png',
    ]);
    expect(item.sourceImageUrls, [
      'https://cdn.example.com/items/source-1.png',
      'https://cdn.example.com/items/source-2.png',
    ]);
  });

  test('carousel uses only photos despite cover and legacy URL variants', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '衣服',
      'cover_image_url': '/photo-1.jpg?Signature=cover',
      'source_image_url': '/photo-1.jpg?Signature=legacy',
      'image_thumbnail_url': '/photo-1-thumb.jpg',
      'ai_rendered_image_url': '/photo-1-render.jpg',
      'photos': [
        {
          'id': 'photo-1',
          'source_image_url': '/photo-1.jpg?Signature=source',
          'image_url': '/photo-1.jpg?Signature=display',
        },
        {'id': 'photo-2', 'source_image_url': '/photo-2.jpg'},
        {'id': 'photo-3', 'image_url': '/photo-3.jpg'},
      ],
    });

    expect(item.displayImageUrls, [
      '/photo-1.jpg?Signature=display',
      '/photo-2.jpg',
      '/photo-3.jpg',
    ]);
    expect(item.sourceImageUrls, [
      '/photo-1.jpg?Signature=source',
      '/photo-2.jpg',
      '/photo-3.jpg',
    ]);
    expect(item.bestImageUrl, '/photo-1.jpg?Signature=cover');
  });

  test('carousel still supports legacy items without photos', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '衣服',
      'source_image_url': '/legacy.jpg',
    });

    expect(item.sourceImageUrls, ['/legacy.jpg']);
    expect(const Item(id: 'empty', name: '无照片').sourceImageUrls, isEmpty);
  });

  test('fromJson reads Go-style URL acronym image fields', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'SourceImageURL': 'https://cdn.example.com/items/source.png',
      'ImageThumbnailURL': 'https://cdn.example.com/items/thumb.png',
    });

    expect(item.imageUrls, ['https://cdn.example.com/items/thumb.png']);
  });

  test('fromJson reads string image field', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'image': 'https://cdn.example.com/items/item-1.png',
    });

    expect(item.bestImageUrl, 'https://cdn.example.com/items/item-1.png');
  });

  test('fromJson recursively reads nested image URL fields', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'images': [
        {'oss_url': 'https://cdn.example.com/items/item-1.png'},
      ],
    });

    expect(item.bestImageUrl, 'https://cdn.example.com/items/item-1.png');
  });

  test('fromJson recursively reads nested image path fields', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'source': {'path': '/uploads/items/item-1.png'},
    });

    expect(item.bestImageUrl, '/uploads/items/item-1.png');
  });

  test('checklist line reads item id aliases and snapshot name aliases', () {
    final itemLine = ChecklistLineItem.fromJson({
      'id': 'line-1',
      'reference_type': 'Item',
      'item_id': {r'$oid': 'item-1'},
    });
    final snapshotLine = ChecklistLineItem.fromJson({
      'id': 'line-2',
      'reference_type': 'snapshot',
      'snapshot_name': '临时雨伞',
    });

    expect(itemLine.referenceId, 'item-1');
    expect(itemLine.referenceType, 'item');
    expect(snapshotLine.snapshotName, '临时雨伞');
  });
}
