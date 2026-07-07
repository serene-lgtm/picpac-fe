import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../checklists/data/checklist_repository.dart';
import '../../../checklists/presentation/pages/checklists_page.dart';
import '../../../items/data/item.dart';
import '../../../items/data/item_repository.dart';
import '../../../me/data/me_repository.dart';
import '../../../me/presentation/pages/me_page.dart';
import '../../data/pack.dart';
import '../../data/pack_repository.dart';
import '../../../../shared/navigation/no_animation_route.dart';
import '../../../../shared/widgets/bottom_nav.dart';

const _packGradientColors = [Color(0xFF71D0C6), Color(0xFFC8EFC1)];

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
  late Future<List<Pack>> _packsFuture;

  @override
  void initState() {
    super.initState();
    _packsFuture = widget.packRepository.listPacks();
  }

  Future<void> _refresh() async {
    final future = widget.packRepository.listPacks();
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
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            FutureBuilder<List<Pack>>(
              future: _packsFuture,
              builder: (context, snapshot) {
                final packs = snapshot.data ?? const <Pack>[];
                return Column(
                  children: [
                    _PackTopBar(
                      title: '我的套组',
                      trailing: Icons.search_rounded,
                      onTrailingTap: () => _openSearch(context),
                    ),
                    Expanded(
                      child:
                          snapshot.connectionState == ConnectionState.waiting &&
                              packs.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : snapshot.hasError && packs.isEmpty
                          ? _PackLoadError(
                              message: snapshot.error.toString(),
                              onRetry: _refresh,
                            )
                          : packs.isEmpty
                          ? const _PackEmptyState(message: '是时候打包一些套组咯')
                          : _PackList(
                              packs: packs,
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
            Positioned(
              right: 38,
              bottom: 78,
              child: SizedBox.square(
                dimension: 52,
                child: FilledButton(
                  onPressed: () => _openCreatePack(context),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: const Color(0xFFC8EFC1),
                    foregroundColor: Colors.black,
                    shape: const CircleBorder(),
                    elevation: 12,
                    shadowColor: const Color(0x44000000),
                  ),
                  child: const Icon(Icons.add_rounded, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePackPage extends StatefulWidget {
  const CreatePackPage({
    super.key,
    required this.itemRepository,
    required this.packRepository,
  });

  final ItemRepository itemRepository;
  final PackRepository packRepository;

  @override
  State<CreatePackPage> createState() => _CreatePackPageState();
}

class _CreatePackPageState extends State<CreatePackPage> {
  final _packNameController = TextEditingController();
  bool _nameTouched = false;

  @override
  void dispose() {
    _packNameController.dispose();
    super.dispose();
  }

  void _goNext() {
    setState(() => _nameTouched = true);
    final name = _packNameController.text.trim();
    if (name.isEmpty) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => PackItemPickerPage(
          packName: name,
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _packNameController.text.trim().isNotEmpty;

    return _CreatePackNameSheet(
      controller: _packNameController,
      showError: _nameTouched && !hasName,
      onChanged: () => setState(() {}),
      onClose: () => Navigator.of(context).pop(),
      onNext: _goNext,
    );
  }
}

class _PackEmptyState extends StatelessWidget {
  const _PackEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 178,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF258B85),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Positioned(
          left: 42,
          right: 42,
          top: 230,
          child: SvgPicture.asset(
            'assets/Empty-pana.svg',
            height: 250,
            semanticsLabel: '空套组插画',
          ),
        ),
      ],
    );
  }
}

class _PackList extends StatelessWidget {
  const _PackList({
    required this.packs,
    required this.onRefresh,
    required this.onPackTap,
  });

  final List<Pack> packs;
  final Future<void> Function() onRefresh;
  final ValueChanged<Pack> onPackTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(34, 24, 34, 148),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _PackCard(
              pack: packs[index],
              onTap: () => onPackTap(packs[index]),
            ),
          );
        },
      ),
    );
  }
}

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
  Future<List<Pack>>? _packsFuture;
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
        _packsFuture = q.isEmpty ? null : widget.packRepository.listPacks(q: q);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 58, 28, 0),
                    child: Row(
                      children: [
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
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF258B85),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('取消'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _packsFuture == null
                      ? const _PackEmptyState(message: '空空如也')
                      : FutureBuilder<List<Pack>>(
                          future: _packsFuture,
                          builder: (context, snapshot) {
                            final packs = snapshot.data ?? const <Pack>[];
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
                              return const _PackEmptyState(message: '空空如也');
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                34,
                                24,
                                34,
                                148,
                              ),
                              itemCount: packs.length,
                              itemBuilder: (context, index) {
                                final pack = packs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _PackCard(
                                    pack: pack,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (context) => PackDetailPage(
                                            pack: pack,
                                            items: const [],
                                            packRepository:
                                                widget.packRepository,
                                            itemRepository:
                                                widget.itemRepository,
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: BottomNav(
                  currentTab: BottomTab.pack,
                  onTabSelected: (tab) {
                    if (tab == BottomTab.item) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
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
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackLoadError extends StatelessWidget {
  const _PackLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
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
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.black,
            size: 28,
          ),
          suffixIcon: IconButton(
            onPressed: onClear,
            icon: const CircleAvatar(
              radius: 8,
              backgroundColor: Color(0xFFC9C9CF),
              child: Icon(Icons.close_rounded, color: Colors.white, size: 13),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFF65C96B), width: 1.6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFF48B8B4), width: 1.8),
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({required this.pack, required this.onTap});

  final Pack pack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final description = pack.description.trim().isEmpty
        ? '红景天，硬壳冲锋衣，保温杯...'
        : pack.description.trim();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(30, 26, 26, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6EC9C3), Color(0xFFC8EFC1)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '一共${pack.items.length}件物品',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const _PackBoxArt(),
          ],
        ),
      ),
    );
  }
}

class _PackBoxArt extends StatelessWidget {
  const _PackBoxArt();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(84, 110), painter: _PackBoxPainter());
  }
}

