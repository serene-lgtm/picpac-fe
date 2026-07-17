part of '../pages/create_pack_page.dart';

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
              color: Colors.white,
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
            'assets/common/empty.svg',
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
    required this.itemsById,
    required this.onRefresh,
    required this.onPackTap,
  });

  final List<Pack> packs;
  final Map<String, Item> itemsById;
  final Future<void> Function() onRefresh;
  final ValueChanged<Pack> onPackTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 148),
        itemCount: packs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PackCard(
              pack: packs[index],
              itemNames: _previewItemNames(packs[index], itemsById),
              onTap: () => onPackTap(packs[index]),
            ),
          );
        },
      ),
    );
  }
}

String _previewItemNames(Pack pack, Map<String, Item> itemsById) {
  final names = pack.items
      .map((id) => itemsById[id]?.name.trim())
      .whereType<String>()
      .where((name) => name.isNotEmpty)
      .take(4)
      .toList(growable: false);
  return names.join('，');
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.itemNames,
    required this.onTap,
  });

  final Pack pack;
  final String itemNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = itemNames.isEmpty ? '暂无物品' : itemNames;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 104,
        padding: const EdgeInsets.fromLTRB(22, 12, 20, 12),
        decoration: BoxDecoration(
          color: _packCardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            const _PackBoxArt(),
            const SizedBox(width: 18),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pack.items.length}件',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preview,
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
    return SvgPicture.asset(
      'assets/common/pack_tile_cover.svg',
      width: 66,
      height: 66,
      fit: BoxFit.contain,
      semanticsLabel: '套组封面',
    );
  }
}
