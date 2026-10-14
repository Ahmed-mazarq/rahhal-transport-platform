import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/support_providers.dart';
import '../../domain/models/support_conversation.dart';
import '../../domain/models/support_message.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/support_attachment_preview.dart';

class SupportChatScreen extends ConsumerStatefulWidget {
  final String userType;
  final String? conversationId;
  final String? ticketId;

  const SupportChatScreen({
    super.key,
    required this.userType,
    this.conversationId,
    this.ticketId,
  });

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  SupportConversation? _conversation;
  bool _isLoading = true;
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
      final repo = ref.read(supportChatRepositoryProvider(widget.userType));
      try {
        String? targetConversationId = widget.conversationId;

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
          _conversation = await repo.createConversationForTicket(
            authState.user.uid,
            widget.ticketId!,
          );
        } else {
          _conversation = await repo.getOrCreateConversation(
            authState.user.uid,
          );
        }

        if (_conversation != null) {
          await repo.markMessagesAsRead(_conversation!.conversationId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error initializing chat: $e')),
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
      final repo = ref.read(supportChatRepositoryProvider(widget.userType));

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
          final chatRepo = ref.read(
            supportChatRepositoryProvider(widget.userType),
          );

          // Use the SupportChatRepository directly which handles SupabaseStorageService
          final url = await chatRepo.uploadAttachment(
            file,
            'support_chat_attachments/${_conversation!.conversationId}',
          );

          await chatRepo.sendMessage(
            _conversation!.conversationId,
            authState.user.uid,
            '', // empty text for attachment message
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

  Widget _buildAttachmentPreview(SupportMessage message, String userId) {
    return SupportAttachmentPreview(
      attachmentUrl: message.attachmentUrl,
      attachmentName: message.attachmentName,
      attachmentSize: message.attachmentSize,
      mimeType: message.mimeType,
      createdAt: message.createdAt,
      senderName: message.senderId == userId ? 'أنت' : 'الدعم الفني',
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

    final authState = ref.watch(authProvider);
    final userId = authState is Authenticated ? authState.user.uid : '';

    final messagesStream = ref
        .watch(supportChatRepositoryProvider(widget.userType))
        .watchMessages(_conversation!.conversationId);

    // We can also watch the conversation directly from Firestore here to get real-time status
    final currentStatusStream = FirebaseFirestore.instance
        .collection('${widget.userType}_support_conversations')
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
                margin: const EdgeInsets.only(left: 8), // left since RTL
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
              Expanded(
                child: StreamBuilder<List<SupportMessage>>(
                  stream: messagesStream,
                  builder: (context, messagesSnapshot) {
                    if (messagesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (messagesSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'عذراً، تعذر تحميل المحادثة.\nالخطأ: ${messagesSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final messages = messagesSnapshot.data ?? [];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('لا توجد رسائل بعد. ابدأ المحادثة الآن!'),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == userId;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
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
                                    ? const Radius.circular(0)
                                    : const Radius.circular(12),
                                bottomRight: isMe
                                    ? const Radius.circular(12)
                                    : const Radius.circular(0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                _buildAttachmentPreview(message, userId),
                                if (message.text.isNotEmpty) Text(message.text),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
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
                        IconButton(
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.attach_file,
                                  color: Colors.grey,
                                ),
                          onPressed: _isUploading
                              ? null
                              : _pickAndUploadAttachment,
                        ),
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
