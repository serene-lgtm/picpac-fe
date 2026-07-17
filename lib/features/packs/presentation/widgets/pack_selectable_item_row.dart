part of '../pages/create_pack_page.dart';

class _SelectableItemRow extends StatelessWidget {
  const _SelectableItemRow({
    required this.item,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  final Item item;
  final bool selected;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(28, 8, 14, 8),
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
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: disabled ? const Color(0xFF8F8F96) : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
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
            selected
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: disabled
                        ? const Color(0xFFB8DCD9)
                        : const Color(0xFF48B8B4),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                : Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC8C8D0),
                        width: 1.4,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
