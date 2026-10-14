import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/admin_support_providers.dart';
import '../../../../common/widgets/app_error_widget.dart';

class AdminSupportContactScreen extends StatefulWidget {
  const AdminSupportContactScreen({super.key});

  @override
  State<AdminSupportContactScreen> createState() =>
      _AdminSupportContactScreenState();
}

class _AdminSupportContactScreenState extends State<AdminSupportContactScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات التواصل'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'الركاب', icon: Icon(Icons.person)),
            Tab(text: 'السائقين', icon: Icon(Icons.drive_eta)),
            Tab(text: 'الشركات', icon: Icon(Icons.business)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ContactForm(userType: 'passenger'),
          _ContactForm(userType: 'driver'),
          _ContactForm(userType: 'company'),
        ],
      ),
    );
  }
}

class _ContactForm extends ConsumerStatefulWidget {
  final String userType;
  const _ContactForm({required this.userType});

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _phone1 = TextEditingController();
  final _phone2 = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _telegram = TextEditingController();
  final _website = TextEditingController();
  final _workingHours = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _isActive = true;

  bool _isSaving = false;

  @override
  void dispose() {
    _phone1.dispose();
    _phone2.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _telegram.dispose();
    _website.dispose();
    _workingHours.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _populateForm(Map<String, dynamic> data) {
    _phone1.text = data['phone1'] ?? '';
    _phone2.text = data['phone2'] ?? '';
    _whatsapp.text = data['whatsapp'] ?? '';
    _email.text = data['email'] ?? '';
    _telegram.text = data['telegram'] ?? '';
    _website.text = data['website'] ?? '';
    _workingHours.text = data['workingHours'] ?? '';
    _address.text = data['address'] ?? '';
    _notes.text = data['notes'] ?? '';
    _isActive = data['isActive'] ?? true;
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'phone1': _phone1.text.trim(),
        'phone2': _phone2.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'email': _email.text.trim(),
        'telegram': _telegram.text.trim(),
        'website': _website.text.trim(),
        'workingHours': _workingHours.text.trim(),
        'address': _address.text.trim(),
        'notes': _notes.text.trim(),
        'isActive': _isActive,
      };

      await ref
          .read(adminSupportRepositoryProvider)
          .updateContact(widget.userType, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ معلومات التواصل بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactAsync = ref.watch(adminContactProvider(widget.userType));

    return contactAsync.when(
      data: (data) {
        // Initialize once when data is loaded
        if (data != null &&
            _phone1.text.isEmpty &&
            _email.text.isEmpty &&
            _address.text.isEmpty) {
          _populateForm(data);
        }

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('تفعيل معلومات التواصل لهذا القسم'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone1,
                decoration: const InputDecoration(
                  labelText: 'الهاتف الأول (الرئيسي)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone2,
                decoration: const InputDecoration(
                  labelText: 'الهاتف الثاني (إختياري)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whatsapp,
                decoration: const InputDecoration(
                  labelText: 'رقم الواتساب',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telegram,
                decoration: const InputDecoration(
                  labelText: 'حساب تيليجرام (رابط أو معرف)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _website,
                decoration: const InputDecoration(
                  labelText: 'الموقع الإلكتروني',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _workingHours,
                decoration: const InputDecoration(
                  labelText: 'ساعات العمل (مثال: من الأحد للخميس، 9ص - 5م)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveContact,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => AppErrorWidget(
        message: 'حدث خطأ أثناء جلب المعلومات',
        onRetry: () => ref.refresh(adminContactProvider(widget.userType)),
      ),
    );
  }
}
