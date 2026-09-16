import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/core/network/api_exception.dart';
import 'package:picpac_fe/features/auth/data/auth_repository.dart';
import 'package:picpac_fe/features/me/data/me_repository.dart';

void main() {
  test(
    'password and code login use public endpoints and preserve passwords',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <Map<String, dynamic>>[];
      server.listen((request) async {
        requests.add({
          'path': request.uri.path,
          'method': request.method,
          'auth': request.headers.value('authorization'),
          'body': jsonDecode(await utf8.decodeStream(request)),
        });
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'access_token': 'access',
            'refresh_token': 'refresh',
            'user': {'id': 'u1'},
          }),
        );
        await request.response.close();
      });
      final repository = ApiAuthRepository(
        ApiClient(
          baseUrl: 'http://localhost:${server.port}',
          accessTokenProvider: () => 'stale',
        ),
      );
      final session = await repository.loginWithPassword(
        phone: '13800138000',
        password: ' Password1! ',
      );
      expect(session.accessToken, 'access');
      expect(session.refreshToken, 'refresh');
      expect(session.user.phone, '13800138000');
      await repository.loginWithPhone(phone: '13800138000', code: '123456');
      await repository.sendPhoneCode('13800138000');
      expect(requests.map((r) => r['path']), [
        '/api/v1/auth/phone/password/login',
        '/api/v1/auth/phone/code/login',
        '/api/v1/auth/phone/code',
      ]);
      expect(
        requests.every((r) => r['auth'] == null && r['method'] == 'POST'),
        isTrue,
      );
      expect(requests.first['body'], {
        'phone': '13800138000',
        'password': ' Password1! ',
      });
    },
  );

  test(
    'setup and change use authenticated JSON; wrong old password does not refresh',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var refreshes = 0;
      final requests = <Map<String, dynamic>>[];
      server.listen((request) async {
        requests.add({
          'path': request.uri.path,
          'method': request.method,
          'auth': request.headers.value('authorization'),
          'body': jsonDecode(await utf8.decodeStream(request)),
        });
        request.response.headers.contentType = ContentType.json;
        if (request.method == 'PUT') {
          request.response.statusCode = 401;
          request.response.write('{"error":"password is invalid"}');
        } else {
          request.response.write('{"setup":true}');
        }
        await request.response.close();
      });
      final repository = ApiMeRepository(
        ApiClient(
          baseUrl: 'http://localhost:${server.port}',
          accessTokenProvider: () => 'access',
          onUnauthorized: () async {
            refreshes++;
            return true;
          },
        ),
      );
      await repository.setupPassword(
        phone: '13800138000',
        password: 'NewPass123',
      );
      await repository.resetPassword(
        phone: '+8613800138000',
        code: '123456',
        newPassword: 'NextPass123!',
      );
      await expectLater(
        repository.changePassword(
          oldPassword: 'wrong',
          newPassword: 'NextPass123',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect(refreshes, 0);
      expect(requests, [
        {
          'path': '/api/v1/auth/password/setup',
          'method': 'POST',
          'auth': 'Bearer access',
          'body': {'phone': '13800138000', 'password': 'NewPass123'},
        },
        {
          'path': '/api/v1/auth/password/reset',
          'method': 'POST',
          'auth': 'Bearer access',
          'body': {
            'phone': '+8613800138000',
            'code': '123456',
            'new_password': 'NextPass123!',
          },
        },
        {
          'path': '/api/v1/auth/password',
          'method': 'PUT',
          'auth': 'Bearer access',
          'body': {'old_password': 'wrong', 'new_password': 'NextPass123'},
        },
      ]);
    },
  );
}
