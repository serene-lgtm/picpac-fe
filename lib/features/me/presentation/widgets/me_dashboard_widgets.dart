import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_top_bar.dart';
import '../../data/me.dart';
import 'me_common_widgets.dart';
import 'me_profile_widgets.dart';

class MeDashboardHeader extends StatelessWidget {
  const MeDashboardHeader({
    super.key,
    required this.user,
    required this.onSettingsTap,
    required this.onProfileTap,
  });

  final MeUser user;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final heroHeight = (width * 0.8).clamp(280.0, 340.0);
    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          Positioned(
            top: safeTop + 0,
            right: 0,
            height: heroHeight,
            child: Image.asset(
              'assets/common/me_cover.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: safeTop,
            right: moduleTopBarHorizontalPadding,
            child: SizedBox(
              width: moduleTopBarActionWidth,
              height: moduleTopBarActionWidth,
              child: IconButton(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.zero,
                onPressed: onSettingsTap,
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black,
                  size: moduleTopBarIconSize,
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            bottom: 16,
            width: (width * 0.56).clamp(226.0, 300.0),
            child: _MeProfileGlassTile(user: user, onTap: onProfileTap),
          ),
        ],
      ),
    );
  }
}

class _MeProfileGlassTile extends StatelessWidget {
  const _MeProfileGlassTile({required this.user, required this.onTap});

  final MeUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 70.0;
    const overlap = 34.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(48),
      child: SizedBox(
        height: 86,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: overlap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(48),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      avatarSize - overlap + 12,
                      8,
                      12,
                      8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(48),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: _MeProfileGlassText(user: user),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 8,
              child: MeAvatar(
                avatarUrl: user.profile.avatarUrl,
                size: avatarSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeProfileGlassText extends StatelessWidget {
  const _MeProfileGlassText({required this.user});

  final MeUser user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          effectiveUsername(user),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '编辑资料',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
          ],
        ),
      ],
    );
  }
}

class MeStatsCard extends StatelessWidget {
  const MeStatsCard({
    super.key,
    required this.itemCount,
    required this.packCount,
    required this.checklistCount,
  });

  final int itemCount;
  final int packCount;
  final int checklistCount;

  @override
  Widget build(BuildContext context) {
    return MeCard(
      height: 106,
      child: Row(
        children: [
          Expanded(
            child: _Stat(value: itemCount, label: '物品资产'),
          ),
          const MeVerticalDivider(),
          Expanded(
            child: _Stat(value: packCount, label: '已创建套组'),
          ),
          const MeVerticalDivider(),
          Expanded(
            child: _Stat(value: checklistCount, label: '历史清单'),
          ),
        ],
      ),
    );
  }
}

class MeGiftTile extends StatelessWidget {
  const MeGiftTile({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(14),
      child: MeCard(
        height: 52,
        child: const Row(
          children: [
            SizedBox(width: 24),
            Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFF7D898B),
              size: 24,
            ),
            SizedBox(width: 18),
            Expanded(
              child: Text(
                '邀请好友',
                style: TextStyle(
                  color: meText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC4CECC),
              size: 26,
            ),
            SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: meText,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          label,
          style: const TextStyle(
            color: meSubText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
