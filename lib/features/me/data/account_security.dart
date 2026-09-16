class AccountSecurity {
  const AccountSecurity({required this.phone, required this.passwordSetup});

  /// Masked display value; never submit this as the setup confirmation phone.
  final String phone;
  final bool passwordSetup;

  factory AccountSecurity.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'];
    final passwordSetup = json['password_setup'];
    if (phone is! String || passwordSetup is! bool) {
      throw const FormatException('账号安全信息格式错误，请重试');
    }
    return AccountSecurity(phone: phone, passwordSetup: passwordSetup);
  }
}
