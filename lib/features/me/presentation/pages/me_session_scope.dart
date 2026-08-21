import 'package:flutter/widgets.dart';

class MeSessionScope extends InheritedWidget {
  const MeSessionScope({
    super.key,
    required super.child,
    required this.onLogout,
  });

  final Future<void> Function() onLogout;

  static MeSessionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MeSessionScope>();
    assert(scope != null, 'MeSessionScope not found in context');
    return scope!;
  }

  Future<void> logout() => onLogout();

  @override
  bool updateShouldNotify(MeSessionScope oldWidget) {
    return onLogout != oldWidget.onLogout;
  }
}
