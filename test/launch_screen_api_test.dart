import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/features/launch_screen/data/launch_screen_repository.dart';

void main() {
  test('fetches public launch config and preserves signed URL', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final http = HttpClient();
    addTearDown(() {
      http.close(force: true);
      return server.close(force: true);
    });
    const url = 'https://example.com/image.webp?Expires=123&Signature=a%2Bb';
    final served = server.first.then((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/v1/app/launch-screen');
      expect(request.headers.value('authorization'), isNull);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'enabled': true,
          'revision': '2026-10-08',
          'type': 'image',
          'media_url': url,
          'poster_url': '',
          'duration_ms': 2500,
          'skip_enabled': false,
        }),
      );
      await request.response.close();
    });
    final config = await ApiLaunchScreenRepository(
      ApiClient(
        baseUrl: 'http://localhost:${server.port}',
        httpClient: http,
        accessTokenProvider: () => 'private-token',
      ),
    ).getLaunchScreen();
    await served;
    expect(config.imageUrl, url);
    expect(config.revision, '2026-10-08');
    expect(config.duration, const Duration(milliseconds: 2500));
    expect(config.skipEnabled, isFalse);
  });
}
