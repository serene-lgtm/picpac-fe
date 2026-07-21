import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../items/data/item.dart';
import '../../data/checklist.dart';
import 'checklist_theme.dart';

class ChecklistDetailMeta extends StatelessWidget {
  const ChecklistDetailMeta({
    super.key,
    required this.checklist,
    required this.checked,
  });

  final Checklist checklist;
  final int checked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          checklistDisplayDate(checklist.targetDate),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        const Spacer(),
        const Icon(Icons.checklist_rounded, size: 15, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          '已完成 $checked/${checklist.items.length} 项',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}

class ChecklistDetailSectionTitle extends StatelessWidget {
  const ChecklistDetailSectionTitle({super.key, required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '装备清单',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onSearch,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class ChecklistLineCard extends StatelessWidget {
  const ChecklistLineCard({
    super.key,
    required this.line,
    required this.item,
    required this.updating,
    required this.removeMode,
    required this.removeSelected,
    required this.onTap,
    required this.onToggle,
  });

  final ChecklistLineItem line;
  final Item? item;
  final bool updating;
  final bool removeMode;
  final bool removeSelected;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final name =
        item?.name ?? (line.snapshotName.isEmpty ? '物品' : line.snapshotName);
    final selected = removeMode ? removeSelected : line.checked;
    return Material(
      color: checklistCardColor,
      borderRadius: BorderRadius.circular(7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              const SizedBox(width: 30),
              Image.asset(checklistGiftAsset, width: 46, height: 46),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: line.checked
                        ? const Color(0xFF8E9D98)
                        : Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    decoration: line.checked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: updating ? null : onToggle,
                icon: updating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : CircleAvatar(
                        radius: 11,
                        backgroundColor: selected
                            ? checklistPrimary
                            : Colors.transparent,
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFC7CDD2),
                                  ),
                                ),
                              ),
                      ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class ChecklistMoreActionsSheet extends StatelessWidget {
  const ChecklistMoreActionsSheet({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetAction(label: '编辑清单', onTap: onEdit),
            _SheetAction(
              label: '删除清单',
              color: const Color(0xFFFF4D4F),
              onTap: onDelete,
            ),
            const Divider(height: 8, thickness: 8, color: Color(0xFFF3F3F6)),
            _SheetAction(label: '取消', onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

class DeleteChecklistDialog extends StatelessWidget {
  const DeleteChecklistDialog({
    super.key,
    this.title = '确认删除该清单吗？',
    this.confirmLabel = '删除',
  });

  final String title;
  final String confirmLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 54),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 34, 28, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/common/trash.svg',
              width: 126,
              height: 126,
              semanticsLabel: confirmLabel,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
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
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChecklistSuccessToast extends StatelessWidget {
  const ChecklistSuccessToast({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_rounded, color: checklistPrimary, size: 22),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(
              color: checklistPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: color ?? Colors.black),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
