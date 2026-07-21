import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../items/data/item.dart';
import '../../../items/data/item_repository.dart';
import '../../../items/presentation/widgets/item_detail_sheet.dart';
import '../../../packs/data/pack_repository.dart';
import '../../data/checklist.dart';
import '../../data/checklist_repository.dart';
import '../widgets/checklist_common_widgets.dart';
import '../widgets/checklist_detail_widgets.dart';
import '../widgets/checklist_list_widgets.dart';
import '../widgets/checklist_meta_sheet.dart';
import 'checklist_detail_search_page.dart';
import 'checklist_import_page.dart';

class ChecklistDetailPage extends StatefulWidget {
  const ChecklistDetailPage({
    super.key,
    required this.checklist,
    required this.checklistRepository,
    required this.itemRepository,
    required this.packRepository,
    this.showSuccessBanner = false,
  });

  final Checklist checklist;
  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;
  final bool showSuccessBanner;

  @override
  State<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends State<ChecklistDetailPage> {
  late Checklist _checklist;
  late Future<Checklist> _checklistFuture;
  Map<String, Item> _itemsById = const {};
  final Set<String> _updatingIds = {};
  final Set<String> _removeIds = {};
  bool _removeMode = false;
  bool _savingMetadata = false;
  bool _showSuccessBanner = false;
  String _successMessage = '添加成功';
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _checklist = widget.checklist;
    _checklistFuture = _load();
    if (widget.showSuccessBanner) _showSuccess();
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  Future<Checklist> _load() async {
    final checklist = await widget.checklistRepository.getChecklist(
      widget.checklist.id,
    );
    final items = await widget.itemRepository.listItems();
    if (mounted) {
      setState(() {
        _checklist = checklist;
        _itemsById = {for (final item in items) item.id: item};
      });
    }
    return checklist;
  }

  void _showSuccess([String message = '添加成功']) {
    _successTimer?.cancel();
    setState(() {
      _successMessage = message;
      _showSuccessBanner = true;
    });
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSuccessBanner = false);
    });
  }

  Future<void> _toggleLine(ChecklistLineItem line) async {
    if (_removeMode || _updatingIds.contains(line.id)) return;
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
        _checklistFuture = Future.value(updated);
        _updatingIds.remove(line.id);
      });
    } finally {
      if (mounted) setState(() => _updatingIds.remove(line.id));
    }
  }

  void _toggleRemoveLine(ChecklistLineItem line) {
    if (!_removeMode) {
      _toggleLine(line);
      return;
    }
    setState(() {
      if (_removeIds.contains(line.id)) {
        _removeIds.remove(line.id);
      } else {
        _removeIds.add(line.id);
      }
    });
  }

  Future<void> _openSearch() async {
    final updated = await Navigator.of(context).push<Checklist>(
      MaterialPageRoute<Checklist>(
        builder: (_) => ChecklistDetailSearchPage(
          checklist: _checklist,
          itemsById: _itemsById,
          checklistRepository: widget.checklistRepository,
          itemRepository: widget.itemRepository,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _checklist = updated;
      _checklistFuture = Future.value(updated);
    });
  }

  Future<void> _openItem(ChecklistLineItem line) async {
    if (_removeMode) {
      setState(() {
        if (_removeIds.contains(line.id)) {
          _removeIds.remove(line.id);
        } else {
          _removeIds.add(line.id);
        }
      });
      return;
    }
    if (line.referenceType != 'item') return;
    final item = _itemsById[line.referenceId];
    if (item == null) return;
    await showItemDetailSheet(
      context: context,
      item: item,
      itemRepository: widget.itemRepository,
    );
    if (mounted) _checklistFuture = _load();
  }

  Future<void> _addItems() async {
    final currentIds = _checklist.items
        .where((line) => line.referenceType == 'item')
        .map((line) => line.referenceId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final result = await Navigator.of(context).push<Checklist>(
      MaterialPageRoute<Checklist>(
        builder: (context) => ChecklistImportPage.add(
          checklistId: _checklist.id,
          checklistRepository: widget.checklistRepository,
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
          initialSelectedIds: currentIds,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _checklist = result;
      _checklistFuture = Future.value(result);
    });
    _showSuccess();
  }

  Future<void> _removeSelected() async {
    if (!_removeMode) {
      setState(() => _removeMode = true);
      return;
    }
    if (_removeIds.isEmpty) {
      setState(() => _removeMode = false);
      return;
    }
    final shouldRemove = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (_) =>
          const DeleteChecklistDialog(title: '确认移除选中物品吗？', confirmLabel: '移除'),
    );
    if (shouldRemove != true) return;
    final updated = await widget.checklistRepository.removeLineItems(
      checklistId: _checklist.id,
      lineItemIds: _removeIds.toList(growable: false),
    );
    if (!mounted) return;
    setState(() {
      _checklist = updated;
      _checklistFuture = Future.value(updated);
      _removeMode = false;
      _removeIds.clear();
    });
    _showSuccess('移除成功');
  }

  void _openMoreActions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (_) => ChecklistMoreActionsSheet(
        onEdit: () {
          Navigator.of(context).pop();
          _openEditSheet();
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDelete();
        },
      ),
    );
  }

  void _openEditSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => ChecklistMetaSheet(
        title: '编辑清单',
        submitLabel: '保存',
        saving: _savingMetadata,
        initialDraft: ChecklistDraft(
          name: _checklist.name,
          targetDate: _checklist.targetDate,
          description: _checklist.description,
        ),
        onSubmit: _updateMetadata,
      ),
    );
  }

  Future<void> _updateMetadata(ChecklistDraft draft) async {
    if (_savingMetadata) return;
    setState(() => _savingMetadata = true);
    try {
      final updated = await widget.checklistRepository.updateChecklist(
        checklistId: _checklist.id,
        name: draft.name,
        targetDate: draft.targetDate,
        description: draft.description,
      );
      if (!mounted) return;
      setState(() {
        _checklist = updated;
        _checklistFuture = Future.value(updated);
        _savingMetadata = false;
      });
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _savingMetadata = false);
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (_) => const DeleteChecklistDialog(),
    );
    if (shouldDelete != true) return;
    await widget.checklistRepository.deleteChecklist(_checklist.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final unchecked = _checklist.items.where((line) => !line.checked);
    final checkedLines = _checklist.items.where((line) => line.checked);
    final lines = [...unchecked, ...checkedLines];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ChecklistScaffold(
        bottomBar: ChecklistBottomActionBar(
          leftLabel: _removeMode ? '取消' : '添加',
          rightLabel: _removeMode ? '确认' : '移除',
          onLeft: _removeMode
              ? () => setState(() {
                  _removeMode = false;
                  _removeIds.clear();
                })
              : _addItems,
          onRight: _removeSelected,
        ),
        floating: Center(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showSuccessBanner ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: ChecklistSuccessToast(message: _successMessage),
            ),
          ),
        ),
        children: [
          ChecklistTopBar(
            title: _checklist.name,
            leading: Icons.chevron_left_rounded,
            trailing: Icons.more_horiz_rounded,
            onLeadingTap: () => Navigator.of(context).pop(),
            onTrailingTap: _openMoreActions,
          ),
          Expanded(
            child: FutureBuilder<Checklist>(
              future: _checklistFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError && _checklist.items.isEmpty) {
                  return ChecklistErrorView(
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() => _checklistFuture = _load()),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(30, 16, 30, 108),
                  children: [
                    const SizedBox(height: 8),
                    ChecklistDetailMeta(
                      checklist: _checklist,
                      checked: checkedLines.length,
                    ),
                    ChecklistDetailSectionTitle(onSearch: _openSearch),
                    for (final line in lines) ...[
                      ChecklistLineCard(
                        line: line,
                        item: _itemsById[line.referenceId],
                        updating: _updatingIds.contains(line.id),
                        removeMode: _removeMode,
                        removeSelected: _removeIds.contains(line.id),
                        onTap: () => _openItem(line),
                        onToggle: () => _toggleRemoveLine(line),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
