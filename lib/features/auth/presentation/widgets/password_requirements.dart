import 'package:flutter/material.dart';
import '../../data/password_rules.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({
    super.key,
    required this.value,
    this.panel = false,
  });
  final String value;
  final bool panel;

  @override
  Widget build(BuildContext context) {
    final rules = PasswordRules(value);
    final strength = rules.strength;
    final color = switch (strength) {
      1 => const Color(0xFFFF5757),
      2 => const Color(0xFFFFAD42),
      3 => const Color(0xFF38AD83),
      _ => const Color(0xFF9FBEB6),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: panel ? 14 : 18),
        Row(
          children: [
            for (var index = 0; index < 3; index++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: index < strength ? color : const Color(0x3392A5A2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              '密码强度：${['未输入', '弱', '中', '强'][strength]}',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
        SizedBox(height: panel ? 16 : 28),
        Container(
          padding: panel
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
              : EdgeInsets.zero,
          decoration: panel
              ? BoxDecoration(
                  color: const Color(0xAFFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '密码规则',
                style: TextStyle(fontSize: 12, color: Color(0xFF788487)),
              ),
              const SizedBox(height: 8),
              _Rule(
                ok: rules.validLength,
                label: '长度 8～32 个字符（当前 ${value.length} 位）',
              ),
              _Rule(
                ok: rules.allowedCharacters,
                label: r'仅限字母、数字及 _#!@$%^&*()+=-',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '至少包含以下三种类型：',
                  style: TextStyle(fontSize: 12, color: Color(0xFF788487)),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _Rule(ok: rules.uppercase, label: '大写字母 A-Z'),
                  ),
                  Expanded(
                    child: _Rule(ok: rules.lowercase, label: '小写字母 a-z'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _Rule(ok: rules.digit, label: '数字 0-9'),
                  ),
                  Expanded(
                    child: _Rule(ok: rules.special, label: '特殊字符'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.ok, required this.label});
  final bool ok;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check,
          size: 16,
          color: ok ? const Color(0xFF38AD83) : const Color(0xFFADB9B6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ok ? const Color(0xFF38AD83) : const Color(0xFF899C97),
            ),
          ),
        ),
      ],
    ),
  );
}
