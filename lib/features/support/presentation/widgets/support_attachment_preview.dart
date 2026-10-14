import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';

class SupportAttachmentPreview extends StatefulWidget {
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? mimeType;
  final DateTime? createdAt;
  final String? senderName;
  final String? bookingId;

  const SupportAttachmentPreview({
    super.key,
    required this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.mimeType,
    this.createdAt,
    this.senderName,
    this.bookingId,
  });

  @override
  State<SupportAttachmentPreview> createState() =>
      _SupportAttachmentPreviewState();
}

class _SupportAttachmentPreviewState extends State<SupportAttachmentPreview> {
  String? _resolvedUrl;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  @override
  void didUpdateWidget(covariant SupportAttachmentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachmentUrl != widget.attachmentUrl) {
      _resolveUrl();
    }
  }

  Future<void> _resolveUrl() async {
    if (widget.attachmentUrl == null || widget.attachmentUrl!.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Import needed manually if not present, assume it is or will be added
      final storageService = SupabaseStorageService();
      final url = await storageService.resolveAttachmentUrl(
        widget.attachmentUrl,
        bookingId: widget.bookingId,
      );
      if (mounted) {
        setState(() {
          _resolvedUrl = url;
          _isLoading = false;
          _hasError = url == null || url.isEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error resolving attachment URL: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  bool get isImage {
    final ext = widget.mimeType?.toLowerCase() ?? '';
    return [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'image/jpeg',
          'image/png',
          'image/gif',
          'image/webp',
        ].contains(ext) ||
        ext.startsWith('image/');
  }

  bool get isVideo {
    final ext = widget.mimeType?.toLowerCase() ?? '';
    return [
          'mp4',
          'mov',
          'avi',
          'video/mp4',
          'video/quicktime',
        ].contains(ext) ||
        ext.startsWith('video/');
  }

  void _showImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'معلومات المرفق',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text('الاسم: ${widget.attachmentName ?? 'غير معروف'}'),
                  Text(
                    'الحجم: ${widget.attachmentSize != null ? "${(widget.attachmentSize! / 1024).toStringAsFixed(2)} KB" : 'غير متوفر'}',
                  ),
                  if (widget.senderName != null)
                    Text('المرسل: ${widget.senderName}'),
                  if (widget.createdAt != null)
                    Text(
                      'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.createdAt!)}',
                    ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _hasError || _resolvedUrl == null
                    ? Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(32),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 50,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'فشل تحميل الصورة',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      )
                    : Image.network(
                        _resolvedUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(32),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 50,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'فشل تحميل الصورة',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Container(
              color: Colors.white,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            GestureDetector(
              onTap: () {
                if (!_isLoading && !_hasError && _resolvedUrl != null) {
                  _showImageViewer(context);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isLoading
                    ? const SizedBox(
                        height: 150,
                        width: 200,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _hasError || _resolvedUrl == null
                    ? Container(
                        height: 150,
                        width: 200,
                        color: Colors.black12,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.red,
                        ),
                      )
                    : Image.network(
                        _resolvedUrl!,
                        height: 150,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                      ),
              ),
            )
          else if (isVideo)
            Container(
              height: 150,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insert_drive_file),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.attachmentName ?? 'ملف مرفق',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (!isImage) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _isLoading || _hasError || _resolvedUrl == null
                      ? null
                      : () async {
                          final uri = Uri.parse(_resolvedUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('فتح'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
