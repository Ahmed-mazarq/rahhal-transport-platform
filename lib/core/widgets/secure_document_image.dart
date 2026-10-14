import 'package:flutter/material.dart';
import '../services/storage/document_resolver_service.dart';

class SecureDocumentImage extends StatefulWidget {
  final String storedReference;
  final BoxFit fit;
  final Widget? placeholder;
  final void Function(bool success)? onLoaded;

  const SecureDocumentImage({
    super.key,
    required this.storedReference,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.onLoaded,
  });

  @override
  State<SecureDocumentImage> createState() => _SecureDocumentImageState();
}

class _SecureDocumentImageState extends State<SecureDocumentImage> {
  final _resolver = DocumentResolverService();
  String? _resolvedUrl;
  String? _error;
  bool _isLoading = true;
  bool _reportedSuccess = false;

  @override
  void initState() {
    super.initState();
    _resolveDocument();
  }

  @override
  void didUpdateWidget(covariant SecureDocumentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedReference != widget.storedReference) {
      _resolveDocument();
    }
  }

  Future<void> _resolveDocument() async {
    _reportedSuccess = false;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await _resolver.resolve(widget.storedReference);
      if (mounted) {
        setState(() {
          _resolvedUrl = doc.resolvedUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
        widget.onLoaded?.call(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _resolvedUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.grey, size: 40),
            const SizedBox(height: 8),
            Text(
              _error ?? 'المرفق غير موجود في التخزين',
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              onPressed: _resolveDocument,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Image.network(
      _resolvedUrl!,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ??
            const Center(child: CircularProgressIndicator());
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame != null) {
          if (!_reportedSuccess) {
            _reportedSuccess = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onLoaded?.call(true);
            });
          }
          return child;
        }
        return widget.placeholder ??
            const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        if (!_reportedSuccess) {
          _reportedSuccess = true; // Prevent multiple calls
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onLoaded?.call(false);
          });
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, color: Colors.grey, size: 40),
              const SizedBox(height: 8),
              const Text(
                'تعذر تحميل الصورة',
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              TextButton.icon(
                onPressed: _resolveDocument,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
