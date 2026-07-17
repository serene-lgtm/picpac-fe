import 'package:flutter/material.dart';

const moduleFloatingButtonRight = 18.0;
const moduleFloatingButtonBottom = 92.0;
const moduleFloatingButtonSize = 58.0;

class ModuleFloatingAddButton extends StatelessWidget {
  const ModuleFloatingAddButton({
    super.key,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF4DBDBB),
    this.foregroundColor = Colors.white,
  });

  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: moduleFloatingButtonRight,
      bottom: moduleFloatingButtonBottom,
      child: SafeArea(
        top: false,
        child: SizedBox.square(
          dimension: moduleFloatingButtonSize,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              shape: const CircleBorder(),
              elevation: 8,
              shadowColor: const Color(0x33000000),
            ),
            child: const Icon(Icons.add_rounded, size: 31),
          ),
        ),
      ),
    );
  }
}
