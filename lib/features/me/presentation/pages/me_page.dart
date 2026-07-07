import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/navigation/no_animation_route.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../checklists/data/checklist_repository.dart';
import '../../../checklists/presentation/pages/checklists_page.dart';
import '../../../items/data/item_repository.dart';
import '../../../items/presentation/pages/items_page.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/presentation/pages/create_pack_page.dart';
import '../../data/me.dart';
import '../../data/me_repository.dart';

const _meGradientColors = [Color(0xFF71D0C6), Color(0xFFC8EFC1)];

class MePage extends StatefulWidget {
  const MePage({
    super.key,
    required this.meRepository,
    required this.itemRepository,
    required this.packRepository,
    required this.checklistRepository,
  });

  final MeRepository meRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;
  final ChecklistRepository checklistRepository;

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  Future<_MeDashboardData>? _dashboardFuture;
  MeUser? _cachedUser;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_MeDashboardData> _loadDashboard() async {
    final results = await Future.wait<Object>([
      widget.meRepository.getMe(),
      widget.itemRepository.listItems(),
      widget.packRepository.listPacks(),
      widget.checklistRepository.listChecklists(),
    ]);
    final user = results[0] as MeUser;
    _cachedUser = user;
    return _MeDashboardData(
      user: user,
      itemCount: (results[1] as List).length,
      packCount: (results[2] as List).length,
      checklistCount: (results[3] as List).length,
    );
  }

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<MeUser>(
      MaterialPageRoute<MeUser>(
        builder: (context) => MeSettingsPage(
          meRepository: widget.meRepository,
          initialUser: _cachedUser,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _cachedUser = updated;
      _dashboardFuture = (_dashboardFuture ?? _loadDashboard()).then(
        (data) => data.copyWith(user: updated),
      );
    });
  }

