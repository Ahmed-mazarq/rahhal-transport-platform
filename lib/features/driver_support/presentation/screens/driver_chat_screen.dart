import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_support_providers.dart';
import '../../domain/models/driver_conversation.dart';
import '../../domain/models/driver_ticket.dart';
import '../../domain/models/driver_message.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../../support/presentation/widgets/support_attachment_preview.dart';

class DriverChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? ticketId;

  const DriverChatScreen({super.key, this.conversationId, this.ticketId});

  @override
  ConsumerState<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends ConsumerState<DriverChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DriverConversation? _conversation;
  DriverTicket? _ticket;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initConversation();
    });
  }

  Future<void> _initConversation() async {
    setState(() => _isLoading = true);
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      final repo = ref.read(driverChatRepositoryProvider);
      try {
        String? targetConversationId = widget.conversationId;

        debugPrint('OPEN CHAT');
        debugPrint('LOAD CONVERSATION');

        if (widget.ticketId != null) {
          final supportRepo = ref.read(driverSupportRepositoryProvider);
          _ticket = await supportRepo.getTicketById(widget.ticketId!);
          if (_ticket != null &&
              targetConversationId == null &&
              _ticket!.conversationId != null) {
            targetConversationId = _ticket!.conversationId;
          }
        }

        if (targetConversationId != null) {
          _conversation = await repo.getConversationById(targetConversationId);
          if (_conversation == null) {
            if (widget.ticketId != null) {
              _conversation = await repo.createConversationForTicket(
                authState.user.uid,
                widget.ticketId!,
              );
            } else {
              _conversation = await repo.getOrCreateConversation(
                authState.user.uid,
              );
            }
          }
        } else if (widget.ticketId != null) {
          // If we have a ticketId but no conversationId at all, create one and link it
          _conversation = await repo.createConversationForTicket(
            authState.user.uid,
            widget.ticketId!,
          );
        } else {
          // Otherwise get the general one
          _conversation = await repo.getOrCreateConversation(
            authState.user.uid,
          );
        }

        if (_conversation != null) {
          await repo.markMessagesAsRead(_conversation!.conversationId);
        }
      } catch (e, st) {
        if (e is FirebaseException) {
          debugPrint('--- FIRESTORE ERROR in _initConversation ---');
          debugPrint('Code: \${e.code}');
          debugPrint('Message: \${e.message}');
          debugPrint(e.stackTrace?.toString() ?? st.toString());
        } else {
          debugPrint('Error initializing chat: \$e\\n\$st');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing chat: \$e')),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _conversation == null) return;

    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      final repo = ref.read(driverChatRepositoryProvider);

      _messageController.clear();
      try {
        await repo.sendMessage(
          _conversation!.conversationId,
          authState.user.uid,
          text,
        );
        _scrollToBottom();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
        }
      }
    }
  }

  String _getMimeType(String? extension) {
    if (extension == null) return 'application/octet-stream';
    final ext = extension.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    if (ext == 'gif') return 'image/gif';
    if (ext == 'mp4') return 'video/mp4';
    if (ext == 'mov') return 'video/quicktime';
    return 'application/octet-stream';
  }

  Future<void> _pickAndUploadAttachment() async {
    if (_conversation == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        setState(() => _isUploading = true);
        try {
          final supportRepo = ref.read(driverSupportRepositoryProvider);
          final chatRepo = ref.read(driverChatRepositoryProvider);

          final url = await supportRepo.uploadAttachment(
            file,
            'driver_chat_attachments',
          );

          await chatRepo.sendMessage(
            _conversation!.conversationId,
            authState.user.uid,
            '',
            attachmentUrl: url,
            attachmentName: result.files.single.name,
            attachmentSize: result.files.single.size,
            mimeType: _getMimeType(result.files.single.extension),
          );
          _scrollToBottom();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('فشل رفع الملف: $e')));
          }
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildAttachmentPreview(DriverMessage message) {
    return SupportAttachmentPreview(
      attachmentUrl: message.attachmentUrl,
      attachmentName: message.attachmentName,
      attachmentSize: message.attachmentSize,
      mimeType: message.mimeType,
      createdAt: message.createdAt,
      senderName: message.senderRole == 'driver' ? 'أنت' : 'الدعم الفني',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_conversation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المحادثة الفورية')),
        body: const Center(child: Text('لا يمكن بدء المحادثة الآن.')),
      );
    }

    final messagesAsync = ref.watch(
      driverMessagesProvider(_conversation!.conversationId),
    );

    final currentStatusStream = FirebaseFirestore.instance
        .collection('driver_support_conversations')
        .doc(_conversation!.conversationId)
        .snapshots()
        .map((doc) => doc.data()?['status'] as String? ?? 'open');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_conversation!.conversationType == 'ticket')
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'تذكرة',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              )
            else if (_conversation!.conversationType == 'report')
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'بلاغ',
                  style: TextStyle(fontSize: 10, color: Colors.red),
                ),
              ),
            const Text('المحادثة مع الدعم'),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<String>(
        stream: currentStatusStream,
        initialData: _conversation!.status,
        builder: (context, statusSnapshot) {
          final currentStatus = statusSnapshot.data ?? _conversation!.status;

          return Column(
            children: [
              if (_ticket != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _ticket!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _ticket!.status,
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ticket!.description,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    debugPrint('LOAD MESSAGES');
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('لا توجد رسائل بعد. ابدأ المحادثة الآن!'),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse:
                          true, // Messages are ordered descending from repository
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderRole == 'driver';

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft: isMe
                                    ? const Radius.circular(12)
                                    : const Radius.circular(0),
                                bottomRight: isMe
                                    ? const Radius.circular(0)
                                    : const Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.attachmentUrl != null)
                                  _buildAttachmentPreview(message),
                                if (message.message.isNotEmpty)
                                  Text(message.message),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) {
                    if (e is FirebaseException) {
                      debugPrint(
                        '--- FIRESTORE ERROR in DriverChatScreen.messagesAsync ---',
                      );
                      debugPrint('Code: ${e.code}');
                      debugPrint('Message: ${e.message}');
                      debugPrint(e.stackTrace?.toString() ?? st.toString());
                    } else {
                      debugPrint('Error loading messages: $e\n$st');
                    }
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'عذراً، تعذر تحميل المحادثة.\nالخطأ: $e',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initConversation,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Input Area
              if (currentStatus == 'closed')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[50],
                  child: const Text(
                    'تم إغلاق المحادثة بواسطة فريق الدعم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
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
                              hintText: 'اكتب رسالتك...',
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
                        if (_isUploading)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.attach_file,
                              color: Colors.blue,
                            ),
                            onPressed: _pickAndUploadAttachment,
                          ),
                        CircleAvatar(
                          backgroundColor: Colors.blue,
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
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('STREAM CLOSED');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
