import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/core/providers/repository_providers.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import 'package:rahal/features/parcel/domain/models/parcel_delivery.dart';
import 'package:rahal/features/trips/domain/models/chat_message.dart';
import 'package:intl/intl.dart';

class ParcelChatScreen extends ConsumerStatefulWidget {
  final ParcelDelivery parcel;

  const ParcelChatScreen({super.key, required this.parcel});

  @override
  ConsumerState<ParcelChatScreen> createState() => _ParcelChatScreenState();
}

class _ParcelChatScreenState extends ConsumerState<ParcelChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        ref
            .read(parcelChatRepositoryProvider)
            .markMessagesAsRead(widget.parcel.id, authState.user.id)
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    setState(() => _isSending = true);

    try {
      final chatRepo = ref.read(parcelChatRepositoryProvider);
      await chatRepo.sendParcelMessage(
        parcelId: widget.parcel.id,
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
    final isPassenger = widget.parcel.senderId == userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isPassenger ? 'محادثة مع السائق' : 'محادثة مع مرسل الطرد',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header info about the parcel
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'رقم التتبع: ${widget.parcel.trackingNumber}',
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
                  .read(parcelChatRepositoryProvider)
                  .watchParcelChatMessages(widget.parcel.id),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              Text(
                                message.senderName,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              message.content,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(message.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.grey[500],
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

          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        hintStyle: const TextStyle(fontFamily: 'Cairo'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isSending)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
