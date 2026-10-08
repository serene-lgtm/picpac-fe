import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/core/network/api_client.dart';
import 'package:picpac_fe/core/network/api_exception.dart';
import 'package:picpac_fe/features/me/data/me.dart';
import 'package:picpac_fe/features/me/data/me_repository.dart';
import 'package:picpac_fe/features/me/presentation/pages/me_profile_page.dart';

class _Me implements MeRepository {
  ApiException? error = ApiException('update failed', statusCode: 500);
  int calls = 0;
  String? savedUsername;
  @override
  Future<MeUser> updateProfile({
    required String username,
    required String gender,
    String birthday = '',
    MultipartFilePart? avatar,
  }) async {
    calls++;
    savedUsername = username;
    if (error != null) throw error!;
    return MeUser(
      id: 'u',
      profile: MeProfile(
        username: username,
        gender: gender,
        birthday: birthday,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'save failure is visible; inputs survive and retry returns updated profile',
    (tester) async {
      final repository = _Me();
      MeUser? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<MeUser>(
                    MaterialPageRoute(
                      builder: (_) => MeProfilePage(
                        meRepository: repository,
                        initialUser: const MeUser(
                          id: 'u',
                          profile: MeProfile(
                            username: '测试用户',
                            gender: 'female',
                            birthday: '2008-01-01',
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('打开资料'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开资料'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '修改后的名字');
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(repository.calls, 1);
      expect(find.text('保存失败，服务暂时不可用，请稍后重试'), findsOneWidget);
      expect(find.text('修改后的名字'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('保存失败，服务暂时不可用，请稍后重试'), findsNothing);
      repository.error = null;
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(result?.profile.username, '修改后的名字');
      expect(find.text('打开资料'), findsOneWidget);
    },
  );
}
