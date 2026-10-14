import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' as ui;
import '../providers/admin_system_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/admin_system_settings.dart';
import '../widgets/admin_permission_gate.dart';
import 'package:intl/intl.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _appNameController;
  late final TextEditingController _supportEmailController;
  late final TextEditingController _supportPhoneController;
  late final TextEditingController _supportWhatsappController;
  late final TextEditingController _maintenanceMessageArController;
  late final TextEditingController _maintenanceMessageEnController;

  String _timezone = 'Asia/Riyadh';
  String _currency = 'SAR';
  bool _maintenanceMode = false;
  bool _allowAdminBypass = true;
  DateTime? _maintenanceUntil;

  bool _initialized = false;
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController()..addListener(_markDirty);
    _supportEmailController = TextEditingController()..addListener(_markDirty);
    _supportPhoneController = TextEditingController()..addListener(_markDirty);
    _supportWhatsappController = TextEditingController()
      ..addListener(_markDirty);
    _maintenanceMessageArController = TextEditingController()
      ..addListener(_markDirty);
    _maintenanceMessageEnController = TextEditingController()
      ..addListener(_markDirty);
  }

  void _markDirty() {
    if (_initialized && !_isDirty) {
      setState(() => _isDirty = true);
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _supportWhatsappController.dispose();
    _maintenanceMessageArController.dispose();
    _maintenanceMessageEnController.dispose();
    super.dispose();
  }

  void _initializeFields(AdminSystemSettings settings) {
    if (_initialized) return;
    _appNameController.text = settings.appName;
    _supportEmailController.text = settings.supportEmail;
    _supportPhoneController.text = settings.supportPhone;
    _supportWhatsappController.text = settings.supportWhatsapp;
    _maintenanceMessageArController.text = settings.maintenanceMessageAr;
    _maintenanceMessageEnController.text = settings.maintenanceMessageEn;

    _timezone = settings.timezone;
    _currency = settings.currency;
    _maintenanceMode = settings.maintenanceMode;
    _allowAdminBypass = settings.allowAdminBypass;
    _maintenanceUntil = settings.maintenanceUntil;

    _initialized = true;
  }

  void _saveSettings(AdminSystemSettings currentSettings) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isDirty) return;

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(adminSystemRepositoryProvider);
      final adminUid = FirebaseAuth.instance.currentUser?.uid;
      if (adminUid == null) {
        throw StateError('Admin Firebase session is not available');
      }

      final updatedSettings = currentSettings.copyWith(
        appName: _appNameController.text.trim(),
        timezone: _timezone,
        currency: _currency,
        maintenanceMode: _maintenanceMode,
        maintenanceMessageAr: _maintenanceMessageArController.text.trim(),
        maintenanceMessageEn: _maintenanceMessageEnController.text.trim(),
        maintenanceUntil: _maintenanceUntil,
        allowAdminBypass: _allowAdminBypass,
        supportEmail: _supportEmailController.text.trim(),
        supportPhone: _supportPhoneController.text.trim(),
        supportWhatsapp: _supportWhatsappController.text.trim(),
      );

      final finalSettings = _maintenanceUntil == null
          ? updatedSettings.clearMaintenanceUntil()
          : updatedSettings;

      await repo.updateAppSettings(finalSettings, adminUid);
      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ إعدادات النظام بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حفظ إعدادات النظام')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickMaintenanceUntil() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _maintenanceUntil ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _maintenanceUntil != null
            ? TimeOfDay.fromDateTime(_maintenanceUntil!)
            : TimeOfDay.now(),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _maintenanceUntil = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _markDirty();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(systemSettingsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إعدادات النظام',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: AdminPermissionGate(
        requiredPermission: 'edit_settings',
        fallback: const Center(
          child: Text(
            'ليس لديك صلاحية للوصول إلى هذا القسم.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.red,
            ),
          ),
        ),
        child: settingsAsync.when(
          data: (settings) {
            if (!_initialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _initialized) return;

                setState(() {
                  _initializeFields(settings);
                });
              });

              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدارة إعدادات منصة رحّال',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'التحكم بالإعدادات العامة والتشغيل والصيانة',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (settings.updatedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.update,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'آخر تحديث: ${DateFormat('yyyy-MM-dd HH:mm').format(settings.updatedAt!)}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildGeneralSettingsCard(),
                    const SizedBox(height: 24),
                    _buildSupportSettingsCard(),
                    const SizedBox(height: 24),
                    _buildSystemStatusCard(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: (_isSaving || !_isDirty)
                            ? null
                            : () => _saveSettings(settings),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text(
                          'حفظ الإعدادات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1F3A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'تعذر تحميل إعدادات النظام',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تعذر جلب الإعدادات من قاعدة البيانات.',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(systemSettingsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1F3A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralSettingsCard() {
    return Card(
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
              'الإعدادات العامة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _appNameController,
              decoration: const InputDecoration(
                labelText: 'اسم المنصة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(child: _buildTimezoneDropdown()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCurrencyDropdown()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildTimezoneDropdown(),
                      const SizedBox(height: 16),
                      _buildCurrencyDropdown(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneDropdown() {
    return DropdownButtonFormField<String>(
      value: _timezone,
      decoration: const InputDecoration(
        labelText: 'المنطقة الزمنية',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: 'Asia/Aden',
          child: Text('توقيت اليمن — عدن'),
        ),
        const DropdownMenuItem(
          value: 'Asia/Riyadh',
          child: Text('توقيت السعودية — الرياض'),
        ),
        const DropdownMenuItem(value: 'UTC', child: Text('UTC')),
        if (_timezone == 'Asia/Dubai')
          const DropdownMenuItem(
            value: 'Asia/Dubai',
            child: Text('توقيت الإمارات — دبي'),
          ),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _timezone = val;
            _markDirty();
          });
        }
      },
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _currency,
      decoration: const InputDecoration(
        labelText: 'العملة الافتراضية',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: 'YER', child: Text('ريال يمني (YER)')),
        const DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
        if (_currency == 'AED' || _currency == 'USD') ...[
          const DropdownMenuItem(
            value: 'AED',
            child: Text('درهم إماراتي (AED)'),
          ),
          const DropdownMenuItem(
            value: 'USD',
            child: Text('دولار أمريكي (USD)'),
          ),
        ],
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _currency = val;
            _markDirty();
          });
        }
      },
    );
  }

  Widget _buildSupportSettingsCard() {
    return Card(
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
              'معلومات التواصل والدعم',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _supportEmailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني للدعم',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val != null && val.isNotEmpty) {
                  if (!val.contains('@')) return 'البريد الإلكتروني غير صالح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _supportPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'رقم هاتف الدعم',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          textDirection: ui.TextDirection.ltr,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _supportWhatsappController,
                          decoration: const InputDecoration(
                            labelText: 'رقم واتساب الدعم',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.message),
                          ),
                          keyboardType: TextInputType.phone,
                          textDirection: ui.TextDirection.ltr,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      TextFormField(
                        controller: _supportPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'رقم هاتف الدعم',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        textDirection: ui.TextDirection.ltr,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _supportWhatsappController,
                        decoration: const InputDecoration(
                          labelText: 'رقم واتساب الدعم',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                        ),
                        keyboardType: TextInputType.phone,
                        textDirection: ui.TextDirection.ltr,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _maintenanceMode ? Colors.red.shade300 : Colors.green.shade300,
          width: 2,
        ),
      ),
      color: _maintenanceMode ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _maintenanceMode ? Icons.build : Icons.check_circle,
                  color: _maintenanceMode ? Colors.red : Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _maintenanceMode
                        ? 'وضع الصيانة مفعل'
                        : 'النظام يعمل بشكل طبيعي',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _maintenanceMode ? Colors.red : Colors.green,
                    ),
                  ),
                ),
                Switch(
                  value: _maintenanceMode,
                  activeThumbColor: Colors.red,
                  activeTrackColor: Colors.red.shade200,
                  inactiveThumbColor: Colors.green,
                  inactiveTrackColor: Colors.green.shade200,
                  onChanged: (val) {
                    setState(() {
                      _maintenanceMode = val;
                      _markDirty();
                    });
                  },
                ),
              ],
            ),
            if (_maintenanceMode) ...[
              const SizedBox(height: 24),
              const Divider(color: Colors.redAccent),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maintenanceMessageArController,
                decoration: const InputDecoration(
                  labelText: 'رسالة الصيانة (عربي)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maintenanceMessageEnController,
                decoration: const InputDecoration(
                  labelText: 'رسالة الصيانة (إنجليزي)',
                  border: OutlineInputBorder(),
                ),
                textDirection: ui.TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickMaintenanceUntil,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'موعد انتهاء الصيانة المتوقع (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _maintenanceUntil != null
                              ? DateFormat(
                                  'yyyy-MM-dd HH:mm',
                                ).format(_maintenanceUntil!)
                              : 'غير محدد',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ),
                  if (_maintenanceUntil != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _maintenanceUntil = null;
                          _markDirty();
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.red,
                title: const Text(
                  'السماح للمشرفين (Admins) بتخطي شاشة الصيانة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: _allowAdminBypass,
                onChanged: (val) {
                  setState(() {
                    _allowAdminBypass = val ?? true;
                    _markDirty();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
