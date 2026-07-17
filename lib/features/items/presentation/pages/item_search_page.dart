import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/search_pill_field.dart';
import '../../../../shared/widgets/search_empty_state.dart';
import '../../data/item.dart';
import '../../data/item_repository.dart';
import '../widgets/item_detail_sheet.dart';
import '../widgets/item_list_widgets.dart';
import '../widgets/item_shared_widgets.dart';

class ItemSearchPage extends StatefulWidget {
  const ItemSearchPage({super.key, required this.itemRepository});

  final ItemRepository itemRepository;

  @override
  State<ItemSearchPage> createState() => _ItemSearchPageState();
}

class _ItemSearchPageState extends State<ItemSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<Item>>? _resultsFuture;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
      final query = value.trim();
      if (!mounted || query == _query) return;
      setState(() {
        _query = query;
        _resultsFuture = query.isEmpty
            ? null
            : widget.itemRepository.listItems(q: query);
      });
    });
  }

  Future<void> _openResult(Item item) async {
    final result = await showItemDetailSheet(
      context: context,
      item: item,
      itemRepository: widget.itemRepository,
    );
    if (!mounted) return;
    if (result != null) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFA7E399),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF48B3AF), Color(0xFFA7E399)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
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
                          onChanged: _onQueryChanged,
                          onClear: () {
                            _controller.clear();
                            _onQueryChanged('');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final future = _resultsFuture;
    if (_query.isEmpty || future == null) return const _SearchInitialState();
    return FutureBuilder<List<Item>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return ItemErrorState(
            message: snapshot.error.toString(),
            onRetry: () async {
              setState(() {
                _resultsFuture = widget.itemRepository.listItems(q: _query);
              });
              await _resultsFuture;
            },
          );
        }
        final items = snapshot.data ?? const <Item>[];
        if (items.isEmpty) return const SearchEmptyState();
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 28, 22, 44),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return ItemListTile(item: item, onTap: () => _openResult(item));
          },
        );
      },
    );
  }
}

class _SearchInitialState extends StatelessWidget {
  const _SearchInitialState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 132, 28, 120),
      children: const [SizedBox(height: 1)],
    );
  }
}
