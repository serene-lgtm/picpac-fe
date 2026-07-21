import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/module_top_bar.dart';
import 'checklist_theme.dart';

class ChecklistScaffold extends StatelessWidget {
  const ChecklistScaffold({
    super.key,
    required this.children,
    this.bottomBar,
    this.floating,
  });

  final List<Widget> children;
  final Widget? bottomBar;
  final Widget? floating;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: checklistGradientColors.last,
      body: Container(
        decoration: checklistGradientDecoration(),
        child: Stack(
          children: [
            Column(children: children),
            if (floating != null) floating!,
            if (bottomBar != null)
              Align(alignment: Alignment.bottomCenter, child: bottomBar!),
          ],
        ),
      ),
    );
  }
}

class ChecklistTopBar extends StatelessWidget {
  const ChecklistTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.onLeadingTap,
    this.onTrailingTap,
  });

  final String title;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return ModuleTopBar(
      title: title,
      leading: leading,
      trailing: trailing,
      onLeadingTap: onLeadingTap,
      onTrailingTap: onTrailingTap,
    );
  }
}

class ChecklistBottomActionBar extends StatelessWidget {
  const ChecklistBottomActionBar({
    super.key,
    this.leftLabel = '添加',
    this.rightLabel = '移除',
    this.onLeft,
    this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFF7FFF8),
        border: Border(top: BorderSide(color: Color(0xFFE7E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onLeft,
              style: TextButton.styleFrom(
                foregroundColor: onLeft == null
                    ? checklistMutedText
                    : const Color(0xFF60716F),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(leftLabel),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: onRight,
              style: TextButton.styleFrom(
                foregroundColor: onRight == null
                    ? checklistMutedText
                    : Colors.red,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Text(rightLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChecklistPillButton extends StatelessWidget {
  const ChecklistPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : 170,
      height: 48,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: checklistPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB9D8D6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          shadowColor: const Color(0x33000000),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class ChecklistEmptyIllustration extends StatelessWidget {
  const ChecklistEmptyIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/common/empty.svg',
      height: 270,
      semanticsLabel: '空清单',
    );
  }
}
