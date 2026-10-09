import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import 'launch_screen.dart';

abstract class LaunchScreenRepository {
  Future<LaunchScreen> getLaunchScreen();
}

class ApiLaunchScreenRepository implements LaunchScreenRepository {
  ApiLaunchScreenRepository(this._client);

  final ApiClient _client;

  @override
  Future<LaunchScreen> getLaunchScreen() async {
    const path = '/api/v1/app/launch-screen';
    if (kDebugMode) {
      debugPrint('[picpac.launch] GET ${_client.resolveUrl(path)}');
    }
    return LaunchScreen.fromJson(
      await _client.getJson(path, requiresAuth: false),
    );
  }
}
