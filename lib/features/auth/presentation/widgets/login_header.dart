import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 304,
    child: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF62BFB9), Color(0xFF9FDE9B)],
              ),
            ),
          ),
        ),
        Positioned(left: -30, top: -15, child: _bubble(105)),
        Positioned(right: -10, top: -10, child: _bubble(95)),
        Positioned(
          right: -20,
          top: 32,
          child: Image.asset(
            'assets/common/me_cover.png',
            width: 296,
            height: 296,
            fit: BoxFit.contain,
          ),
        ),
        const Positioned(
          left: 34,
          top: 74,
          child: Text(
            '你好！',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const Positioned(
          left: 34,
          top: 126,
          child: Text(
            '欢迎使用picpac',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ],
    ),
  );

  Widget _bubble(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0x26FFFFFF),
      shape: BoxShape.circle,
    ),
  );
}
