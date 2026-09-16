import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/app/app.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/core/network/api_exception.dart';
import 'package:picpac_fe/features/auth/data/auth_repository.dart';
import 'package:picpac_fe/features/auth/data/session_store.dart';
import 'package:picpac_fe/features/auth/presentation/pages/login_page.dart';
import 'package:picpac_fe/features/items/data/item.dart';
import 'package:picpac_fe/features/items/data/item_repository.dart';
import 'package:picpac_fe/features/items/presentation/pages/items_page.dart';
import 'package:picpac_fe/features/me/data/me.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_session_scope.dart';

class _RealHttp extends HttpOverrides {}

class _Items implements ItemRepository {
  @override
  Future<List<Item>> listItems({
    String? userId,
    String? q,
    String? categoryId,
  }) async => [];
  @override
  Future<List<ItemCategory>> listCategories() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Store implements SessionStore {
  AuthSession? session = const AuthSession(
    accessToken: 'expired',
    refreshToken: 'refresh',
    user: MeUser(id: 'u', profile: MeProfile()),
  );
  int clears = 0;
  @override
  Future<AuthSession?> read() async => session;
  @override
  Future<void> write(AuthSession value) async {
    session = value;
  }

  @override
  Future<void> clear() async {
    clears++;
    session = null;
  }
}

void main() {
  test(
    'expired authorization signs out without refresh or retry; credential errors stay local',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var requests = 0;
      server.listen((request) async {
        requests++;
        await request.drain<void>();
        request.response.statusCode = 401;
        request.response.write(
          jsonEncode({
            'error': request.uri.path == '/wrong-password'
                ? 'password is invalid'
                : 'access token is expired',
          }),
        );
        await request.response.close();
      });
      final expiredTokens = <String?>[];
      var refreshes = 0;
      final client = ApiClient(
        httpClient: _RealHttp().createHttpClient(null),
        baseUrl: 'http://localhost:${server.port}',
        accessTokenProvider: () => 'expired',
        onSessionExpired: (token) async {
          expiredTokens.add(token);
        },
        onUnauthorized: () async {
          refreshes++;
          return true;
        },
      );
      Future<void> fails(Future<dynamic> request) =>
          expectLater(request, throwsA(isA<ApiException>()));
      await fails(client.getJson('/items'));
      expect(expiredTokens, ['expired']);
      expect(requests, 1);
      expect(refreshes, 0);
      await fails(
        client.putJson(
          '/wrong-password',
          body: {},
          refreshOnUnauthorized: false,
        ),
      );
      expect(expiredTokens.length, 1);
      await fails(
        client.putJson('/password', body: {}, refreshOnUnauthorized: false),
      );
      expect(expiredTokens.length, 2);
      await fails(client.postJson('/login', body: {}, requiresAuth: false));
      expect(expiredTokens.length, 2);
      await fails(client.postMultipart('/upload', fields: {}));
      expect(expiredTokens.length, 3);
    },
  );

  testWidgets(
    'clearing session dismisses nested pages and dialogs and persists logout',
    (tester) async {
      final store = _Store();
      await tester.pumpWidget(
        PicpacApp(sessionStore: store, itemRepository: _Items()),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(ItemsPage));
      final session = MeSessionScope.of(context);
      final navigator = Navigator.of(context);
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('过期页面')),
        ),
      );
      await tester.pumpAndSettle();
      showDialog<void>(
        context: tester.element(find.text('过期页面')),
        builder: (_) => const AlertDialog(content: Text('操作弹窗')),
      );
      await tester.pumpAndSettle();
      await session.passwordChanged();
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('过期页面'), findsNothing);
      expect(find.text('操作弹窗'), findsNothing);
      expect(navigator.canPop(), isFalse);
      expect(store.session, isNull);
      expect(store.clears, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
