import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/driver_providers.dart';
import '../widgets/driver_avatar.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import '../providers/driver_profile_image_provider.dart';

class ProfileManagementScreen extends ConsumerStatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  ConsumerState<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState
    extends ConsumerState<ProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingImage = false;

  late TextEditingController _fullNameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _nationalityCtrl;
  late TextEditingController _emergencyContactCtrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(driverProfileProvider).value;
    _fullNameCtrl = TextEditingController(text: profile?.fullName ?? '');
    _bioCtrl = TextEditingController(text: profile?.bio ?? '');
    _nationalityCtrl = TextEditingController(text: profile?.country ?? '');
    _emergencyContactCtrl = TextEditingController(
      text: profile?.emergencyContact ?? '',
    );
  }

  void _showImagePickerOptions() {
    final imageState = ref.read(driverProfileImageProvider).value;
    final hasImage = imageState != null && imageState.url.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: Text(
                hasImage ? 'تغيير الصورة' : 'إضافة صورة شخصية',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    if (!mounted) return;

    // Show preview dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'معاينة الصورة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(file.path),
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check),
            label: const Text(
              'حفظ الصورة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploadingImage = true);

    try {
      final profile = ref.read(driverProfileProvider).value;
      if (profile == null) throw Exception('لم يتم العثور على الملف الشخصي');

      final storageService = SupabaseStorageService();
      // Upload to public bucket
      final publicUrl = await storageService.uploadProfileImage(
        profile.id,
        file,
      );

      final updatedTime = DateTime.now().millisecondsSinceEpoch;

      // Use the dedicated repository method to ensure only image fields are touched
      final repo = ref.read(driverRepositoryProvider);
      await repo.updateDriverProfileImage(profile.id, publicUrl, updatedTime);

      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(profile.id)
          .get();
      final dUrl = driverDoc.data()?['profileImage'];



      if (dUrl == null || dUrl.toString().isEmpty) {
        throw Exception('تعذر التحقق من حفظ الصورة الشخصية');
      }

      // We do not need to manually invalidate driverProfileProvider for the image anymore
      // because driverProfileImageProvider is a realtime stream that will update automatically.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تحديث الصورة الشخصية بنجاح',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحديث الصورة الشخصية، يرجى المحاولة لاحقاً',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) return;

      final repo = ref.read(driverRepositoryProvider);

      // CRITICAL FIX: Update ONLY the specific text fields using a dedicated repository method.
      // This completely avoids serializing the entire DriverProfile, guaranteeing that
      // profileImage and profileImageUpdatedAt are never accidentally overwritten.
      await repo.updateDriverProfileInfo(
        authState.user.id,
        _fullNameCtrl.text,
        _bioCtrl.text,
        _nationalityCtrl.text,
        _emergencyContactCtrl.text,
      );

      ref.invalidate(driverProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم تحديث الملف الشخصي',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر حفظ بيانات الملف الشخصي، يرجى المحاولة لاحقاً',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(driverProfileProvider).value;
    final imageState = ref.watch(driverProfileImageProvider).value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المعلومات الشخصية',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'حفظ',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _showImagePickerOptions,
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: DriverAvatar(
                          imageUrl: imageState?.url ?? '',
                          radius: 50,
                          cacheKey: imageState?.updatedAt != null
                              ? '${imageState?.url}_${imageState?.updatedAt}'
                              : (imageState?.url ?? ''),
                        ),
                      ),
                      if (_isUploadingImage)
                        const Positioned.fill(
                          child: CircularProgressIndicator(),
                        ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _fullNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: profile?.phoneNumber ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف (للقراءة فقط)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nationalityCtrl,
                decoration: const InputDecoration(
                  labelText: 'الجنسية',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactCtrl,
                decoration: const InputDecoration(
                  labelText: 'جهة اتصال للطوارئ (الاسم والرقم)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.emergency),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'نبذة عنك (السيرة الذاتية)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
