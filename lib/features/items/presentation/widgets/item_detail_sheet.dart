import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/item.dart';
import '../../data/item_repository.dart';
import 'add_item_sheet.dart';
import 'item_detail_result.dart';
import 'item_shared_widgets.dart';

Future<ItemDetailResult?> showItemDetailSheet({
  required BuildContext context,
  required Item item,
  required ItemRepository itemRepository,
  String? initialSuccessMessage,
}) {
  return showModalBottomSheet<ItemDetailResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    builder: (context) => _ItemDetailSheet(
      item: item,
      itemRepository: itemRepository,
      initialSuccessMessage: initialSuccessMessage,
    ),
  );
}

class _ItemDetailSheet extends StatefulWidget {
  const _ItemDetailSheet({
    required this.item,
    required this.itemRepository,
    this.initialSuccessMessage,
  });

  final Item item;
  final ItemRepository itemRepository;
  final String? initialSuccessMessage;

  @override
  State<_ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends State<_ItemDetailSheet> {
  late Future<Item> _itemFuture;
  late Item _item;
  Timer? _successTimer;
  String? _successMessage;
  bool _deleting = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _itemFuture = _loadItem();
    final message = widget.initialSuccessMessage;
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSuccess(message);
      });
    }
  }

  Future<Item> _loadItem() async {
    final item = await widget.itemRepository.getItem(widget.item.id);
    _item = item;
    return item;
  }

  void _showSuccess(String message) {
    _successTimer?.cancel();
    setState(() => _successMessage = message);
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _successMessage = null);
    });
  }

  void _openEdit() {
    setState(() {
      _editing = true;
      _successMessage = null;
    });
  }

  void _cancelEdit() {
    if (!mounted) return;
    setState(() => _editing = false);
  }

  void _handleUpdated(Item updated) {
    if (!mounted) return;
    setState(() {
      _item = updated;
      _itemFuture = Future.value(updated);
      _editing = false;
    });
    _showSuccess('修改成功');
  }

  Future<void> _confirmDelete(Item item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 54),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/common/trash.svg',
                  width: 126,
                  height: 126,
                  semanticsLabel: '删除物品',
                ),
                const SizedBox(height: 20),
                Text(
                  '确认删除该物品吗？',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 158,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5757),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0x33000000),
                    ),
                    child: const Text(
                      '删除',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (shouldDelete != true || _deleting || !mounted) return;
    setState(() => _deleting = true);
    try {
      await widget.itemRepository.deleteItem(item.id);
      if (mounted) Navigator.of(context).pop(ItemDetailResult.deleted);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final imageSize = (screenWidth * 0.54).clamp(190.0, 224.0).toDouble();
    if (_editing) {
      return AddItemSheet(
        initialItem: _item,
        title: '编辑物品',
        submitLabel: '保存',
        popOnSubmit: false,
        onSubmitted: _handleUpdated,
        onCancel: _cancelEdit,
        onSubmit: (name, description, image) {
          return widget.itemRepository.updateItem(
            itemId: _item.id,
            name: name,
            description: description,
            image: image,
          );
        },
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: EdgeInsets.only(top: _successMessage == null ? 0 : 42),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<Item>(
            future: _itemFuture,
            initialData: _item,
            builder: (context, snapshot) {
              final item = snapshot.data ?? _item;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ItemSheetHeader(
                      title: '查看物品',
                      onClose: () =>
                          Navigator.of(context).pop(ItemDetailResult.updated),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ItemImageFrame(
                        item: item,
                        size: imageSize,
                        iconSize: imageSize * 0.62,
                        borderRadius: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(height: 1, color: const Color(0xFFE1E4E8)),
                    const SizedBox(height: 12),
                    Text(
                      item.description.isEmpty ? '暂无描述' : item.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF465258),
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: ItemSheetActionButton(
                            label: '编辑',
                            color: const Color(0xFF4DBDBB),
                            onPressed: _openEdit,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ItemSheetActionButton(
                            label: '删除',
                            color: const Color(0xFFFF5757),
                            onPressed: _deleting
                                ? null
                                : () => _confirmDelete(item),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_successMessage != null)
          Positioned(
            top: 0,
            left: 42,
            right: 42,
            child: ItemSuccessBanner(message: _successMessage!),
          ),
      ],
    );
  }
}
