import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../items/data/item.dart';
import '../../../items/data/item_repository.dart';
import '../../../packs/data/pack.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/presentation/pages/create_pack_page.dart';
import '../../data/checklist.dart';
import '../../data/checklist_repository.dart';
import '../../../../shared/navigation/no_animation_route.dart';
import '../../../../shared/widgets/bottom_nav.dart';

const _checklistGradientColors = [Color(0xFF71D0C6), Color(0xFFC8EFC1)];

class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({
    super.key,
    required this.checklistRepository,
    required this.itemRepository,
    required this.packRepository,
  });

  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;

  @override
  State<ChecklistsPage> createState() => _ChecklistsPageState();
}

class _ChecklistsPageState extends State<ChecklistsPage> {
  late Future<List<Checklist>> _checklistsFuture;

  @override
  void initState() {
    super.initState();
    _checklistsFuture = widget.checklistRepository.listChecklists();
  }

  Future<void> _refresh() async {
    final future = widget.checklistRepository.listChecklists();
    setState(() => _checklistsFuture = future);
    await future;
  }

  void _openCreateSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) {
        return _ChecklistMetaSheet(
          onNext: (draft) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => _ChecklistImportPage(
                  draft: draft,
                  checklistRepository: widget.checklistRepository,
                  itemRepository: widget.itemRepository,
                  packRepository: widget.packRepository,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleTabSelected(BottomTab tab) {
    if (tab == BottomTab.checklist) return;
    if (tab == BottomTab.item) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    if (tab == BottomTab.pack) {
      Navigator.of(context).pushReplacement(
        noAnimationRoute<void>(
          (context) => PacksPage(
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
            FutureBuilder<List<Checklist>>(
              future: _checklistsFuture,
              builder: (context, snapshot) {
                final checklists = snapshot.data ?? const <Checklist>[];
                return Column(
                  children: [
                    _ChecklistTopBar(
                      title: '我的清单',
                      trailing: Icons.search_rounded,
                      onTrailingTap: () {},
                    ),
                    Expanded(
                      child:
                          snapshot.connectionState == ConnectionState.waiting &&
                              checklists.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : snapshot.hasError && checklists.isEmpty
                          ? _ChecklistError(
                              message: snapshot.error.toString(),
                              onRetry: _refresh,
                            )
                          : checklists.isEmpty
                          ? const _ChecklistEmptyState()
                          : _ChecklistList(
                              checklists: checklists,
                              onRefresh: _refresh,
                              onTap: (checklist) {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            ChecklistDetailPage(
                                              checklist: checklist,
                                              checklistRepository:
                                                  widget.checklistRepository,
                                              itemRepository:
                                                  widget.itemRepository,
                                            ),
                                      ),
                                    )
                                    .then((_) {
                                      if (!context.mounted) return;
                                      _refresh();
                                    });
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              right: 38,
              bottom: 78,
              child: SizedBox.square(
                dimension: 52,
                child: FilledButton(
                  onPressed: _openCreateSheet,
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
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: BottomNav(
                  currentTab: BottomTab.checklist,
                  onTabSelected: _handleTabSelected,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistTopBar extends StatelessWidget {
  const _ChecklistTopBar({
    required this.title,
    this.leading,
    this.trailing,
    this.onLeadingTap,
    this.onTrailingTap,
  });

  final String title;
  final IconData? leading;
  final IconData? trailing;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _checklistGradientColors,
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
                    icon: Icon(leading, color: Colors.black, size: 28),
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
            if (trailing != null)
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

class _ChecklistEmptyState extends StatelessWidget {
  const _ChecklistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 178,
          child: Text(
            '是时候罗列一些清单咯',
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
            semanticsLabel: '空清单插画',
          ),
        ),
      ],
    );
  }
}

class _ChecklistList extends StatelessWidget {
  const _ChecklistList({
    required this.checklists,
    required this.onRefresh,
    required this.onTap,
  });

  final List<Checklist> checklists;
  final Future<void> Function() onRefresh;
  final ValueChanged<Checklist> onTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 148),
        itemCount: checklists.length,
        itemBuilder: (context, index) {
          final checklist = checklists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ChecklistCard(
              checklist: checklist,
              onTap: () => onTap(checklist),
            ),
          );
        },
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.checklist, required this.onTap});

  final Checklist checklist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = checklist.items.length;
    final checked = checklist.items.where((item) => item.checked).length;
    final progress = total == 0 ? 0.0 : checked / total;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 160,
        padding: const EdgeInsets.fromLTRB(24, 28, 16, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FB9B1), Color(0xFFA9E99C)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -2,
              top: 12,
              bottom: 10,
              child: Image.asset(
                'assets/checklist_tile_deco.png',
                width: 118,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              width: 190,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checklist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    checklist.targetDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '已完成 $checked/$total 项',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  const Spacer(),
                  _ChecklistProgressBar(progress: progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistProgressBar extends StatelessWidget {
  const _ChecklistProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: 160,
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF332956)),
            FractionallySizedBox(
              widthFactor: clamped,
              alignment: Alignment.centerLeft,
              child: const ColoredBox(color: Color(0xFF18C9BF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistDraft {
  const _ChecklistDraft({
    required this.name,
    required this.targetDate,
    this.description = '',
  });

  final String name;
  final String targetDate;
  final String description;
}

class _ChecklistMetaSheet extends StatefulWidget {
  const _ChecklistMetaSheet({required this.onNext});

  final ValueChanged<_ChecklistDraft> onNext;

  @override
  State<_ChecklistMetaSheet> createState() => _ChecklistMetaSheetState();
}

class _ChecklistMetaSheetState extends State<_ChecklistMetaSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _targetDate;
  bool _touched = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _targetDateText {
    final date = _targetDate;
    if (date == null) return '';
    return _formatDate(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _targetDate = picked);
  }

  void _next() {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    final targetDate = _targetDateText;
    if (name.isEmpty || targetDate.isEmpty) return;
    widget.onNext(
      _ChecklistDraft(
        name: name,
        targetDate: targetDate,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missingName = _touched && _nameController.text.trim().isEmpty;
    final missingDate = _touched && _targetDateText.isEmpty;
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
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 36),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '新增清单',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F2F7),
                        foregroundColor: Colors.black87,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SheetLabel(text: '名称', required: true),
                const SizedBox(height: 8),
                _SheetTextField(
                  controller: _nameController,
                  hintText: '输入名称...',
                  error: missingName,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _SheetLabel(text: '日期', required: true),
                const SizedBox(height: 8),
                _SheetTapField(
                  text: _targetDateText,
                  hintText: '选择日期',
                  error: missingDate,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                const _SheetLabel(text: '描述（选填）'),
                const SizedBox(height: 8),
                _SheetTextField(
                  controller: _descriptionController,
                  hintText: '添加描述...',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 44,
                    child: FilledButton(
                      onPressed: _next,
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
      ),
    );
  }
}

class _ChecklistImportPage extends StatefulWidget {
  const _ChecklistImportPage({
    required this.draft,
    required this.checklistRepository,
    required this.itemRepository,
    required this.packRepository,
  });

  final _ChecklistDraft draft;
  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;

  @override
  State<_ChecklistImportPage> createState() => _ChecklistImportPageState();
}

enum _ChecklistImportMode { item, pack }

class _ChecklistImportPageState extends State<_ChecklistImportPage> {
  final _searchController = TextEditingController();
  _ChecklistImportMode _mode = _ChecklistImportMode.item;
  late Future<List<Item>> _itemsFuture;
  late Future<List<Pack>> _packsFuture;
  final Map<String, Item> _selectedItems = {};
  final Map<String, Pack> _selectedPacks = {};
  Timer? _searchTimer;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.itemRepository.listItems();
    _packsFuture = widget.packRepository.listPacks();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 260), () {
      final q = _searchController.text.trim();
      setState(() {
        if (_mode == _ChecklistImportMode.item) {
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

  void _setMode(_ChecklistImportMode mode) {
    if (_mode == mode) return;
    _searchController.clear();
    setState(() => _mode = mode);
  }

  int get _selectedItemCount {
    final itemIds = <String>{..._selectedItems.keys};
    for (final pack in _selectedPacks.values) {
      itemIds.addAll(pack.items);
    }
    return itemIds.length;
  }

  Future<void> _createChecklist() async {
    if (_submitting || _selectedItemCount == 0) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final itemIds = <String>{..._selectedItems.keys};
    for (final pack in _selectedPacks.values) {
      itemIds.addAll(pack.items);
    }
    final inputs = itemIds.map(ChecklistItemInput.item).toList(growable: false);
    try {
      final checklist = await widget.checklistRepository.createChecklist(
        name: widget.draft.name,
        description: widget.draft.description,
        targetDate: widget.draft.targetDate,
        items: inputs,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => ChecklistDetailPage(
            checklist: checklist,
            checklistRepository: widget.checklistRepository,
            itemRepository: widget.itemRepository,
            showSuccessBanner: true,
          ),
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
            _ChecklistTopBar(
              title: '导入物品',
              leading: Icons.chevron_left_rounded,
              onLeadingTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
                children: [
                  _ChecklistImportTabs(mode: _mode, onChanged: _setMode),
                  const SizedBox(height: 20),
                  _ChecklistSearchField(
                    controller: _searchController,
                    onChanged: _search,
                  ),
                  const SizedBox(height: 20),
                  _mode == _ChecklistImportMode.item
                      ? _buildItemsList()
                      : _buildPacksList(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
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
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE7E7EC))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '已选 $_selectedItemCount 项（${_selectedItems.length} 件物品，${_selectedPacks.length} 个套组）',
                      style: const TextStyle(
                        color: Color(0xFF8C949A),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton(
                        onPressed: _selectedItemCount == 0 || _submitting
                            ? null
                            : _createChecklist,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF48B8B4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          _submitting ? '创建中...' : '添加并创建清单',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return FutureBuilder<List<Item>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Item>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError && items.isEmpty) {
          return _ChecklistError(
            message: snapshot.error.toString(),
            onRetry: () => setState(
              () => _itemsFuture = widget.itemRepository.listItems(),
            ),
          );
        }
        return Column(
          children: items
              .map((item) {
                final selected = _selectedItems.containsKey(item.id);
                return _ImportItemRow(
                  title: item.name,
                  subtitle: item.description.isEmpty ? '证件' : item.description,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedItems.remove(item.id);
                      } else {
                        _selectedItems[item.id] = item;
                      }
                    });
                  },
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildPacksList() {
    return FutureBuilder<List<Pack>>(
      future: _packsFuture,
      builder: (context, snapshot) {
        final packs = snapshot.data ?? const <Pack>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            packs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 80),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError && packs.isEmpty) {
          return _ChecklistError(
            message: snapshot.error.toString(),
            onRetry: () => setState(
              () => _packsFuture = widget.packRepository.listPacks(),
            ),
          );
        }
        return Column(
          children: packs
              .map((pack) {
                final selected = _selectedPacks.containsKey(pack.id);
                return _ImportItemRow(
                  title: pack.name,
                  titleSuffix: '${pack.items.length}件',
                  subtitle: pack.description.isEmpty ? '套组' : pack.description,
                  selected: selected,
                  onMoreTap: () => _openPackItemsSheet(pack),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedPacks.remove(pack.id);
                      } else {
                        _selectedPacks[pack.id] = pack;
                      }
                    });
                  },
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  void _openPackItemsSheet(Pack pack) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) {
        return _PackItemsPreviewSheet(
          pack: pack,
          itemsFuture: widget.itemRepository.listItems(),
        );
      },
    );
  }
}

class _PackItemsPreviewSheet extends StatelessWidget {
  const _PackItemsPreviewSheet({required this.pack, required this.itemsFuture});

  final Pack pack;
  final Future<List<Item>> itemsFuture;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pack.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '共 ${pack.items.length} 件物品',
                style: const TextStyle(color: Color(0xFF9DA4AA), fontSize: 13),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: FutureBuilder<List<Item>>(
                  future: itemsFuture,
                  builder: (context, snapshot) {
                    final itemsById = {
                      for (final item in snapshot.data ?? const <Item>[])
                        item.id: item,
                    };
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        itemsById.isEmpty) {
                      return const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (pack.items.isEmpty) {
                      return const SizedBox(
                        height: 96,
                        child: Center(
                          child: Text(
                            '这个套组里还没有物品',
                            style: TextStyle(color: Color(0xFF9DA4AA)),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: pack.items.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, index) {
                        final itemId = pack.items[index];
                        final item = itemsById[itemId];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item?.name ?? itemId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: item != null && item.description.isNotEmpty
                              ? Text(
                                  item.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChecklistDetailPage extends StatefulWidget {
  const ChecklistDetailPage({
    super.key,
    required this.checklist,
    required this.checklistRepository,
    required this.itemRepository,
    this.showSuccessBanner = false,
  });

  final Checklist checklist;
  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final bool showSuccessBanner;

  @override
  State<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends State<ChecklistDetailPage> {
  late Checklist _checklist;
  late Future<Checklist> _checklistFuture;
  Map<String, Item> _itemsById = const {};
  bool _showSuccessBanner = false;
  bool _updatingMetadata = false;
  final Set<String> _updatingLineItemIds = {};
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _checklist = widget.checklist;
    _checklistFuture = _loadChecklist();
    if (widget.showSuccessBanner) {
      _showSuccessBanner = true;
      _successTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _showSuccessBanner = false);
      });
    }
  }

  Future<Checklist> _loadChecklist() async {
    final checklist = await widget.checklistRepository.getChecklist(
      widget.checklist.id,
    );
    final items = await widget.itemRepository.listItems();
    final itemsById = {for (final item in items) item.id: item};
    if (mounted) {
      setState(() {
        _checklist = checklist;
        _itemsById = itemsById;
      });
    } else {
      _checklist = checklist;
      _itemsById = itemsById;
    }
    return checklist;
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
        return _ChecklistMoreActionsSheet(
          onEdit: () {
            Navigator.of(context).pop();
            _openEditMetadataSheet();
          },
        );
      },
    );
  }

  void _openEditMetadataSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) {
        return _EditChecklistMetadataSheet(
          initialName: _checklist.name,
          initialDescription: _checklist.description,
          initialTargetDate: _checklist.targetDate,
          saving: _updatingMetadata,
          onSave: _updateMetadata,
        );
      },
    );
  }

  Future<void> _updateMetadata(_ChecklistDraft draft) async {
    if (_updatingMetadata) return;
    setState(() => _updatingMetadata = true);
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
        _updatingMetadata = false;
      });
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingMetadata = false);
    }
  }

  Future<void> _toggleLineItem(ChecklistLineItem lineItem) async {
    if (_updatingLineItemIds.contains(lineItem.id)) return;
    final nextStatus = lineItem.checked ? 'unchecked' : 'checked';
    setState(() => _updatingLineItemIds.add(lineItem.id));
    try {
      final updated = await widget.checklistRepository.updateLineItemStatus(
        checklistId: _checklist.id,
        lineItemId: lineItem.id,
        status: nextStatus,
      );
      if (!mounted) return;
      setState(() {
        _checklist = updated;
        _checklistFuture = Future.value(updated);
        _updatingLineItemIds.remove(lineItem.id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingLineItemIds.remove(lineItem.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final checked = _checklist.items.where((item) => item.checked).length;
    final total = _checklist.items.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                _ChecklistTopBar(
                  title: '',
                  leading: Icons.chevron_left_rounded,
                  onLeadingTap: () => Navigator.of(context).pop(),
                  trailing: Icons.more_horiz,
                  onTrailingTap: _openMoreActions,
                ),
                Expanded(
                  child: FutureBuilder<Checklist>(
                    future: _checklistFuture,
                    builder: (context, snapshot) {
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(30, 18, 30, 40),
                        children: [
                          Text(
                            _checklist.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Color(0xFF9DA4AA),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _checklist.targetDate,
                                style: const TextStyle(
                                  color: Color(0xFF9DA4AA),
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.playlist_add_check_rounded,
                                size: 18,
                                color: Color(0xFF9DA4AA),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '已完成 $checked/$total 项',
                                style: const TextStyle(
                                  color: Color(0xFF9DA4AA),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (_checklist.description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              _checklist.description,
                              style: const TextStyle(
                                color: Color(0xFF9DA4AA),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          const Row(
                            children: [
                              Text(
                                '装备清单',
                                style: TextStyle(
                                  color: Color(0xFFB4BDC3),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.search_rounded,
                                color: Color(0xFFB4BDC3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ..._checklist.items.map(_buildLineItem),
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
              left: 44,
              right: 44,
              bottom: 36,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showSuccessBanner ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const _ChecklistSuccessBanner(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItem(ChecklistLineItem lineItem) {
    final item = lineItem.referenceType == 'item'
        ? _itemsById[lineItem.referenceId]
        : null;
    final name =
        item?.name ??
        (lineItem.snapshotName.isEmpty ? '物品' : lineItem.snapshotName);
    final description = item?.description ?? '';
    final imageUrl = item?.imageThumbnailUrl.isNotEmpty == true
        ? item!.imageThumbnailUrl
        : item?.sourceImageUrl ?? '';
    final checked = lineItem.checked;
    final updating = _updatingLineItemIds.contains(lineItem.id);
    return InkWell(
      onTap: updating ? null : () => _toggleLineItem(lineItem),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: checked
                    ? const Color(0xFF48B8B4)
                    : Colors.white,
                child: updating
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : checked
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC7CDD2)),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: checked
                            ? const Color(0xFFB7C0C5)
                            : const Color(0xFF2B2B2B),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB7C0C5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (imageUrl.isNotEmpty) ...[
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(width: 44, height: 44);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistMoreActionsSheet extends StatelessWidget {
  const _ChecklistMoreActionsSheet({required this.onEdit});

  final VoidCallback onEdit;

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
                onPressed: onEdit,
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text(
                  '修改清单信息',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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

class _EditChecklistMetadataSheet extends StatefulWidget {
  const _EditChecklistMetadataSheet({
    required this.initialName,
    required this.initialDescription,
    required this.initialTargetDate,
    required this.saving,
    required this.onSave,
  });

  final String initialName;
  final String initialDescription;
  final String initialTargetDate;
  final bool saving;
  final ValueChanged<_ChecklistDraft> onSave;

  @override
  State<_EditChecklistMetadataSheet> createState() =>
      _EditChecklistMetadataSheetState();
}

class _EditChecklistMetadataSheetState
    extends State<_EditChecklistMetadataSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime? _targetDate;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _targetDate = DateTime.tryParse(widget.initialTargetDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _targetDateText {
    final date = _targetDate;
    if (date == null) return widget.initialTargetDate;
    return _formatDate(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _targetDate = picked);
  }

  void _save() {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    final targetDate = _targetDateText.trim();
    if (name.isEmpty || targetDate.isEmpty || widget.saving) return;
    widget.onSave(
      _ChecklistDraft(
        name: name,
        targetDate: targetDate,
        description: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missingName = _touched && _nameController.text.trim().isEmpty;
    final missingDate = _touched && _targetDateText.trim().isEmpty;
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
                      '修改清单信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SheetLabel(text: '名称', required: true),
                const SizedBox(height: 8),
                _SheetTextField(
                  controller: _nameController,
                  hintText: '输入名称...',
                  error: missingName,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _SheetLabel(text: '日期', required: true),
                const SizedBox(height: 8),
                _SheetTapField(
                  text: _targetDateText,
                  hintText: '选择日期',
                  error: missingDate,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                const _SheetLabel(text: '描述（选填）'),
                const SizedBox(height: 8),
                _SheetTextField(
                  controller: _descriptionController,
                  hintText: '添加描述...',
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton(
                    onPressed: widget.saving ? null : _save,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
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

class _ChecklistImportTabs extends StatelessWidget {
  const _ChecklistImportTabs({required this.mode, required this.onChanged});

  final _ChecklistImportMode mode;
  final ValueChanged<_ChecklistImportMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _tab('从物品导入', _ChecklistImportMode.item),
          _tab('从套组导入', _ChecklistImportMode.pack),
        ],
      ),
    );
  }

  Widget _tab(String label, _ChecklistImportMode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : const Color(0xFF9DA4AA),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistSearchField extends StatefulWidget {
  const _ChecklistSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  State<_ChecklistSearchField> createState() => _ChecklistSearchFieldState();
}

class _ChecklistSearchFieldState extends State<_ChecklistSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _ChecklistSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearSearch() {
    if (widget.controller.text.isEmpty) return;
    widget.controller.clear();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return SizedBox(
      height: 42,
      child: TextField(
        controller: widget.controller,
        onChanged: (_) => widget.onChanged(),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF9DA4AA),
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF9DA4AA),
                    size: 18,
                  ),
                  tooltip: '清空',
                )
              : null,
          hintText: '搜索物品...',
          hintStyle: const TextStyle(color: Color(0xFF9DA4AA)),
          filled: true,
          fillColor: const Color(0xFFF0F0F6),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ImportItemRow extends StatelessWidget {
  const _ImportItemRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.titleSuffix,
    this.onMoreTap,
  });

  final String title;
  final String? titleSuffix;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: selected
                  ? const Color(0xFF48B8B4)
                  : Colors.white,
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC8C8D0)),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: title,
                      children: [
                        if (titleSuffix != null)
                          TextSpan(
                            text: '  $titleSuffix',
                            style: const TextStyle(
                              color: Color(0xFF9DA4AA),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9DA4AA),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onMoreTap != null) ...[
              const SizedBox(width: 6),
              IconButton(
                onPressed: onMoreTap,
                visualDensity: VisualDensity.compact,
                tooltip: '查看套组内容',
                icon: const Icon(Icons.more_horiz, color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.hintText,
    this.error = false,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final bool error;
  final int maxLines;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF0F0F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorText: error ? '' : null,
        errorStyle: const TextStyle(height: 0, fontSize: 0),
      ),
    );
  }
}

class _SheetTapField extends StatelessWidget {
  const _SheetTapField({
    required this.text,
    required this.hintText,
    required this.onTap,
    this.error = false,
  });

  final String text;
  final String hintText;
  final VoidCallback onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF0F0F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorText: error ? '' : null,
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
        child: Text(
          text.isEmpty ? hintText : text,
          style: TextStyle(
            color: text.isEmpty ? const Color(0xFFB8B8C4) : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _ChecklistSuccessBanner extends StatelessWidget {
  const _ChecklistSuccessBanner();

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

class _ChecklistError extends StatelessWidget {
  const _ChecklistError({required this.message, required this.onRetry});

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

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
