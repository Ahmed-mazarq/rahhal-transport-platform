import 'package:flutter/material.dart';
import 'package:rahal/features/common/models/verification_document.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rahal/core/services/storage/document_resolver_service.dart';
import 'package:rahal/core/widgets/secure_document_image.dart';

import 'package:rahal/features/common/constants/document_labels.dart';

class DocumentViewerScreen extends StatefulWidget {
  final List<MapEntry<String, VerificationDocument>> documents;
  final int initialIndex;

  const DocumentViewerScreen({
    super.key,
    required this.documents,
    required this.initialIndex,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty || url.contains('placehold.co')) return;
    try {
      final resolvedUrl = await DocumentResolverService().resolveDocumentUrl(
        url,
      );
      final uri = Uri.parse(resolvedUrl);
      if (!await launchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('لا يمكن فتح الرابط')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في فتح الرابط: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.documents.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('المستندات')),
        body: const Center(child: Text('لا توجد مستندات لعرضها')),
      );
    }

    final currentDocEntry = widget.documents[_currentIndex];
    final title = currentDocEntry.key;
    final doc = currentDocEntry.value;
    final displayTitle = DocumentLabels.getLabel(title);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'تاريخ الرفع: ${DateFormat('yyyy-MM-dd HH:mm').format(doc.updatedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'فتح وتنزيل',
            onPressed: doc.url.contains('placehold.co')
                ? null
                : () => _openUrl(doc.url),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'فتح في نافذة جديدة',
            onPressed: doc.url.contains('placehold.co')
                ? null
                : () => _openUrl(doc.url),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentIndex + 1} / ${widget.documents.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.documents.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final document = widget.documents[index].value;
              final isPlaceholder =
                  document.url.isEmpty || document.url.contains('placehold.co');

              if (isPlaceholder) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'الصورة غير متوفرة',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return _ZoomableImage(
                storedReference: document.url,
                tag: 'doc_${widget.documents[index].key}',
              );
            },
          ),

          // Navigation Overlays
          if (_currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          if (_currentIndex < widget.documents.length - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String storedReference;
  final String tag;

  const _ZoomableImage({required this.storedReference, required this.tag});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final matrix = Matrix4.identity();
      matrix.setEntry(0, 0, 3.0); // scale X
      matrix.setEntry(1, 1, 3.0); // scale Y
      matrix.setEntry(2, 2, 1.0); // scale Z
      matrix.setEntry(0, 3, -position.dx * 2); // translate X
      matrix.setEntry(1, 3, -position.dy * 2); // translate Y
      _transformationController.value = matrix;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Hero(
            tag: widget.tag,
            child: SecureDocumentImage(
              storedReference: widget.storedReference,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
