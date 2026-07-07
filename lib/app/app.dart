import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/session_store.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/checklists/data/checklist_repository.dart';
import '../features/items/data/item_repository.dart';
import '../features/items/presentation/pages/items_page.dart';
import '../features/me/data/me.dart';
import '../features/me/data/me_repository.dart';
import '../features/me/presentation/pages/me_page.dart';
import '../features/packs/data/pack_repository.dart';
import 'theme.dart';

class PicpacApp extends StatefulWidget {
  const PicpacApp({
    super.key,
    AuthRepository? authRepository,
    ChecklistRepository? checklistRepository,
    ItemRepository? itemRepository,
    MeRepository? meRepository,
    PackRepository? packRepository,
    SessionStore? sessionStore,
  }) : _authRepositoryOverride = authRepository,
       _checklistRepositoryOverride = checklistRepository,
       _itemRepositoryOverride = itemRepository,
       _meRepositoryOverride = meRepository,
       _packRepositoryOverride = packRepository,
       _sessionStoreOverride = sessionStore;

  final AuthRepository? _authRepositoryOverride;
  final ChecklistRepository? _checklistRepositoryOverride;
  final ItemRepository? _itemRepositoryOverride;
  final MeRepository? _meRepositoryOverride;
  final PackRepository? _packRepositoryOverride;
  final SessionStore? _sessionStoreOverride;

  @override
  State<PicpacApp> createState() => _PicpacAppState();
}

class _PicpacAppState extends State<PicpacApp> {
  AuthSession? _session;
  bool _bootstrapping = true;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final ChecklistRepository _checklistRepository;
  late final ItemRepository _itemRepository;
  late final MeRepository _meRepository;
  late final PackRepository _packRepository;
  late final SessionStore _sessionStore;

  @override
  void initState() {
    super.initState();
    _sessionStore = widget._sessionStoreOverride ?? SharedPrefsSessionStore();
    _apiClient = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      accessTokenProvider: () => _session?.accessToken,
      onUnauthorized: _refreshSessionSilently,
    );
    _authRepository =
        widget._authRepositoryOverride ?? ApiAuthRepository(_apiClient);
    _checklistRepository =
        widget._checklistRepositoryOverride ??
        ApiChecklistRepository(_apiClient);
    _itemRepository =
        widget._itemRepositoryOverride ?? ApiItemRepository(_apiClient);
    _meRepository = widget._meRepositoryOverride ?? ApiMeRepository(_apiClient);
    _packRepository =
        widget._packRepositoryOverride ?? ApiPackRepository(_apiClient);
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    final stored = await _sessionStore.read();
    if (!mounted) return;
    setState(() {
      _session = stored;
      _bootstrapping = false;
    });
  }

  Future<bool> _refreshSessionSilently() async {
    final current = _session;
    if (current == null || current.refreshToken.trim().isEmpty) {
      await _resetSession();
      return false;
    }

    try {
      final refreshed = await _authRepository.refreshSession(
        refreshToken: current.refreshToken,
      );
      final nextSession = AuthSession(
        accessToken: refreshed.accessToken,
        refreshToken: refreshed.refreshToken,
        user: _resolvedUser(refreshed.user, fallback: current.user),
      );
      await _sessionStore.write(nextSession);
      if (!mounted) return false;
      setState(() {
        _session = nextSession;
      });
      return true;
    } catch (_) {
      await _resetSession();
      return false;
    }
  }

  Future<void> _handleLoggedIn(AuthSession session) async {
    await _sessionStore.write(session);
    if (!mounted) return;
    setState(() {
      _session = session;
    });
  }

  Future<void> _handleLoggedOut() async {
    final refreshToken = _session?.refreshToken.trim() ?? '';
    if (refreshToken.isNotEmpty) {
      try {
        await _authRepository.logout(refreshToken: refreshToken);
      } catch (_) {}
    }
    await _resetSession();
  }

  Future<void> _resetSession() async {
    await _sessionStore.clear();
    if (!mounted) return;
    setState(() {
      _session = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '物品',
      debugShowCheckedModeBanner: false,
      theme: PicpacTheme.light(),
      builder: (context, child) {
        if (_session == null || child == null) return child ?? const SizedBox();
        return MeSessionScope(onLogout: _handleLoggedOut, child: child);
      },
      home: _bootstrapping
          ? const _AppBootstrapPage()
          : _session == null
          ? LoginPage(
              authRepository: _authRepository,
              onLogin: (session) => _handleLoggedIn(session),
            )
          : ItemsPage(
              repository: _itemRepository,
              packRepository: _packRepository,
              checklistRepository: _checklistRepository,
              meRepository: _meRepository,
            ),
    );
  }
}

MeUser _resolvedUser(MeUser user, {required MeUser fallback}) {
  if (user.id.isEmpty) return fallback;
  return user;
}

class _AppBootstrapPage extends StatelessWidget {
  const _AppBootstrapPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
