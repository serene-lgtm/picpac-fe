import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/app/theme.dart';
import 'package:picpac_fe/core/network/api_exception.dart';
import 'package:picpac_fe/features/auth/data/auth_repository.dart';
import 'package:picpac_fe/features/auth/presentation/pages/login_page.dart';
import 'package:picpac_fe/features/auth/presentation/widgets/password_field.dart';
import 'package:picpac_fe/features/me/data/me.dart';
import 'package:picpac_fe/features/me/data/account_security.dart';
import 'package:picpac_fe/features/me/data/me_repository.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_password_page.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_account_security_page.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_session_scope.dart';

class _Auth implements AuthRepository {
  int passwordCalls = 0;
  int codeCalls = 0;
  int sendCalls = 0;
  ApiException? error;
  @override
  Future<void> sendPhoneCode(String phone) async {
    sendCalls++;
  }

  @override
  Future<AuthSession> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    passwordCalls++;
    if (error != null) throw error!;
    return const AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      user: MeUser(id: 'u', profile: MeProfile()),
    );
  }

  @override
  Future<AuthSession> loginWithPhone({
    required String phone,
    required String code,
  }) async {
    codeCalls++;
    return const AuthSession(
      accessToken: 'a',
      refreshToken: 'r',
      user: MeUser(id: 'u', profile: MeProfile()),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Me implements MeRepository {
  bool passwordSetup = false;
  bool securityFails = false;
  int securityCalls = 0;
  @override
  Future<AccountSecurity> getSecurity() async {
    securityCalls++;
    if (securityFails) throw ApiException('failed', statusCode: 500);
    return AccountSecurity(phone: '138****8000', passwordSetup: passwordSetup);
  }

  @override
  Future<MeUser> getMe() async => const MeUser(
    id: 'u',
    profile: MeProfile(username: '测试用户'),
  );

  int setups = 0;
  int changes = 0;
  String? phone;
  String? password;
  String? oldPassword;
  ApiException? error;
  @override
  Future<void> setupPassword({
    required String phone,
    required String password,
  }) async {
    setups++;
    this.phone = phone;
    this.password = password;
    if (error != null) throw error!;
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    changes++;
    this.oldPassword = oldPassword;
    password = newPassword;
    if (error != null) throw error!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void size(WidgetTester tester, [double width = 393]) {
  tester.view.physicalSize = Size(width, 852);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PASSWORD_UI')) return;
  if (find.byType(LoginPage).evaluate().isNotEmpty) {
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/common/me_cover.png'),
        tester.element(find.byType(LoginPage)),
      ),
    );
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      '/tmp/picpac-$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Widget app(Widget child) => MaterialApp(
  theme: const bool.fromEnvironment('CAPTURE_PASSWORD_UI')
      ? PicpacTheme.light().copyWith(
          textTheme: PicpacTheme.light().textTheme.apply(
            fontFamily: 'PreviewFont',
          ),
        )
      : PicpacTheme.light(),
  home: RepaintBoundary(key: const ValueKey('capture'), child: child),
);
Finder passwordField(int index) => find.descendant(
  of: find.byType(PasswordField).at(index),
  matching: find.byType(TextField),
);

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_PASSWORD_UI')) return;
    final font = FontLoader('PreviewFont')
      ..addFont(
        File(
          '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        File(
          '/Users/shu/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        ).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
    await font.load();
    await icons.load();
  });
  testWidgets(
    'login tabs, valid phone gate, password login and code registration',
    (tester) async {
      size(tester);
      final auth = _Auth();
      var logins = 0;
      await tester.pumpWidget(
        app(
          LoginPage(
            authRepository: auth,
            onLogin: (_) {
              logins++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '获取验证码'))
            .onPressed,
        isNull,
      );
      await capture(tester, 'login-code');
      await tester.enterText(find.byType(TextField).first, '13800138000');
      await tester.pump();
      await tester.tap(find.text('获取验证码'));
      await tester.pumpAndSettle();
      expect(auth.sendCalls, 1);
      await tester.tap(find.text('密码登录'));
      await tester.pumpAndSettle();
      await capture(tester, 'login-password');
      await tester.enterText(passwordField(0), 'Password123');
      await tester.pump();
      await tester.tap(find.byTooltip('显示密码'));
      expect(tester.widget<TextField>(passwordField(0)).obscureText, isTrue);
      await tester.pump();
      expect(tester.widget<TextField>(passwordField(0)).obscureText, isFalse);
      await tester.ensureVisible(find.widgetWithText(FilledButton, '登录'));
      await tester.tap(find.widgetWithText(FilledButton, '登录'));
      await tester.pumpAndSettle();
      expect(auth.passwordCalls, 1);
      expect(logins, 1);
      await tester.tap(find.text('验证码注册'));
      await tester.pumpAndSettle();
      expect(find.text('登录 / 注册'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.pump();
      await tester.ensureVisible(find.text('登录 / 注册'));
      await tester.tap(find.text('登录 / 注册'));
      await tester.pumpAndSettle();
      expect(auth.codeCalls, 1);
      expect(logins, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'locked password login offers code login and does not authenticate',
    (tester) async {
      size(tester, 320);
      final auth = _Auth()
        ..error = ApiException(
          '{"error":"password is locked"}',
          statusCode: 403,
        );
      var logins = 0;
      await tester.pumpWidget(
        app(
          LoginPage(
            authRepository: auth,
            onLogin: (_) {
              logins++;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).first, '13800138000');
      await tester.pump();
      await tester.tap(find.text('密码登录'));
      await tester.pump();
      await tester.enterText(passwordField(0), 'Password123');
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(FilledButton, '登录'));
      await tester.tap(find.widgetWithText(FilledButton, '登录'));
      await tester.pumpAndSettle();
      expect(find.textContaining('密码登录已锁定'), findsOneWidget);
      expect(logins, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final isSetup in [true, false]) {
    testWidgets('password form validates and submits: setup=$isSetup', (
      tester,
    ) async {
      size(tester);
      final repository = _Me();
      var cleared = 0;
      await tester.pumpWidget(
        app(
          MeSessionScope(
            onLogout: () async {},
            onPasswordChanged: () async {
              cleared++;
            },
            child: MePasswordPage(
              meRepository: repository,
              isSetup: isSetup,
              phone: '13800138000',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (!isSetup) await tester.enterText(passwordField(0), 'OldPassword1');
      await tester.pump();
      final newIndex = isSetup ? 0 : 1;
      await tester.enterText(passwordField(newIndex), 'abc123ABC');
      await tester.pump();
      await tester.enterText(passwordField(newIndex + 1), 'different');
      await tester.pump();
      expect(find.text('两次输入的密码不一致'), findsOneWidget);
      await capture(tester, isSetup ? 'setup-password' : 'change-password');
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认修改'))
            .onPressed,
        isNull,
      );
      await tester.enterText(passwordField(newIndex + 1), 'abc123ABC');
      await tester.pump();
      await tester.ensureVisible(find.text('确认修改'));
      await tester.tap(find.text('确认修改'));
      await tester.pump();
      expect(repository.password, 'abc123ABC');
      if (isSetup) {
        expect(repository.phone, '13800138000');
        expect(repository.setups, 1);
        expect(cleared, 0);
        expect(find.text('密码设置成功'), findsOneWidget);
        await tester.pump(const Duration(seconds: 2));
      } else {
        expect(repository.oldPassword, 'OldPassword1');
        expect(repository.changes, 1);
        expect(cleared, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'account security routes using server state and refreshes on return',
    (tester) async {
      size(tester);
      final repository = _Me();
      await tester.pumpWidget(
        app(
          MeSessionScope(
            onLogout: () async {},
            phone: '13800138000',
            child: MeAccountSecurityPage(meRepository: repository),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('已设置'), findsNothing);
      expect(find.text('未设置'), findsOneWidget);
      expect(find.text('138****8000'), findsOneWidget);
      await capture(tester, 'account-security');
      await tester.tap(find.text('登录密码'));
      await tester.pumpAndSettle();

      final setup = tester.widget<MePasswordPage>(find.byType(MePasswordPage));
      expect(setup.isSetup, isTrue);
      expect(setup.phone, '13800138000');
      repository.passwordSetup = true;
      Navigator.of(tester.element(find.byType(MePasswordPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('已设置'), findsOneWidget);
      expect(repository.securityCalls, 2);
      await tester.tap(find.text('登录密码'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<MePasswordPage>(find.byType(MePasswordPage)).isSetup,
        isFalse,
      );
    },
  );

  testWidgets('security failures cannot route to setup until retry succeeds', (
    tester,
  ) async {
    size(tester);
    final repository = _Me()..securityFails = true;
    await tester.pumpWidget(
      app(MeAccountSecurityPage(meRepository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('登录密码'), findsNothing);
    expect(find.text('账号安全信息加载失败，请重试'), findsOneWidget);
    repository.securityFails = false;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登录密码'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MePasswordPage>(find.byType(MePasswordPage)).phone,
      isEmpty,
    );
    expect(find.text('确认当前账号手机号'), findsOneWidget);
  });

  testWidgets(
    'wrong current password stays on the form without clearing session',
    (tester) async {
      size(tester, 320);
      final repository = _Me()
        ..error = ApiException('password is invalid', statusCode: 401);
      var cleared = 0;
      await tester.pumpWidget(
        app(
          MeSessionScope(
            onLogout: () async {
              cleared++;
            },
            child: MePasswordPage(
              meRepository: repository,
              isSetup: false,
              phone: '13800138000',
            ),
          ),
        ),
      );
      await tester.enterText(passwordField(0), 'OldPassword1');
      await tester.pump();
      await tester.enterText(passwordField(1), 'NewPassword1');
      await tester.pump();
      await tester.enterText(passwordField(2), 'NewPassword1');
      await tester.pump();
      await tester.ensureVisible(find.text('确认修改'));
      await tester.tap(find.text('确认修改'));
      await tester.pumpAndSettle();
      expect(cleared, 0);
      expect(find.textContaining('当前密码错误'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
