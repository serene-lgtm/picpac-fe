import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({super.key, required this.onSubmit});

  final Future<void> Function(
    String name,
    String description,
    MultipartFilePart? image,
  )
  onSubmit;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  XFile? _image;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      await widget.onSubmit(
        _nameController.text.trim(),
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
        Navigator.of(context).pop(true);
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
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      '添加物品',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _FieldLabel('名称 *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: '例如：手机'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入物品名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const _FieldLabel('描述（选填）'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: '添加描述...'),
                ),
                const SizedBox(height: 18),
                const _FieldLabel('照片（选填）'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _submitting ? null : _pickImage,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5F4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _image == null
                        ? const Icon(Icons.add_photo_alternate_outlined)
                        : Image.file(File(_image!.path), fit: BoxFit.cover),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_submitting ? '保存中' : '保存'),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: const Color(0xFF4A6260),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
