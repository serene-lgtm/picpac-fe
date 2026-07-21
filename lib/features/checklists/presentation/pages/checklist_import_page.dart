import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../items/data/item.dart';
import '../../../items/data/item_repository.dart';
import '../../../packs/data/pack.dart';
import '../../../packs/data/pack_repository.dart';
import '../../data/checklist.dart';
import '../../data/checklist_repository.dart';
import '../widgets/checklist_common_widgets.dart';
import '../widgets/checklist_import_widgets.dart';
import '../widgets/checklist_list_widgets.dart';
import '../widgets/checklist_meta_sheet.dart';
import '../../../../shared/widgets/search_empty_state.dart';
import 'checklist_detail_page.dart';

class ChecklistImportPage extends StatefulWidget {
  const ChecklistImportPage.create({
    super.key,
    required ChecklistDraft draft,
    required this.checklistRepository,
    required this.itemRepository,
    required this.packRepository,
  }) : _draft = draft,
       checklistId = null,
       initialSelectedIds = const {};

  const ChecklistImportPage.add({
    super.key,
    required this.checklistId,
    required this.checklistRepository,
    required this.itemRepository,
    required this.packRepository,
    this.initialSelectedIds = const {},
  }) : _draft = null;

  final ChecklistDraft? _draft;
  final String? checklistId;
  final Set<String> initialSelectedIds;
  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;

  @override
  State<ChecklistImportPage> createState() => _ChecklistImportPageState();
}

class _ChecklistImportPageState extends State<ChecklistImportPage> {
  final _searchController = TextEditingController();
  final Set<String> _selectedItemIds = {};
  final Set<String> _expandedPackIds = {};
  ChecklistImportMode _mode = ChecklistImportMode.item;
  late Future<List<Item>> _itemsFuture;
  late Future<List<Pack>> _packsFuture;
  late Future<List<Item>> _allItemsFuture;
  Timer? _searchTimer;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedItemIds.addAll(widget.initialSelectedIds);
    _itemsFuture = widget.itemRepository.listItems();
    _allItemsFuture = widget.itemRepository.listItems();
    _packsFuture = widget.packRepository.listPacks();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isCreate => widget._draft != null;

  String get _title => _mode == ChecklistImportMode.item ? '选择物品' : '选择套组';

  int get _selectedCount => _selectedItemIds.length;

  bool get _canSubmit {
    if (_submitting) return false;
    if (_isCreate) return _selectedItemIds.isNotEmpty;
    return _selectedItemIds.difference(widget.initialSelectedIds).isNotEmpty;
  }

