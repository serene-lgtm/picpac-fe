import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/features/items/data/item.dart';
import 'package:picpac_fe/features/items/data/item_repository.dart';

void main() {
  test('getItem reads wrapped item response image URL', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    addTearDown(server.close);

    unawaited(
      server.first.then((request) async {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            '{"item":{"id":"item-1","name":"抹茶鸭",'
            '"source_image_url":"/uploads/item-1.png"}}',
          );
        await request.response.close();
      }),
    );

    final repository = ApiItemRepository(
      ApiClient(baseUrl: 'http://localhost:$port'),
    );

    final item = await repository.getItem('item-1');

    expect(item.name, '抹茶鸭');
    expect(item.bestImageUrl, 'http://localhost:$port/uploads/item-1.png');
  });

  test('generateItemDrafts posts text and reads draft items', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    late Uri requestUri;
    late Map<String, dynamic> requestBody;
    final requestDone = Completer<void>();
    unawaited(
      server.first.then((request) async {
        requestUri = request.uri;
        requestBody =
            jsonDecode(await utf8.decodeStream(request))
                as Map<String, dynamic>;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            '{"draft_items":[{"name":"手机","category_id":"category-1",'
            '"category_key":"electronics","category_name":"电子产品"}]}',
          );
        await request.response.close();
        requestDone.complete();
      }),
    );

    final repository = ApiItemRepository(
      ApiClient(baseUrl: 'http://localhost:${server.port}'),
    );

    final drafts = await repository.generateItemDrafts(' 手机、相机 ');
    await requestDone.future;

    expect(requestUri.path, '/api/v1/ai/item-drafts');
    expect(requestBody, {'text': '手机、相机'});
    expect(drafts, hasLength(1));
    expect(drafts.single.name, '手机');
    expect(drafts.single.categoryId, 'category-1');
    expect(drafts.single.categoryName, '电子产品');
  });

  test('batchCreateItems posts drafts and reads created items', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    late Uri requestUri;
    late Map<String, dynamic> requestBody;
    final requestDone = Completer<void>();
    unawaited(
      server.first.then((request) async {
        requestUri = request.uri;
        requestBody =
            jsonDecode(await utf8.decodeStream(request))
                as Map<String, dynamic>;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            '{"items":[{"id":"item-1","name":"手机",'
            '"category_id":"category-1","category_key":"electronics",'
            '"category_name":"电子产品"}]}',
          );
        await request.response.close();
        requestDone.complete();
      }),
    );

    final repository = ApiItemRepository(
      ApiClient(baseUrl: 'http://localhost:${server.port}'),
    );

    final items = await repository.batchCreateItems(const [
      ItemDraft(name: '手机', description: '备用机', categoryId: 'category-1'),
    ]);
    await requestDone.future;

    expect(requestUri.path, '/api/v1/item/batch');
    expect(requestBody, {
      'items': [
        {'name': '手机', 'description': '备用机', 'category_id': 'category-1'},
      ],
    });
    expect(items, hasLength(1));
    expect(items.single.id, 'item-1');
    expect(items.single.categoryName, '电子产品');
  });
}
