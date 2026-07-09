import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                        child: Container(
                          height: 51,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            onChanged: _onQueryChanged,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFFC4C7CC),
                              ),
                              suffixIcon: _controller.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _controller.clear();
                                        _onQueryChanged('');
                                      },
                                      icon: const Icon(Icons.cancel_rounded),
                                      color: const Color(0xFFC4C7CC),
                                      iconSize: 18,
                                    ),
                              hintText: '请输入关键词',
                              hintStyle: const TextStyle(
                                color: Color(0xFFC4C7CC),
                                fontSize: 15,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                            ),
                          ),
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
        if (items.isEmpty) return _SearchEmptyState(query: _query);
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

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 166, 28, 120),
      children: [
        SvgPicture.asset(
          'assets/common/no_result.svg',
          height: 270,
          semanticsLabel: '无搜索结果',
        ),
      ],
    );
  }
}
