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
    );
  }

  @override
  Future<AuthSession> loginWithPhone({
    required String phone,
    required String code,
  }) async {
    final response = await _client.postJson(
      '/api/v1/auth/phone/login',
      body: <String, dynamic>{'phone': phone, 'code': code},
      requiresAuth: false,
    );
    return AuthSession.fromJson(response);
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
