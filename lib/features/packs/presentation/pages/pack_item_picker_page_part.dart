part of 'create_pack_page.dart';

class PackItemPickerPage extends StatefulWidget {
  const PackItemPickerPage({
    super.key,
    required this.packName,
    required this.itemRepository,
    required this.packRepository,
    this.existingPack,
    this.existingItems = const [],
  });

  final String packName;
  final ItemRepository itemRepository;
  final PackRepository packRepository;
  final Pack? existingPack;
  final List<Item> existingItems;

  @override
  State<PackItemPickerPage> createState() => _PackItemPickerPageState();
}

class _PackItemPickerPageState extends State<PackItemPickerPage> {
  final _searchController = TextEditingController();
  late Future<List<Item>> _itemsFuture;
  final Set<String> _selectedItemIds = {};
  final Map<String, Item> _knownItemsById = {};
  Timer? _searchTimer;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final item in widget.existingItems) {
      _selectedItemIds.add(item.id);
      _knownItemsById[item.id] = item;
    }
    _itemsFuture = widget.itemRepository.listItems();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchItems() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 260), () {
      final q = _searchController.text.trim();
      setState(() {
        _itemsFuture = widget.itemRepository.listItems(q: q.isEmpty ? null : q);
      });
    });
  }

  Future<void> _submitItems() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final existingPack = widget.existingPack;
      final itemIds = _selectedItemIds.toList(growable: false);
      Pack pack;
      if (existingPack == null) {
        pack = await widget.packRepository.createPack(
          name: widget.packName,
          itemIds: itemIds,
        );
      } else {
        final newItemIds = itemIds
            .where((id) => !existingPack.items.contains(id))
            .toList(growable: false);
        if (newItemIds.isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop();
          return;
        }
        pack = await widget.packRepository.addPackItems(
          packId: existingPack.id,
          itemIds: newItemIds,
        );
      }
      if (!mounted) return;
      final selectedItems = _selectedItemIds
          .map((id) => _knownItemsById[id])
          .nonNulls
          .toList(growable: false);
      if (existingPack != null) {
        Navigator.of(context).pop(
          _PackItemsEditResult(
            pack: pack,
            items: selectedItems,
            message: '添加成功',
          ),
        );
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (context) => PackDetailPage(
            pack: pack,
            items: selectedItems,
            packRepository: widget.packRepository,
            itemRepository: widget.itemRepository,
            showSuccessBanner: true,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFA7E399),
        body: _PackGradientBackground(
          child: FutureBuilder<List<Item>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              final allItems = snapshot.data ?? const <Item>[];
              for (final item in allItems) {
                _knownItemsById[item.id] = item;
              }

              return Column(
                children: [
                  _PickerTopBar(
                    submitting: _submitting,
                    onBack: () => Navigator.of(context).pop(),
                    onDone: snapshot.hasData ? _submitItems : null,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                      children: [
                        _PackSearchField(
                          controller: _searchController,
                          onChanged: _searchItems,
                        ),
                        const SizedBox(height: 18),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 80),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (snapshot.hasError)
                          _PickerError(
                            message: snapshot.error.toString(),
                            onRetry: () => setState(
                              () => _itemsFuture = widget.itemRepository
                                  .listItems(),
                            ),
                          )
                        else
                          ...allItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _SelectableItemRow(
                                item: item,
                                selected: _selectedItemIds.contains(item.id),
                                disabled: widget.existingItems.any(
                                  (existing) => existing.id == item.id,
                                ),
                                onTap: () {
                                  if (widget.existingItems.any(
                                    (existing) => existing.id == item.id,
                                  )) {
                                    return;
                                  }
                                  setState(() {
                                    if (_selectedItemIds.contains(item.id)) {
                                      _selectedItemIds.remove(item.id);
                                    } else {
                                      _selectedItemIds.add(item.id);
                                      _knownItemsById[item.id] = item;
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _PickerSelectionBar(count: _selectedItemIds.length),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PickerSelectionBar extends StatelessWidget {
  const _PickerSelectionBar({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF7FFF8),
        border: Border(top: BorderSide(color: Color(0xFFE7E7EC))),
      ),
      child: Text(
        '已选中$count项',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PackItemsEditResult {
  const _PackItemsEditResult({
    required this.pack,
    required this.items,
    required this.message,
  });

  final Pack pack;
  final List<Item> items;
  final String message;
}

class _PackRemoveItemsPage extends StatefulWidget {
  const _PackRemoveItemsPage({
    required this.pack,
    required this.items,
    required this.packRepository,
  });

  final Pack pack;
  final List<Item> items;
  final PackRepository packRepository;

  @override
  State<_PackRemoveItemsPage> createState() => _PackRemoveItemsPageState();
}

class _PackRemoveItemsPageState extends State<_PackRemoveItemsPage> {
  late final Set<String> _selectedItemIds;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedItemIds = <String>{};
  }

  Future<void> _removeItems() async {
    if (_submitting) return;
    final shouldRemove = await _showPackDeleteDialog(
      context: context,
      title: '确认移除所选物品吗？',
      confirmLabel: '移除',
    );
    if (shouldRemove != true || !mounted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final remainingItems = widget.items
        .where((item) => !_selectedItemIds.contains(item.id))
        .toList(growable: false);
    try {
      final updated = await widget.packRepository.removePackItems(
        packId: widget.pack.id,
        itemIds: _selectedItemIds.toList(growable: false),
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        _PackItemsEditResult(
          pack: updated,
          items: remainingItems,
          message: '移除成功',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFA7E399),
        body: _PackGradientBackground(
          child: Column(
            children: [
              _PickerTopBar(
                submitting: _submitting,
                onBack: () => Navigator.of(context).pop(),
                onDone: _selectedItemIds.isEmpty ? null : _removeItems,
                doneLabel: '移除',
                doneColor: Colors.red,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  children: [
                    ...widget.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _SelectableItemRow(
                          item: item,
                          selected: _selectedItemIds.contains(item.id),
                          onTap: () {
                            setState(() {
                              if (_selectedItemIds.contains(item.id)) {
                                _selectedItemIds.remove(item.id);
                              } else {
                                _selectedItemIds.add(item.id);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _PickerSelectionBar(count: _selectedItemIds.length),
            ],
          ),
        ),
      ),
    );
  }
}
