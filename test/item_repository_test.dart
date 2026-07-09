import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';
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
}
