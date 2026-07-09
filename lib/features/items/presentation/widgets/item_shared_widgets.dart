import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/item.dart';

class ItemImageFrame extends StatefulWidget {
  const ItemImageFrame({
    super.key,
    required this.item,
    required this.size,
    required this.iconSize,
    this.borderRadius = 16,
  });

  final Item item;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  State<ItemImageFrame> createState() => _ItemImageFrameState();
}

class _ItemImageFrameState extends State<ItemImageFrame> {
  var _failedUrlCount = 0;

  @override
  void didUpdateWidget(covariant ItemImageFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.imageUrls.join('\n') !=
        widget.item.imageUrls.join('\n')) {
      _failedUrlCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.item.imageUrls;
    final imageUrl = _failedUrlCount < imageUrls.length
        ? imageUrls[_failedUrlCount]
        : '';
    if (imageUrl.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _DefaultItemCover(iconSize: widget.iconSize),
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              debugPrint(
                '[picpac.item.image] failed url=$imageUrl error=$error',
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _failedUrlCount < imageUrls.length) {
                setState(() => _failedUrlCount += 1);
              }
            });
            return _DefaultItemCover(iconSize: widget.iconSize);
          },
        ),
      ),
    );
  }
}

class _DefaultItemCover extends StatelessWidget {
  const _DefaultItemCover({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/common/gift_box.png',
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
      ),
    );
  }
}

class ItemErrorState extends StatelessWidget {
  const ItemErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/common/empty.svg', height: 96),
            const SizedBox(height: 20),
            const Text('加载失败', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class ItemSuccessBanner extends StatelessWidget {
  const ItemSuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: Color(0xFF36C4C3), size: 24),
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

class ItemSheetHeader extends StatelessWidget {
  const ItemSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
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
            top: 25,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: -9,
            top: 18,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              iconSize: 24,
              color: const Color(0xFF33363D),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemSheetActionButton extends StatelessWidget {
  const ItemSheetActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 4,
          shadowColor: const Color(0x22000000),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
