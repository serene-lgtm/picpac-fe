import 'package:flutter/material.dart';

import '../../../items/data/item.dart';
import '../../../packs/data/pack.dart';
import '../../../../shared/widgets/search_pill_field.dart';
import 'checklist_theme.dart';

enum ChecklistImportMode { item, pack }

class ChecklistImportTabs extends StatelessWidget {
  const ChecklistImportTabs({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ChecklistImportMode mode;
  final ValueChanged<ChecklistImportMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xEEF7F7FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _tab('从物品导入', ChecklistImportMode.item),
          _tab('从套组导入', ChecklistImportMode.pack),
        ],
      ),
    );
  }

  Widget _tab(String label, ChecklistImportMode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : const Color(0xFF9AA0A8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class ChecklistImportSearch extends StatefulWidget {
  const ChecklistImportSearch({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  State<ChecklistImportSearch> createState() => _ChecklistImportSearchState();
}

class _ChecklistImportSearchState extends State<ChecklistImportSearch> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant ChecklistImportSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_sync);
    widget.controller.addListener(_sync);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SearchPillField(
      controller: widget.controller,
      hintText: '搜索',
      onChanged: (_) => widget.onChanged(),
      onClear: () {
        widget.controller.clear();
        widget.onChanged();
      },
    );
  }
}

class ChecklistItemImportTile extends StatelessWidget {
  const ChecklistItemImportTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final Item item;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return _ImportCard(
      leading: Image.asset(checklistGiftAsset, width: 48, height: 48),
      title: item.name,
      selected: selected,
      locked: locked,
      onTap: onTap,
    );
  }
}

class ChecklistPackImportTile extends StatelessWidget {
  const ChecklistPackImportTile({
    super.key,
    required this.pack,
    required this.itemsById,
    required this.selectedItemIds,
    required this.lockedItemIds,
    required this.expanded,
    required this.onTogglePack,
    required this.onToggleExpanded,
    required this.onToggleItem,
  });

  final Pack pack;
  final Map<String, Item> itemsById;
  final Set<String> selectedItemIds;
  final Set<String> lockedItemIds;
  final bool expanded;
  final VoidCallback onTogglePack;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onToggleItem;

  bool get _allSelected {
    if (pack.items.isEmpty) return false;
    return pack.items.every(selectedItemIds.contains);
  }

  bool get _allLocked {
    if (pack.items.isEmpty) return false;
    return pack.items.every(lockedItemIds.contains);
  }

  @override
  Widget build(BuildContext context) {
    final names = pack.items
        .map((id) => itemsById[id]?.name)
        .whereType<String>()
        .take(3)
        .join('、');
    return Material(
      color: checklistCardColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 104,
            child: Row(
              children: [
                const SizedBox(width: 16),
                _SelectionCircle(
                  selected: _allSelected,
                  locked: _allLocked,
                  onTap: onTogglePack,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: InkWell(
                    onTap: onToggleExpanded,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pack.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${pack.items.length}件',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          names.isEmpty ? pack.description : names,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.chevron_right_rounded,
                  ),
                ),
              ],
            ),
          ),
          if (expanded)
            ...pack.items.map((itemId) {
              final item = itemsById[itemId];
              return _ExpandedItemRow(
                name: item?.name ?? itemId,
                selected: selectedItemIds.contains(itemId),
                locked: lockedItemIds.contains(itemId),
                onTap: () => onToggleItem(itemId),
              );
            }),
        ],
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  const _ImportCard({
    required this.leading,
    required this.title,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final Widget leading;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checklistCardColor,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              const SizedBox(width: 14),
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _SelectionCircle(
                selected: selected,
                locked: locked,
                onTap: onTap,
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedItemRow extends StatelessWidget {
  const _ExpandedItemRow({
    required this.name,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: locked ? null : onTap,
      child: Container(
        height: 58,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x19000000))),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Image.asset(checklistGiftAsset, width: 42, height: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _SelectionCircle(selected: selected, locked: locked, onTap: onTap),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: CircleAvatar(
        radius: 11,
        backgroundColor: selected
            ? locked
                  ? const Color(0xFFB8C6C5)
                  : checklistPrimary
            : Colors.transparent,
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC7CDD2)),
                ),
              ),
      ),
    );
  }
}
