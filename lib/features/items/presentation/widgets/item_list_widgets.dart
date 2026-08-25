import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/module_top_bar.dart';
import '../../data/item.dart';
import 'item_shared_widgets.dart';

class ItemsHeader extends StatelessWidget {
  const ItemsHeader({super.key, required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ModuleTopBar(
      title: '我的物品',
      trailing: Icons.search_rounded,
      onTrailingTap: onSearch,
    );
  }
}

class ItemCategoryTabs extends StatelessWidget {
  const ItemCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.padding = const EdgeInsets.fromLTRB(18, 12, 18, 0),
  });

  final List<ItemCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox(height: 8);
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedCategoryId;
          return _ItemCategoryTab(
            key: ValueKey('item-category-tab-${category.id}'),
            label: category.name,
            selected: selected,
            onTap: () => onSelected(selected ? null : category.id),
          );
        },
      ),
    );
  }
}

class _ItemCategoryTab extends StatelessWidget {
  const _ItemCategoryTab({
    super.key,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 17),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 1 : 0.22),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? const Color(0xFF3DB7B5) : Colors.black54,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
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
            padding: const EdgeInsets.fromLTRB(24, 16, 22, 112),
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
            top: 70,
            right: 4,
            bottom: 86,
            child: IgnorePointer(
              child: FittedBox(fit: BoxFit.scaleDown, child: AlphabetIndex()),
            ),
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
    return AppItemTile(
      item: item,
      title: item.name,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
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
