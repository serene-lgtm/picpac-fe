import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/features/me/data/me_repository.dart';

void main() {
  test(
    'profile update sends authenticated PUT multipart and parses saved profile',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      late String method, path, body;
      String? auth, contentType;
      server.listen((request) async {
        method = request.method;
        path = request.uri.path;
        auth = request.headers.value('authorization');
        contentType = request.headers.value('content-type');
        body = await utf8.decodeStream(request);
        request.response.write(
          jsonEncode({
            'id': 'u',
            'profile': {
              'username': '测试用户',
              'gender': 'female',
              'birthday': '2008-01-01',
            },
          }),
        );
        await request.response.close();
      });
      final repository = ApiMeRepository(
        ApiClient(
          baseUrl: 'http://localhost:${server.port}',
          accessTokenProvider: () => 'access',
        ),
      );
      final updated = await repository.updateProfile(
        username: ' 测试用户 ',
        gender: 'female',
        birthday: '2008-01-01',
      );
      expect(method, 'PUT');
      expect(path, '/api/v1/me/profile');
      expect(auth, 'Bearer access');
      expect(contentType, startsWith('multipart/form-data; boundary='));
      for (final value in [
        'name="username"',
        '测试用户',
        'name="gender"',
        'female',
        'name="birthday"',
        '2008-01-01',
      ]) {
        expect(body, contains(value));
      }
      expect(body, isNot(contains('name="avatar"')));
      expect(updated.profile.username, '测试用户');
      expect(updated.profile.birthday, '2008-01-01');
    },
  );
}
