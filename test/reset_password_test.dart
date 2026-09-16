import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_exception.dart';
import 'package:picpac_fe/features/auth/data/auth_repository.dart';
import 'package:picpac_fe/features/me/data/me_repository.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_password_page.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_reset_password_page.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_session_scope.dart';
import 'password_flows_test.dart' as helpers;

class _Auth implements AuthRepository {
  final phones = <String>[];
  ApiException? error;
  @override
  Future<void> sendPhoneCode(String phone) async {
    phones.add(phone);
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Me implements MeRepository {
  final requests = <List<String>>[];
  ApiException? error;
  @override
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    requests.add([phone, code, newPassword]);
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_PASSWORD_UI')) return;
    final font = FontLoader('PreviewFont')
      ..addFont(
        File(
          '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '/Users/shu/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
    await icons.load();
  });
  testWidgets('reset layout preview', (tester) async {
    helpers.size(tester);
    await tester.pumpWidget(
      helpers.app(
        MeResetPasswordPage(
          meRepository: _Me(),
          authRepository: _Auth(),
          phone: '13800138000',
        ),
      ),
    );
    await tester.enterText(helpers.passwordField(0), '123@piacpi');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await helpers.capture(tester, 'reset-password');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'forgot password opens reset; verifies once and returns to login after toast',
    (tester) async {
      helpers.size(tester);
      final auth = _Auth();
      final me = _Me();
      var cleared = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MeSessionScope(
            authRepository: auth,
            onLogout: () async {
              fail('Reset should only clear local credentials');
            },
            onPasswordChanged: () async {
              cleared++;
            },
            child: child!,
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MePasswordPage(
                    meRepository: me,
                    isSetup: false,
                    phone: '+8613800138000',
                  ),
                ),
              ),
              child: const Text('登录页'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('登录页'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('忘记密码？通过手机验证码重置'));
      await tester.tap(find.text('忘记密码？通过手机验证码重置'));
      await tester.pumpAndSettle();
      expect(find.byType(MeResetPasswordPage), findsOneWidget);
      expect(find.text('+86 138****8000'), findsOneWidget);
      await tester.enterText(helpers.passwordField(0), 'NewPass2026!');
      await tester.enterText(helpers.passwordField(1), 'NewPass2026!');
      await tester.enterText(
        find.byKey(const ValueKey('reset-code')),
        '123456',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('确认重置'));
      await tester.tap(find.text('确认重置'));
      await tester.pump();
      expect(me.requests.single, ['+8613800138000', '123456', 'NewPass2026!']);
      expect(auth.phones, isEmpty); // dev codes do not require sending first.
      expect(find.text('修改成功'), findsOneWidget);
      expect(cleared, 0);
      await tester.pump(const Duration(milliseconds: 1999));
      expect(cleared, 0);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(cleared, 1);
      expect(find.text('登录页'), findsOneWidget);
      expect(find.byType(MeResetPasswordPage), findsNothing);
    },
  );

  testWidgets(
    'small screen: full phone fallback, countdown, validation and retry',
    (tester) async {
      helpers.size(tester, 320);
      final auth = _Auth();
      final me = _Me()
        ..error = ApiException('phone code is invalid', statusCode: 400);
      var cleared = 0;
      await tester.pumpWidget(
        helpers.app(
          MeSessionScope(
            onLogout: () async {
              cleared++;
            },
            child: MeResetPasswordPage(
              meRepository: me,
              authRepository: auth,
              phone: '138****8000',
            ),
          ),
        ),
      );
      await tester.enterText(helpers.passwordField(0), 'NewPass2026!');
      await tester.enterText(helpers.passwordField(1), 'mismatch');
      await tester.pump();
      expect(find.text('两次输入的密码不一致'), findsOneWidget);
      await tester.enterText(helpers.passwordField(1), 'NewPass2026!');
      await tester.ensureVisible(find.byKey(const ValueKey('reset-phone')));
      await tester.enterText(
        find.byKey(const ValueKey('reset-phone')),
        '13800138000',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('发送验证码'));
      await tester.tap(find.text('发送验证码'));
      await tester.pump();
      expect(auth.phones, ['13800138000']);
      expect(find.text('60s 后重发'), findsOneWidget);
      await tester.tap(find.text('60s 后重发'));
      expect(auth.phones.length, 1);
      await tester.enterText(find.byKey(const ValueKey('reset-code')), '12345');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认重置'))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('reset-code')),
        '123456',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('确认重置'));
      await tester.tap(find.text('确认重置'));
      await tester.pump();
      expect(find.textContaining('重置失败，请检查'), findsOneWidget);
      expect(cleared, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(find.textContaining('重置失败，请检查'), findsNothing);
      expect(
        tester.widget<TextField>(helpers.passwordField(0)).controller!.text,
        'NewPass2026!',
      );
      me.error = null;
      await tester.tap(find.text('确认重置'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(cleared, 1);
      expect(me.requests.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('send failure shows transient toast and permits retry', (
    tester,
  ) async {
    helpers.size(tester);
    final auth = _Auth()..error = ApiException('too frequent', statusCode: 429);
    await tester.pumpWidget(
      helpers.app(
        MeResetPasswordPage(
          meRepository: _Me(),
          authRepository: auth,
          phone: '13800138000',
        ),
      ),
    );
    await tester.ensureVisible(find.text('发送验证码'));
    await tester.tap(find.text('发送验证码'));
    await tester.pump();
    expect(find.text('操作过于频繁，请稍后重试'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('操作过于频繁，请稍后重试'), findsNothing);
    auth.error = null;
    await tester.tap(find.text('发送验证码'));
    await tester.pump();
    expect(auth.phones.length, 2);
    await tester.pump(const Duration(seconds: 60));
    expect(find.text('发送验证码'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
