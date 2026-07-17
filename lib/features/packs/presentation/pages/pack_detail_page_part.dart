part of 'create_pack_page.dart';

class PackDetailPage extends StatefulWidget {
  const PackDetailPage({
    super.key,
    required this.pack,
    required this.items,
    required this.packRepository,
    required this.itemRepository,
    this.showSuccessBanner = false,
  });

  final Pack pack;
  final List<Item> items;
  final PackRepository packRepository;
  final ItemRepository itemRepository;
  final bool showSuccessBanner;

  @override
  State<PackDetailPage> createState() => _PackDetailPageState();
}

class _PackDetailPageState extends State<PackDetailPage> {
  late Pack _pack;
  late Future<Pack> _packFuture;
  late List<Item> _packItems;
  bool _showSuccessBanner = false;
  String _successMessage = '添加成功';
  Timer? _successTimer;
  bool _updatingName = false;
  bool _deleting = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pack = widget.pack;
    _packItems = widget.items;
    _packFuture = _loadPack();
    if (widget.showSuccessBanner) {
      _showSuccessBanner = true;
      _successMessage = '添加成功';
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _showSuccessBanner = false);
      });
    }
  }

  Future<Pack> _loadPack() async {
    final pack = await widget.packRepository.getPack(widget.pack.id);
    final items = await _loadPackItems(pack);
    if (mounted) {
      setState(() {
        _pack = pack;
        _packItems = items;
      });
    } else {
      _pack = pack;
      _packItems = items;
    }
    return pack;
  }

  Future<List<Item>> _loadPackItems(Pack pack) async {
    if (widget.items.isNotEmpty) return widget.items;
    if (pack.items.isEmpty) return const [];

    final allItems = await widget.itemRepository.listItems();
    final itemById = {for (final item in allItems) item.id: item};
    return pack.items
        .map((id) => itemById[id])
        .whereType<Item>()
        .toList(growable: false);
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    _handleSearchChanged('');
  }

  void _openMoreActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) {
        return _PackMoreActionsSheet(
          deleting: _deleting,
          onEditName: () {
            Navigator.of(context).pop();
            _openEditNameSheet();
          },
          onDelete: _deletePack,
        );
      },
    );
  }

  void _openEditNameSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) {
        return _EditPackNameSheet(
          initialName: _pack.name,
          saving: _updatingName,
          onSave: _updatePackName,
        );
      },
    );
  }

  Future<void> _updatePackName(String name) async {
    final trimmed = name.trim();
    if (!_isValidPackName(trimmed) || _updatingName) return;
    setState(() => _updatingName = true);
    try {
      final updated = await widget.packRepository.updatePackProfile(
        packId: _pack.id,
        name: trimmed,
        description: _pack.description,
      );
      if (!mounted) return;
      setState(() {
        _pack = updated;
        _packFuture = Future.value(updated);
        _updatingName = false;
      });
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingName = false);
    }
  }

  Future<void> _deletePack() async {
    if (_deleting) return;
    final shouldDelete = await _showPackDeleteDialog(
      context: context,
      title: '确认删除该套组吗？',
      confirmLabel: '删除',
    );
    if (shouldDelete != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.packRepository.deletePack(_pack.id);
      if (!mounted) return;
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
    }
  }

  Future<void> _openItemDetail(Item item) async {
    final result = await showItemDetailSheet(
      context: context,
      item: item,
      itemRepository: widget.itemRepository,
    );
    if (!mounted) return;
    if (result == ItemDetailResult.updated ||
        result == ItemDetailResult.deleted) {
      setState(() => _packFuture = _loadPack());
    }
  }

  Future<void> _openAddItems() async {
    final result = await Navigator.of(context).push<_PackItemsEditResult>(
      MaterialPageRoute<_PackItemsEditResult>(
        builder: (context) => PackItemPickerPage(
          packName: _pack.name,
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
          existingPack: _pack,
          existingItems: _packItems,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _applyItemsEditResult(result);
  }

  Future<void> _openRemoveItems() async {
    if (_packItems.isEmpty) return;
    final result = await Navigator.of(context).push<_PackItemsEditResult>(
      MaterialPageRoute<_PackItemsEditResult>(
        builder: (context) => _PackRemoveItemsPage(
          pack: _pack,
          items: _packItems,
          packRepository: widget.packRepository,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _applyItemsEditResult(result);
  }

  void _applyItemsEditResult(_PackItemsEditResult result) {
    _successTimer?.cancel();
    setState(() {
      _pack = result.pack;
      _packItems = result.items;
      _packFuture = Future.value(result.pack);
      _successMessage = result.message;
      _showSuccessBanner = true;
    });
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSuccessBanner = false);
    });
  }

  List<Item> get _visiblePackItems {
    if (_searchQuery.isEmpty) return _packItems;
    return _packItems
        .where((item) {
          return item.name.toLowerCase().contains(_searchQuery) ||
              item.description.toLowerCase().contains(_searchQuery);
        })
        .toList(growable: false);
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
              Column(
                children: [
                  _PackTopBar(
                    title: _pack.name,
                    leading: Icons.chevron_left_rounded,
                    onLeadingTap: () => Navigator.of(context).pop(),
                    trailing: Icons.more_horiz,
                    onTrailingTap: _openMoreActions,
                  ),
                  Expanded(
                    child: FutureBuilder<Pack>(
                      future: _packFuture,
                      builder: (context, snapshot) {
                        final visibleItems = _visiblePackItems;
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 92),
                          children: [
                            SearchPillField(
                              controller: _searchController,
                              hintText: '',
                              onChanged: _handleSearchChanged,
                              onClear: _clearSearch,
                            ),
                            const SizedBox(height: 16),
                            if (_packItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 14),
                                child: _PackDetailItemCard(
                                  name: '暂无物品',
                                  description: '添加物品后会显示在这里',
                                ),
                              )
                            else if (visibleItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 72),
                                child: SearchEmptyIllustration(),
                              )
                            else
                              ...visibleItems.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _PackDetailItemCard(
                                    name: item.name,
                                    description: item.description,
                                    onTap: () => _openItemDetail(item),
                                  ),
                                ),
                              ),
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              const Padding(
                                padding: EdgeInsets.only(top: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _PackDetailBottomActions(
                  onAdd: _openAddItems,
                  onRemove: _openRemoveItems,
                ),
              ),
              Positioned(
                left: 40,
                right: 40,
                bottom: 402,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showSuccessBanner ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: _PackSuccessBanner(message: _successMessage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
