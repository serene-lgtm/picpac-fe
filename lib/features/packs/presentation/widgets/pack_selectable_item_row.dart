part of '../pages/create_pack_page.dart';

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
    return AppItemTile(
      item: item,
      title: item.name,
      description: item.description,
      onTap: onTap,
      disabled: disabled,
      backgroundColor: _packCardColor,
      border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      borderRadius: 6,
      padding: const EdgeInsets.fromLTRB(20, 6, 14, 6),
      trailing: ItemSelectionCircle(selected: selected, locked: disabled),
    );
  }
}
