part of '../pages/create_pack_page.dart';

class _PackLoadError extends StatelessWidget {
  const _PackLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _PickerTopBar extends StatelessWidget {
  const _PickerTopBar({
    required this.submitting,
    required this.onBack,
    required this.onDone,
    this.doneLabel,
    this.doneColor,
  });

  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback? onDone;
  final String? doneLabel;
  final Color? doneColor;

  @override
  Widget build(BuildContext context) {
    if (submitting) {
      return const ModuleTopBar(
        title: '选择物品',
        leading: Icons.chevron_left_rounded,
        trailingText: '',
      );
    }
    return ModuleTopBar(
      title: '选择物品',
      leading: Icons.chevron_left_rounded,
      trailingText: doneLabel ?? '完成',
      trailingTextColor: doneColor ?? Colors.white,
      onLeadingTap: onBack,
      onTrailingTap: onDone,
    );
  }
}

class _PackSearchField extends StatefulWidget {
  const _PackSearchField({required this.controller, required this.onChanged});

  final TextEditingController? controller;
  final VoidCallback onChanged;

  @override
  State<_PackSearchField> createState() => _PackSearchFieldState();
}

class _PackSearchFieldState extends State<_PackSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant _PackSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller?.removeListener(_handleControllerChanged);
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearSearch() {
    final controller = widget.controller;
    if (controller == null || controller.text.isEmpty) return;
    controller.clear();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller?.text.isNotEmpty == true;
    return SizedBox(
      height: 52,
      child: TextField(
        controller: widget.controller,
        onChanged: (_) => widget.onChanged(),
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFC3C5CC),
            size: 28,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: const CircleAvatar(
                    radius: 8,
                    backgroundColor: Color(0xFFC9C9CF),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                  tooltip: '清空',
                )
              : null,
          hintText: '',
          hintStyle: const TextStyle(
            color: Color(0xFFB8B8C4),
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _PickerError extends StatelessWidget {
  const _PickerError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _PackTopBar extends StatelessWidget {
  const _PackTopBar({
    required this.title,
    required this.trailing,
    this.leading,
    this.onLeadingTap,
    this.onTrailingTap,
  });

  final String title;
  final IconData trailing;
  final IconData? leading;
  final VoidCallback? onLeadingTap;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return ModuleTopBar(
      title: title,
      leading: leading,
      trailing: trailing,
      onLeadingTap: onLeadingTap,
      onTrailingTap: onTrailingTap,
    );
  }
}

class _PackDetailBottomActions extends StatelessWidget {
  const _PackDetailBottomActions({required this.onAdd, required this.onRemove});

  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFF7FFF8),
        border: Border(top: BorderSide(color: Color(0xFFE7E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: onAdd,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF60716F),
              ),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: Text('添加'),
                ),
              ),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 28),
                  child: Text('移除'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackDetailItemCard extends StatelessWidget {
  const _PackDetailItemCard({
    required this.name,
    required this.description,
    this.onTap,
  });

  final String name;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(28, 8, 18, 8),
        decoration: BoxDecoration(
          color: _packCardColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/common/gift_box.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF646A6A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackGradientBackground extends StatelessWidget {
  const _PackGradientBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _packGradientColors,
        ),
      ),
      child: child,
    );
  }
}

class _PackSuccessBanner extends StatelessWidget {
  const _PackSuccessBanner({this.message = '添加成功'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFF36C4C3), size: 22),
          const SizedBox(width: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF36C4C3),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
