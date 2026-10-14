import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/support_providers.dart';
import '../../domain/models/support_report.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart'
    hide supportRepositoryProvider;

class SupportReportScreen extends ConsumerStatefulWidget {
  final String userType;
  const SupportReportScreen({super.key, required this.userType});

  @override
  ConsumerState<SupportReportScreen> createState() =>
      _SupportReportScreenState();
}

class _SupportReportScreenState extends ConsumerState<SupportReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _category = 'passenger_issue';
  String _subCategory = 'سلوك غير لائق';
  String? _selectedBookingId;
  List<Map<String, dynamic>> _recentInteractions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentInteractions();
    });
  }

  Future<void> _loadRecentInteractions() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    try {
      final tripRepo = ref.read(tripRepositoryProvider);

      if (widget.userType == 'passenger') {
        final interactions = await tripRepo
            .getPassengerRecentBookingInteractions(authState.user.uid);
        if (mounted) {
          setState(() {
            _recentInteractions = interactions;
          });
        }
      } else if (widget.userType == 'driver') {
        final interactions = await tripRepo.getDriverRecentBookingInteractions(
          authState.user.uid,
        );
        if (mounted) {
          setState(() {
            _recentInteractions = interactions;
          });
        }
      } else if (widget.userType == 'company') {
        final interactions = await tripRepo.getCompanyRecentBookingInteractions(
          authState.user.uid,
        );
        if (mounted) {
          setState(() {
            _recentInteractions = interactions;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load recent interactions: $e');
    }
  }

  final Map<String, String> _categoryLabels = {
    'passenger_issue': 'مشكلة مع مستخدم',
    'vehicle_issue': 'مشكلة في المركبة',
    'trip_issue': 'مشكلة في الرحلات',
    'documents_issue': 'مشكلة في الوثائق',
    'payment_issue': 'مشكلة في المدفوعات',
    'app_issue': 'مشكلة في التطبيق',
  };

  final Map<String, List<String>> _subCategories = {
    'passenger_issue': [
      'سلوك غير لائق',
      'إساءة لفظية',
      'عدم الالتزام بالتعليمات',
      'محاولة الاحتيال',
      'عدم دفع الأجرة',
      'تهديد أو اعتداء',
      'أخرى',
    ],
    'vehicle_issue': ['عطل بالمركبة', 'بيانات المركبة غير صحيحة', 'أخرى'],
    'trip_issue': ['الرحلة لم تتم', 'مشكلة في الحجوزات', 'أخرى'],
    'documents_issue': [
      'مشكلة في الوثائق',
      'الوثائق قيد المراجعة لفترة طويلة',
      'مشكلة في التحقق من الهوية',
      'أخرى',
    ],
    'payment_issue': [
      'مشكلة في الحساب البنكي',
      'لم يصل التحويل',
      'فشل عملية السحب',
      'مشكلة في الأرباح',
      'أخرى',
    ],
    'app_issue': [
      'التطبيق يتوقف',
      'بطء شديد',
      'مشكلة في تسجيل الدخول',
      'مشكلة في الإشعارات',
      'مشكلة في الموقع',
      'أخرى',
    ],
  };

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      final repo = ref.read(supportRepositoryProvider(widget.userType));

      final selectedInteraction = _recentInteractions.firstWhere(
        (e) => e['bookingId'] == _selectedBookingId,
        orElse: () => {},
      );

      final report = SupportReport(
        id: '',
        reason: '$_category: $_subCategory',
        reporterType: widget.userType,
        reporterId: authState.user.uid,
        reportedId: selectedInteraction['targetId'],
        reportedType: selectedInteraction['targetType'],
        tripId: selectedInteraction['tripId'],
        bookingId: selectedInteraction['bookingId'],
        companyId: selectedInteraction['companyId'],
        driverId: selectedInteraction['driverId'],
        description: _descriptionController.text.trim(),
        status: 'open',
        priority: 'high',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await repo.submitReport(report);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال البلاغ بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإبلاغ عن مشكلة'),
        centerTitle: true,
        backgroundColor: Colors.red[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[800]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'نأخذ جميع البلاغات بجدية تامة. سيتم التحقيق في بلاغك من قبل فريق الدعم في أسرع وقت.',
                        style: TextStyle(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'نوع المشكلة الأساسية',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categoryLabels.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                      final subs = _subCategories[value] ?? [];
                      _subCategory = subs.isNotEmpty ? subs.first : '';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // SubCategory
              DropdownButtonFormField<String>(
                key: ValueKey(_category),
                initialValue: _subCategory,
                decoration: const InputDecoration(
                  labelText: 'التصنيف الفرعي',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                ),
                items: (_subCategories[_category] ?? []).map((sub) {
                  return DropdownMenuItem(value: sub, child: Text(sub));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _subCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Reported User/Trip Selector
              if (_recentInteractions.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedBookingId,
                  decoration: const InputDecoration(
                    labelText: 'تحديد الرحلة / المستخدم',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.history),
                  ),
                  items: _recentInteractions.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['bookingId'],
                      child: Text(item['title']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBookingId = val),
                ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل البلاغ',
                  hintText: 'يرجى تقديم أكبر قدر ممكن من التفاصيل...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) => value == null || value.isEmpty
                    ? 'يرجى كتابة تفاصيل البلاغ'
                    : null,
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitReport,
                  icon: _isLoading ? const SizedBox() : const Icon(Icons.send),
                  label: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'إرسال البلاغ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
