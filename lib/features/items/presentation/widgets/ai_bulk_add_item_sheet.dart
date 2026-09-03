import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/item.dart';
import '../../data/item_repository.dart';
import 'add_item_sheet.dart';
import 'item_shared_widgets.dart';

enum AddItemMethod { manual, aiBulk }

class AddItemMethodSheet extends StatelessWidget {
  const AddItemMethodSheet({
    super.key,
    required this.onManual,
    required this.onAiBulk,
  });

  final VoidCallback onManual;
  final VoidCallback onAiBulk;

  @override
  Widget build(BuildContext context) {
    return _ItemBottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandleHeader(
            title: '添加物品',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _AddMethodCard(
                  icon: Icons.add_rounded,
                  title: '逐一添加',
                  subtitle: '手动填写物品信息',
                  selected: false,
                  onTap: onManual,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AddMethodCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI 批量添加',
                  subtitle: '通过一段文本批量识别',
                  selected: true,
                  onTap: onAiBulk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AiBulkAddItemSheet extends StatefulWidget {
  const AiBulkAddItemSheet({
    super.key,
    required this.repository,
    required this.categories,
  });

  final ItemRepository repository;
  final List<ItemCategory> categories;

  @override
  State<AiBulkAddItemSheet> createState() => _AiBulkAddItemSheetState();
}

class _AiBulkAddItemSheetState extends State<AiBulkAddItemSheet> {
  static const _maxLength = 200;
  static const _examples = [
    _QuickExample(label: '旅行装备', text: '护照夹、充电宝、旅行枕、眼罩、行李牌'),
    _QuickExample(label: '露营用品', text: '帐篷、睡袋、防潮垫、头灯、折叠椅、保温杯'),
    _QuickExample(label: '办公必备', text: '笔记本电脑、鼠标、充电器、工牌、降噪耳机'),
    _QuickExample(label: '健身装备', text: '运动鞋、速干衣、水壶、毛巾、护腕'),
  ];

  final _controller = TextEditingController();
  final _dots = ValueNotifier<int>(1);
  Timer? _dotsTimer;
  Timer? _toastTimer;
  _AiBulkStep _step = _AiBulkStep.input;
  List<ItemDraft> _drafts = const [];
  int? _editingDraftIndex;
  bool _saving = false;
  String? _error;
  String? _toastMessage;

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _toastTimer?.cancel();
    _dots.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _step == _AiBulkStep.analyzing) return;
    setState(() {
      _step = _AiBulkStep.analyzing;
      _error = null;
    });
    _startDots();
    try {
      final drafts = await widget.repository.generateItemDrafts(text);
      if (!mounted) return;
      _stopDots();
      setState(() {
        _drafts = drafts;
        _step = _AiBulkStep.drafts;
      });
    } catch (error) {
      if (!mounted) return;
      _stopDots();
      setState(() {
        _step = _AiBulkStep.input;
        _error = error.toString();
      });
    }
  }

  void _startDots() {
    _dots.value = 1;
    _dotsTimer?.cancel();
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      _dots.value = _dots.value == 3 ? 1 : _dots.value + 1;
    });
  }

  void _stopDots() {
    _dotsTimer?.cancel();
    _dotsTimer = null;
  }

