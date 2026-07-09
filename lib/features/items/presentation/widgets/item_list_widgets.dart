import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/item.dart';
import 'item_shared_widgets.dart';

class ItemsHeader extends StatelessWidget {
  const ItemsHeader({super.key, required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                '我的物品',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.zero,
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded, color: Colors.black),
              iconSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class ItemsBlank extends StatelessWidget {
  const ItemsBlank({super.key, required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 100, 28, 132),
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
            'assets/common/empty.svg',
            height: 300,
            semanticsLabel: '空物品列表',
          ),
        ],
      ),
    );
  }
}

class ItemsList extends StatelessWidget {
  const ItemsList({
    super.key,
    required this.items,
    required this.onRefresh,
    required this.onItemSelected,
  });

  final List<Item> items;
  final Future<void> Function() onRefresh;
  final ValueChanged<Item> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Stack(
        children: [
          ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 22, 112),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return ItemListTile(
                item: items[index],
                onTap: () => onItemSelected(items[index]),
              );
            },
          ),
          const Positioned(
            top: 46,
            right: 4,
            bottom: 86,
            child: IgnorePointer(child: AlphabetIndex()),
          ),
        ],
      ),
    );
  }
}

class ItemListTile extends StatelessWidget {
  const ItemListTile({super.key, required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        decoration: BoxDecoration(
          color: const Color(0xCDEAF7F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ItemImageFrame(item: item, size: 50, iconSize: 56, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlphabetIndex extends StatelessWidget {
  const AlphabetIndex({super.key});

  static const _letters = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final letter in _letters)
          Text(
            letter,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.black.withValues(alpha: 0.72),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
