import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/features/me/data/account_security.dart';
import 'package:picpac_fe/features/me/data/me_repository.dart';

void main() {
  test(
    'security parses both states and empty phone without guessing missing state',
    () {
      expect(
        AccountSecurity.fromJson({
          'phone': '',
          'password_setup': false,
        }).passwordSetup,
        isFalse,
      );
      expect(
        AccountSecurity.fromJson({
          'phone': '138****8000',
          'password_setup': true,
        }).passwordSetup,
        isTrue,
      );
      expect(
        () => AccountSecurity.fromJson({'phone': '138****8000'}),
        throwsFormatException,
      );
      expect(
        () =>
            AccountSecurity.fromJson({'phone': '', 'password_setup': 'false'}),
        throwsFormatException,
      );
    },
  );

  test(
    'security fetch uses authenticated GET and retains masked phone',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      String? method;
      String? path;
      String? token;
      server.listen((request) async {
        method = request.method;
        path = request.uri.path;
        token = request.headers.value('authorization');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          '{"phone":"138****8000","password_setup":false}',
        );
        await request.response.close();
      });
      final repository = ApiMeRepository(
        ApiClient(
          baseUrl: 'http://localhost:${server.port}',
          accessTokenProvider: () => 'access',
        ),
      );
      final security = await repository.getSecurity();
      expect(method, 'GET');
      expect(path, '/api/v1/auth/security');
      expect(token, 'Bearer access');
      expect(security.phone, '138****8000');
      expect(security.passwordSetup, isFalse);
    },
  );
}