class _PackBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final red = Paint()..color = const Color(0xFFFF6A57);
    final darkRed = Paint()..color = const Color(0xFFC9473F);
    final light = Paint()..color = const Color(0xFFFFB0A2);
    final shadow = Paint()..color = const Color(0x22000000);

    canvas.drawRect(Rect.fromLTWH(24, 28, 48, 56), shadow);
    canvas.drawRect(Rect.fromLTWH(34, 6, 42, 48), red);
    canvas.drawRect(Rect.fromLTWH(22, 56, 54, 48), red);
    canvas.drawRect(Rect.fromLTWH(10, 50, 36, 10), darkRed);
    canvas.drawRect(Rect.fromLTWH(34, 62, 16, 8), light);
    canvas.drawRect(Rect.fromLTWH(36, 12, 4, 4), darkRed);
    canvas.drawRect(Rect.fromLTWH(54, 12, 4, 4), darkRed);
    canvas.drawRect(Rect.fromLTWH(66, 34, 4, 6), darkRed);
    canvas.drawRect(Rect.fromLTWH(28, 92, 5, 6), light);
    canvas.drawRect(Rect.fromLTWH(68, 88, 5, 7), light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CreatePackNameSheet extends StatelessWidget {
  const _CreatePackNameSheet({
    required this.controller,
    required this.showError,
    required this.onChanged,
    required this.onClose,
    required this.onNext,
  });

  final TextEditingController controller;
  final bool showError;
  final VoidCallback onChanged;
  final VoidCallback onClose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: const Color(0x33000000),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D4DC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filled(
                      onPressed: onClose,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F2F7),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ),
                  Text(
                    '新建套组',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(text: '套组名 '),
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Color(0xFFE45B5B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: '为你的套组取个名字',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB8B8C4),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F0F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    errorText: showError ? '' : null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 44,
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF48B8B4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '下一步',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
      final pack = existingPack == null
          ? await widget.packRepository.createPack(
              name: widget.packName,
              itemIds: itemIds,
            )
          : await widget.packRepository.updatePack(
              packId: existingPack.id,
              name: existingPack.name,
              description: existingPack.description,
              itemIds: itemIds,
            );
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
        backgroundColor: Colors.white,
        body: FutureBuilder<List<Item>>(
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
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                    children: [
                      _PackSearchField(
                        controller: _searchController,
                        onChanged: _searchItems,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '已选中${_selectedItemIds.length}项',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
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
              ],
            );
          },
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
    setState(() {
      _submitting = true;
      _error = null;
    });
    final remainingItems = widget.items
        .where((item) => !_selectedItemIds.contains(item.id))
        .toList(growable: false);
    try {
      final updated = await widget.packRepository.updatePack(
        packId: widget.pack.id,
        name: widget.pack.name,
        description: widget.pack.description,
        itemIds: remainingItems.map((item) => item.id).toList(growable: false),
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
        backgroundColor: Colors.white,
        body: Column(
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
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                children: [
                  Text(
                    '已选中${_selectedItemIds.length}项',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ...widget.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 22),
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
          ],
        ),
      ),
    );
  }
}

