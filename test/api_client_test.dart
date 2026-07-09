import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';

void main() {
  test('postMultipart sends unicode fields as utf8 text parts', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);

    late String body;
    final requestDone = Completer<void>();
    unawaited(
      server.first.then((request) async {
        body = await utf8.decodeStream(request);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write('{"id":"1","name":"抽纸"}');
        await request.response.close();
        requestDone.complete();
      }),
    );

    final client = ApiClient(baseUrl: 'http://localhost:${server.port}');
    await client.postMultipart('/api/v1/item', fields: {'name': '抽纸'});
    await requestDone.future;

    expect(body, contains('Content-Type: text/plain; charset=utf-8'));
    expect(body, contains('抽纸'));
  });

  test('resolveUrl normalizes image URL variants', () {
    final client = ApiClient(baseUrl: 'http://localhost:9090/api');

    expect(
      client.resolveUrl('/uploads/item.png'),
      'http://localhost:9090/uploads/item.png',
    );
    expect(
      client.resolveUrl('uploads/item.png'),
      'http://localhost:9090/uploads/item.png',
    );
    expect(
      client.resolveUrl('//cdn.example.com/item.png'),
      'http://cdn.example.com/item.png',
    );
    expect(
      client.resolveUrl('cdn.example.com/item.png'),
      'https://cdn.example.com/item.png',
    );
    expect(
      client.resolveUrl('http://cdn.example.com/item.png'),
      'https://cdn.example.com/item.png',
    );
    expect(
      client.resolveUrl('http://localhost:9090/item.png'),
      'http://localhost:9090/item.png',
    );
  });
}
