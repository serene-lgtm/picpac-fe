import 'package:flutter/material.dart';

PageRoute<T> noAnimationRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
