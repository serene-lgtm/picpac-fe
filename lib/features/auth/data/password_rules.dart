class PasswordRules {
  const PasswordRules(this.value);

  final String value;
  static final _allowed = RegExp(r'^[A-Za-z0-9_#!@$%^&*()+=-]+$');
  static final _special = RegExp(r'[_#!@$%^&*()+=-]');

  bool get validLength => value.length >= 8 && value.length <= 32;
  bool get allowedCharacters => _allowed.hasMatch(value);
  bool get uppercase => RegExp(r'[A-Z]').hasMatch(value);
  bool get lowercase => RegExp(r'[a-z]').hasMatch(value);
  bool get digit => RegExp(r'[0-9]').hasMatch(value);
  bool get special => _special.hasMatch(value);
  int get categoryCount =>
      [uppercase, lowercase, digit, special].where((matches) => matches).length;
  bool get isValid => validLength && allowedCharacters && categoryCount >= 3;

  // A valid 8–11 character password is medium; 12+ characters is strong.
  int get strength => value.isEmpty
      ? 0
      : !isValid
      ? 1
      : value.length < 12
      ? 2
      : 3;
}
