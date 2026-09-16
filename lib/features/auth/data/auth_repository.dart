import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../me/data/me.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final MeUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AuthSession(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      user: userJson is Map<String, dynamic>
          ? MeUser.fromJson(userJson)
          : const MeUser(id: '', profile: MeProfile()),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }

  String toStorageValue() => jsonEncode(toJson());

  static AuthSession? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      return AuthSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

abstract class AuthRepository {
  Future<void> sendPhoneCode(String phone);

  Future<AuthSession> loginWithPhone({
    required String phone,
    required String code,
  });

  Future<AuthSession> refreshSession({required String refreshToken});

  Future<AuthSession> loginWithPassword({
    required String phone,
    required String password,
  });

  Future<void> logout({required String refreshToken});
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> sendPhoneCode(String phone) async {
    await _client.postJson(
      '/api/v1/auth/phone/code',
      body: <String, dynamic>{'phone': phone},
      requiresAuth: false,
    );
  }

  @override
  Future<AuthSession> loginWithPhone({
    required String phone,
    required String code,
  }) async {
    final response = await _client.postJson(
      '/api/v1/auth/phone/code/login',
      body: <String, dynamic>{'phone': phone, 'code': code},
      requiresAuth: false,
    );
    return _loginSession(response, phone);
  }

  @override
  Future<AuthSession> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    final response = await _client.postJson(
      '/api/v1/auth/phone/password/login',
      body: {'phone': phone, 'password': password},
      requiresAuth: false,
    );
    return _loginSession(response, phone);
  }

  AuthSession _loginSession(Map<String, dynamic> response, String phone) {
    final user = response['user'];
    // Retain the account used to authenticate when GET /me omits the phone.
    return AuthSession.fromJson({
      ...response,
      if (user is Map<String, dynamic>)
        'user': {...user, 'phone': user['phone'] ?? phone},
    });
  }

  @override
  Future<AuthSession> refreshSession({required String refreshToken}) async {
    final response = await _client.postJson(
      '/api/v1/auth/refresh',
      body: <String, dynamic>{'refresh_token': refreshToken},
      requiresAuth: false,
    );
    return AuthSession(
      accessToken: response['access_token'] as String? ?? '',
      refreshToken: refreshToken,
      user: const MeUser(id: '', profile: MeProfile()),
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _client.postJson(
      '/api/v1/auth/logout',
      body: <String, dynamic>{'refresh_token': refreshToken},
      requiresAuth: false,
    );
  }
}