class _PickerTopBar extends StatelessWidget {
  const _PickerTopBar({
    required this.submitting,
    required this.onBack,
    required this.onDone,
    this.doneLabel,
    this.doneColor,
  });

  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback? onDone;
  final String? doneLabel;
  final Color? doneColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _packGradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: submitting ? null : onBack,
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                ),
              ),
              Text(
                '选择物品',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: submitting
                    ? const Padding(
                        padding: EdgeInsets.only(right: 18),
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : doneLabel == null
                    ? IconButton(
                        onPressed: onDone,
                        icon: const Icon(Icons.check_rounded, size: 34),
                      )
                    : TextButton(
                        onPressed: onDone,
                        style: TextButton.styleFrom(
                          foregroundColor: doneColor ?? Colors.black,
                        ),
                        child: Text(
                          doneLabel!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

class _PackSearchField extends StatelessWidget {
  const _PackSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.black,
            size: 28,
          ),
          hintText: '',
          hintStyle: const TextStyle(
            color: Color(0xFFB8B8C4),
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFF65C96B), width: 1.6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: Color(0xFF48B8B4), width: 1.8),
          ),
        ),
      ),
    );
  }
}

class _SelectableItemRow extends StatelessWidget {
  const _SelectableItemRow({
    required this.item,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final Item item;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 60,
        padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: disabled ? const Color(0xFF8F8F96) : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description.isEmpty ? '证件' : item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFB1B1B1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            selected
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: disabled
                        ? const Color(0xFFB8DCD9)
                        : const Color(0xFF48B8B4),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC8C8D0),
                        width: 1.4,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _PickerError extends StatelessWidget {
  const _PickerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

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
    super.dispose();
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
    if (trimmed.isEmpty || _updatingName) return;
    setState(() => _updatingName = true);
    try {
      final updated = await widget.packRepository.updatePack(
        packId: _pack.id,
        name: trimmed,
        description: _pack.description,
        itemIds: _pack.items,
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

  void _openItemDetail(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _PackItemDetailPage(item: item),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                _PackTopBar(
                  title: '我的套组',
                  leading: Icons.chevron_left_rounded,
                  onLeadingTap: () => Navigator.of(context).pop(),
                  trailing: Icons.more_horiz,
                  onTrailingTap: _openMoreActions,
                ),
                Expanded(
                  child: FutureBuilder<Pack>(
                    future: _packFuture,
                    builder: (context, snapshot) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(28, 20, 28, 92),
                        children: [
                          Text(
                            _pack.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 18),
                          if (_packItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 18),
                              child: _PackDetailItemCard(
                                name: '暂无物品',
                                description: '添加物品后会显示在这里',
                              ),
                            )
                          else
                            ..._packItems.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _PackDetailItemCard(
                                  name: item.name,
                                  description: item.description.isEmpty
                                      ? '证件'
                                      : item.description,
                                  onTap: () => _openItemDetail(item),
                                ),
                              ),
                            ),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Center(child: CircularProgressIndicator()),
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
              left: 44,
              right: 44,
              bottom: 86,
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
    );
  }
}

class _PackTopBar extends StatelessWidget {
  const _PackTopBar({
    required this.title,
    required this.trailing,
    this.leading,
    this.onLeadingTap,
    this.onTrailingTap,
  });

  final String title;
  final IconData trailing;
  final IconData? leading;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 106,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _packGradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: IconButton(
                    onPressed: onLeadingTap,
                    icon: Icon(leading, color: Colors.black, size: 30),
                  ),
                ),
              ),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 28),
                child: IconButton(
                  onPressed: onTrailingTap,
                  icon: Icon(trailing, color: Colors.black, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackDetailBottomActions extends StatelessWidget {
  const _PackDetailBottomActions({required this.onAdd, required this.onRemove});

  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE7E7EC))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onAdd,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF60716F),
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text('添加'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 28),
                    child: Text('移除'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackMoreActionsSheet extends StatelessWidget {
  const _PackMoreActionsSheet({
    required this.deleting,
    required this.onEditName,
    required this.onDelete,
  });

  final bool deleting;
  final VoidCallback onEditName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              child: TextButton(
                onPressed: onEditName,
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text(
                  '修改套组名',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: TextButton(
                onPressed: deleting ? null : onDelete,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(
                  deleting ? '删除中...' : '删除套组',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Divider(height: 8, thickness: 8, color: Color(0xFFF3F3F6)),
            SizedBox(
              height: 64,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text(
                  '取消',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPackNameSheet extends StatefulWidget {
  const _EditPackNameSheet({
    required this.initialName,
    required this.saving,
    required this.onSave,
  });

  final String initialName;
  final bool saving;
  final ValueChanged<String> onSave;

  @override
  State<_EditPackNameSheet> createState() => _EditPackNameSheetState();
}

class _EditPackNameSheetState extends State<_EditPackNameSheet> {
  late final TextEditingController _controller;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _controller.text.trim().isNotEmpty;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4D4DC),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filled(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F2F7),
                          foregroundColor: Colors.black87,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                    ),
                    Text(
                      '修改套组名',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    children: const [
                      TextSpan(text: '套组名 '),
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Color(0xFFE45B5B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() => _touched = true),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF0F0F6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _touched && !hasName ? '' : null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 44,
                    child: FilledButton(
                      onPressed: widget.saving
                          ? null
                          : () {
                              setState(() => _touched = true);
                              if (!hasName) return;
                              widget.onSave(_controller.text);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF48B8B4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        widget.saving ? '保存中...' : '保存',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PackDetailItemCard extends StatelessWidget {
  const _PackDetailItemCard({
    required this.name,
    required this.description,
    this.onTap,
  });

  final String name;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 60,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB1B1B1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackItemDetailPage extends StatelessWidget {
  const _PackItemDetailPage({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _PackTopBar(
              title: '物品详情',
              leading: Icons.chevron_left_rounded,
              onLeadingTap: () => Navigator.of(context).pop(),
              trailing: Icons.more_horiz,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PackDetailItemCard(
                    name: '描述',
                    description: item.description.isEmpty
                        ? '暂无描述'
                        : item.description,
                  ),
                  if (item.status.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _PackDetailItemCard(name: '状态', description: item.status),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackSuccessBanner extends StatelessWidget {
  const _PackSuccessBanner({this.message = '添加成功'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF36C4C3), size: 22),
          const SizedBox(width: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF36C4C3),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
