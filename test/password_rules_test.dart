import 'package:flutter_test/flutter_test.dart';
import 'package:picpac_fe/features/auth/data/password_rules.dart';

void main() {
  test(
    'password accepts only the documented alphabet and any three categories',
    () {
      for (final value in [
        'Trip2026Pass',
        'Abcdef1!',
        'abcdef1!',
        'ABCDEF1!',
        'Abcdefgh!',
      ]) {
        expect(PasswordRules(value).isValid, isTrue, reason: value);
      }
      for (final value in [
        'Abc1234',
        'Abcdefgh',
        '12345678',
        'abcdef12',
        ' Abc12345',
        'Abc12345 ',
        'Abc12345中',
        'Abc12345😀',
        'Abc12345.',
        'Abc12345\n',
        'Abc12345\\',
      ]) {
        expect(PasswordRules(value).isValid, isFalse, reason: value);
      }
      expect(PasswordRules('Aa1${'b' * 29}').isValid, isTrue);
      expect(PasswordRules('Aa1${'b' * 30}').isValid, isFalse);
      for (final character in r'_#!@$%^&*()+=-'.split('')) {
        expect(PasswordRules('Abcdefg$character').isValid, isTrue);
      }
    },
  );

  test('strength progresses from empty through weak, medium, strong', () {
    expect(const PasswordRules('').strength, 0);
    expect(const PasswordRules('abcdef').strength, 1);
    expect(const PasswordRules('abc123ABC').strength, 2);
    expect(const PasswordRules('LongTrip2026!').strength, 3);
  });
}
