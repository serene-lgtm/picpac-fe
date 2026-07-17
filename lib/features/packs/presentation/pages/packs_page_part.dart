part of 'create_pack_page.dart';

class PacksPage extends StatefulWidget {
  const PacksPage({
    super.key,
    required this.itemRepository,
    required this.packRepository,
    required this.checklistRepository,
    required this.meRepository,
  });

  final ItemRepository itemRepository;
  final PackRepository packRepository;
  final ChecklistRepository checklistRepository;
  final MeRepository meRepository;

  @override
  State<PacksPage> createState() => _PacksPageState();
}

class _PacksPageState extends State<PacksPage> {
  late Future<Object> _packsFuture;

  @override
  void initState() {
    super.initState();
    _packsFuture = _loadPacks();
  }

  Future<_PackListData> _loadPacks() async {
    final results = await Future.wait<Object>([
      widget.packRepository.listPacks(),
      widget.itemRepository.listItems(),
    ]);
    return _PackListData(
      packs: results[0] as List<Pack>,
      itemsById: {for (final item in results[1] as List<Item>) item.id: item},
    );
  }

  Future<void> _refresh() async {
    final future = _loadPacks();
    setState(() {
      _packsFuture = future;
    });
    await future;
  }

  void _openCreatePack(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CreatePackPage(
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
        );
      },
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PackSearchPage(
          packRepository: widget.packRepository,
          itemRepository: widget.itemRepository,
          meRepository: widget.meRepository,
          checklistRepository: widget.checklistRepository,
        ),
      ),
    );
  }

  void _handleTabSelected(BuildContext context, BottomTab tab) {
    if (tab == BottomTab.pack) return;
    if (tab == BottomTab.item) {
      Navigator.of(context).pop();
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
    if (tab == BottomTab.me) {
      Navigator.of(context).pushReplacement(
        noAnimationRoute<void>(
          (context) => MePage(
            meRepository: widget.meRepository,
            itemRepository: widget.itemRepository,
            packRepository: widget.packRepository,
            checklistRepository: widget.checklistRepository,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFA7E399),
        body: _PackGradientBackground(
          child: Stack(
            children: [
              FutureBuilder<Object>(
                future: _packsFuture,
                builder: (context, snapshot) {
                  final data = _PackListData.fromSnapshot(snapshot.data);
                  final packs = data.packs;
                  return Column(
                    children: [
                      _PackTopBar(
                        title: '我的套组',
                        trailing: Icons.search_rounded,
                        onTrailingTap: () => _openSearch(context),
                      ),
                      Expanded(
                        child:
                            snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                packs.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : snapshot.hasError && packs.isEmpty
                            ? _PackLoadError(
                                message: snapshot.error.toString(),
                                onRetry: _refresh,
                              )
                            : packs.isEmpty
                            ? const _PackEmptyState(message: '是时候打包一些套组咯！')
                            : _PackList(
                                packs: packs,
                                itemsById: data.itemsById,
                                onRefresh: _refresh,
                                onPackTap: (pack) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => PackDetailPage(
                                        pack: pack,
                                        items: const [],
                                        packRepository: widget.packRepository,
                                        itemRepository: widget.itemRepository,
                                      ),
                                    ),
                                  );
                                },
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
                    currentTab: BottomTab.pack,
                    onTabSelected: (tab) => _handleTabSelected(context, tab),
                  ),
                ),
              ),
              ModuleFloatingAddButton(
                onPressed: () => _openCreatePack(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackListData {
  const _PackListData({required this.packs, required this.itemsById});

  static const empty = _PackListData(packs: [], itemsById: {});

  final List<Pack> packs;
  final Map<String, Item> itemsById;

  static _PackListData fromSnapshot(Object? data) {
    if (data is _PackListData) return data;
    if (data is List<Pack>) {
      return _PackListData(packs: data, itemsById: const {});
    }
    return empty;
  }
}
