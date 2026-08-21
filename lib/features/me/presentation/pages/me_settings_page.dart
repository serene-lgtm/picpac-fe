import 'package:flutter/material.dart';

import '../../data/me.dart';
import '../../data/me_repository.dart';
import '../widgets/me_widgets.dart';
import 'me_account_security_page.dart';
import 'me_session_scope.dart';

class MeSettingsPage extends StatefulWidget {
  const MeSettingsPage({
    super.key,
    required this.meRepository,
    this.initialUser,
  });

  final MeRepository meRepository;
  final MeUser? initialUser;

  @override
  State<MeSettingsPage> createState() => _MeSettingsPageState();
}

class _MeSettingsPageState extends State<MeSettingsPage> {
  bool _loggingOut = false;

  Future<void> _openAccount() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MeAccountSecurityPage(
          meRepository: widget.meRepository,
          initialUser: widget.initialUser,
        ),
      ),
    );
  }

  Future<void> _showCleanCacheDialog() async {
    final cache = PaintingBinding.instance.imageCache;
    final size = _formatBytes(cache.currentSizeBytes);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) => MeConfirmDialog(
        assetPath: 'assets/common/cache.png',
        message: '确定清除缓存吗？',
        detail: '当前图片缓存约 $size',
        confirmLabel: '确定',
        onConfirm: () {
          cache.clear();
          cache.clearLiveImages();
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  Future<void> _showLogoutDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return MeConfirmDialog(
            assetPath: 'assets/common/leave.png',
            message: '确认要退出登录吗？',
            confirmLabel: '退出登录',
            danger: true,
            loading: _loggingOut,
            onConfirm: () async {
              if (_loggingOut) return;
              setState(() => _loggingOut = true);
              setDialogState(() {});
              await MeSessionScope.of(context).logout();
              if (!mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          );
        },
      ),
    );
    if (mounted && _loggingOut) setState(() => _loggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return MeGradientScaffold(
      child: Column(
        children: [
          const MeSimpleTopBar(title: '设置'),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final inset = meContentInset(constraints.maxWidth);
                return ListView(
                  padding: EdgeInsets.fromLTRB(inset, 24, inset, 34),
                  children: [
                    MeTileGroup(
                      children: [
                        MeTile(
                          icon: Icons.shield_outlined,
                          title: '账号安全',
                          onTap: _openAccount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MeTileGroup(
                      children: [
                        MeTile(
                          icon: Icons.delete_outline_rounded,
                          title: '清除缓存',
                          onTap: _showCleanCacheDialog,
                        ),
                        const MeHorizontalDivider(),
                        const MeTile(
                          icon: Icons.info_outline_rounded,
                          title: '关于 picpac',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    MeCenteredAction(
                      icon: Icons.logout_rounded,
                      label: '退出登录',
                      onTap: _showLogoutDialog,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}
