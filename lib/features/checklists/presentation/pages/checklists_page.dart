import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../items/data/item_repository.dart';
import '../../../me/data/me_repository.dart';
import '../../../me/presentation/pages/me_page.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/presentation/pages/create_pack_page.dart';
import '../../data/checklist.dart';
import '../../data/checklist_repository.dart';
import '../../../../shared/navigation/no_animation_route.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../../shared/widgets/module_floating_add_button.dart';
import '../widgets/checklist_common_widgets.dart';
import '../widgets/checklist_list_widgets.dart';
import '../widgets/checklist_meta_sheet.dart';
import 'checklist_detail_page.dart';
import 'checklist_import_page.dart';
import 'checklist_search_page.dart';

class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({
    super.key,
    required this.checklistRepository,
    required this.itemRepository,
    required this.packRepository,
    required this.meRepository,
  });

  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;
  final MeRepository meRepository;

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
      builder: (sheetContext) => ChecklistMetaSheet(
        title: '新增清单',
        submitLabel: '下一步',
        onSubmit: (draft) {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChecklistImportPage.create(
                draft: draft,
                checklistRepository: widget.checklistRepository,
                itemRepository: widget.itemRepository,
                packRepository: widget.packRepository,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openChecklist(Checklist checklist) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ChecklistDetailPage(
              checklist: checklist,
              checklistRepository: widget.checklistRepository,
              itemRepository: widget.itemRepository,
              packRepository: widget.packRepository,
            ),
          ),
        )
        .then((_) {
          if (mounted) _refresh();
        });
  }

  void _handleTabSelected(BottomTab tab) {
    if (tab == BottomTab.checklist) return;
    if (tab == BottomTab.item) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (tab == BottomTab.pack) {
      Navigator.of(context).pushReplacement(
        noAnimationRoute<void>(
          (_) => PacksPage(
            itemRepository: widget.itemRepository,
            packRepository: widget.packRepository,
            checklistRepository: widget.checklistRepository,
            meRepository: widget.meRepository,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      noAnimationRoute<void>(
        (_) => MePage(
          meRepository: widget.meRepository,
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
          checklistRepository: widget.checklistRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ChecklistScaffold(
        floating: ModuleFloatingAddButton(onPressed: _openCreateSheet),
        bottomBar: SafeArea(
          top: false,
          child: BottomNav(
            currentTab: BottomTab.checklist,
            onTabSelected: _handleTabSelected,
          ),
        ),
        children: [
          ChecklistTopBar(
            title: '我的清单',
            trailing: Icons.search_rounded,
            onTrailingTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChecklistSearchPage(
                    checklistRepository: widget.checklistRepository,
                    itemRepository: widget.itemRepository,
                    packRepository: widget.packRepository,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Checklist>>(
              future: _checklistsFuture,
              builder: (context, snapshot) {
                final checklists = snapshot.data ?? const <Checklist>[];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    checklists.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError && checklists.isEmpty) {
                  return ChecklistErrorView(
                    message: snapshot.error.toString(),
                    onRetry: _refresh,
                  );
                }
                if (checklists.isEmpty) return const ChecklistEmptyState();
                return ChecklistList(
                  checklists: checklists,
                  onRefresh: _refresh,
                  onTap: _openChecklist,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
