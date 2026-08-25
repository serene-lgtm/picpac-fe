import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/checklists/data/checklist.dart';
import 'package:picpac_fe/features/items/data/item.dart';

void main() {
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

  test('fromJson reads Go-style URL acronym image fields', () {
    final item = Item.fromJson({
      'id': 'item-1',
      'name': '抹茶鸭',
      'SourceImageURL': 'https://cdn.example.com/items/source.png',
      'ImageThumbnailURL': 'https://cdn.example.com/items/thumb.png',
    });

    expect(item.imageUrls, [
      'https://cdn.example.com/items/thumb.png',
      'https://cdn.example.com/items/source.png',
    ]);
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
