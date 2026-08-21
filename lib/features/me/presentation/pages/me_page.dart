import 'package:flutter/material.dart';

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
import '../widgets/me_widgets.dart';
import 'me_profile_page.dart';
import 'me_settings_page.dart';

export 'me_session_scope.dart';

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
  String? _toastMessage;

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
    setState(() => _dashboardFuture = future);
    await future;
  }

  Future<void> _openProfile() async {
    final updated = await Navigator.of(context).push<MeUser>(
      MaterialPageRoute<MeUser>(
        builder: (_) => MeProfilePage(
          meRepository: widget.meRepository,
          initialUser: _cachedUser,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _cachedUser = updated;
      _toastMessage = '修改成功';
      _dashboardFuture = (_dashboardFuture ?? _loadDashboard()).then(
        (data) => data.copyWith(user: updated),
      );
    });
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _toastMessage == '修改成功') {
        setState(() => _toastMessage = null);
      }
    });
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<MeUser>(
      MaterialPageRoute<MeUser>(
        builder: (_) => MeSettingsPage(
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
    if (tab == BottomTab.item) _replaceWithItems();
    if (tab == BottomTab.pack) _replaceWithPacks();
    if (tab == BottomTab.checklist) _replaceWithChecklists();
  }

  void _replaceWithItems() {
    Navigator.of(context).pushReplacement(
      noAnimationRoute<void>(
        (_) => ItemsPage(
          repository: widget.itemRepository,
          packRepository: widget.packRepository,
          checklistRepository: widget.checklistRepository,
          meRepository: widget.meRepository,
        ),
      ),
    );
  }

  void _replaceWithPacks() {
    Navigator.of(context).pushReplacement(
      noAnimationRoute<void>(
        (_) => PacksPage(
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
          checklistRepository: widget.checklistRepository,
          meRepository: widget.meRepository,
        ),
      ),
    );
  }

  void _replaceWithChecklists() {
    Navigator.of(context).pushReplacement(
      noAnimationRoute<void>(
        (_) => ChecklistsPage(
          checklistRepository: widget.checklistRepository,
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
          meRepository: widget.meRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeGradientScaffold(
      child: FutureBuilder<_MeDashboardData>(
        future: _dashboardFuture ??= _loadDashboard(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final user = data?.user ?? _cachedUser;
          if (snapshot.connectionState == ConnectionState.waiting &&
              user == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError && user == null) {
            return MeErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          return _MeDashboardView(
            data: data ?? _fallbackData(user),
            onRefresh: _refresh,
            onSettingsTap: _openSettings,
            onProfileTap: _openProfile,
            onTabSelected: _handleTabSelected,
            toastMessage: _toastMessage,
          );
        },
      ),
    );
  }

  _MeDashboardData _fallbackData(MeUser? user) {
    return _MeDashboardData(
      user: user ?? const MeUser(id: '', profile: MeProfile()),
      itemCount: 0,
      packCount: 0,
      checklistCount: 0,
    );
  }
}

class _MeDashboardView extends StatelessWidget {
  const _MeDashboardView({
    required this.data,
    required this.onRefresh,
    required this.onSettingsTap,
    required this.onProfileTap,
    required this.onTabSelected,
    required this.toastMessage,
  });

  final _MeDashboardData data;
  final Future<void> Function() onRefresh;
  final VoidCallback onSettingsTap;
  final VoidCallback onProfileTap;
  final ValueChanged<BottomTab> onTabSelected;
  final String? toastMessage;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 96 + MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: onRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inset = meContentInset(constraints.maxWidth);
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomPadding),
                children: [
                  MeDashboardHeader(
                    user: data.user,
                    onSettingsTap: onSettingsTap,
                    onProfileTap: onProfileTap,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    child: MeStatsCard(
                      itemCount: data.itemCount,
                      packCount: data.packCount,
                      checklistCount: data.checklistCount,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    child: const MeGiftTile(),
                  ),
                ],
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: BottomNav(
              currentTab: BottomTab.me,
              onTabSelected: onTabSelected,
            ),
          ),
        ),
        if (toastMessage != null) MeSuccessToast(message: toastMessage!),
      ],
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
