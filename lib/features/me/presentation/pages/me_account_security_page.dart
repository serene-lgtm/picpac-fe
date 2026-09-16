import 'package:flutter/material.dart';

import '../../data/me.dart';
import '../../data/account_security.dart';
import '../../../../shared/widgets/module_top_bar.dart';
import '../../data/me_repository.dart';
import '../widgets/me_widgets.dart';
import 'me_password_page.dart';
import 'me_session_scope.dart';

class MeAccountSecurityPage extends StatefulWidget {
  const MeAccountSecurityPage({
    super.key,
    required this.meRepository,
    this.initialUser,
  });

  final MeRepository meRepository;
  final MeUser? initialUser;

  @override
  State<MeAccountSecurityPage> createState() => _MeAccountSecurityPageState();
}

class _MeAccountSecurityPageState extends State<MeAccountSecurityPage> {
  late Future<AccountSecurity> _securityFuture;
  bool _openingPassword = false;

  @override
  void initState() {
    super.initState();
    _securityFuture = widget.meRepository.getSecurity();
  }

  void _reload() {
    setState(() {
      _securityFuture = widget.meRepository.getSecurity();
    });
  }

  Future<void> _openPassword(AccountSecurity security) async {
    if (_openingPassword) return;
    setState(() => _openingPassword = true);
    // Security.phone is masked. Only use a full phone from the current session.
    final candidates = [
      MeSessionScope.maybeOf(context)?.phone ?? '',
      widget.initialUser?.phone ?? '',
    ];
    final phone = candidates.firstWhere(
      (value) => RegExp(r'^(\+86)?1[3-9]\d{9}$').hasMatch(value),
      orElse: () => '',
    );
    try {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => MePasswordPage(
            meRepository: widget.meRepository,
            isSetup: !security.passwordSetup,
            phone: phone,
          ),
        ),
      );
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _openingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) => MeGradientScaffold(
    child: Column(
      children: [
        ModuleTopBar(
          title: '账号安全',
          foregroundColor: Colors.white,
          leading: Icons.chevron_left_rounded,
          onLeadingTap: () => Navigator.of(context).maybePop(),
        ),
        Expanded(
          child: FutureBuilder<AccountSecurity>(
            future: _securityFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return MeErrorState(
                  message: '账号安全信息加载失败，请重试',
                  onRetry: _reload,
                );
              }
              final security = snapshot.data!;
              return _AccountSecurityContent(
                security: security,
                onPasswordTap: _openingPassword
                    ? null
                    : () => _openPassword(security),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _AccountSecurityContent extends StatelessWidget {
  const _AccountSecurityContent({
    required this.security,
    required this.onPasswordTap,
  });

  final AccountSecurity security;
  final VoidCallback? onPasswordTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = meContentInset(constraints.maxWidth);
        return ListView(
          padding: EdgeInsets.fromLTRB(inset, 24, inset, 34),
          children: [
            MeTileGroup(
              children: [
                MeTile(
                  icon: Icons.phone_iphone_rounded,
                  title: '手机号码',
                  trailing: Text(
                    security.phone.isEmpty ? '未绑定' : security.phone,
                    style: const TextStyle(
                      color: Color(0xFF666E72),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  showChevron: false,
                ),
                const MeHorizontalDivider(),
                MeTile(
                  icon: Icons.lock_outline_rounded,
                  title: '登录密码',
                  onTap: onPasswordTap,
                  trailing: Text(
                    security.passwordSetup ? '已设置' : '未设置',
                    style: const TextStyle(
                      color: Color(0xFF666E72),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            MeCenteredAction(
              icon: Icons.person_remove_alt_1_outlined,
              label: '注销账号',
              onTap: () {},
            ),
          ],
        );
      },
    );
  }
}
