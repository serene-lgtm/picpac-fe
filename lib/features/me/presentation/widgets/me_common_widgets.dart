import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/module_top_bar.dart';
import '../../data/me.dart';

const meGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF4CBAB5), Color(0xFFA7E99D)],
);
const meTeal = Color(0xFF4CBAB5);
const mePanel = Color(0xEAF2FFFC);
const meText = Color(0xFF111718);
const meSubText = Color(0xFF788487);
const meDivider = Color(0x1A92A5A2);

class MeGradientScaffold extends StatelessWidget {
  const MeGradientScaffold({
    super.key,
    required this.child,
    this.bottomNavigationBar,
  });

  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF83DB98),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: meGradient),
          child: child,
        ),
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}

class MeSimpleTopBar extends StatelessWidget {
  const MeSimpleTopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ModuleTopBar(
      title: title,
      leading: Icons.chevron_left_rounded,
      onLeadingTap: () => Navigator.of(context).maybePop(),
      foregroundColor: Colors.black,
      background: const BoxDecoration(color: Colors.transparent),
    );
  }
}

class MeCard extends StatelessWidget {
  const MeCard({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: mePanel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class MeTileGroup extends StatelessWidget {
  const MeTileGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MeCard(
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class MeTile extends StatelessWidget {
  const MeTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF3B30) : meText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 18),
            Icon(
              icon,
              size: 20,
              color: danger ? color : const Color(0xFF7D898B),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: danger ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFC4CECC),
                size: 24,
              ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class MeCenteredAction extends StatelessWidget {
  const MeCenteredAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: MeCard(
        height: 52,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFFFF3B30)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeVerticalDivider extends StatelessWidget {
  const MeVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: double.infinity, color: meDivider);
  }
}

class MeHorizontalDivider extends StatelessWidget {
  const MeHorizontalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Container(height: 1, color: meDivider),
    );
  }
}

class MePrimaryButton extends StatelessWidget {
  const MePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.danger = false,
    this.width,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool danger;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: danger ? const Color(0xFFFF565B) : meTeal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB9D0CC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
          elevation: 10,
          shadowColor: (danger ? const Color(0xFFFF565B) : meTeal).withValues(
            alpha: 0.28,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class MeConfirmDialog extends StatelessWidget {
  const MeConfirmDialog({
    super.key,
    required this.assetPath,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    this.detail,
    this.danger = false,
    this.loading = false,
  });

  final String assetPath;
  final String message;
  final String? detail;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 64),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 144,
              height: 144,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: meText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: meSubText, fontSize: 13),
              ),
            ],
            const SizedBox(height: 22),
            MePrimaryButton(
              label: confirmLabel,
              onPressed: onConfirm,
              danger: danger,
              loading: loading,
              width: 160,
              height: 44,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: loading ? null : () => Navigator.of(context).pop(),
              child: const Text(
                '取消',
                style: TextStyle(
                  color: meText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeSuccessToast extends StatelessWidget {
  const MeSuccessToast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class MeErrorState extends StatelessWidget {
  const MeErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final FutureOr<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '加载失败',
              style: TextStyle(
                color: meText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: meSubText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => onRetry(), child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

double meContentInset(double width) => (width * 0.062).clamp(18.0, 32.0);

String effectiveUsername(MeUser user) {
  final username = user.profile.username.trim();
  if (username.isNotEmpty) return username;
  final phone = user.phone.trim();
  if (phone.isNotEmpty) return 'user_$phone';
  final id = user.id.trim();
  if (id.isNotEmpty) return 'user_$id';
  return 'user_picpac';
}

String maskedAccount(MeUser user) {
  final phone = user.phone.trim();
  if (phone.length >= 7) {
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }
  final username = user.profile.username.trim();
  final fromUsername = RegExp(r'^user_?(\d{7,})$').firstMatch(username);
  final digits = fromUsername?.group(1);
  if (digits != null && digits.length >= 7) {
    return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
  }
  final id = user.id.trim();
  if (id.length > 8) {
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }
  return id.isEmpty ? '未绑定' : id;
}

String formatMeDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
