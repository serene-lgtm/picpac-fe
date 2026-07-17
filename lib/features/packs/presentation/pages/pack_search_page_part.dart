part of 'create_pack_page.dart';

class PackSearchPage extends StatefulWidget {
  const PackSearchPage({
    super.key,
    required this.packRepository,
    required this.itemRepository,
    required this.meRepository,
    required this.checklistRepository,
  });

  final PackRepository packRepository;
  final ItemRepository itemRepository;
  final MeRepository meRepository;
  final ChecklistRepository checklistRepository;

  @override
  State<PackSearchPage> createState() => _PackSearchPageState();
}

class _PackSearchPageState extends State<PackSearchPage> {
  final _controller = TextEditingController();
  Future<_PackListData>? _packsFuture;
  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 260), () {
      final q = _controller.text.trim();
      setState(() {
        _packsFuture = q.isEmpty ? null : _loadSearchResults(q);
      });
    });
  }

  Future<_PackListData> _loadSearchResults(String q) async {
    final results = await Future.wait<Object>([
      widget.packRepository.listPacks(q: q),
      widget.itemRepository.listItems(),
    ]);
    return _PackListData(
      packs: results[0] as List<Pack>,
      itemsById: {for (final item in results[1] as List<Item>) item.id: item},
    );
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
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 34, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.chevron_left_rounded, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 30,
                          height: 48,
                        ),
                      ),
                      Expanded(
                        child: _PackSearchInput(
                          controller: _controller,
                          onChanged: _search,
                          onClear: () {
                            _controller.clear();
                            setState(() => _packsFuture = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _packsFuture == null
                    ? const SizedBox.shrink()
                    : FutureBuilder<_PackListData>(
                        future: _packsFuture,
                        builder: (context, snapshot) {
                          final data = snapshot.data ?? _PackListData.empty;
                          final packs = data.packs;
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              packs.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError && packs.isEmpty) {
                            return _PackLoadError(
                              message: snapshot.error.toString(),
                              onRetry: _search,
                            );
                          }
                          if (packs.isEmpty) {
                            return const SearchEmptyState();
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                            itemCount: packs.length,
                            itemBuilder: (context, index) {
                              final pack = packs[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _PackCard(
                                  pack: pack,
                                  itemNames: _previewItemNames(
                                    pack,
                                    data.itemsById,
                                  ),
                                  onTap: () {
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
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackSearchInput extends StatelessWidget {
  const _PackSearchInput({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFC3C5CC),
            size: 28,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: const CircleAvatar(
                    radius: 8,
                    backgroundColor: Color(0xFFC9C9CF),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
