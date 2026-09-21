import '../../localization/localization.dart';
import 'package:flutter/material.dart';

/// Retries only after an image failure, keeping the original request URL.
class CatalogNetworkImage extends StatefulWidget {
  const CatalogNetworkImage(
      {super.key,
      this.url,
      this.imageKey,
      this.placeholder = Icons.image_outlined});
  final String? url;
  final Key? imageKey;
  final IconData placeholder;

  @override
  State<CatalogNetworkImage> createState() => _CatalogNetworkImageState();
}

class _CatalogNetworkImageState extends State<CatalogNetworkImage> {
  int _attempt = 0;
  bool _retrying = false;

  Future<void> _retry(NetworkImage provider) async {
    if (_retrying) return;
    _retrying = true;
    try {
      await provider.evict();
      if (mounted && widget.url == provider.url) {
        setState(() => _attempt++);
      }
    } finally {
      _retrying = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url == null || url.isEmpty) {
      return Center(
          child: Icon(widget.placeholder, key: widget.imageKey, size: 36));
    }
    final provider = NetworkImage(url);
    return KeyedSubtree(
      key: ValueKey((url, _attempt)),
      child: Image(
        key: widget.imageKey,
        image: provider,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, synchronous) =>
            synchronous || frame != null
                ? child
                : Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, semanticsLabel: context.l10n.catalogImageLoading))),
        errorBuilder: (context, error, stack) => Center(
          child: IconButton(
            tooltip: context.l10n.catalogImageRetry,
            onPressed: () => _retry(provider),
            icon: Icon(Icons.refresh, size: 28),
          ),
        ),
      ),
    );
  }
}
