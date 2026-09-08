import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../data/item.dart';
import '../../../../shared/widgets/fullscreen_image.dart';

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
    List<MultipartFilePart> photos,
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
  late List<ItemPhoto> _existingPhotos;
  final List<_PendingItemPhoto> _newPhotos = [];
  String? _selectedCategoryId;
  bool _submitting = false;
  bool _pickingPhotos = false;
  String? _error;

  static const _maxPhotos = 6;
  static const _photoMaxDimension = 1600.0;
  static const _photoQuality = 82;
  static const _previewCacheSize = 156;

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
    _existingPhotos = item?.photos ?? const [];
    if (item != null) {
      _nameController.text = item.name;
      _descriptionController.text = item.description;
      _selectedCategoryId = item.categoryId.isNotEmpty ? item.categoryId : null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _submitting || _pickingPhotos) {
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
        await _photoParts(),
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
    if (_photoCount >= _maxPhotos || _pickingPhotos || _submitting) return;
    setState(() => _pickingPhotos = true);
    try {
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
      if (source == null || !mounted) return;
      final remaining = _maxPhotos - _photoCount;
      final List<XFile> images;
      if (source == ImageSource.gallery && remaining > 1) {
        images = await _imagePicker.pickMultiImage(
          maxWidth: _photoMaxDimension,
          maxHeight: _photoMaxDimension,
          imageQuality: _photoQuality,
          requestFullMetadata: false,
          limit: remaining,
        );
      } else {
        final image = await _imagePicker.pickImage(
          source: source,
          maxWidth: _photoMaxDimension,
          maxHeight: _photoMaxDimension,
          imageQuality: _photoQuality,
          requestFullMetadata: false,
        );
        images = image == null ? [] : [image];
      }
      for (final image in images.take(remaining)) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          _newPhotos.add(
            _PendingItemPhoto(
              fileName: image.name,
              contentType: _contentTypeFor(image.name),
              bytes: bytes,
            ),
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '照片添加失败，请重试');
      }
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  int get _photoCount => _existingPhotos.length + _newPhotos.length;

  bool get _photoListChanged {
    final initialPhotos = widget.initialItem?.photos ?? const <ItemPhoto>[];
    if (_newPhotos.isNotEmpty) return true;
    if (_existingPhotos.length != initialPhotos.length) return true;
    for (var index = 0; index < initialPhotos.length; index += 1) {
      if (_existingPhotos[index].id != initialPhotos[index].id) return true;
    }
    return false;
  }

  Future<List<MultipartFilePart>> _photoParts() async {
    if (!_photoListChanged) return const [];
    if (_photoCount == 0 && (widget.initialItem?.photos.isNotEmpty ?? false)) {
      throw StateError('当前接口暂不支持清空所有照片，请至少保留一张照片或新增一张照片');
    }
    final parts = <MultipartFilePart>[];
    for (final photo in _existingPhotos) {
      final url = photo.bestSourceUrl;
      if (url.isEmpty) continue;
      parts.add(
        MultipartFilePart(
          fieldName: 'photos',
          fileName: _fileNameForRemotePhoto(photo),
          contentType: _contentTypeFor(url),
          bytes: _readRemotePhoto(url),
        ),
      );
    }
    for (final photo in _newPhotos) {
      parts.add(
        MultipartFilePart(
          fieldName: 'photos',
          fileName: photo.fileName,
          contentType: photo.contentType,
          bytes: Future.value(photo.bytes),
        ),
      );
    }
    return parts;
  }

  Future<List<int>> _readRemotePhoto(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('图片读取失败', uri: Uri.parse(url));
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  String _fileNameForRemotePhoto(ItemPhoto photo) {
    final extension = _extensionFor(photo.bestSourceUrl);
    final id = photo.id.isEmpty ? 'existing' : photo.id;
    return '$id$extension';
  }

  String _extensionFor(String fileNameOrUrl) {
    final lower = fileNameOrUrl.toLowerCase().split('?').first;
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.gif')) return '.gif';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    return '.jpg';
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
                _PhotoPickerGrid(
                  existingPhotos: _existingPhotos,
                  newPhotos: _newPhotos,
                  enabled: !_submitting && !_pickingPhotos,
                  maxPhotos: _maxPhotos,
                  onAdd: _pickImage,
                  onRemoveExisting: (index) {
                    setState(() {
                      _existingPhotos = [
                        ..._existingPhotos.take(index),
                        ..._existingPhotos.skip(index + 1),
                      ];
                    });
                  },
                  onRemoveNew: (index) {
                    setState(() => _newPhotos.removeAt(index));
                  },
                ),
                if (widget.initialItem == null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '照片（选填）',
                    style: TextStyle(color: Color(0xFF9CA4AE), fontSize: 13),
                  ),
                ],
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
                      onPressed: _submitting || _pickingPhotos ? null : _submit,
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

class _PhotoPickerGrid extends StatelessWidget {
  const _PhotoPickerGrid({
    required this.existingPhotos,
    required this.newPhotos,
    required this.enabled,
    required this.maxPhotos,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<ItemPhoto> existingPhotos;
  final List<_PendingItemPhoto> newPhotos;
  final bool enabled;
  final int maxPhotos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  @override
  Widget build(BuildContext context) {
    final total = existingPhotos.length + newPhotos.length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var index = 0; index < existingPhotos.length; index += 1)
          _PhotoTile(
            enabled: enabled,
            onRemove: () => onRemoveExisting(index),
            child: _RemotePhotoImage(photo: existingPhotos[index]),
          ),
        for (var index = 0; index < newPhotos.length; index += 1)
          _PhotoTile(
            enabled: enabled,
            onRemove: () => onRemoveNew(index),
            child: Image.memory(
              newPhotos[index].bytes,
              fit: BoxFit.cover,
              cacheWidth: _AddItemSheetState._previewCacheSize,
              cacheHeight: _AddItemSheetState._previewCacheSize,
              gaplessPlayback: true,
            ),
          ),
        if (total < maxPhotos) _AddPhotoTile(enabled: enabled, onTap: onAdd),
      ],
    );
  }
}

class _PendingItemPhoto {
  const _PendingItemPhoto({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.child,
    required this.enabled,
    required this.onRemove,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFC5CC), width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
          Positioned(
            right: -7,
            top: -7,
            child: GestureDetector(
              onTap: enabled ? onRemove : null,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5757),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemotePhotoImage extends StatelessWidget {
  const _RemotePhotoImage({required this.photo});

  final ItemPhoto photo;

  @override
  Widget build(BuildContext context) {
    final imageUrl = photo.bestDisplayUrl;
    if (imageUrl.isEmpty) {
      return const Icon(
        Icons.photo_camera_outlined,
        color: Color(0xFF4DBDBB),
        size: 30,
      );
    }
    return ImagePreview(
      sourceUrl: photo.bestSourceUrl,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        cacheWidth: _AddItemSheetState._previewCacheSize,
        cacheHeight: _AddItemSheetState._previewCacheSize,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.photo_camera_outlined,
            color: Color(0xFF4DBDBB),
            size: 30,
          );
        },
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: CustomPaint(
        painter: _DashedPhotoBorderPainter(
          color: enabled ? const Color(0xFFBFC5CC) : const Color(0xFFE1E4EA),
          radius: 12,
        ),
        child: Container(
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            color: enabled ? const Color(0xFF4DBDBB) : const Color(0xFFB7BBC3),
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _DashedPhotoBorderPainter extends CustomPainter {
  const _DashedPhotoBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 5;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPhotoBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
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
