import 'package:flutter/material.dart';

class ImagePreview extends StatelessWidget {
  const ImagePreview({
    super.key,
    required this.sourceUrl,
    required this.child,
    this.fallbackAsset,
  });

  final String sourceUrl;
  final String? fallbackAsset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: sourceUrl.isEmpty && fallbackAsset == null
          ? null
          : () => Navigator.of(context, rootNavigator: true).push<void>(
              MaterialPageRoute(
                builder: (_) => _FullscreenImage(
                  url: sourceUrl,
                  fallbackAsset: fallbackAsset,
                ),
                fullscreenDialog: true,
              ),
            ),
      child: child,
    );
  }
}

class _FullscreenImage extends StatelessWidget {
  const _FullscreenImage({required this.url, this.fallbackAsset});

  final String url;
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: url.isEmpty && fallbackAsset != null
                      ? Image.asset(fallbackAsset!, fit: BoxFit.contain)
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          errorBuilder: (context, error, stackTrace) =>
                              const Text(
                                '原图加载失败，请返回后重试',
                                style: TextStyle(color: Colors.white),
                              ),
                        ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: '关闭原图',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