  Future<void> _saveAll() async {
    if (_saving || _drafts.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final items = await widget.repository.batchCreateItems(_drafts);
      if (mounted) Navigator.of(context).pop(items);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString();
        });
      }
    }
  }

  void _editDraft(int index) {
    setState(() {
      _editingDraftIndex = index;
      _step = _AiBulkStep.editing;
    });
  }

  void _saveDraftEdit(ItemDraft updated) {
    final index = _editingDraftIndex;
    if (index == null) return;
    setState(() {
      _drafts = [..._drafts.take(index), updated, ..._drafts.skip(index + 1)];
      _editingDraftIndex = null;
      _step = _AiBulkStep.drafts;
    });
  }

  void _returnToDrafts() {
    setState(() {
      _editingDraftIndex = null;
      _step = _AiBulkStep.drafts;
    });
  }

  Future<void> _deleteDraft(int index) async {
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
                SvgPicture.asset('assets/common/trash.svg', width: 118),
                const SizedBox(height: 18),
                const Text(
                  '确认删除该草稿吗？',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                    ),
                    child: const Text('删除'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (shouldDelete != true || !mounted) return;
    setState(() {
      _drafts = [..._drafts.take(index), ..._drafts.skip(index + 1)];
    });
    _showCenterToast('删除成功');
  }

  void _showCenterToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  void _previewDraft(ItemDraft draft) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) {
        return _DraftPreviewSheet(draft: draft);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheet = switch (_step) {
      _AiBulkStep.input => _buildInput(),
      _AiBulkStep.analyzing => _buildAnalyzing(),
      _AiBulkStep.drafts => _buildDrafts(),
      _AiBulkStep.editing => _buildEditing(),
    };
    return SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          sheet,
          if (_toastMessage != null)
            Center(child: _CenterToast(message: _toastMessage!)),
        ],
      ),
    );
  }

  Widget _buildInput() {
    final textLength = _controller.text.characters.length;
    return _ItemBottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandleHeader(
            title: 'AI 批量添加',
            icon: Icons.auto_awesome_rounded,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 14),
          const Text(
            '用自然语言描述想添加的物品，AI 会自动识别并整理',
            style: TextStyle(color: Color(0xFF8D969D), fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 4,
            maxLines: 4,
            maxLength: _maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '护照夹、充电宝、旅行枕、眼罩、行李牌',
              hintStyle: const TextStyle(color: Color(0xFF9CA4AE)),
              filled: true,
              fillColor: const Color(0xFFF2F5F5),
              counterText: '$textLength/$_maxLength',
              counterStyle: const TextStyle(color: Color(0xFF9CA4AE)),
              contentPadding: const EdgeInsets.all(14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF73D3CA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF48B8B4)),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                '快捷示例',
                style: TextStyle(color: Color(0xFF9CA4AE), fontSize: 12),
              ),
              for (final example in _examples)
                ActionChip(
                  label: Text(example.label),
                  onPressed: () {
                    _controller.text = example.text;
                    _controller.selection = TextSelection.collapsed(
                      offset: _controller.text.length,
                    );
                    setState(() {});
                  },
                  labelStyle: const TextStyle(
                    color: Color(0xFF3DB7B5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: const Color(0xFFD6F4EF),
                  side: const BorderSide(color: Color(0xFFAAE6DE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _controller.text.trim().isEmpty ? null : _analyze,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('开始解析'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4DBDBB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE1E4EA),
                disabledForegroundColor: const Color(0xFF9EA7B0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzing() {
    return _ItemBottomPanel(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/common/processing.png', width: 142),
            const SizedBox(height: 18),
            ValueListenableBuilder<int>(
              valueListenable: _dots,
              builder: (context, count, _) {
                return Text(
                  'AI 正在解析${List.filled(count, '.').join()}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              '正在识别「${_controller.text.trim()}」',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA4AE), fontSize: 13),
            ),
            const SizedBox(height: 18),
            const _AnalyzingDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrafts() {
    return _ItemBottomPanel(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandleHeader(
              title: '解析完成',
              icon: Icons.check_circle_rounded,
              titleSuffix: '共 ${_drafts.length} 项',
              onClose: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFE1E4E8)),
            const SizedBox(height: 10),
            const Text(
              '可直接编辑名称和分类，确认后保存',
              style: TextStyle(color: Color(0xFF9CA4AE), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _drafts.isEmpty
                  ? const Center(
                      child: Text(
                        '未解析出物品',
                        style: TextStyle(color: Color(0xFF9CA4AE)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _drafts.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _ItemDraftTile(
                          draft: _drafts[index],
                          onTap: () => _previewDraft(_drafts[index]),
                          onEdit: () => _editDraft(index),
                          onDelete: () => _deleteDraft(index),
                        );
                      },
                    ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving || _drafts.isEmpty ? null : _saveAll,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4DBDBB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE1E4EA),
                  disabledForegroundColor: const Color(0xFF9EA7B0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('全部保存（${_drafts.length} 项）'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditing() {
    final index = _editingDraftIndex;
    if (index == null || index < 0 || index >= _drafts.length) {
      return _buildDrafts();
    }
    final draft = _drafts[index];
    return AddItemSheet(
      initialItem: Item(
        id: 'draft-$index',
        name: draft.name,
        description: draft.description,
        categoryId: draft.categoryId,
        categoryKey: draft.categoryKey,
        categoryName: draft.categoryName,
      ),
      title: '编辑物品',
      submitLabel: '保存',
      categories: widget.categories,
      onBack: _returnToDrafts,
      onCancel: () => Navigator.of(context).pop(),
      popOnSubmit: false,
      onSubmitted: (item) {
        _saveDraftEdit(
          ItemDraft(
            name: item.name,
            description: item.description,
            categoryId: item.categoryId,
            categoryKey: item.categoryKey,
            categoryName: item.categoryName,
          ),
        );
      },
      onSubmit: (name, categoryId, description, image) async {
        final category = _categoryFor(categoryId);
        return Item(
          id: 'draft-$index',
          name: name,
          description: description,
          categoryId: category?.id ?? categoryId,
          categoryKey: category?.key ?? draft.categoryKey,
          categoryName: category?.name ?? draft.categoryName,
        );
      },
    );
  }

  ItemCategory? _categoryFor(String categoryId) {
    for (final category in widget.categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }
}

class _DraftPreviewSheet extends StatelessWidget {
  const _DraftPreviewSheet({required this.draft});

  final ItemDraft draft;

  @override
  Widget build(BuildContext context) {
    return _ItemBottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetHandleHeader(
            title: '查看物品',
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'assets/common/gift_box.png',
              width: 180,
              height: 180,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            draft.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          if (draft.categoryName.isNotEmpty) ...[
            const SizedBox(height: 10),
            ItemCategoryPill(label: draft.categoryName),
          ],
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE1E4E8)),
          const SizedBox(height: 10),
          Text(
            draft.description.isEmpty ? '暂无描述' : draft.description,
            style: const TextStyle(
              color: Color(0xFF465258),
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterToast extends StatelessWidget {
  const _CenterToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemDraftTile extends StatelessWidget {
  const _ItemDraftTile({
    required this.draft,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ItemDraft draft;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final item = Item(
      id: '',
      name: draft.name,
      description: draft.description,
      categoryId: draft.categoryId,
      categoryKey: draft.categoryKey,
      categoryName: draft.categoryName,
    );
    return _DraftTileFrame(
      child: AppItemTile(
        item: item,
        title: draft.name,
        description: draft.description,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        borderRadius: 8,
        padding: const EdgeInsets.fromLTRB(20, 6, 14, 6),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DraftIconButton(
              icon: Icons.edit_outlined,
              color: const Color(0xFF3DB7B5),
              onTap: onEdit,
            ),
            const SizedBox(width: 10),
            _DraftIconButton(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFFF5757),
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftTileFrame extends StatelessWidget {
  const _DraftTileFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        foregroundPainter: const _DashedRoundedBorderPainter(
          color: Color(0xFF48B3AF),
          radius: 8,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF48B3AF).withValues(alpha: 0.5),
                const Color(0xFFA7E399).withValues(alpha: 0.5),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;
  static const _strokeWidth = 1.0;
  static const _dash = 4.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(_strokeWidth / 2),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _DraftIconButton extends StatelessWidget {
  const _DraftIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _AddMethodCard extends StatelessWidget {
  const _AddMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : Colors.black;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4DBDBB) : const Color(0xFFF1F8F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E7E5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.22)
                    : const Color(0xFFD6F4EF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF4DBDBB),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(alpha: 0.82)
                    : const Color(0xFF9CA4AE),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandleHeader extends StatelessWidget {
  const _SheetHandleHeader({
    required this.title,
    required this.onClose,
    this.icon,
    this.titleSuffix,
  });

  final String title;
  final VoidCallback onClose;
  final IconData? icon;
  final String? titleSuffix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8D8DD),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 2,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 22, color: const Color(0xFF4DBDBB)),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (titleSuffix != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    titleSuffix!,
                    style: const TextStyle(
                      color: Color(0xFF9CA4AE),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            right: -9,
            bottom: -8,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF7D858B),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemBottomPanel extends StatelessWidget {
  const _ItemBottomPanel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 28),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: padding,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(top: false, child: child),
      ),
    );
  }
}

class _AnalyzingDots extends StatelessWidget {
  const _AnalyzingDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(),
        SizedBox(width: 6),
        _Dot(),
        SizedBox(width: 6),
        _Dot(),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF67C9C3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const SizedBox(width: 8, height: 8),
    );
  }
}

enum _AiBulkStep { input, analyzing, drafts, editing }

class _QuickExample {
  const _QuickExample({required this.label, required this.text});

  final String label;
  final String text;
}
