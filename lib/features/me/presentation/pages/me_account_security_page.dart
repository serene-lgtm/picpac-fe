import 'package:flutter/material.dart';

import '../../data/me.dart';
import '../../data/me_repository.dart';
import '../widgets/me_widgets.dart';

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
  late Future<MeUser> _meFuture;

  @override
  void initState() {
    super.initState();
    _meFuture = widget.initialUser == null
        ? widget.meRepository.getMe()
        : Future<MeUser>.value(widget.initialUser);
  }

  @override
  Widget build(BuildContext context) {
    return MeGradientScaffold(
      child: FutureBuilder<MeUser>(
        future: _meFuture,
        builder: (context, snapshot) {
          final user = snapshot.data ?? widget.initialUser;
          return Column(
            children: [
              const MeSimpleTopBar(title: '账号安全'),
              Expanded(
                child:
                    snapshot.connectionState == ConnectionState.waiting &&
                        user == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : snapshot.hasError && user == null
                    ? MeErrorState(
                        message: snapshot.error.toString(),
                        onRetry: () {
                          setState(() {
                            _meFuture = widget.meRepository.getMe();
                          });
                        },
                      )
                    : _AccountSecurityContent(
                        user:
                            user ?? const MeUser(id: '', profile: MeProfile()),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccountSecurityContent extends StatelessWidget {
  const _AccountSecurityContent({required this.user});

  final MeUser user;

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
                    maskedAccount(user),
                    style: const TextStyle(
                      color: Color(0xFF666E72),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  showChevron: false,
                ),
                const MeHorizontalDivider(),
                const MeTile(
                  icon: Icons.lock_outline_rounded,
                  title: '登录密码',
                  trailing: Text(
                    '已设置',
                    style: TextStyle(
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
