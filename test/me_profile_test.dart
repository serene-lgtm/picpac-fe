import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/me/data/me.dart';

void main() {
  test('OSS default avatar shares its signed display and source URL', () {
    const avatar =
        'https://picpac.oss-cn-shanghai.aliyuncs.com/users/default/avatar.png'
        '?Expires=1783588103&OSSAccessKeyId=test&Signature=test%2Bsignature';
    final user = MeUser.fromJson({
      'id': 'user-1',
      'profile': {'avatar_url': avatar, 'avatar_source_url': avatar},
    });

    expect(user.profile.avatarUrl, avatar);
    expect(user.profile.avatarSourceUrl, avatar);
    final restored = MeUser.fromJson(user.toJson());
    expect(restored.profile.avatarUrl, avatar);
    expect(restored.profile.avatarSourceUrl, avatar);
  });

  test('profile preserves display and source avatar URLs independently', () {
    final profile = MeProfile.fromJson({
      'avatar_url': '/avatar/display.jpg',
      'avatar_source_url': '/avatar/source.png',
    });
    expect(profile.avatarUrl, '/avatar/display.jpg');
    expect(profile.avatarSourceUrl, '/avatar/source.png');
    final restored = MeProfile.fromJson(profile.toJson());
    expect(restored.avatarSourceUrl, profile.avatarSourceUrl);
    expect(restored.avatarUrl, profile.avatarUrl);
  });

  test('legacy profile without source URL still parses', () {
    final profile = MeProfile.fromJson({'avatar_url': '/avatar.jpg'});
    expect(profile.avatarUrl, '/avatar.jpg');
    expect(profile.avatarSourceUrl, isEmpty);
  });
}
