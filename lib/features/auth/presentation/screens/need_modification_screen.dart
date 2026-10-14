import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import 'package:rahal/features/common/constants/modification_keys.dart';
import 'package:rahal/features/common/models/driver_model.dart';
import 'package:rahal/features/common/models/user_model.dart';
import 'package:rahal/core/services/storage/supabase_storage_service.dart';

class NeedModificationScreen extends ConsumerStatefulWidget {
  const NeedModificationScreen({super.key});

  @override
  ConsumerState<NeedModificationScreen> createState() =>
      _NeedModificationScreenState();
}

class _NeedModificationScreenState
    extends ConsumerState<NeedModificationScreen> {
  bool _isSubmitting = false;
  bool _isLoading = true;

  // Data: key -> note
  final Map<String, String> _requestedFields = {};

  // Current user data
  DriverModel? _driverModel;
  UserModel? _userModel;

  // Dynamic form state
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, XFile?> _images = {};

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;

    _userModel = authState.user;

    // Fetch driver model to get current values
    if (_userModel?.role == 'driver') {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('drivers')
            .doc(_userModel!.id)
            .get();
        if (doc.exists) {
          _driverModel = DriverModel.fromFirestore(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('Error fetching driver model: $e');
      }
    }

    final checklist = _userModel!.modificationChecklist;
    int genericCounter = 0;

    for (var item in checklist) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          final note = decoded['note']?.toString() ?? '';
          final fields = List<String>.from(decoded['fields'] ?? []);

          for (var f in fields) {
            // Map legacy strings to constants if needed
            final key = ModificationKeys.legacyMap[f] ?? f;
            _requestedFields[key] = note;

            if (ModificationKeys.firestoreImages.containsKey(key)) {
              _images[key] = null;
            } else {
              _controllers[key] = TextEditingController();
            }
          }
        } else {
          throw const FormatException('Not a valid JSON object');
        }
      } catch (e) {
        // Fallback for old string format
        genericCounter++;
        final note = item;
        _requestedFields['general_$genericCounter'] = note;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(String key) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _images[key] = pickedFile;
      });
    }
  }

  Future<void> _submit() async {
    if (_userModel == null) return;

    // Validation
    for (var f in _controllers.keys) {
      if (_controllers[f]?.text.trim().isEmpty ?? true) {
        final label = ModificationKeys.labels[f] ?? f;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('الرجاء إكمال الحقل: $label')));
        return;
      }
    }
    for (var img in _images.keys) {
      if (_images[img] == null) {
        final label = ModificationKeys.labels[img] ?? img;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('الرجاء رفع: $label')));
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      debugPrint('--- _submit() START ---');
      final firestore = FirebaseFirestore.instance;
      final storageService = SupabaseStorageService();
      Map<String, dynamic> userUpdates = {};
      Map<String, dynamic> documentUpdates = {};

      // Upload to Supabase Storage
      for (var imgKey in _images.keys) {
        final file = _images[imgKey];
        if (file != null) {
          final firestoreKey =
              ModificationKeys.firestoreImages[imgKey] ?? imgKey;
          String url = '';
          try {
            if (firestoreKey == 'personalPhoto' ||
                firestoreKey == 'profileImage') {
              url = await storageService.uploadDriverVerificationPhoto(
                _userModel!.id,
                file,
              );
            } else if (firestoreKey.startsWith('vehicle')) {
              url = await storageService.uploadVehiclePhoto(
                _userModel!.id,
                'registration',
                firestoreKey,
                file,
                isPrivate: true,
              );
            } else {
              url = await storageService.uploadDriverDocument(
                _userModel!.id,
                firestoreKey,
                file,
              );
            }
          } catch (e) {
            debugPrint('Failed to upload $firestoreKey: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('فشل رفع $firestoreKey')));
            setState(() => _isSubmitting = false);
            return;
          }

          if (url.isNotEmpty) {
            documentUpdates['documents.$firestoreKey'] = {
              'url': url,
              'status': 'pending',
              'updatedAt': DateTime.now().toIso8601String(),
            };
          }
        }
      }

      // Update fields using DriverModel logic
      final currentMap = _driverModel!.toFirestore();
      for (var f in _controllers.keys) {
        final val = _controllers[f]!.text.trim();
        final fsKey = ModificationKeys.firestoreFields[f];
        if (fsKey != null) {
          if (fsKey == 'seatCount' ||
              fsKey == 'branchCount' ||
              fsKey == 'fleetSize' ||
              fsKey == 'driverCount') {
            currentMap[fsKey] = int.tryParse(val) ?? 0;
            documentUpdates[fsKey] = int.tryParse(val) ?? 0;
          } else if (fsKey == 'rating' || fsKey == 'walletBalance') {
            currentMap[fsKey] = double.tryParse(val) ?? 0.0;
            documentUpdates[fsKey] = double.tryParse(val) ?? 0.0;
          } else {
            currentMap[fsKey] = val;
            documentUpdates[fsKey] = val;
          }
          if (fsKey == 'fullName') {
            userUpdates['name'] = val;
            userUpdates['fullName'] = val;
          }
        }
      }

      // Common status updates
      userUpdates['status'] = 'pending_review';
      userUpdates['rejectedReason'] = FieldValue.delete();
      userUpdates['modificationChecklist'] = [];
      documentUpdates['status'] = 'pending_review';

      debugPrint('Preparing batch...');
      final batch = firestore.batch();

      debugPrint('batch.update(users)');
      batch.update(
        firestore.collection('users').doc(_userModel!.id),
        userUpdates,
      );

      if (_userModel!.role == 'driver') {
        if (_driverModel == null) {
          debugPrint(
            'Driver document does not exist. Creating it before batch update.',
          );
          final newDriver = DriverModel(
            id: _userModel!.id,
            userId: _userModel!.id,
            fullName: _userModel!.name,
            phone: _userModel!.phone,
            email: _userModel!.email,
            licenseNumber: '',
            rating: 5.0,
            totalTrips: 0,
            isVerified: false,
            status: 'pending_review',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final fullData = newDriver.toFirestore();
          fullData.addAll(documentUpdates);
          debugPrint('batch.set(drivers) with full data');
          batch.set(
            firestore.collection('drivers').doc(_userModel!.id),
            fullData,
          );
        } else {
          debugPrint('batch.set(drivers) with merge: true');
          batch.set(
            firestore.collection('drivers').doc(_userModel!.id),
            documentUpdates,
            SetOptions(merge: true),
          );
        }
      } else if (_userModel!.role == 'company') {
        debugPrint('batch.set(companies) with merge: true');
        batch.set(
          firestore.collection('companies').doc(_userModel!.id),
          documentUpdates,
          SetOptions(merge: true),
        );
      }

      debugPrint('Starting batch.commit()...');
      await batch.commit();
      debugPrint('batch.commit() finished.');

      if (!mounted) return;
      ref.invalidate(authProvider);
    } catch (e) {
      debugPrint('Exception in _submit: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      debugPrint('finally block reached. Setting _isSubmitting = false');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getCurrentValue(String key) {
    if (_driverModel == null) return 'غير متوفر';
    final map = _driverModel!.toFirestore();
    final fsKey = ModificationKeys.firestoreFields[key];
    if (fsKey == null) return 'غير متوفر';
    final val = map[fsKey];
    return val?.toString() ?? 'غير متوفر';
  }

  List<String> _getKeysForSection(int sectionIndex) {
    final Map<int, List<String>> sections = {
      0: [
        ModificationKeys.fullName,
        ModificationKeys.nationalId,
        ModificationKeys.passportNumber,
        ModificationKeys.nationality,
        ModificationKeys.birthDate,
        ModificationKeys.gender,
        ModificationKeys.phone,
        ModificationKeys.secondaryPhone,
        ModificationKeys.passportExpiry,
      ],
      1: [
        ModificationKeys.country,
        ModificationKeys.province,
        ModificationKeys.city,
        ModificationKeys.district,
        ModificationKeys.street,
        ModificationKeys.detailedAddress,
        ModificationKeys.gpsLocation,
      ],
      2: [
        ModificationKeys.licenseNumber,
        ModificationKeys.licenseIssueDate,
        ModificationKeys.licenseExpiryDate,
        ModificationKeys.licenseType,
        ModificationKeys.licenseCountry,
      ],
      3: [
        ModificationKeys.vehicleBrand,
        ModificationKeys.vehicleModel,
        ModificationKeys.vehicleYear,
        ModificationKeys.vehicleColor,
        ModificationKeys.vehiclePlate,
        ModificationKeys.vin,
        ModificationKeys.seats,
        ModificationKeys.vehicleType,
        ModificationKeys.transmission,
        ModificationKeys.fuelType,
        ModificationKeys.vehicleCategory,
        ModificationKeys.vehicleRegistrationExpiry,
        ModificationKeys.registrationNumber,
        ModificationKeys.plateCountry,
      ],
      4: [
        ModificationKeys.insuranceCompany,
        ModificationKeys.insuranceNumber,
        ModificationKeys.policyNumber,
        ModificationKeys.insuranceExpiry,
        ModificationKeys.coverage,
      ],
      5: [ModificationKeys.operatingAreas, ModificationKeys.operatingCities],
      6: [
        ModificationKeys.bankName,
        ModificationKeys.accountHolder,
        ModificationKeys.accountNumber,
        ModificationKeys.iban,
        ModificationKeys.ewalletName,
        ModificationKeys.ewalletNumber,
      ],
      7: [
        ModificationKeys.emergencyContactName,
        ModificationKeys.emergencyContactRelation,
        ModificationKeys.emergencyContactPhone,
      ],
      8: [
        ModificationKeys.passportFrontImage,
        ModificationKeys.passportBackImage,
        ModificationKeys.driverPhoto,
        ModificationKeys.licenseFrontImage,
        ModificationKeys.licenseBackImage,
        ModificationKeys.vehicleFrontImage,
        ModificationKeys.vehicleBackImage,
        ModificationKeys.vehicleRightImage,
        ModificationKeys.vehicleLeftImage,
        ModificationKeys.vehicleInteriorImage,
        ModificationKeys.vehiclePlateImage,
        ModificationKeys.insurancePhoto,
      ],
    };

    final sectionKeys = sections[sectionIndex] ?? [];
    return sectionKeys.where((k) => _requestedFields.containsKey(k)).toList();
  }

  bool _isSectionRequested(int sectionIndex) {
    return _getKeysForSection(sectionIndex).isNotEmpty;
  }

  Widget _buildRequestedFieldWidget(String key) {
    final isImage = ModificationKeys.firestoreImages.containsKey(key);
    final note = _requestedFields[key] ?? '';
    final label = ModificationKeys.labels[key] ?? key;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (!isImage && (_controllers[key]?.text.isNotEmpty ?? false))
                const Icon(Icons.check_circle, color: Colors.green)
              else if (isImage && _images[key] != null)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          const SizedBox(height: 12),

          // Admin Reason
          if (note.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB), // Amber 50
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Current Value (only for text fields)
          if (!isImage) ...[
            Text(
              'القيمة الحالية:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              _getCurrentValue(key),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _controllers[key],
              decoration: InputDecoration(
                labelText: 'القيمة الجديدة لـ $label',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
                ),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ] else ...[
            _buildModernUploadCard(key, label),
          ],
        ],
      ),
    );
  }

  Widget _buildModernUploadCard(String key, String label) {
    final file = _images[key];
    final hasFile = file != null;

    return InkWell(
      onTap: () => _pickImage(key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: hasFile
              ? Colors.blue.withValues(alpha: 0.05)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? const Color(0xFF0D6EFD) : Colors.grey.shade300,
            width: hasFile ? 2 : 1,
            style: hasFile ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: hasFile
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(file.path, fit: BoxFit.cover)
                        : Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.greenAccent,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اضغط لتغيير الصورة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'رفع $label',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<Step> _buildSteps() {
    final steps = <Step>[];

    final sectionTitles = [
      'البيانات الشخصية والهوية',
      'العنوان',
      'رخصة القيادة',
      'بيانات المركبة',
      'التأمين',
      'مناطق العمل',
      'البيانات المالية',
      'جهة الاتصال (طوارئ)',
      'المستندات والصور',
    ];

    for (int i = 0; i < 9; i++) {
      if (_isSectionRequested(i)) {
        final keys = _getKeysForSection(i);
        bool isComplete = true;
        for (var k in keys) {
          if (ModificationKeys.firestoreImages.containsKey(k)) {
            if (_images[k] == null) isComplete = false;
          } else {
            if (_controllers[k]?.text.trim().isEmpty ?? true) {
              isComplete = false;
            }
          }
        }

        steps.add(
          Step(
            title: Text(
              sectionTitles[i],
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            state: isComplete ? StepState.complete : StepState.indexed,
            isActive: _currentStep >= steps.length,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: keys.map((k) => _buildRequestedFieldWidget(k)).toList(),
            ),
          ),
        );
      }
    }

    // Add review step
    steps.add(
      Step(
        title: const Text(
          'مراجعة وإرسال',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        state: StepState.indexed,
        isActive: _currentStep == steps.length,
        content: Column(
          children: [
            const Icon(Icons.verified_user, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'شكراً لك!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'يرجى التأكد من إكمال جميع التعديلات المطلوبة قبل الإرسال.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'اعتماد البيانات وتحديثها',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_requestedFields.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(
          child: Text(
            'لا توجد تعديلات مطلوبة. يرجى التواصل مع الدعم الفني.',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final steps = _buildSteps();

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0B1F3A),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0B1F3A),
          secondary: Color(0xFFF5A623),
          error: Color(0xFFEF4444),
          surface: Colors.white,
        ),
        fontFamily: 'Cairo',
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'تعديل المستندات والبيانات',
            style: TextStyle(
              color: Color(0xFF0B1F3A),
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF0B1F3A)),
          actions: [
            IconButton(
              icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF0B1F3A)),
              tooltip: 'الدعم الفني',
              onPressed: () => Navigator.of(context).pushNamed('/driver-support'),
            ),
          ],
        ),
        body: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () {
            if (_currentStep < steps.length - 1) {
              setState(() => _currentStep += 1);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (context, details) {
            if (_currentStep == steps.length - 1) {
              return const SizedBox.shrink(); // Hide default controls on last step
            }
            return Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'متابعة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'رجوع',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: steps,
        ),
      ),
    );
  }
}
