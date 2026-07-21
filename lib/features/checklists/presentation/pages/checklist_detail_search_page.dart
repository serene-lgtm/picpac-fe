import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../items/data/item.dart';
import '../../../items/data/item_repository.dart';
import '../../../items/presentation/widgets/item_detail_sheet.dart';
import '../../data/checklist.dart';
import '../../data/checklist_repository.dart';
import '../../../../shared/widgets/search_empty_state.dart';
import '../../../../shared/widgets/search_pill_field.dart';
import '../widgets/checklist_common_widgets.dart';
import '../widgets/checklist_detail_widgets.dart';

class ChecklistDetailSearchPage extends StatefulWidget {
  const ChecklistDetailSearchPage({
    super.key,
    required this.checklist,
    required this.itemsById,
    required this.checklistRepository,
    required this.itemRepository,
  });

  final Checklist checklist;
  final Map<String, Item> itemsById;
  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;

  @override
  State<ChecklistDetailSearchPage> createState() =>
      _ChecklistDetailSearchPageState();
}

class _ChecklistDetailSearchPageState extends State<ChecklistDetailSearchPage> {
  final _controller = TextEditingController();
  late Checklist _checklist;
  late Map<String, Item> _itemsById;
  final Set<String> _updatingIds = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _checklist = widget.checklist;
    _itemsById = widget.itemsById;
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    _loadItemsIfNeeded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadItemsIfNeeded() async {
    if (_itemsById.isNotEmpty) return;
    final items = await widget.itemRepository.listItems();
    if (!mounted) return;
    setState(() => _itemsById = {for (final item in items) item.id: item});
  }

  void _search(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  void _close() {
    Navigator.of(context).pop(_checklist);
  }

  bool _matches(ChecklistLineItem line) {
    if (_query.isEmpty) return true;
    final item = _itemsById[line.referenceId];
    final name = item?.name ?? line.snapshotName;
    final description = item?.description ?? '';
    return name.toLowerCase().contains(_query) ||
        description.toLowerCase().contains(_query);
  }

  List<ChecklistLineItem> get _visibleLines {
    final unchecked = _checklist.items.where((line) => !line.checked);
    final checked = _checklist.items.where((line) => line.checked);
    return [...unchecked, ...checked].where(_matches).toList(growable: false);
  }

  Future<void> _toggleLine(ChecklistLineItem line) async {
    if (_updatingIds.contains(line.id)) return;
    setState(() => _updatingIds.add(line.id));
    try {
      final updated = await widget.checklistRepository.updateLineItemStatus(
        checklistId: _checklist.id,
        lineItemId: line.id,
        status: line.checked ? 'unchecked' : 'checked',
      );
      if (!mounted) return;
      setState(() {
        _checklist = updated;
        _updatingIds.remove(line.id);
      });
    } finally {
      if (mounted) setState(() => _updatingIds.remove(line.id));
    }
  }

  Future<void> _openItem(ChecklistLineItem line) async {
    if (line.referenceType != 'item') return;
    final item = _itemsById[line.referenceId];
    if (item == null) return;
    await showItemDetailSheet(
      context: context,
      item: item,
      itemRepository: widget.itemRepository,
    );
    if (!mounted) return;
    final items = await widget.itemRepository.listItems();
    if (mounted) {
      setState(() => _itemsById = {for (final item in items) item.id: item});
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = _visibleLines;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ChecklistScaffold(
        children: [
          ChecklistTopBar(
            title: '搜索物品',
            leading: Icons.chevron_left_rounded,
            onLeadingTap: _close,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 24, 30, 22),
            child: SearchPillField(
              controller: _controller,
              autofocus: true,
              hintText: '搜索',
              onChanged: _search,
              onClear: () {
                _controller.clear();
                _search('');
              },
            ),
          ),
          Expanded(
            child: lines.isEmpty && _query.isNotEmpty
                ? const SearchEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
                    children: [
                      for (final line in lines) ...[
                        ChecklistLineCard(
                          line: line,
                          item: _itemsById[line.referenceId],
                          updating: _updatingIds.contains(line.id),
                          removeMode: false,
                          removeSelected: false,
                          onTap: () => _openItem(line),
                          onToggle: () => _toggleLine(line),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