  void _handleTabSelected(BottomTab tab) {
    if (tab == BottomTab.me) return;
    if (tab == BottomTab.item) {
      Navigator.of(context).pushReplacement(
        noAnimationRoute<void>(
          (context) => ItemsPage(
            repository: widget.itemRepository,
            packRepository: widget.packRepository,
            checklistRepository: widget.checklistRepository,
            meRepository: widget.meRepository,
          ),
        ),
      );
    }
    if (tab == BottomTab.pack) {
      Navigator.of(context).pushReplacement(
        noAnimationRoute<void>(
          (context) => PacksPage(
            itemRepository: widget.itemRepository,
            packRepository: widget.packRepository,
            checklistRepository: widget.checklistRepository,
            meRepository: widget.meRepository,
          ),
        ),
      );
    }
    if (tab == BottomTab.checklist) {
      Navigator.of(context).pushReplacement(
        noAnimationRoute<void>(
          (context) => ChecklistsPage(
            checklistRepository: widget.checklistRepository,
            itemRepository: widget.itemRepository,
            packRepository: widget.packRepository,
            meRepository: widget.meRepository,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<_MeDashboardData>(
          future: _dashboardFuture ??= _loadDashboard(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final user = data?.user ?? _cachedUser;
            if (snapshot.connectionState == ConnectionState.waiting &&
                user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError && user == null) {
              return _MeErrorState(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }

            final effectiveData =
                data ??
                _MeDashboardData(
                  user: user ?? const MeUser(id: '', profile: MeProfile()),
                  itemCount: 0,
                  packCount: 0,
                  checklistCount: 0,
                );
            return RefreshIndicator(
              onRefresh: _refresh,
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final topHeight = (width * 0.69).clamp(236.0, 310.0);
                      final horizontalInset = _contentInset(width);
                      final statsTop = topHeight - 21;
                      final actionTop = statsTop + 104;
                      final bottomNavSpace =
                          96 + MediaQuery.paddingOf(context).bottom;
                      final contentHeight = (actionTop + 168 + bottomNavSpace)
                          .clamp(constraints.maxHeight + 1, double.infinity);
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(
                            height: contentHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                _MeTopBar(
                                  height: topHeight,
                                  user: effectiveData.user,
                                  onSettingsTap: _openSettings,
                                ),
                                Positioned(
                                  left: horizontalInset,
                                  right: horizontalInset,
                                  top: statsTop,
                                  child: _MeStatsCard(data: effectiveData),
                                ),
                                Positioned(
                                  left: horizontalInset,
                                  right: horizontalInset,
                                  top: actionTop,
                                  child: const _MeActionCard(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      child: BottomNav(
                        currentTab: BottomTab.me,
                        onTabSelected: _handleTabSelected,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MeDashboardData {
  const _MeDashboardData({
    required this.user,
    required this.itemCount,
    required this.packCount,
    required this.checklistCount,
  });

  final MeUser user;
  final int itemCount;
  final int packCount;
  final int checklistCount;

  _MeDashboardData copyWith({MeUser? user}) {
    return _MeDashboardData(
      user: user ?? this.user,
      itemCount: itemCount,
      packCount: packCount,
      checklistCount: checklistCount,
    );
  }
}

class MeSettingsPage extends StatelessWidget {
  const MeSettingsPage({
    super.key,
    required this.meRepository,
    this.initialUser,
  });

  final MeRepository meRepository;
  final MeUser? initialUser;

  Future<void> _openProfile(BuildContext context) async {
    final updated = await Navigator.of(context).push<MeUser>(
      MaterialPageRoute<MeUser>(
        builder: (context) =>
            MeProfilePage(meRepository: meRepository, initialUser: initialUser),
      ),
    );
    if (!context.mounted || updated == null) return;
    Navigator.of(context).pop(updated);
  }

  Future<void> _logout(BuildContext context) async {
    await MeSessionScope.of(context).logout();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FA),
        body: Column(
          children: [
            const _SimpleTopBar(title: '设置'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalInset = _contentInset(constraints.maxWidth);
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalInset,
                      20,
                      horizontalInset,
                      34,
                    ),
                    children: [
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.person_outline_rounded,
                            title: '个人资料',
                            onTap: () => _openProfile(context),
                          ),
                          const _SettingsDivider(),
                          const _SettingsTile(
                            icon: Icons.shield_outlined,
                            title: '账号安全',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.delete_outline_rounded,
                            title: '清除缓存',
                          ),
                          _SettingsDivider(),
                          _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: '关于Picpac',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _LogoutCard(onTap: () => _logout(context)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MeSessionScope extends InheritedWidget {
  const MeSessionScope({
    super.key,
    required super.child,
    required this.onLogout,
  });

  final Future<void> Function() onLogout;

  static MeSessionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MeSessionScope>();
    assert(scope != null, 'MeSessionScope not found in context');
    return scope!;
  }

  Future<void> logout() => onLogout();

  @override
  bool updateShouldNotify(MeSessionScope oldWidget) {
    return onLogout != oldWidget.onLogout;
  }
}

class MeProfilePage extends StatefulWidget {
  const MeProfilePage({
    super.key,
    required this.meRepository,
    this.initialUser,
  });

  final MeRepository meRepository;
  final MeUser? initialUser;

  @override
  State<MeProfilePage> createState() => _MeProfilePageState();
}

class _MeProfilePageState extends State<MeProfilePage> {
  final _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late Future<MeUser> _meFuture;
  String _gender = 'private';
  String _birthday = '';
  XFile? _pickedAvatar;
  bool _usernameTouched = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialUser = widget.initialUser;
    if (initialUser != null) {
      _applyUser(initialUser);
      _meFuture = Future<MeUser>.value(initialUser);
    } else {
      _meFuture = _loadMe();
    }
  }

  Future<MeUser> _loadMe() async {
    final user = await widget.meRepository.getMe();
    _applyUser(user);
    return user;
  }

  void _applyUser(MeUser user) {
    _usernameController.text = user.profile.username;
    _gender = user.profile.gender.isEmpty ? 'private' : user.profile.gender;
    _birthday = user.profile.birthday;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    Navigator.of(context).pop();
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;
    setState(() {
      _pickedAvatar = image;
    });
  }

  Future<void> _openAvatarActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D7D7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '选择头像',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('从相册选择'),
                  onTap: () => _pickAvatar(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('拍照'),
                  onTap: () => _pickAvatar(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final parsedBirthday = DateTime.tryParse(_birthday);
    final initialDate = parsedBirthday ?? DateTime(now.year - 18, 1, 1);
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (date == null) return;
    setState(() {
      _birthday = _formatDate(date);
    });
  }

  Future<void> _save() async {
    setState(() {
      _usernameTouched = true;
    });
    final username = _usernameController.text.trim();
    if (username.isEmpty || _saving) return;

    setState(() {
      _saving = true;
    });
    try {
      final updated = await widget.meRepository.updateProfile(
        username: username,
        gender: _gender,
        birthday: _birthday,
        avatar: _pickedAvatar == null ? null : _avatarPart(_pickedAvatar!),
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUsername = _usernameController.text.trim().isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5FA),
        body: FutureBuilder<MeUser>(
          future: _meFuture,
          builder: (context, snapshot) {
            final profile =
                snapshot.data?.profile ?? widget.initialUser?.profile;
            return Column(
              children: [
                const _SimpleTopBar(title: '个人资料'),
                Expanded(
                  child:
                      snapshot.connectionState == ConnectionState.waiting &&
                          profile == null
                      ? const Center(child: CircularProgressIndicator())
                      : snapshot.hasError && profile == null
                      ? _MeErrorState(
                          message: snapshot.error.toString(),
                          onRetry: () {
                            setState(() {
                              _meFuture = _loadMe();
                            });
                          },
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final horizontalInset = _contentInset(
                              constraints.maxWidth,
                            );
                            return ListView(
                              padding: EdgeInsets.fromLTRB(
                                horizontalInset,
                                20,
                                horizontalInset,
                                34,
                              ),
                              children: [
                                _ProfileAvatarCard(
                                  avatarUrl: profile?.avatarUrl ?? '',
                                  pickedAvatar: _pickedAvatar,
                                  onTap: _openAvatarActions,
                                ),
                                const SizedBox(height: 16),
                                _ProfileInfoCard(
                                  usernameController: _usernameController,
                                  showUsernameError:
                                      _usernameTouched && !hasUsername,
                                  gender: _gender,
                                  birthday: _birthday,
                                  onChanged: () => setState(() {}),
                                  onGenderChanged: (value) {
                                    setState(() {
                                      _gender = value;
                                    });
                                  },
                                  onBirthdayTap: _pickBirthday,
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    onPressed: _saving ? null : _save,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF4DBDBB),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFFD4DAE1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _saving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            '保存修改',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MeTopBar extends StatelessWidget {
  const _MeTopBar({
    required this.height,
    required this.user,
    required this.onSettingsTap,
  });

  final double height;
  final MeUser user;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final avatarSize = (height * 0.28).clamp(64.0, 82.0);
    final width = MediaQuery.sizeOf(context).width;
    final username = user.profile.username.trim();
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _meGradientColors,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: height * 0.37,
            child: _ProfileAvatar(
              avatarUrl: user.profile.avatarUrl,
              size: avatarSize,
              borderWidth: 2,
            ),
          ),
          Positioned(
            top: height * 0.71,
            child: Text(
              username,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontSize: (height * 0.08).clamp(20.0, 24.0),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            top: height * 0.83,
            child: Text(
              'picpac · 收纳达人',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            top: height * 0.325,
            right: (width * 0.064).clamp(20.0, 32.0),
            child: GestureDetector(
              onTap: onSettingsTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTopBar extends StatelessWidget {
  const _SimpleTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final topBarHeight = _topBarHeight(context);
    return Container(
      height: topBarHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _meGradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: topBarHeight - MediaQuery.paddingOf(context).top,
          child: Row(
            children: [
              SizedBox(width: _contentInset(MediaQuery.sizeOf(context).width)),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                width: _contentInset(MediaQuery.sizeOf(context).width) + 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeStatsCard extends StatelessWidget {
  const _MeStatsCard({required this.data});

  final _MeDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(value: '${data.itemCount}', label: '物品资产'),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatCell(value: '${data.packCount}', label: '已创建套组'),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _StatCell(value: '${data.checklistCount}', label: '历史清单'),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF173B3A),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9BA4AE),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 84, color: const Color(0xFFEDEEF2));
  }
}

class _MeActionCard extends StatelessWidget {
  const _MeActionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.card_giftcard_rounded, color: Color(0xFF8D929A), size: 21),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              '邀请好友',
              style: TextStyle(
                color: Color(0xFF1C2529),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Color(0xFFD6D9DE)),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 18),
            Icon(icon, color: const Color(0xFF8D929A), size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1C2529),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFD4D8DE)),
            const SizedBox(width: 13),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 53),
      child: Container(height: 1, color: const Color(0xFFEDEEF2)),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF3B30), size: 18),
            SizedBox(width: 8),
            Text(
              '退出登录',
              style: TextStyle(
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

class _ProfileAvatarCard extends StatelessWidget {
  const _ProfileAvatarCard({
    required this.avatarUrl,
    required this.pickedAvatar,
    required this.onTap,
  });

  final String avatarUrl;
  final XFile? pickedAvatar;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EditableAvatar(avatarUrl: avatarUrl, pickedAvatar: pickedAvatar),
              const SizedBox(height: 10),
              const Text(
                '点击修改头像',
                style: TextStyle(
                  color: Color(0xFF4DBDBB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.usernameController,
    required this.showUsernameError,
    required this.gender,
    required this.birthday,
    required this.onChanged,
    required this.onGenderChanged,
    required this.onBirthdayTap,
  });

  final TextEditingController usernameController;
  final bool showUsernameError;
  final String gender;
  final String birthday;
  final VoidCallback onChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onBirthdayTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const SizedBox(
                  width: 72,
                  child: Text(
                    '用户名',
                    style: TextStyle(
                      color: Color(0xFF1C2529),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: usernameController,
                    onChanged: (_) => onChanged(),
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorText: showUsernameError ? '' : null,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF686F79),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const _SettingsDivider(),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '性别',
                    style: TextStyle(
                      color: Color(0xFF1C2529),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _GenderPill(
                  label: '男',
                  selected: gender == 'male',
                  onTap: () => onGenderChanged('male'),
                ),
                const SizedBox(width: 8),
                _GenderPill(
                  label: '女',
                  selected: gender == 'female',
                  onTap: () => onGenderChanged('female'),
                ),
                const SizedBox(width: 8),
                _GenderPill(
                  label: '保密',
                  selected: gender == 'private' || gender.isEmpty,
                  onTap: () => onGenderChanged('private'),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          const _SettingsDivider(),
          InkWell(
            onTap: onBirthdayTap,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '生日',
                      style: TextStyle(
                        color: Color(0xFF1C2529),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    birthday.isEmpty ? '' : birthday,
                    style: const TextStyle(
                      color: Color(0xFF686F79),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderPill extends StatelessWidget {
  const _GenderPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4DBDBB) : const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6F7780),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MeErrorState extends StatelessWidget {
  const _MeErrorState({required this.message, required this.onRetry});

  final String message;
  final FutureOr<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF173B3A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6F7C7C)),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => onRetry(), child: const Text('重试')),
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.avatarUrl, required this.pickedAvatar});

  final String avatarUrl;
  final XFile? pickedAvatar;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? imageProvider = switch ((
      pickedAvatar,
      avatarUrl,
    )) {
      (final XFile file?, _) => FileImage(File(file.path)),
      (_, final String url) when url.isNotEmpty => NetworkImage(url),
      _ => null,
    };

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFF7DD4A6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBCECCD), width: 2),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: imageProvider == null
                  ? const Icon(
                      Icons.person_outline_rounded,
                      size: 42,
                      color: Colors.white,
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: 5,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: const Color(0xFF4DBDBB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.size,
    this.borderWidth = 0,
  });

  final String avatarUrl;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF7DD4A6),
        shape: BoxShape.circle,
        border: borderWidth == 0
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: borderWidth,
              ),
        image: avatarUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              ),
      ),
      alignment: Alignment.center,
      child: avatarUrl.isNotEmpty
          ? null
          : Icon(
              Icons.person_outline_rounded,
              size: size * 0.52,
              color: Colors.white,
            ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

double _contentInset(double width) {
  return (width * 0.12).clamp(18.0, 50.0);
}

double _topBarHeight(BuildContext context) {
  final topPadding = MediaQuery.paddingOf(context).top;
  return (topPadding + 96).clamp(118.0, 148.0);
}

MultipartFilePart _avatarPart(XFile file) {
  final extension = file.path.split('.').last.toLowerCase();
  final contentType = switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' || 'heif' => 'image/heic',
    _ => 'image/jpeg',
  };
  return MultipartFilePart(
    fieldName: 'avatar',
    fileName: file.name,
    contentType: contentType,
    bytes: file.readAsBytes().then((bytes) => bytes.toList()),
  );
}
