import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../items/data/item_repository.dart';
import '../../../packs/data/pack_repository.dart';
import '../../data/checklist.dart';
import '../../data/checklist_repository.dart';
import '../../../../shared/widgets/search_empty_state.dart';
import '../../../../shared/widgets/search_pill_field.dart';
import '../widgets/checklist_common_widgets.dart';
import '../widgets/checklist_list_widgets.dart';
import 'checklist_detail_page.dart';

class ChecklistSearchPage extends StatefulWidget {
  const ChecklistSearchPage({
    super.key,
    required this.checklistRepository,
    required this.itemRepository,
    required this.packRepository,
  });

  final ChecklistRepository checklistRepository;
  final ItemRepository itemRepository;
  final PackRepository packRepository;

  @override
  State<ChecklistSearchPage> createState() => _ChecklistSearchPageState();
}

class _ChecklistSearchPageState extends State<ChecklistSearchPage> {
  final _controller = TextEditingController();
  Future<List<Checklist>>? _future;
  String _query = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _future = null;
      });
      return;
    }
    final future = widget.checklistRepository.listChecklists(q: q);
    setState(() {
      _query = q;
      _future = future;
    });
    await future;
  }

  void _search() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 260), () {
      final q = _controller.text.trim();
      setState(() {
        _query = q;
        _future = q.isEmpty
            ? null
            : widget.checklistRepository.listChecklists(q: q);
      });
    });
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ChecklistScaffold(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 20, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.chevron_left_rounded),
                      iconSize: 26,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SearchPillField(
                      controller: _controller,
                      autofocus: true,
                      hintText: '搜索',
                      onChanged: (_) => _search(),
                      onClear: () {
                        _controller.clear();
                        setState(() {
                          _query = '';
                          _future = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _future == null
                ? const SizedBox.shrink()
                : FutureBuilder<List<Checklist>>(
                    future: _future,
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
                      if (checklists.isEmpty && _query.isNotEmpty) {
                        return const SearchEmptyState();
                      }
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
