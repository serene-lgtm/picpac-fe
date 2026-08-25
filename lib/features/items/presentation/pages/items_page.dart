import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/navigation/no_animation_route.dart';
import '../../../../shared/widgets/bottom_nav.dart';
import '../../../../shared/widgets/module_floating_add_button.dart';
import '../../../checklists/data/checklist_repository.dart';
import '../../../checklists/presentation/pages/checklists_page.dart';
import '../../../me/data/me_repository.dart';
import '../../../me/presentation/pages/me_page.dart';
import '../../../packs/data/pack_repository.dart';
import '../../../packs/presentation/pages/create_pack_page.dart';
import '../../data/item.dart';
import '../../data/item_repository.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/item_detail_result.dart';
import '../widgets/item_detail_sheet.dart';
import '../widgets/item_list_widgets.dart';
import '../widgets/item_shared_widgets.dart';
import 'item_search_page.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({
    super.key,
    required this.repository,
    required this.packRepository,
    required this.checklistRepository,
    required this.meRepository,
  });

  final ItemRepository repository;
  final PackRepository packRepository;
  final ChecklistRepository checklistRepository;
  final MeRepository meRepository;

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late Future<List<Item>> _itemsFuture;
  List<Item> _allItems = const [];
  List<Item> _items = const [];
  List<ItemCategory> _categories = const [];
  String? _selectedCategoryId;
  Timer? _successTimer;
  bool _showSuccessBanner = false;
  String _successMessage = '添加成功';

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
    unawaited(_loadCategories());
  }

  Future<List<Item>> _loadItems() async {
    final items = await widget.repository.listItems();
    final filteredItems = _filterItemsByCategory(items, _selectedCategoryId);
    _allItems = items;
    _items = filteredItems;
    return filteredItems;
  }

  Future<void> _loadCategories() async {
    final List<ItemCategory> categories;
    try {
      categories = await widget.repository.listCategories();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _categories = categories;
    });
  }

  Future<void> _refresh() async {
    final future = _loadItems();
    setState(() {
      _itemsFuture = future;
    });
    await future;
  }

  Future<void> _openAddItem() async {
    if (_categories.isEmpty) {
      final categories = await widget.repository.listCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    }
    final created = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) {
        return AddItemSheet(
          categories: _categories,
          onSubmit: (name, categoryId, description, image) {
            return widget.repository.createItem(
              name: name,
              categoryId: categoryId,
              description: description,
              image: image,
            );
          },
        );
      },
    );
    if (created != null && mounted) {
      await _refresh();
      await _openItemDetail(created, successMessage: '添加成功');
    }
  }

  Future<void> _openItemDetail(Item item, {String? successMessage}) async {
    final result = await showItemDetailSheet(
      context: context,
      item: item,
      itemRepository: widget.repository,
      categories: _categories,
      initialSuccessMessage: successMessage,
    );
    await _handleDetailResult(result);
  }

  Future<void> _openSearch() async {
    final result = await Navigator.of(context).push<ItemDetailResult>(
      MaterialPageRoute<ItemDetailResult>(
        builder: (context) => ItemSearchPage(itemRepository: widget.repository),
      ),
    );
    await _handleDetailResult(result);
  }

  Future<void> _handleDetailResult(ItemDetailResult? result) async {
    if (!mounted) return;
    if (result == ItemDetailResult.deleted) {
      await _refresh();
      if (mounted) _showSuccess('删除成功');
    } else if (result == ItemDetailResult.updated) {
      await _refresh();
    }
  }

  void _handleCategorySelected(String? categoryId) {
    if (categoryId == _selectedCategoryId) return;
    final filteredItems = _filterItemsByCategory(_allItems, categoryId);
    setState(() {
      _selectedCategoryId = categoryId;
      _items = filteredItems;
      _itemsFuture = Future.value(filteredItems);
    });
  }

  List<Item> _filterItemsByCategory(List<Item> items, String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return items;
    final category = _categories.where((category) => category.id == categoryId);
    if (category.isEmpty) return items;
    final selectedCategory = category.first;
    return items
        .where((item) => _itemMatchesCategory(item, selectedCategory))
        .toList(growable: false);
  }

  bool _itemMatchesCategory(Item item, ItemCategory category) {
    if (item.categoryId.isNotEmpty && item.categoryId == category.id) {
      return true;
    }
    if (item.categoryKey.isNotEmpty && category.key.isNotEmpty) {
      if (item.categoryKey == category.key) return true;
    }
    if (item.categoryName.isNotEmpty && category.name.isNotEmpty) {
      return item.categoryName == category.name;
    }
    return false;
  }

  void _showSuccess(String message) {
    _successTimer?.cancel();
    setState(() {
      _successMessage = message;
      _showSuccessBanner = true;
    });
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showSuccessBanner = false;
      });
    });
  }

  void _handleTabSelected(BottomTab tab) {
    if (tab == BottomTab.item) return;
    if (tab == BottomTab.pack) {
      Navigator.of(context).push(
        noAnimationRoute<void>(
          (context) => PacksPage(
            itemRepository: widget.repository,
            packRepository: widget.packRepository,
            checklistRepository: widget.checklistRepository,
            meRepository: widget.meRepository,
          ),
        ),
      );
    }
    if (tab == BottomTab.checklist) {
      Navigator.of(context).push(
        noAnimationRoute<void>(
          (context) => ChecklistsPage(
            checklistRepository: widget.checklistRepository,
            itemRepository: widget.repository,
            packRepository: widget.packRepository,
            meRepository: widget.meRepository,
          ),
        ),
      );
    }
    if (tab == BottomTab.me) {
      Navigator.of(context).push(
        noAnimationRoute<void>(
          (context) => MePage(
            meRepository: widget.meRepository,
            itemRepository: widget.repository,
            packRepository: widget.packRepository,
            checklistRepository: widget.checklistRepository,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
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
          child: Stack(
            children: [
              Column(
                children: [
                  ItemsHeader(onSearch: _openSearch),
                  ItemCategoryTabs(
                    categories: _categories,
                    selectedCategoryId: _selectedCategoryId,
                    onSelected: _handleCategorySelected,
                  ),
                  Expanded(
                    child: FutureBuilder<List<Item>>(
                      future: _itemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            _items.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }
                        if (snapshot.hasError && _items.isEmpty) {
                          return ItemErrorState(
                            message: snapshot.error.toString(),
                            onRetry: _refresh,
                          );
                        }
                        final items = snapshot.data ?? _items;
                        if (items.isEmpty) {
                          return ItemsBlank(onRefresh: _refresh);
                        }
                        return ItemsList(
                          items: items,
                          onRefresh: _refresh,
                          onItemSelected: _openItemDetail,
                        );
                      },
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: BottomNav(
                    currentTab: BottomTab.item,
                    onTabSelected: _handleTabSelected,
                  ),
                ),
              ),
              ModuleFloatingAddButton(onPressed: _openAddItem),
              Positioned(
                left: 50,
                right: 50,
                bottom: 90,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showSuccessBanner ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: ItemSuccessBanner(message: _successMessage),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
