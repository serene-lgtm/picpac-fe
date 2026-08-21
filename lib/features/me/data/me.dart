class MeUser {
  const MeUser({
    required this.id,
    required this.profile,
    this.status = '',
    this.phone = '',
  });

  final String id;
  final MeProfile profile;
  final String status;
  final String phone;

  factory MeUser.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    return MeUser(
      id: json['id'] as String? ?? '',
      profile: profileJson is Map<String, dynamic>
          ? MeProfile.fromJson(profileJson)
          : const MeProfile(),
      status: json['status'] as String? ?? '',
      phone:
          json['phone'] as String? ??
          json['phone_number'] as String? ??
          json['mobile'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'profile': profile.toJson(),
      'status': status,
      'phone': phone,
    };
  }
}

class MeProfile {
  const MeProfile({
    this.username = '',
    this.gender = '',
    this.birthday = '',
    this.avatarUrl = '',
  });

  final String username;
  final String gender;
  final String birthday;
  final String avatarUrl;

  factory MeProfile.fromJson(Map<String, dynamic> json) {
    return MeProfile(
      username: json['username'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'gender': gender,
      'birthday': birthday,
      'avatar_url': avatarUrl,
    };
  }
}
