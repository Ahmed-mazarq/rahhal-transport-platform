import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../domain/models/support_conversation.dart';
import '../../../../common/widgets/app_error_widget.dart';
import '../../providers/admin_support_providers.dart';
import '../../widgets/support_attachment_preview.dart';
import '../../../../admin/presentation/screens/admin_user_details_screen.dart';

class AdminOpenChatScreen extends ConsumerStatefulWidget {
  final SupportConversation conversation;

  const AdminOpenChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<AdminOpenChatScreen> createState() =>
      _AdminOpenChatScreenState();
}

class _AdminOpenChatScreenState extends ConsumerState<AdminOpenChatScreen> {
  final _messageController = TextEditingController();
  PlatformFile? _selectedFile; // PlatformFile
  SupportConversation? _fetchedConversation;
  bool _isFetching = false;

  SupportConversation get currentConversation =>
      _fetchedConversation ?? widget.conversation;

  @override
  void initState() {
    super.initState();
    if (widget.conversation.userType == 'unknown') {
      _fetchConversation();
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

  Future<void> _fetchConversation() async {
    setState(() => _isFetching = true);
    try {
      final userType = widget.conversation.userType;
      if (userType == 'unknown') {
        setState(() => _isFetching = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('${userType}_support_conversations')
          .doc(widget.conversation.conversationId)
          .get();

      if (doc.exists && doc.data() != null) {
        final conversation = SupportConversation.fromJson(doc.data()!, doc.id);
        if (mounted) {
          setState(() {
            _fetchedConversation = conversation;
            _isFetching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isFetching = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    try {
      String? attachmentUrl;
      String? attachmentName;
      int? attachmentSize;
      String? attachmentMimeType;

      if (_selectedFile != null) {
        attachmentUrl = await ref
            .read(adminChatRepositoryProvider(currentConversation.userType))
            .uploadAttachment(
              _selectedFile!,
              '${currentConversation.userType}_support_attachments/${currentConversation.conversationId}',
            );
        attachmentName = _selectedFile!.name;
        attachmentSize = _selectedFile!.size;
        attachmentMimeType = _getMimeType(_selectedFile!.extension);
      }

      await ref
          .read(adminChatRepositoryProvider(currentConversation.userType))
          .sendMessage(
            currentConversation.conversationId,
            authState.user.uid,
            text,
            senderType: 'admin',
            attachmentUrl: attachmentUrl,
            attachmentName: attachmentName,
            attachmentSize: attachmentSize,
            mimeType: attachmentMimeType,
          );
      if (mounted) {
        _messageController.clear();
        setState(() {
          _selectedFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الرسالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateStatus(String status) async {
    final authState = ref.read(authProvider);
    final adminId = authState is Authenticated ? authState.user.uid : null;

    try {
      await ref
          .read(adminSupportRepositoryProvider)
          .updateConversationStatus(
            currentConversation.conversationId,
            status,
            adminId: adminId,
          );
      if (mounted) {
        final message = status == 'closed'
            ? 'تم إغلاق المحادثة بنجاح'
            : 'تم تحديث الحالة بنجاح';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث الحالة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updatePriority(String priority) async {
    try {
      await ref
          .read(adminSupportRepositoryProvider)
          .updateConversationPriority(
            currentConversation.conversationId,
            priority,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الأولوية بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث الأولوية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _transferConversation() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedDept = 'technical';
        String selectedPriority =
            [
              'low',
              'medium',
              'high',
              'urgent',
            ].contains(currentConversation.priority)
            ? currentConversation.priority
            : 'low';
        return AlertDialog(
          title: const Text('تحويل المحادثة'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedDept,
                    items: const [
                      DropdownMenuItem(
                        value: 'technical',
                        child: Text('الدعم الفني'),
                      ),
                      DropdownMenuItem(
                        value: 'billing',
                        child: Text('الحسابات والفوترة'),
                      ),
                      DropdownMenuItem(
                        value: 'complaints',
                        child: Text('الشكاوى'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => selectedDept = v);
                    },
                    decoration: const InputDecoration(labelText: 'القسم'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                      DropdownMenuItem(value: 'medium', child: Text('متوسطة')),
                      DropdownMenuItem(value: 'high', child: Text('عالية')),
                      DropdownMenuItem(
                        value: 'urgent',
                        child: Text('عاجلة جداً'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => selectedPriority = v);
                    },
                    decoration: const InputDecoration(labelText: 'الأولوية'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(adminSupportRepositoryProvider)
                      .transferConversation(
                        currentConversation.conversationId,
                        selectedDept,
                        selectedPriority,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحويل المحادثة بنجاح')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل التحويل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('تحويل'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetching) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (currentConversation.userType == 'unknown') {
      return Scaffold(
        appBar: AppBar(title: const Text('خطأ')),
        body: const Center(child: Text('لم يتم العثور على المحادثة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.conversation.conversationType == 'ticket')
              Container(
                margin: const EdgeInsets.only(right: 8),
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
            else if (widget.conversation.conversationType == 'report')
              Container(
                margin: const EdgeInsets.only(right: 8),
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
            Text(
              'محادثة ${widget.conversation.conversationId.substring(0, 8)}...',
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'transfer') {
                _transferConversation();
              } else if (value == 'close') {
                _updateStatus('closed');
              } else if (value == 'resolve') {
                _updateStatus('resolved');
              } else if (['low', 'medium', 'high', 'urgent'].contains(value)) {
                _updatePriority(value);
              }
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'open', child: Text('مفتوحة')),
              const PopupMenuItem(value: 'resolved', child: Text('محلولة')),
              const PopupMenuItem(value: 'closed', child: Text('مغلقة')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'low', child: Text('أولوية: منخفضة')),
              const PopupMenuItem(
                value: 'medium',
                child: Text('أولوية: متوسطة'),
              ),
              const PopupMenuItem(value: 'high', child: Text('أولوية: عالية')),
              const PopupMenuItem(
                value: 'urgent',
                child: Text('أولوية: عاجلة'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'transfer',
                child: Text('تحويل المحادثة'),
              ),
            ],
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'معلومات المستخدم',
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('${currentConversation.userType}_support_conversations')
            .doc(currentConversation.conversationId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final currentStatus =
              data?['status'] as String? ?? currentConversation.status;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 800;
              final chatPanel = _buildChatPanel(context, currentStatus);
              final userContextPanel = _buildUserContextPanel(
                context,
                currentStatus,
              );

              if (isDesktop) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: chatPanel),
                    const VerticalDivider(width: 1),
                    Expanded(flex: 1, child: userContextPanel),
                  ],
                );
              }

              // Mobile Layout
              return chatPanel;
            },
          );
        },
      ),
      endDrawer: Drawer(
        child: Builder(
          builder: (context) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(
                    '${currentConversation.userType}_support_conversations',
                  )
                  .doc(currentConversation.conversationId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final currentStatus =
                    data?['status'] as String? ?? currentConversation.status;
                return _buildUserContextPanel(context, currentStatus);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatPanel(BuildContext context, String currentStatus) {
    return Column(
      children: [
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final messagesAsync = ref.watch(
                adminConversationMessagesProvider((
                  conversationId: widget.conversation.conversationId,
                  userType: widget.conversation.userType,
                )),
              );
              return messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(child: Text('لا توجد رسائل'));
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isAdmin = msg.senderType == 'admin';

                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? Colors.blue[100]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdmin
                                    ? 'الدعم الفني'
                                    : widget.conversation.userType
                                          .toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: isAdmin
                                      ? Colors.blue[900]
                                      : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (msg.attachmentUrl != null)
                                SupportAttachmentPreview(
                                  attachmentUrl: msg.attachmentUrl,
                                  attachmentName: msg.attachmentName,
                                  attachmentSize: msg.attachmentSize,
                                  mimeType: msg.mimeType,
                                  createdAt: msg.createdAt,
                                  senderName: isAdmin
                                      ? 'الدعم الفني'
                                      : widget.conversation.userType,
                                ),
                              if (msg.text.isNotEmpty) Text(msg.text),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(msg.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => AppErrorWidget(
                  message: e.toString(),
                  onRetry: () => ref.refresh(
                    adminConversationMessagesProvider((
                      conversationId: widget.conversation.conversationId,
                      userType: widget.conversation.userType,
                    )),
                  ),
                ),
              );
            },
          ),
        ),
        // Chat Input
        if (currentStatus == 'closed')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red[50],
            child: const Text(
              'تم إغلاق هذه المحادثة بواسطة فريق الدعم.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedFile != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _selectedFile!.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => _selectedFile = null),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickFile,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب ردك هنا...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUserContextPanel(BuildContext context, String currentStatus) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'معلومات المستخدم',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('نوع الحساب'),
                    subtitle: Text(widget.conversation.userType),
                    dense: true,
                  ),
                  ListTile(
                    title: const Text('حالة المحادثة'),
                    subtitle: Text(currentStatus),
                    dense: true,
                  ),
                  ListTile(
                    title: const Text('الأولوية'),
                    subtitle: Text(
                      widget.conversation.priority,
                      style: TextStyle(
                        color: widget.conversation.priority == 'urgent'
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    dense: true,
                  ),
                  const Divider(),
                  // Dynamic User Profile
                  Consumer(
                    builder: (context, ref, child) {
                      final userId =
                          widget.conversation.participantIds.isNotEmpty
                          ? widget.conversation.participantIds.first
                          : '';

                      if (userId.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final userAsync = ref.watch(
                        adminUserDetailsProvider((
                          userId: userId,
                          userType: widget.conversation.userType,
                        )),
                      );

                      return userAsync.when(
                        data: (user) {
                          if (user == null) {
                            return const Text('المستخدم غير موجود');
                          }

                          final profileImage = user['profileImage'] as String?;
                          final createdAt = user['createdAt'];
                          final registrationDate = createdAt != null
                              ? (createdAt is Timestamp
                                    ? createdAt.toDate()
                                    : (createdAt is DateTime
                                          ? createdAt
                                          : null))
                              : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (![
                                    'passenger',
                                    'driver',
                                    'company',
                                  ].contains(widget.conversation.userType)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'بيانات المستخدم غير متوفرة',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final safeUserMap = Map<String, dynamic>.from(
                                    user,
                                  );
                                  if (safeUserMap['role'] == null) {
                                    safeUserMap['role'] =
                                        widget.conversation.userType;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminUserDetailsScreen(
                                        userId: userId,
                                        user: safeUserMap,
                                      ),
                                    ),
                                  );
                                },
                                child: Center(
                                  child:
                                      profileImage != null &&
                                          profileImage.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(
                                            profileImage,
                                          ),
                                        )
                                      : const CircleAvatar(
                                          radius: 30,
                                          child: Icon(Icons.person, size: 30),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: const Text('الاسم'),
                                subtitle: Text(user['name'] ?? 'غير متوفر'),
                                dense: true,
                              ),
                              ListTile(
                                title: const Text('رقم الهاتف'),
                                subtitle: Text(user['phone'] ?? 'غير متوفر'),
                                dense: true,
                              ),
                              ListTile(
                                title: const Text('حالة الحساب'),
                                subtitle: Text(user['status'] ?? 'غير متوفر'),
                                dense: true,
                              ),
                              if (registrationDate != null)
                                ListTile(
                                  title: const Text('تاريخ التسجيل'),
                                  subtitle: Text(
                                    DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(registrationDate),
                                  ),
                                  dense: true,
                                ),
                              ListTile(
                                title: const Text('إجمالي الرحلات'),
                                subtitle: Text(
                                  '${user['totalTrips'] ?? 0} رحلة',
                                ),
                                dense: true,
                              ),
                              ListTile(
                                title: const Text('التقييم'),
                                subtitle: Text('${user['rating'] ?? 0.0} ★'),
                                dense: true,
                              ),
                              ListTile(
                                title: const Text('المدينة'),
                                subtitle: Text(user['city'] ?? 'غير متوفر'),
                                dense: true,
                              ),
                              ListTile(
                                title: const Text('الدولة'),
                                subtitle: Text(user['country'] ?? 'غير متوفر'),
                                dense: true,
                              ),
                              ListTile(
                                title: const Text('التوثيق'),
                                subtitle: Text(
                                  user['isVerified'] == true
                                      ? 'موثق'
                                      : 'غير موثق',
                                ),
                                dense: true,
                              ),
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, st) => const Text('خطأ في تحميل البيانات'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _transferConversation,
              icon: const Icon(Icons.transfer_within_a_station),
              label: const Text('تحويل المحادثة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateStatus('closed'),
              icon: const Icon(Icons.close),
              label: const Text('إغلاق المحادثة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
