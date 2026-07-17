part of '../pages/create_pack_page.dart';

class _EditPackNameSheet extends StatefulWidget {
  const _EditPackNameSheet({
    required this.initialName,
    required this.saving,
    required this.onSave,
  });

  final String initialName;
  final bool saving;
  final ValueChanged<String> onSave;

  @override
  State<_EditPackNameSheet> createState() => _EditPackNameSheetState();
}

class _EditPackNameSheetState extends State<_EditPackNameSheet> {
  late final TextEditingController _controller;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorText = _touched ? _packNameError(_controller.text.trim()) : null;
    final length = _controller.text.characters.length;
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                    ),
                    Text(
                      '修改套组名',
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
                    controller: _controller,
                    maxLength: _packNameMaxLength,
                    onChanged: (_) => setState(() => _touched = true),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: widget.initialName,
                      hintStyle: const TextStyle(
                        color: Color(0xFFB8B8C4),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F0F6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      errorText: errorText == null ? null : '',
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: errorText == null
                          ? const SizedBox.shrink()
                          : Text(
                              errorText,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFFE45B5B),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                    ),
                    Text(
                      '$length/$_packNameMaxLength',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9B9BA3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 44,
                    child: FilledButton(
                      onPressed: widget.saving
                          ? null
                          : () {
                              setState(() => _touched = true);
                              if (!_isValidPackName(_controller.text.trim())) {
                                return;
                              }
                              widget.onSave(_controller.text);
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF48B8B4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        widget.saving ? '保存中...' : '保存',
                        style: const TextStyle(
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
      ),
    );
  }
}
