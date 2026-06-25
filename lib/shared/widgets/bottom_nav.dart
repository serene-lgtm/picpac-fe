import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum BottomTab { checklist, pack, item, me }

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentTab, this.onTabSelected});

  final BottomTab currentTab;
  final ValueChanged<BottomTab>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: BottomTab.values.map((tab) {
            return _NavItem(
              tab: tab,
              active: tab == currentTab,
              onTap: onTabSelected == null ? null : () => onTabSelected!(tab),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final BottomTab tab;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              tab.assetPath,
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on BottomTab {
  String get label {
    return switch (this) {
      BottomTab.checklist => '清单',
      BottomTab.pack => '套组',
      BottomTab.item => '物品',
      BottomTab.me => '我的',
    };
  }

  String get assetPath {
    return switch (this) {
      BottomTab.checklist => 'assets/checklist.svg',
      BottomTab.pack => 'assets/pack.svg',
      BottomTab.item => 'assets/item.svg',
      BottomTab.me => 'assets/me.svg',
    };
  }
}
