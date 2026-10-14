import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/booking.dart';
import '../../domain/models/chat_message.dart';
import '../../../support/presentation/widgets/support_attachment_preview.dart';

class BookingChatScreen extends ConsumerStatefulWidget {
  final Booking booking;

  const BookingChatScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingChatScreen> createState() => _BookingChatScreenState();
}

class _BookingChatScreenState extends ConsumerState<BookingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        ref
            .read(bookingChatRepositoryProvider)
            .markMessagesAsRead(widget.booking.id, authState.user.id)
            .catchError((e) {
              debugPrint('Error marking messages as read: $e');
            });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndSendImage() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isSending = true);

    try {
      final storage = SupabaseStorageService();
      // Determine if user is passenger or driver for folder prefix
      final role = widget.booking.passengerId == authState.user.id
          ? 'passenger'
          : 'driver';

      final xfile = XFile(pickedFile.path);
      final size = await xfile.length();
      final ext = p.extension(xfile.name).toLowerCase();
      final mimeType = ext == '.png'
          ? 'image/png'
          : (ext == '.webp' ? 'image/webp' : 'image/jpeg');

      String? uploadedUrl;
      try {
        uploadedUrl = await storage.uploadBookingChatAttachment(
          role,
          authState.user.id,
          widget.booking.id,
          xfile,
        );
      } catch (uploadError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'فشل رفع الصورة: $uploadError',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        }
        return;
      }

      try {
        final chatRepo = ref.read(bookingChatRepositoryProvider);
        await chatRepo.sendBookingMessage(
          bookingId: widget.booking.id,
          senderId: authState.user.id,
          senderName: authState.user.fullName,
          content: 'صورة مرفقة',
          attachmentUrl: uploadedUrl,
          attachmentName: xfile.name,
          attachmentSize: size,
          mimeType: mimeType,
        );
      } catch (dbError) {
        debugPrint(
          '[BOOKING_CHAT_ATTACHMENT] Failed to save message to Firestore: $dbError',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر إرسال الرسالة، يرجى المحاولة مرة أخرى.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          );
        }
        // Ideally we would delete the uploaded file here, but since it's an edge case we log it.
        // await storage.deleteFile(uploadedUrl); // Future enhancement if needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ غير متوقع: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    setState(() => _isSending = true);

    try {
      final chatRepo = ref.read(bookingChatRepositoryProvider);
      await chatRepo.sendBookingMessage(
        bookingId: widget.booking.id,
        senderId: authState.user.id,
        senderName: authState.user.fullName,
        content: text,
      );
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر إرسال الرسالة',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState is Authenticated ? authState.user.id : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثة', style: TextStyle(fontFamily: 'Cairo')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header info about the booking
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'رقم الحجز: ${widget.booking.id.substring(0, 5).toUpperCase()}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ref
                  .read(bookingChatRepositoryProvider)
                  .watchBookingChatMessages(widget.booking.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'حدث خطأ أثناء تحميل الرسائل',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد رسائل بعد.\nابدأ المحادثة الآن!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == userId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                            bottomLeft: !isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.attachmentUrl != null)
                              SupportAttachmentPreview(
                                attachmentUrl: message.attachmentUrl,
                                attachmentName: message.attachmentName,
                                attachmentSize: message.attachmentSize,
                                mimeType: message.mimeType,
                                bookingId: widget.booking.id,
                              ),
                            if (message.content.isNotEmpty)
                              Text(
                                message.content,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'hh:mm a',
                                'ar',
                              ).format(message.timestamp),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _isSending ? null : _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
