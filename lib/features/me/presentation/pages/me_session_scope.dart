import 'package:flutter/widgets.dart';
import '../../../auth/data/auth_repository.dart';

class MeSessionScope extends InheritedWidget {
  const MeSessionScope({
    super.key,
    required super.child,
    required this.onLogout,
    this.onPasswordChanged,
    this.phone = '',
    this.authRepository,
  });

  final Future<void> Function() onLogout;
  final Future<void> Function()? onPasswordChanged;
  final String phone;
  final AuthRepository? authRepository;

  static MeSessionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MeSessionScope>();

  static MeSessionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MeSessionScope>();
    assert(scope != null, 'MeSessionScope not found in context');
    return scope!;
  }

  Future<void> logout() => onLogout();

  Future<void> passwordChanged() => (onPasswordChanged ?? onLogout)();

  @override
  bool updateShouldNotify(MeSessionScope oldWidget) {
    return onLogout != oldWidget.onLogout ||
        onPasswordChanged != oldWidget.onPasswordChanged ||
        phone != oldWidget.phone ||
        authRepository != oldWidget.authRepository;
  }
}
