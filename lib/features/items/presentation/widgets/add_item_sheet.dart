import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../data/item.dart';

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({
    super.key,
    required this.onSubmit,
    this.initialItem,
    this.onSubmitted,
    this.categories = const [],
    this.popOnSubmit = true,
    this.submitLabel = '保存',
    this.title = '添加物品',
    this.onBack,
    this.onCancel,
  });

  final Future<Item> Function(
    String name,
    String categoryId,
    String description,
    MultipartFilePart? image,
  )
  onSubmit;
  final Item? initialItem;
  final ValueChanged<Item>? onSubmitted;
  final List<ItemCategory> categories;
  final bool popOnSubmit;
  final String submitLabel;
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onCancel;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _image;
  String? _selectedCategoryId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _selectedCategoryLabel {
    for (final category in _categoryOptions) {
      if (category.id == _selectedCategoryId) return category.name;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _nameController.text = item.name;
      _descriptionController.text = item.description;
      _selectedCategoryId = item.categoryId.isNotEmpty ? item.categoryId : null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final item = await widget.onSubmit(
        _nameController.text.trim(),
        _selectedCategoryId ?? '',
        _descriptionController.text.trim(),
        _image == null
            ? null
            : MultipartFilePart(
                fieldName: 'image',
                fileName: _image!.name,
                contentType: _contentTypeFor(_image!.name),
                bytes: _image!.readAsBytes(),
              ),
      );
      if (mounted) {
        if (widget.popOnSubmit) {
          Navigator.of(context).pop(item);
        } else {
          widget.onSubmitted?.call(item);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('从相册选择'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('拍照'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (source == null) return;
    final image = await _imagePicker.pickImage(source: source);
    if (image != null && mounted) {
      setState(() => _image = image);
    }
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  List<ItemCategory> get _categoryOptions {
    final options = [...widget.categories];
    final item = widget.initialItem;
    if (item != null &&
        item.categoryId.isNotEmpty &&
        item.categoryName.isNotEmpty &&
        !options.any((category) => category.id == item.categoryId)) {
      options.add(
        ItemCategory(
          id: item.categoryId,
          key: item.categoryKey,
          name: item.categoryName,
        ),
      );
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final categoryOptions = _categoryOptions;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 56,
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
                        top: 27,
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (widget.onBack != null)
                        Positioned(
                          left: -12,
                          top: 16,
                          child: IconButton(
                            onPressed: widget.onBack,
                            icon: const Icon(Icons.chevron_left_rounded),
                            iconSize: 32,
                            color: Colors.black,
                          ),
                        ),
                      Positioned(
                        right: -9,
                        top: 20,
                        child: IconButton(
                          onPressed:
                              widget.onCancel ??
                              () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          iconSize: 24,
                          color: const Color(0xFF33363D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    widget.initialItem == null ? '名称 *' : '手机',
                  ),
                  maxLength: 20,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入物品名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                FormField<String>(
                  initialValue: _selectedCategoryId,
                  validator: (_) {
                    final value = _selectedCategoryId;
                    if (value == null || value.trim().isEmpty) {
                      return '请选择分类';
                    }
                    return null;
                  },
                  builder: (field) {
                    return _CategoryPickerField(
                      label: _selectedCategoryLabel,
                      hintText: '分类 *',
                      categories: categoryOptions,
                      enabled: !_submitting,
                      errorText: field.errorText,
                      onChanged: (category) {
                        setState(() => _selectedCategoryId = category.id);
                        field.didChange(category.id);
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: _inputDecoration(
                    widget.initialItem == null ? '描述（选填）' : '添加描述...',
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _submitting ? null : _pickImage,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFBFC5CC),
                            width: 1.2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _image == null
                            ? _ExistingImageOrPicker(item: widget.initialItem)
                            : Image.file(File(_image!.path), fit: BoxFit.cover),
                      ),
                      if (widget.initialItem == null) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '照片（选填）',
                          style: TextStyle(
                            color: Color(0xFF9CA4AE),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Center(
                  child: SizedBox(
                    width: 168,
                    height: 49,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4DBDBB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0x22000000),
                      ),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              widget.submitLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
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

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFB7BBC3), fontSize: 15),
      filled: true,
      fillColor: const Color(0xFFF0F1F6),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _ExistingImageOrPicker extends StatelessWidget {
  const _ExistingImageOrPicker({required this.item});

  final Item? item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item?.bestImageUrl ?? '';
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.photo_camera_outlined,
        color: Color(0xFF4DBDBB),
        size: 30,
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.photo_camera_outlined,
          color: Color(0xFF4DBDBB),
          size: 30,
        );
      },
    );
  }
}

class _CategoryPickerField extends StatefulWidget {
  const _CategoryPickerField({
    required this.label,
    required this.hintText,
    required this.categories,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String hintText;
  final List<ItemCategory> categories;
  final bool enabled;
  final ValueChanged<ItemCategory> onChanged;
  final String? errorText;

  @override
  State<_CategoryPickerField> createState() => _CategoryPickerFieldState();
}

class _CategoryPickerFieldState extends State<_CategoryPickerField> {
  final _layerLink = LayerLink();
  final _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _hideOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (!widget.enabled) return;
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? const Size(0, 52);
    _searchController.clear();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final query = _searchController.text.trim().toLowerCase();
            final categories = query.isEmpty
                ? widget.categories
                : widget.categories
                      .where(
                        (category) =>
                            category.name.toLowerCase().contains(query) ||
                            category.key.toLowerCase().contains(query),
                      )
                      .toList(growable: false);
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _hideOverlay,
                    child: const SizedBox.expand(),
                  ),
                ),
                CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height + 6),
                  child: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: size.width,
                      child: _CategoryPickerMenu(
                        searchController: _searchController,
                        categories: categories,
                        onSearchChanged: (_) => setOverlayState(() {}),
                        onSelected: (category) {
                          widget.onChanged(category);
                          _hideOverlay();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.label.trim().isNotEmpty;
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggleOverlay,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue ? widget.label : widget.hintText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasValue
                            ? const Color(0xFF26393D)
                            : const Color(0xFFB7BBC3),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    _overlayEntry == null
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: const Color(0xFFB7BBC3),
                  ),
                ],
              ),
            ),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                widget.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPickerMenu extends StatelessWidget {
  const _CategoryPickerMenu({
    required this.searchController,
    required this.categories,
    required this.onSearchChanged,
    required this.onSelected,
  });

  final TextEditingController searchController;
  final List<ItemCategory> categories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ItemCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 286),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E4EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: '搜索分类',
                  hintStyle: const TextStyle(
                    color: Color(0xFFB7BBC3),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFAEB5BE),
                    size: 20,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 38),
                  filled: true,
                  fillColor: const Color(0xFFF0F1F6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            child: categories.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      '没有匹配分类',
                      style: TextStyle(color: Color(0xFF9CA4AE)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 6),
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return InkWell(
                        onTap: () => onSelected(category),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          child: Text(
                            category.name,
                            style: const TextStyle(
                              color: Color(0xFF26393D),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
