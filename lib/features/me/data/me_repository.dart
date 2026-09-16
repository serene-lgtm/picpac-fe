import '../../../core/network/api_client.dart';
import 'me.dart';
import 'account_security.dart';

abstract class MeRepository {
  Future<MeUser> getMe();

  Future<AccountSecurity> getSecurity();

  Future<void> setupPassword({required String phone, required String password});

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  });

  Future<MeUser> updateProfile({
    required String username,
    required String gender,
    String birthday,
    MultipartFilePart? avatar,
  });
}

class ApiMeRepository implements MeRepository {
  ApiMeRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> resetPassword({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    await _client.postJson(
      '/api/v1/auth/password/reset',
      body: {'phone': phone, 'code': code, 'new_password': newPassword},
    );
  }

  @override
  Future<AccountSecurity> getSecurity() async {
    return AccountSecurity.fromJson(
      await _client.getJson('/api/v1/auth/security'),
    );
  }

  @override
  Future<void> setupPassword({
    required String phone,
    required String password,
  }) async {
    await _client.postJson(
      '/api/v1/auth/password/setup',
      body: {'phone': phone, 'password': password},
    );
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.putJson(
      '/api/v1/auth/password',
      body: {'old_password': oldPassword, 'new_password': newPassword},
      refreshOnUnauthorized: false,
    );
  }

  @override
  Future<MeUser> getMe() async {
    final response = await _client.getJson('/api/v1/me');
    return MeUser.fromJson(response);
  }

  @override
  Future<MeUser> updateProfile({
    required String username,
    required String gender,
    String birthday = '',
    MultipartFilePart? avatar,
  }) async {
    final response = await _client.putMultipart(
      '/api/v1/me/profile',
      fields: <String, String>{
        'username': username.trim(),
        'gender': gender,
        'birthday': birthday.trim(),
      },
      file: avatar,
    );
    return MeUser.fromJson(response);
  }
}
