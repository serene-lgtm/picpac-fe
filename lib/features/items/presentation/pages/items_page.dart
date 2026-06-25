import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../checklists/data/checklist_repository.dart';
import '../../../checklists/presentation/pages/checklists_page.dart';
import '../../data/item.dart';
import '../../data/item_repository.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/presentation/pages/create_pack_page.dart';
import '../../../../shared/navigation/no_animation_route.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../../shared/widgets/top_controls.dart';
import '../widgets/add_item_sheet.dart';

const _itemIconLabelGap = 8.0;
const _itemsGridCrossAxisCount = 4;
const _itemsGridHorizontalPadding = 36.0;
const _itemsGridCrossAxisSpacing = 22.0;
const _treasureBackgroundBottom = 28.0;
const _treasureBackgroundHeight = 260.0;

class ItemsPage extends StatefulWidget {
  const ItemsPage({
    super.key,
    required this.repository,
    required this.packRepository,
    required this.checklistRepository,
  });

  final ItemRepository repository;
  final PackRepository packRepository;
  final ChecklistRepository checklistRepository;

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late Future<List<Item>> _itemsFuture;
  List<Item> _items = const [];
  Timer? _addSuccessTimer;
  bool _showAddSuccessBanner = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<Item>> _loadItems() async {
    final items = await widget.repository.listItems();
    _items = items;
    return items;
  }

  Future<void> _refresh() async {
    final future = _loadItems();
    setState(() {
      _itemsFuture = future;
    });
    await future;
  }

