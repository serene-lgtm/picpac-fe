import '../../../core/network/api_client.dart';
import 'me.dart';

abstract class MeRepository {
  Future<MeUser> getMe();

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
