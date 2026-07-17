part of '../pages/create_pack_page.dart';

class CreatePackPage extends StatefulWidget {
  const CreatePackPage({
    super.key,
    required this.itemRepository,
    required this.packRepository,
  });

  final ItemRepository itemRepository;
  final PackRepository packRepository;

  @override
  State<CreatePackPage> createState() => _CreatePackPageState();
}

class _CreatePackPageState extends State<CreatePackPage> {
  final _packNameController = TextEditingController();
  bool _nameTouched = false;

  @override
  void dispose() {
    _packNameController.dispose();
    super.dispose();
  }

  void _goNext() {
    setState(() => _nameTouched = true);
    final name = _packNameController.text.trim();
    if (!_isValidPackName(name)) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute<void>(
        builder: (context) => PackItemPickerPage(
          packName: name,
          itemRepository: widget.itemRepository,
          packRepository: widget.packRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CreatePackNameSheet(
      controller: _packNameController,
      errorText: _nameTouched
          ? _packNameError(_packNameController.text.trim())
          : null,
      onChanged: () => setState(() {}),
      onClose: () => Navigator.of(context).pop(),
      onNext: _goNext,
    );
  }
}

class _CreatePackNameSheet extends StatelessWidget {
  const _CreatePackNameSheet({
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onClose,
    required this.onNext,
  });

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onChanged;
  final VoidCallback onClose;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: const Color(0x33000000),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D4DC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ),
                  Text(
                    '新建套组',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 42,
                child: TextField(
                  controller: controller,
                  maxLength: _packNameMaxLength,
                  onChanged: (_) => onChanged(),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '为你的套组取个名字',
                    hintStyle: const TextStyle(
                      color: Color(0xFFB8B8C4),
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F0F6),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorText == null ? null : '',
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE45B5B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Center(
                child: SizedBox(
                  width: 160,
                  height: 44,
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF48B8B4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      '下一步',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _PackMoreActionsSheet extends StatelessWidget {
  const _PackMoreActionsSheet({
    required this.deleting,
    required this.onEditName,
    required this.onDelete,
  });

  final bool deleting;
  final VoidCallback onEditName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              child: TextButton(
                onPressed: onEditName,
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text(
                  '修改套组名',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: TextButton(
                onPressed: deleting ? null : onDelete,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(
                  deleting ? '删除中...' : '删除套组',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Divider(height: 8, thickness: 8, color: Color(0xFFF3F3F6)),
            SizedBox(
              height: 64,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text(
                  '取消',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isValidPackName(String name) => _packNameError(name) == null;

String? _packNameError(String name) {
  if (name.trim().isEmpty) return '请输入套组名';
  if (name.characters.length > _packNameMaxLength) {
    return '套组名不能超过$_packNameMaxLength个字符';
  }
  return null;
}

Future<bool?> _showPackDeleteDialog({
  required BuildContext context,
  required String title,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (context) {
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
}