  Future<void> _openAddItem() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return AddItemSheet(
          onSubmit: (name, description, image) {
            return widget.repository.createItem(
              name: name,
              description: description,
              image: image,
            );
          },
        );
      },
    );
    if (created == true && mounted) {
      await _refresh();
      _showAddSuccess();
    }
  }

  void _showAddSuccess() {
    _addSuccessTimer?.cancel();
    setState(() {
      _showAddSuccessBanner = true;
    });
    _addSuccessTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showAddSuccessBanner = false;
      });
    });
  }

  void _openItemDetail(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ItemDetailPage(
          item: item,
          itemRepository: widget.repository,
          packRepository: widget.packRepository,
          checklistRepository: widget.checklistRepository,
        ),
      ),
    );
  }

  void _handleTabSelected(BottomTab tab) {
    if (tab == BottomTab.item) return;
    if (tab == BottomTab.pack) {
      Navigator.of(context).push(
        noAnimationRoute<void>(
          (context) => PacksPage(
            itemRepository: widget.repository,
            packRepository: widget.packRepository,
            checklistRepository: widget.checklistRepository,
          ),
        ),
      );
    }
    if (tab == BottomTab.checklist) {
      Navigator.of(context).push(
        noAnimationRoute<void>(
          (context) => ChecklistsPage(
            checklistRepository: widget.checklistRepository,
            itemRepository: widget.repository,
            packRepository: widget.packRepository,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _addSuccessTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFA7E399),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF48B3AF), Color(0xFFA7E399)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                const Positioned(
                  bottom: _treasureBackgroundBottom,
                  child: IgnorePointer(child: _TreasureBackground()),
                ),
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      '我的物品',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TopControls(onAdd: _openAddItem),
                    Expanded(
                      child: FutureBuilder<List<Item>>(
                        future: _itemsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              _items.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }
                          if (snapshot.hasError && _items.isEmpty) {
                            return _ErrorState(
                              message: snapshot.error.toString(),
                              onRetry: _refresh,
                            );
                          }
                          final items = snapshot.data ?? _items;
                          if (items.isEmpty) {
                            return _ItemsBlank(onRefresh: _refresh);
                          }
                          return _ItemsGrid(
                            items: items,
                            onRefresh: _refresh,
                            onItemSelected: _openItemDetail,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomNav(
                    currentTab: BottomTab.item,
                    onTabSelected: _handleTabSelected,
                  ),
                ),
                Positioned(
                  left: 50,
                  right: 50,
                  bottom: 90,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showAddSuccessBanner ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const _AddItemSuccessBanner(),
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

class _TreasureBackground extends StatelessWidget {
  const _TreasureBackground();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/Treasure-cuate.svg',
      height: _treasureBackgroundHeight,
      semanticsLabel: '物品插画',
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({
    super.key,
    required this.item,
    required this.itemRepository,
    required this.packRepository,
    required this.checklistRepository,
  });

  final Item item;
  final ItemRepository itemRepository;
  final PackRepository packRepository;
  final ChecklistRepository checklistRepository;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageSize = (screenWidth * 0.52).clamp(168.0, 220.0).toDouble();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFA7E399),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF48B3AF), Color(0xFFA7E399)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  left: -28,
                  right: -28,
                  bottom: 70,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.28,
                      child: SvgPicture.asset(
                        'assets/Treasure-cuate.svg',
                        height: 260,
                        semanticsLabel: '物品插画',
                      ),
                    ),
                  ),
                ),
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 128),
                  children: [
                    _ItemDetailHeader(
                      onBack: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 34),
                    Center(
                      child: _ItemImageFrame(
                        item: item,
                        size: imageSize,
                        iconSize: 82,
                        borderRadius: 26,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            shadows: const [
                              Shadow(
                                color: Color(0x33000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                    ),
                    const SizedBox(height: 28),
                    _ItemDetailPanel(item: item),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomNav(
                    currentTab: BottomTab.item,
                    onTabSelected: (tab) {
                      if (tab == BottomTab.pack) {
                        Navigator.of(context).pushReplacement(
                          noAnimationRoute<void>(
                            (context) => PacksPage(
                              itemRepository: itemRepository,
                              packRepository: packRepository,
                              checklistRepository: checklistRepository,
                            ),
                          ),
                        );
                      }
                      if (tab == BottomTab.checklist) {
                        Navigator.of(context).pushReplacement(
                          noAnimationRoute<void>(
                            (context) => ChecklistsPage(
                              checklistRepository: checklistRepository,
                              itemRepository: itemRepository,
                              packRepository: packRepository,
                            ),
                          ),
                        );
                      }
                    },
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

class _ItemDetailHeader extends StatelessWidget {
  const _ItemDetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox.square(
              dimension: 44,
              child: FilledButton(
                onPressed: onBack,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: const CircleBorder(),
                  elevation: 8,
                  shadowColor: const Color(0x33000000),
                ),
                child: const Icon(Icons.chevron_left_rounded, size: 30),
              ),
            ),
          ),
          Text(
            '物品详情',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDetailPanel extends StatelessWidget {
  const _ItemDetailPanel({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _ItemDetailRow(
            icon: Icons.inventory_2_outlined,
            label: '名称',
            value: item.name,
          ),
          const SizedBox(height: 18),
          _ItemDetailRow(
            icon: Icons.notes_rounded,
            label: '描述',
            value: item.description.isEmpty ? '暂无描述' : item.description,
            alignTop: true,
          ),
          if (item.status.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ItemDetailRow(
              icon: Icons.check_circle_outline_rounded,
              label: '状态',
              value: item.status,
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemDetailRow extends StatelessWidget {
  const _ItemDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.alignTop = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: alignTop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0x3348B3AF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF258B85), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF60716F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemsBlank extends StatelessWidget {
  const _ItemsBlank({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 164, 28, 132),
        children: [
          Text(
            '请添加一些物品吧！',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          SvgPicture.asset(
            'assets/Empty-pana.svg',
            height: 300,
            semanticsLabel: '空物品列表',
          ),
        ],
      ),
    );
  }
}

class _ItemsGrid extends StatelessWidget {
  const _ItemsGrid({
    required this.items,
    required this.onRefresh,
    required this.onItemSelected,
  });

  final List<Item> items;
  final Future<void> Function() onRefresh;
  final ValueChanged<Item> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cellWidth =
        (screenWidth -
            _itemsGridHorizontalPadding * 2 -
            _itemsGridCrossAxisSpacing * (_itemsGridCrossAxisCount - 1)) /
        _itemsGridCrossAxisCount;
    final iconSize = (screenWidth * 0.2).clamp(0.0, cellWidth).toDouble();
    final itemMainAxisExtent =
        iconSize +
        _itemIconLabelGap +
        22 +
        6; // iconSize + vertical spacing + line height + margin/padding

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          _itemsGridHorizontalPadding,
          36,
          _itemsGridHorizontalPadding,
          100,
        ),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _itemsGridCrossAxisCount,
              crossAxisSpacing: _itemsGridCrossAxisSpacing,
              mainAxisSpacing: 12,
              mainAxisExtent: itemMainAxisExtent,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _ItemIcon(
                item: items[index],
                iconSize: iconSize,
                onTap: () => onItemSelected(items[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({
    required this.item,
    required this.iconSize,
    required this.onTap,
  });

  final Item item;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          _ItemImageFrame(item: item, size: iconSize, iconSize: 42),
          const SizedBox(height: _itemIconLabelGap),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(
                  color: Color(0x55000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemImageFrame extends StatelessWidget {
  const _ItemImageFrame({
    required this.item,
    required this.size,
    required this.iconSize,
    this.borderRadius = 16,
  });

  final Item item;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageThumbnailUrl.isNotEmpty
        ? item.imageThumbnailUrl
        : item.sourceImageUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0x66A7E399),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? Icon(
              Icons.phone_iphone_rounded,
              color: Colors.white,
              size: iconSize,
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.phone_iphone_rounded,
                  color: Colors.white,
                  size: iconSize,
                );
              },
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/smiley-nauseas.svg', height: 96),
            const SizedBox(height: 20),
            const Text('加载失败', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _AddItemSuccessBanner extends StatelessWidget {
  const _AddItemSuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: Color(0xFF36C4C3), size: 24),
          const SizedBox(width: 10),
          Text(
            '添加成功',
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
