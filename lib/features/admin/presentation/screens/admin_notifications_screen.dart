import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _body = '';
  String _targetGroup = 'all_users';
  String _type = 'info';
  bool _isLoading = false;

  final Map<String, String> _groups = {
    'all_users': 'جميع المستخدمين',
    'passengers': 'الركاب فقط',
    'drivers': 'السائقين فقط',
    'companies': 'الشركات فقط',
    'admins': 'المدراء',
  };

  final Map<String, String> _types = {
    'info': 'إعلامي',
    'promotion': 'ترويجي',
    'warning': 'تحذير',
    'emergency': 'طوارئ',
  };

  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid == null) {
        throw StateError('Admin authentication is required.');
      }

      const roleMap = <String, String>{
        'all_users': 'all',
        'passengers': 'passenger',
        'drivers': 'driver',
        'companies': 'company',
        'admins': 'admin',
      };

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': '',
        'title': _title,
        'body': _body,
        'category': _type,
        'targetRole': roleMap[_targetGroup] ?? 'all',
        'status': 'sent',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUid,
        'isRead': false,
        'readCount': 0,
        'deliveredCount': 0,
        'failedCount': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم جدولة الإشعار للإرسال عبر الخوادم السحابية'),
          ),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'مركز الإشعارات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إرسال إشعار جديد (Push Notification)',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'سيتم إرسال الإشعار إلى أجهزة المستخدمين المستهدفين. قد يستغرق وصول الإشعار بضع دقائق.',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'محتوى الإشعار',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'عنوان الإشعار',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'مطلوب' : null,
                              onSaved: (val) => _title = val!,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'نص الإشعار',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 4,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'مطلوب' : null,
                              onSaved: (val) => _body = val!,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الاستهداف والنوع',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'المجموعة المستهدفة',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _targetGroup,
                              items: _groups.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _targetGroup = val!),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'نوع الإشعار',
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _type,
                              items: _types.entries
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setState(() => _type = val!),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _sendNotification,
                        icon: const Icon(Icons.send),
                        label: const Text(
                          'إرسال الإشعار الآن',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1F3A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
