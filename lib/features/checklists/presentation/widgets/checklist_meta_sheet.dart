import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'checklist_common_widgets.dart';
import 'checklist_theme.dart';

class ChecklistDraft {
  const ChecklistDraft({
    required this.name,
    required this.targetDate,
    this.description = '',
  });

  final String name;
  final String targetDate;
  final String description;
}

class ChecklistMetaSheet extends StatefulWidget {
  const ChecklistMetaSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initialDraft,
    this.saving = false,
  });

  final String title;
  final String submitLabel;
  final ChecklistDraft? initialDraft;
  final bool saving;
  final ValueChanged<ChecklistDraft> onSubmit;

  @override
  State<ChecklistMetaSheet> createState() => _ChecklistMetaSheetState();
}

class _ChecklistMetaSheetState extends State<ChecklistMetaSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late DateTime? _targetDate;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _nameController = TextEditingController(text: draft?.name ?? '');
    _descriptionController = TextEditingController(
      text: draft?.description ?? '',
    );
    _targetDate = DateTime.tryParse(draft?.targetDate ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _targetDateText {
    final date = _targetDate;
    if (date != null) return checklistApiDate(date);
    return widget.initialDraft?.targetDate ?? '';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  void _submit() {
    setState(() => _touched = true);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _targetDateText.isEmpty
        ? checklistApiDate(DateTime.now())
        : _targetDateText;
    if (name.isEmpty || widget.saving) return;
    widget.onSubmit(
      ChecklistDraft(name: name, targetDate: date, description: description),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missingName = _touched && _nameController.text.trim().isEmpty;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDADDE2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SheetField(
                  controller: _nameController,
                  hintText: '输入名称...',
                  maxLength: 20,
                  error: missingName,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 14),
                _DateField(text: _targetDateText, onTap: _pickDate),
                const SizedBox(height: 14),
                _SheetField(
                  controller: _descriptionController,
                  hintText: '添加描述...（选填）',
                  maxLength: 200,
                  minLines: 4,
                  maxLines: 4,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                ChecklistPillButton(
                  label: widget.saving ? '保存中...' : widget.submitLabel,
                  enabled: !widget.saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.error = false,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final bool error;
  final int? minLines;
  final int maxLines;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      onChanged: (_) => onChanged?.call(),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFB7BBC2)),
        filled: true,
        fillColor: const Color(0xFFF1F2F6),
        counterText: '${controller.text.characters.length}/$maxLength',
        counterStyle: const TextStyle(color: Color(0xFFB7BBC2), fontSize: 12),
        errorText: error ? '请输入名称' : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text.isEmpty ? '选择日期（选填）' : checklistDisplayDate(text),
          style: TextStyle(
            color: text.isEmpty ? const Color(0xFFB7BBC2) : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
