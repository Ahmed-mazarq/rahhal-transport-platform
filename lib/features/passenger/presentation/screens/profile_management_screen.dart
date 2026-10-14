import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/passenger_providers.dart';
import '../../../../core/providers/repository_providers.dart';

class ProfileManagementScreen extends ConsumerStatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  ConsumerState<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState
    extends ConsumerState<ProfileManagementScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final Map<String, List<String>> _locations = {
    'اليمن': [
      'صنعاء',
      'أمانة العاصمة',
      'عدن',
      'تعز',
      'إب',
      'الحديدة',
      'حضرموت',
      'شبوة',
      'المهرة',
      'سقطرى',
      'مأرب',
      'الجوف',
      'صعدة',
      'حجة',
      'المحويت',
      'ريمة',
      'ذمار',
      'البيضاء',
      'الضالع',
      'لحج',
      'أبين',
      'عمران',
    ],
    'السعودية': [
      'الرياض',
      'مكة المكرمة',
      'المدينة المنورة',
      'القصيم',
      'المنطقة الشرقية',
      'عسير',
      'تبوك',
      'حائل',
      'الحدود الشمالية',
      'جازان',
      'نجران',
      'الباحة',
      'الجوف',
    ],
  };

  String _selectedCountry = 'اليمن';
  String _selectedGovernorate = 'صنعاء';
  bool _isInitialized = false;
  XFile? _pickedFile;
  Uint8List? _imageBytes;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_pickedFile == null) return null;

    try {
      final storageService = SupabaseStorageService();
      return await storageService.uploadProfileImage(uid, _pickedFile!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في الرفع: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الاسم الكامل مطلوب',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) return;

      String photoUrl = authState.user.profileImage;
      if (_imageBytes != null) {
        final url = await _uploadImage(authState.user.uid);
        if (url != null) photoUrl = url;
      }

      // Update User Model (Auth Repository)
      final updatedUser = authState.user.copyWith(
        fullName: _nameController.text.trim(),
        profileImage: photoUrl,
        updatedAt: DateTime.now(),
      );
      await ref.read(authRepositoryProvider).updateUserProfile(updatedUser);

      // Update Passenger Profile (Passenger Repository)
      final profileState = ref.read(passengerProfileProvider);
      final profile = profileState.valueOrNull;
      if (profile != null) {
        final updatedProfile = profile.copyWith(
          country: _selectedCountry,
          governorate: _selectedGovernorate,
          updatedAt: DateTime.now(),
        );
        await ref
            .read(passengerRepositoryProvider)
            .updatePassengerProfile(updatedProfile);
      }

      // Invalidate to refresh UI
      ref.invalidate(authProvider);
      ref.invalidate(passengerProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم حفظ التعديلات بنجاح!',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'حدث خطأ أثناء الحفظ',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showPasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'تغيير كلمة المرور',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  _buildTextField(
                    isDark,
                    label: 'كلمة المرور الحالية',
                    controller: currentPasswordController,
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    isDark,
                    label: 'كلمة المرور الجديدة',
                    controller: newPasswordController,
                    icon: Icons.lock_reset,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    isDark,
                    label: 'تأكيد كلمة المرور الجديدة',
                    controller: confirmPasswordController,
                    icon: Icons.check_circle_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1F3A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (currentPasswordController.text.isEmpty ||
                                  newPasswordController.text.isEmpty ||
                                  confirmPasswordController.text.isEmpty) {
                                setSheetState(
                                  () => errorMessage = 'جميع الحقول مطلوبة',
                                );
                                return;
                              }
                              if (newPasswordController.text !=
                                  confirmPasswordController.text) {
                                setSheetState(
                                  () =>
                                      errorMessage = 'كلمات المرور غير متطابقة',
                                );
                                return;
                              }
                              if (newPasswordController.text.length < 6) {
                                setSheetState(
                                  () => errorMessage =
                                      'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                                );
                                return;
                              }
                              setSheetState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              try {
                                await ref
                                    .read(authRepositoryProvider)
                                    .changePassword(
                                      currentPassword:
                                          currentPasswordController.text,
                                      newPassword: newPasswordController.text,
                                    );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'تم تغيير كلمة المرور بنجاح',
                                        style: TextStyle(fontFamily: 'Cairo'),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setSheetState(() {
                                    isLoading = false;
                                    errorMessage = e.toString().replaceAll(
                                      'Exception: ',
                                      '',
                                    );
                                  });
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'تأكيد التغيير',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authProvider);
    final profileState = ref.watch(passengerProfileProvider);

    if (!_isInitialized) {
      if (authState is Authenticated) {
        _nameController.text = authState.user.fullName;
        _phoneController.text = authState.user.phone;
      }
      final profile = profileState.valueOrNull;
      if (profile != null) {
        _selectedCountry =
            profile.country.isNotEmpty &&
                _locations.containsKey(profile.country)
            ? profile.country
            : 'اليمن';
        final validGovernorates = _locations[_selectedCountry]!;
        if (profile.governorate.isNotEmpty &&
            validGovernorates.contains(profile.governorate)) {
          _selectedGovernorate = profile.governorate;
        } else {
          _selectedGovernorate = validGovernorates.isNotEmpty
              ? validGovernorates.first
              : '';
        }
        _isInitialized = true;
      }
    }

    String currentPhotoUrl = '';
    if (authState is Authenticated) {
      currentPhotoUrl = authState.user.profileImage;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تعديل الملف الشخصي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Picture Edit
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0B1F3A),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue,
                        backgroundImage: _imageBytes != null
                            ? MemoryImage(_imageBytes!) as ImageProvider
                            : (currentPhotoUrl.isNotEmpty
                                  ? NetworkImage(currentPhotoUrl)
                                  : null),
                        child: (_imageBytes == null && currentPhotoUrl.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5A623),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField(
              isDark,
              label: 'الاسم الكامل',
              controller: _nameController,
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              isDark,
              label: 'رقم الهاتف (غير قابل للتعديل)',
              controller: _phoneController,
              icon: Icons.phone,
              enabled: false,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),

            // Country Dropdown
            const Padding(
              padding: EdgeInsets.only(right: 8, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'البلاد',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF0B1F3A),
                  ),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  items: _locations.keys.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.public,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null && newValue != _selectedCountry) {
                      setState(() {
                        _selectedCountry = newValue;
                        final govs = _locations[newValue] ?? [];
                        _selectedGovernorate = govs.isNotEmpty
                            ? govs.first
                            : '';
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Governorate Dropdown
            const Padding(
              padding: EdgeInsets.only(right: 8, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'المحافظة',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGovernorate,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF0B1F3A),
                  ),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  items: (_locations[_selectedCountry] ?? []).map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(value),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _selectedGovernorate = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Password Change Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0B1F3A),
                  side: const BorderSide(color: Color(0xFF0B1F3A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showPasswordSheet,
                icon: const Icon(Icons.lock_outline),
                label: const Text(
                  'تغيير كلمة المرور',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    bool isDark, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontFamily: 'Cairo',
        color: enabled ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