  void _search() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 260), () {
      final q = _searchController.text.trim();
      setState(() {
        if (_mode == ChecklistImportMode.item) {
          _itemsFuture = widget.itemRepository.listItems(
            q: q.isEmpty ? null : q,
          );
        } else {
          _packsFuture = widget.packRepository.listPacks(
            q: q.isEmpty ? null : q,
          );
        }
      });
    });
  }

  void _setMode(ChecklistImportMode mode) {
    if (_mode == mode) return;
    _searchController.clear();
    setState(() => _mode = mode);
    _search();
  }

  void _toggleItem(String itemId) {
    if (widget.initialSelectedIds.contains(itemId)) return;
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  void _togglePack(Pack pack) {
    setState(() {
      final editableIds = pack.items
          .where(
            (id) => id.isNotEmpty && !widget.initialSelectedIds.contains(id),
          )
          .toList(growable: false);
      final allEditableSelected =
          editableIds.isNotEmpty &&
          editableIds.every(_selectedItemIds.contains);
      if (allEditableSelected) {
        _selectedItemIds.removeAll(editableIds);
      } else {
        _selectedItemIds.addAll(editableIds);
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final newIds = _selectedItemIds.difference(widget.initialSelectedIds);
    final ids = _isCreate ? _selectedItemIds : newIds;
    final inputs = ids.map(ChecklistItemInput.item).toList(growable: false);
    try {
      final checklist = _isCreate
          ? await widget.checklistRepository.createChecklist(
              name: widget._draft!.name,
              description: widget._draft!.description,
              targetDate: widget._draft!.targetDate,
              items: inputs,
            )
          : await widget.checklistRepository.addLineItems(
              checklistId: widget.checklistId!,
              items: inputs,
            );
      if (!mounted) return;
      if (_isCreate) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => ChecklistDetailPage(
              checklist: checklist,
              checklistRepository: widget.checklistRepository,
              itemRepository: widget.itemRepository,
              packRepository: widget.packRepository,
              showSuccessBanner: true,
            ),
          ),
        );
      } else {
        Navigator.of(context).pop(checklist);
      }
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
      child: ChecklistScaffold(
        bottomBar: Container(
          width: double.infinity,
          height: 122,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          color: const Color(0xF8FFFFFF),
          child: Column(
            children: [
              Text(
                '已选中 $_selectedCount 个物品',
                style: const TextStyle(color: Colors.black, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ChecklistPillButton(
                label: _isCreate
                    ? (_submitting ? '创建中...' : '创建清单')
                    : (_submitting ? '添加中...' : '添加'),
                enabled: _canSubmit,
                expand: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
        children: [
          ChecklistTopBar(
            title: _title,
            leading: Icons.chevron_left_rounded,
            onLeadingTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              children: [
                ChecklistImportTabs(mode: _mode, onChanged: _setMode),
                const SizedBox(height: 16),
                ChecklistImportSearch(
                  controller: _searchController,
                  onChanged: _search,
                ),
                const SizedBox(height: 18),
                if (_mode == ChecklistImportMode.item)
                  _buildItems()
                else
                  _buildPacks(),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return FutureBuilder<List<Item>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Item>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 70),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError && items.isEmpty) {
          return ChecklistErrorView(
            message: snapshot.error.toString(),
            onRetry: () => setState(
              () => _itemsFuture = widget.itemRepository.listItems(),
            ),
          );
        }
        if (items.isEmpty && _searchController.text.trim().isNotEmpty) {
          return const SearchEmptyIllustration();
        }
        return Column(
          children: [
            for (final item in items) ...[
              ChecklistItemImportTile(
                item: item,
                selected: _selectedItemIds.contains(item.id),
                locked: widget.initialSelectedIds.contains(item.id),
                onTap: () => _toggleItem(item.id),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPacks() {
    return FutureBuilder<List<Object>>(
      future: Future.wait([_packsFuture, _allItemsFuture]),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final packs = data == null ? const <Pack>[] : data[0] as List<Pack>;
        final items = data == null ? const <Item>[] : data[1] as List<Item>;
        final itemsById = {for (final item in items) item.id: item};
        if (snapshot.connectionState == ConnectionState.waiting &&
            packs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 70),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError && packs.isEmpty) {
          return ChecklistErrorView(
            message: snapshot.error.toString(),
            onRetry: () => setState(
              () => _packsFuture = widget.packRepository.listPacks(),
            ),
          );
        }
        if (packs.isEmpty && _searchController.text.trim().isNotEmpty) {
          return const SearchEmptyIllustration();
        }
        return Column(
          children: [
            for (final pack in packs) ...[
              ChecklistPackImportTile(
                pack: pack,
                itemsById: itemsById,
                selectedItemIds: _selectedItemIds,
                lockedItemIds: widget.initialSelectedIds,
                expanded: _expandedPackIds.contains(pack.id),
                onTogglePack: () => _togglePack(pack),
                onToggleExpanded: () => setState(() {
                  if (_expandedPackIds.contains(pack.id)) {
                    _expandedPackIds.remove(pack.id);
                  } else {
                    _expandedPackIds.add(pack.id);
                  }
                }),
                onToggleItem: _toggleItem,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}
