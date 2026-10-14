import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/supabase_config.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../../../common/models/driver_model.dart';
import '../../../common/models/verification_document.dart';
import '../../../common/models/user_model.dart';
import '../../../driver/domain/models/driver_payment_method.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_theme_wrapper.dart';

class DriverSignUpScreen extends ConsumerStatefulWidget {
  const DriverSignUpScreen({super.key});

  @override
  ConsumerState<DriverSignUpScreen> createState() => _DriverSignUpScreenState();
}

class _DriverSignUpScreenState extends ConsumerState<DriverSignUpScreen> {
  int _currentStep = 0;
  final int _totalSteps = 8;
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(8, (_) => GlobalKey<FormState>());
  bool _isLoading = false;
  String _uploadStatusText = '';

  // Step 1: Personal & Account
  final _nameController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _secondaryPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _nationality = 'يمني';
  String _gender = 'ذكر';
  final _dobController = TextEditingController();
  String _country = 'اليمن';
  String? _selectedGovernorate;
  String? _selectedCity;
  final _addressController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  List<String> _governorates = [];
  bool _isLoadingGovs = false;

  // Step 2: Identity & Passport
  final _passportNumberController = TextEditingController();
  final _passportExpiryController = TextEditingController();
  XFile? _frontIdImage;
  XFile? _backIdImage;
  XFile? _personalPhoto;

  // Step 3: Driving License
  final _licenseNumberController = TextEditingController();
  String _licenseType = 'خصوصي';
  String _licenseCountry = 'اليمن';
  final _licenseIssueController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  XFile? _frontLicenseImage;
  XFile? _backLicenseImage;

  // Step 4: Vehicle
  String _vehicleType = 'سيارة';
  String _fuelType = 'بنزين';
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _plateCountryController = TextEditingController(text: 'اليمن');
  final _seatsController = TextEditingController(text: '4');
  final _vinController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _registrationExpiryController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  XFile? _vehicleFrontImage;
  XFile? _vehicleBackImage;
  XFile? _vehicleRightImage;
  XFile? _vehicleLeftImage;
  XFile? _vehicleInteriorImage;
  XFile? _vehiclePlateImage;

  // Step 5: Working Areas
  bool _areaYemen = true;
  bool _areaSaudi = false;
  bool _areaBoth = false;
  final _citiesController = TextEditingController();

  // Step 6: Payment Methods
  String _paymentType = 'bank'; // 'bank' or 'wallet'
  final _paymentProviderController = TextEditingController(text: 'بنك الكريمي');
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  String _paymentCurrency = 'YER';

  // Step 7: Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // Step 8: Confirmation & Terms
  bool _confirmData = false;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _primaryPhoneController.dispose();
    _secondaryPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _addressController.dispose();

    _passportNumberController.dispose();
    _passportExpiryController.dispose();

    _licenseNumberController.dispose();
    _licenseIssueController.dispose();
    _licenseExpiryController.dispose();

    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _plateNumberController.dispose();
    _plateCountryController.dispose();
    _seatsController.dispose();
    _vinController.dispose();
    _registrationNumberController.dispose();
    _registrationExpiryController.dispose();
    _insuranceNumberController.dispose();
    _insuranceExpiryController.dispose();

    _citiesController.dispose();

    _paymentProviderController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();

    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadGovernorates() async {
    setState(() {
      _isLoadingGovs = true;
      _governorates = [];
      _selectedGovernorate = null;
    });

    try {
      final geoRepo = ref.read(geoRepositoryProvider);
      final countries = await geoRepo.getCountries();
      final countryCode = _country == 'اليمن' ? 'yemen' : 'saudi_arabia';
      final matches = countries.where((c) => c.id == countryCode).toList();
      if (matches.isNotEmpty) {
        final govs = await geoRepo.getGovernorates(matches.first.id);
        if (mounted) {
          setState(() {
            _governorates = govs.map((g) => g.nameAr).toList();
            if (_governorates.isNotEmpty) {
              _selectedGovernorate = _governorates.first;
            }
          });
        }
      } else {
        throw Exception();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_country == 'اليمن') {
            _governorates = [
              'أمانة العاصمة',
              'صنعاء',
              'عدن',
              'تعز',
              'إب',
              'حضرموت',
              'الحديدة',
              'مأرب',
              'شبوة',
            ];
          } else {
            _governorates = [
              'الرياض',
              'مكة المكرمة',
              'المدينة المنورة',
              'المنطقة الشرقية',
              'عسير',
              'نجران',
              'جازان',
            ];
          }
          _selectedGovernorate = _governorates.first;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingGovs = false);
      }
    }
  }

  Future<void> _pickImage(Function(XFile?) onPicked) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        onPicked(image);
      });
    }
  }

  Future<void> _selectDate({
    required BuildContext context,
    required TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate ?? DateTime(1940),
      lastDate: lastDate ?? DateTime(2045),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0B1F3A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0B1F3A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<bool> _callClaimBridge(String firebaseToken) async {
    final url =
        '${SupabaseConfig.supabaseUrl}/functions/v1/firebase-claim-bridge';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $firebaseToken',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  int _countUploadedDocuments() {
    int count = 0;
    if (_frontIdImage != null) count++;
    if (_backIdImage != null) count++;
    if (_personalPhoto != null) count++;
    if (_frontLicenseImage != null) count++;
    if (_backLicenseImage != null) count++;
    if (_vehicleFrontImage != null) count++;
    if (_vehicleBackImage != null) count++;
    if (_vehicleRightImage != null) count++;
    if (_vehicleLeftImage != null) count++;
    if (_vehicleInteriorImage != null) count++;
    if (_vehiclePlateImage != null) count++;
    return count;
  }

  void _onNextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? true) {
      // Custom validations per step
      if (_currentStep == 0) {
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('كلمات المرور غير متطابقة',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
      } else if (_currentStep == 1) {
        if (_frontIdImage == null ||
            _backIdImage == null ||
            _personalPhoto == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى إرفاق جميع صور الهوية والصورة الشخصية',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
      } else if (_currentStep == 2) {
        if (_frontLicenseImage == null || _backLicenseImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى إرفاق صورتي الرخصة (الأمام والخلف)',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
      } else if (_currentStep == 3) {
        if (_vehicleFrontImage == null ||
            _vehicleBackImage == null ||
            _vehicleRightImage == null ||
            _vehicleLeftImage == null ||
            _vehicleInteriorImage == null ||
            _vehiclePlateImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى إرفاق جميع صور المركبة (6 صور)',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
      } else if (_currentStep == 4) {
        if (!_areaYemen && !_areaSaudi && !_areaBoth) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('يرجى اختيار منطقة عمل واحدة على الأقل',
                  style: TextStyle(fontFamily: 'Cairo')),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          return;
        }
      }

      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    }
  }

  void _onPrevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    if (!_confirmData || !_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى الموافقة على جميع الشروط والإقرار بصحة البيانات',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Verify all 11 images
    if (_countUploadedDocuments() < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى استكمال رفع جميع المستندات المطلوبة (11 مستند)',
              style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatusText = 'جاري إنشاء الحساب وتجهيز الصلاحيات...';
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.setRegistrationInProgress(true);

      final expectedEmail = "${_primaryPhoneController.text.trim()}@rahal.app";
      final currentFbUser = FirebaseAuth.instance.currentUser;
      UserModel? user;

      if (currentFbUser != null && currentFbUser.email == expectedEmail) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentFbUser.uid)
            .get();
        if (doc.exists) {
          user = UserModel.fromFirestore(doc.data()!, doc.id);
        } else {
          user = UserModel(
            id: currentFbUser.uid,
            name: _nameController.text.trim(),
            email: expectedEmail,
            phone: _primaryPhoneController.text.trim(),
            role: 'driver',
            status: 'registering',
            walletBalance: 0.0,
            createdAt: DateTime.now(),
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentFbUser.uid)
              .set(user.toFirestore());
        }
      } else {
        user = await authNotifier.registerDriver(
          name: _nameController.text.trim(),
          email: expectedEmail,
          password: _passwordController.text,
          phone: _primaryPhoneController.text.trim(),
        );
      }

      if (!mounted) return;

      if (user != null) {
        final uid = user.id;

        setState(
            () => _uploadStatusText = 'جاري توثيق جلسة الأمان مع السحابة...');

        Future<void> performClaimBridge() async {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null) {
            final initialToken = await fbUser.getIdToken();
            if (initialToken != null) {
              final success = await _callClaimBridge(initialToken);
              if (!success) {
                throw Exception('فشل ربط جلسة الأمان مع خادم الصلاحيات.');
              }
              await fbUser.getIdToken(true);
            }
          }
        }

        await performClaimBridge();

        final storageService = SupabaseStorageService();
        final vehicleId = const Uuid().v4();

        Future<String> getUrl(
          String key,
          XFile file,
          String label, {
          bool isRetry = false,
        }) async {
          try {
            if (mounted) {
              setState(() => _uploadStatusText = 'جاري رفع $label...');
            }
            String url = '';
            if (key == 'personalPhoto') {
              url = await storageService.uploadDriverVerificationPhoto(
                  uid, file);
            } else if (key == 'vehicleFront' ||
                key == 'vehicleBack' ||
                key == 'vehicleRight' ||
                key == 'vehicleLeft' ||
                key == 'vehicleInterior') {
              String mappedKey = key;
              if (key == 'vehicleFront') mappedKey = 'exterior_front';
              if (key == 'vehicleBack') mappedKey = 'exterior_rear';
              if (key == 'vehicleRight') mappedKey = 'exterior_side_right';
              if (key == 'vehicleLeft') mappedKey = 'exterior_side_left';
              if (key == 'vehicleInterior') mappedKey = 'interior';
              url = await storageService.uploadVehiclePhoto(
                uid,
                vehicleId,
                mappedKey,
                file,
                isPrivate: false,
              );
            } else if (key == 'vehiclePlate') {
              url = await storageService.uploadVehiclePhoto(
                uid,
                vehicleId,
                key,
                file,
                isPrivate: true,
              );
            } else {
              url = await storageService.uploadDriverDocument(uid, key, file);
            }
            return url;
          } catch (e) {
            if (!isRetry) {
              await performClaimBridge();
              return await getUrl(key, file, label, isRetry: true);
            }
            throw Exception('فشل رفع $label. يرجى إعادة المحاولة.');
          }
        }

        Map<String, VerificationDocument> docs = {
          'idFront': VerificationDocument(
            url: await getUrl('idFront', _frontIdImage!, 'الهوية أمامي'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'idBack': VerificationDocument(
            url: await getUrl('idBack', _backIdImage!, 'الهوية خلفي'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'personalPhoto': VerificationDocument(
            url: await getUrl(
                'personalPhoto', _personalPhoto!, 'الصورة الشخصية'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'licenseFront': VerificationDocument(
            url: await getUrl(
                'licenseFront', _frontLicenseImage!, 'الرخصة أمامي'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'licenseBack': VerificationDocument(
            url:
                await getUrl('licenseBack', _backLicenseImage!, 'الرخصة خلفي'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'vehicleFront': VerificationDocument(
            url: await getUrl(
                'vehicleFront', _vehicleFrontImage!, 'المركبة أمامي'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'vehicleBack': VerificationDocument(
            url: await getUrl(
                'vehicleBack', _vehicleBackImage!, 'المركبة خلفي'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'vehicleRight': VerificationDocument(
            url: await getUrl(
                'vehicleRight', _vehicleRightImage!, 'المركبة يمين'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'vehicleLeft': VerificationDocument(
            url:
                await getUrl('vehicleLeft', _vehicleLeftImage!, 'المركبة يسار'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'vehicleInterior': VerificationDocument(
            url: await getUrl('vehicleInterior', _vehicleInteriorImage!,
                'المركبة من الداخل'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
          'vehiclePlate': VerificationDocument(
            url: await getUrl(
                'vehiclePlate', _vehiclePlateImage!, 'لوحة المركبة'),
            status: 'uploaded',
            updatedAt: DateTime.now(),
          ),
        };

        if (mounted) {
          setState(() => _uploadStatusText = 'جاري حفظ الملف والبيانات...');
        }

        List<String> areas = [];
        if (_areaYemen) areas.add('داخل اليمن');
        if (_areaSaudi) areas.add('داخل السعودية');
        if (_areaBoth) areas.add('اليمن ↔ السعودية');

        final driver = DriverModel.empty(uid).copyWith(
          fullName: _nameController.text.trim(),
          phone: _primaryPhoneController.text.trim(),
          email: expectedEmail,
          licenseNumber: _licenseNumberController.text.trim(),
          nationality: _nationality,
          gender: _gender,
          dateOfBirth: _dobController.text.trim(),
          country: _country,
          governorate: _selectedGovernorate ?? '',
          city: _selectedCity ?? _citiesController.text.trim(),
          secondaryPhone: _secondaryPhoneController.text.trim(),
          detailedAddress: _addressController.text.trim(),
          passportNumber: _passportNumberController.text.trim(),
          passportExpiry: _passportExpiryController.text.trim(),
          licenseType: _licenseType,
          licenseCountry: _licenseCountry,
          licenseIssueDate: _licenseIssueController.text.trim(),
          licenseExpiryDate: _licenseExpiryController.text.trim(),
          vehicleType: _vehicleType,
          vehicleManufacturer: _manufacturerController.text.trim(),
          vehicleModel: _modelController.text.trim(),
          vehicleYear: _yearController.text.trim(),
          vehicleColor: _colorController.text.trim(),
          fuelType: _fuelType,
          plateNumber: _plateNumberController.text.trim(),
          plateCountry: _plateCountryController.text.trim(),
          seatCount: int.tryParse(_seatsController.text) ?? 4,
          vin: _vinController.text.trim(),
          registrationNumber: _registrationNumberController.text.trim(),
          registrationExpiry: _registrationExpiryController.text.trim(),
          insuranceNumber: _insuranceNumberController.text.trim(),
          insuranceExpiry: _insuranceExpiryController.text.trim(),
          operatingAreas: areas,
          operatingCities: [_citiesController.text.trim()],
          bankName: _paymentProviderController.text.trim(),
          accountHolder: _accountHolderController.text.trim(),
          accountNumber: _accountNumberController.text.trim(),
          iban: _ibanController.text.trim(),
          ewalletName: _paymentType == 'wallet'
              ? _paymentProviderController.text.trim()
              : '',
          ewalletNumber: _accountNumberController.text.trim(),
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactRelation: _emergencyRelationController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
          documents: docs,
          status: 'pending_review',
          vehicleId: vehicleId,
        );

        final vehicle = Vehicle(
          id: vehicleId,
          driverId: uid,
          make: _manufacturerController.text.trim(),
          model: _modelController.text.trim(),
          year: int.tryParse(_yearController.text) ?? DateTime.now().year,
          color: _colorController.text.trim(),
          plateNumber: _plateNumberController.text.trim(),
          vin: _vinController.text.trim(),
          registrationNumber: _registrationNumberController.text.trim(),
          insuranceNumber: _insuranceNumberController.text.trim(),
          type: _vehicleType,
          fuelType: _fuelType,
          seatsCount: int.tryParse(_seatsController.text) ?? 4,
          status: 'Pending',
          photoUrl: docs['vehicleFront']?.url ?? '',
          additionalPhotos: [
            if (docs['vehicleBack']?.url != null) docs['vehicleBack']!.url,
            if (docs['vehicleRight']?.url != null) docs['vehicleRight']!.url,
            if (docs['vehicleLeft']?.url != null) docs['vehicleLeft']!.url,
            if (docs['vehicleInterior']?.url != null)
              docs['vehicleInterior']!.url,
          ],
          isDefault: true,
        );

        final batch = FirebaseFirestore.instance.batch();
        final driverRef =
            FirebaseFirestore.instance.collection('drivers').doc(uid);
        final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        final vehicleRef =
            FirebaseFirestore.instance.collection('vehicles').doc(vehicleId);

        batch.set(driverRef, driver.toFirestore());
        batch.set(vehicleRef, vehicle.toJson());
        batch.update(userRef, {'status': 'pending_review'});

        // Part 17 & 45: Save initial payment method as active, approvalStatus: 'not_required'
        if (_accountNumberController.text.trim().isNotEmpty) {
          final paymentId = const Uuid().v4();
          final paymentMethod = DriverPaymentMethod(
            id: paymentId,
            driverId: uid,
            type: _paymentType,
            providerName: _paymentProviderController.text.trim(),
            accountHolderName: _accountHolderController.text.trim(),
            accountNumber: _accountNumberController.text.trim(),
            iban: _ibanController.text.trim(),
            currency: _paymentCurrency,
            country: _country,
            isActive: true,
            approvalStatus: 'not_required',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          final paymentRef = FirebaseFirestore.instance
              .collection('driver_payment_methods')
              .doc(paymentId);
          batch.set(paymentRef, paymentMethod.toJson());
        }

        await batch.commit();

        if (!mounted) return;
        context.go('/pending-approval');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      ref.read(authProvider.notifier).setRegistrationInProgress(false);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthThemeWrapper(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0B1F3A),
                size: 20,
              ),
              onPressed: _onPrevStep,
            ),
            title: const Text(
              'تسجيل كابتن رحال',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1F3A),
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: _isLoading ? _buildLoadingOverlay() : _buildWizardBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B1F3A).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF5A623)),
                strokeWidth: 3.5,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _uploadStatusText.isNotEmpty
                  ? _uploadStatusText
                  : 'جاري معالجة طلب التسجيل...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1F3A),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'يرجى عدم إغلاق التطبيق أثناء رفع المستندات الآمنة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardBody() {
    final titles = [
      'المعلومات الشخصية والحساب',
      'الهوية والجواز',
      'رخصة القيادة',
      'بيانات ومستندات المركبة',
      'مناطق ومسارات العمل',
      'طرق استلام المستحقات',
      'جهة اتصال الطوارئ',
      'المراجعة النهائية والمستندات',
    ];

    return Column(
      children: [
        // Wizard Progress Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المرحلة ${_currentStep + 1} من $_totalSteps',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF5A623),
                    ),
                  ),
                  Text(
                    '${_countUploadedDocuments()} / 11 مستند',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                titles[_currentStep],
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F3A),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF0B1F3A),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // Wizard Step Page Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildCurrentStepContent(),
          ),
        ),

        // Bottom Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _onPrevStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B1F3A),
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'السابق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _onNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B1F3A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == _totalSteps - 1
                            ? 'إرسال طلب الانضمام'
                            : 'التالي',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentStep == _totalSteps - 1
                            ? Icons.check_circle_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal();
      case 1:
        return _buildStep2Identity();
      case 2:
        return _buildStep3License();
      case 3:
        return _buildStep4Vehicle();
      case 4:
        return _buildStep5Areas();
      case 5:
        return _buildStep6Payment();
      case 6:
        return _buildStep7Emergency();
      case 7:
        return _buildStep8Review();
      default:
        return const SizedBox();
    }
  }

  // STEP 1: Personal Info
  Widget _buildStep1Personal() {
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'الاسم الرباعي الكامل *',
            icon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'يرجى إدخال الاسم';
              if (v.trim().split(RegExp(r'\s+')).length < 3) {
                return 'الاسم يجب أن يكون ثلاثياً على الأقل';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: _buildTextField(
              controller: _primaryPhoneController,
              label: 'رقم الهاتف الأساسي *',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'يرجى إدخال رقم الهاتف'
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: _buildTextField(
              controller: _secondaryPhoneController,
              label: 'رقم هاتف إضافي (اختياري)',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            label: 'كلمة المرور *',
            icon: Icons.lock_outline_rounded,
            isPassword: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) =>
                v == null || v.length < 8 ? 'يجب أن لا تقل عن 8 خانات' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'تأكيد كلمة المرور *',
            icon: Icons.lock_outline_rounded,
            isPassword: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (v) => v != _passwordController.text
                ? 'كلمات المرور غير متطابقة'
                : null,
          ),
          const SizedBox(height: 12),
          _buildDateField(
            controller: _dobController,
            label: 'تاريخ الميلاد *',
            icon: Icons.cake_outlined,
            initialDate: DateTime(1995, 1, 1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'الجنسية *',
                  value: _nationality,
                  items: const ['يمني', 'سعودي', 'أخرى'],
                  onChanged: (v) => setState(() => _nationality = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'الجنس *',
                  value: _gender,
                  items: const ['ذكر', 'أنثى'],
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'الدولة الحالية *',
            value: _country,
            items: const ['اليمن', 'السعودية'],
            onChanged: (v) {
              setState(() => _country = v!);
              _loadGovernorates();
            },
          ),
          const SizedBox(height: 12),
          if (_isLoadingGovs)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_governorates.isNotEmpty)
            _buildDropdown(
              label: 'المحافظة *',
              value: _selectedGovernorate ?? _governorates.first,
              items: _governorates,
              onChanged: (v) => setState(() => _selectedGovernorate = v),
            ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressController,
            label: 'العنوان التفصيلي / الشارع *',
            icon: Icons.home_work_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'يرجى إدخال العنوان' : null,
          ),
        ],
      ),
    );
  }

  // STEP 2: Identity & Passport
  Widget _buildStep2Identity() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _passportNumberController,
            label: 'رقم الهوية الوطنية / جواز السفر *',
            icon: Icons.badge_outlined,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'يرجى إدخال رقم الهوية أو الجواز'
                : null,
          ),
          const SizedBox(height: 12),
          _buildDateField(
            controller: _passportExpiryController,
            label: 'تاريخ انتهاء الهوية / الجواز *',
            icon: Icons.event_available_outlined,
            initialDate: DateTime.now().add(const Duration(days: 365)),
          ),
          const SizedBox(height: 20),
          const Text(
            'المستندات المطلوبة (3 صور)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'احرص على أن تكون الصور واضحة وخالية من الانعكاسات الضوئية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _buildUploadCard(
            title: 'الصورة الشخصية للكابتن',
            subtitle: 'صورة حديثة واضحة الوجه (بخلفية بيضاء أو محايدة)',
            file: _personalPhoto,
            isRequired: true,
            onPick: () => _pickImage((f) => _personalPhoto = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'صورة الهوية / الجواز (الوجه الأمامي)',
            subtitle: 'تظهر فيها الصورة والبيانات الشخصية بوضوح',
            file: _frontIdImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _frontIdImage = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'صورة الهوية / الجواز (الوجه الخلفي)',
            subtitle: 'الصفحة المقابلة أو الوجه الخلفي للبطاقة',
            file: _backIdImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _backIdImage = f),
          ),
        ],
      ),
    );
  }

  // STEP 3: Driving License
  Widget _buildStep3License() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _licenseNumberController,
            label: 'رقم رخصة القيادة *',
            icon: Icons.assignment_outlined,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'يرجى إدخال رقم الرخصة'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'فئة الرخصة *',
                  value: _licenseType,
                  items: const ['خصوصي', 'عمومي', 'نقل خفيف', 'نقل ثقيل'],
                  onChanged: (v) => setState(() => _licenseType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'دولة الإصدار *',
                  value: _licenseCountry,
                  items: const ['اليمن', 'السعودية', 'أخرى'],
                  onChanged: (v) => setState(() => _licenseCountry = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDateField(
            controller: _licenseIssueController,
            label: 'تاريخ إصدار الرخصة *',
            icon: Icons.event_note_outlined,
            initialDate: DateTime.now().subtract(const Duration(days: 365)),
          ),
          const SizedBox(height: 12),
          _buildDateField(
            controller: _licenseExpiryController,
            label: 'تاريخ انتهاء الرخصة *',
            icon: Icons.event_available_outlined,
            initialDate: DateTime.now().add(const Duration(days: 730)),
          ),
          const SizedBox(height: 20),
          const Text(
            'صور رخصة القيادة (مستندان)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 14),
          _buildUploadCard(
            title: 'رخصة القيادة (الوجه الأمامي)',
            subtitle: 'يجب أن تظهر تفاصيل الاسم والرقم وفئة القيادة بوضوح',
            file: _frontLicenseImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _frontLicenseImage = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'رخصة القيادة (الوجه الخلفي)',
            subtitle: 'تظهر تاريخ الصلاحية وملاحظات الإصدار',
            file: _backLicenseImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _backLicenseImage = f),
          ),
        ],
      ),
    );
  }

  // STEP 4: Vehicle Information
  Widget _buildStep4Vehicle() {
    return Form(
      key: _formKeys[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'نوع المركبة *',
                  value: _vehicleType,
                  items: const ['سيارة', 'باص', 'فان', 'صالون', 'أخرى'],
                  onChanged: (v) => setState(() => _vehicleType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'نوع الوقود *',
                  value: _fuelType,
                  items: const ['بنزين', 'ديزل', 'هجين', 'غاز'],
                  onChanged: (v) => setState(() => _fuelType = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _manufacturerController,
                  label: 'الشركة (مثل: تويوتا) *',
                  icon: Icons.directions_car_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _modelController,
                  label: 'الموديل (مثل: كامري) *',
                  icon: Icons.drive_eta_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _yearController,
                  label: 'سنة الصنع *',
                  icon: Icons.date_range_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _colorController,
                  label: 'لون المركبة *',
                  icon: Icons.color_lens_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _plateNumberController,
                  label: 'رقم اللوحة *',
                  icon: Icons.tag_rounded,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _seatsController,
                  label: 'عدد المقاعد *',
                  icon: Icons.event_seat_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'مطلوب' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _vinController,
            label: 'رقم الهيكل (VIN) *',
            icon: Icons.vpn_key_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'يرجى إدخال رقم الهيكل' : null,
          ),
          const SizedBox(height: 12),
          _buildDateField(
            controller: _registrationExpiryController,
            label: 'تاريخ انتهاء استمارة المركبة *',
            icon: Icons.event_available_outlined,
            initialDate: DateTime.now().add(const Duration(days: 365)),
          ),
          const SizedBox(height: 12),
          _buildDateField(
            controller: _insuranceExpiryController,
            label: 'تاريخ انتهاء تأمين المركبة *',
            icon: Icons.security_outlined,
            initialDate: DateTime.now().add(const Duration(days: 365)),
          ),
          const SizedBox(height: 20),
          const Text(
            'صور المركبة المطلوبة (6 صور)',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 14),
          _buildUploadCard(
            title: 'صورة المركبة من الأمام',
            subtitle: 'صورة زاوية كاملة للواجهة الأمامية للمركبة',
            file: _vehicleFrontImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _vehicleFrontImage = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'صورة المركبة من الخلف',
            subtitle: 'تظهر فيها خلفية المركبة واللوحة بوضوح',
            file: _vehicleBackImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _vehicleBackImage = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'صورة المركبة من الجانب الأيمن',
            subtitle: 'هيكل المركبة من الجهة اليمنى كاملاً',
            file: _vehicleRightImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _vehicleRightImage = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'صورة المركبة من الجانب الأيسر',
            subtitle: 'هيكل المركبة من جهة السائق كاملاً',
            file: _vehicleLeftImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _vehicleLeftImage = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'صورة مقصورة المركبة من الداخل',
            subtitle: 'توضح نظافة المقاعد وراحة الركاب',
            file: _vehicleInteriorImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _vehicleInteriorImage = f),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: 'صورة لوحة المركبة (مقرّبة)',
            subtitle: 'صورة واضحة ومباشرة لأرقام وحروف اللوحة',
            file: _vehiclePlateImage,
            isRequired: true,
            onPick: () => _pickImage((f) => _vehiclePlateImage = f),
          ),
        ],
      ),
    );
  }

  // STEP 5: Operating Areas
  Widget _buildStep5Areas() {
    return Form(
      key: _formKeys[4],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نطاق تشغيل الرحلات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اختر النطاق الجغرافي الذي ترغب في تقديم رحلاتك ونقل الركاب والطرود خلاله:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _buildAreaChip(
            title: 'داخل محافظات الجمهورية اليمنية',
            subtitle: 'رحلات بين المدن والمحافظات اليمنية',
            isSelected: _areaYemen,
            onToggle: () => setState(() => _areaYemen = !_areaYemen),
          ),
          const SizedBox(height: 12),
          _buildAreaChip(
            title: 'داخل المملكة العربية السعودية',
            subtitle: 'رحلات بين مناطق ومدن المملكة',
            isSelected: _areaSaudi,
            onToggle: () => setState(() => _areaSaudi = !_areaSaudi),
          ),
          const SizedBox(height: 12),
          _buildAreaChip(
            title: 'رحلات دولية مشتركة (اليمن ↔ السعودية)',
            subtitle: 'رحلات عبر المنافذ البرية الدولية (الوديعة وغيرها)',
            isSelected: _areaBoth,
            onToggle: () => setState(() => _areaBoth = !_areaBoth),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _citiesController,
            label: 'المدن والمحافظات المفضلة (اختياري)',
            icon: Icons.map_outlined,
            hint: 'مثال: صنعاء، عدن، تعز، الرياض، مكة المكرمة...',
          ),
        ],
      ),
    );
  }

  // STEP 6: Payment Methods (No Admin Approval Required)
  Widget _buildStep6Payment() {
    return Form(
      key: _formKeys[5],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFF5A623).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Color(0xFFB45309),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'طرق الدفع تفعل فورياً لحسابك بدون الحاجة لموافقة مسبقة من الإدارة.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  label: 'حساب بنكي',
                  icon: Icons.account_balance_outlined,
                  isSelected: _paymentType == 'bank',
                  onSelect: () => setState(() {
                    _paymentType = 'bank';
                    _paymentProviderController.text = 'بنك الكريمي';
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChoiceChip(
                  label: 'محفظة إلكترونية',
                  icon: Icons.account_balance_wallet_outlined,
                  isSelected: _paymentType == 'wallet',
                  onSelect: () => setState(() {
                    _paymentType = 'wallet';
                    _paymentProviderController.text = 'محفظة جيب / كاش';
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _paymentProviderController,
            label: _paymentType == 'bank'
                ? 'اسم البنك / المصرف *'
                : 'اسم المحفظة الإلكترونية *',
            icon: Icons.storefront_outlined,
            hint: _paymentType == 'bank'
                ? 'الكريمي، الراجحي، بنك التضامن...'
                : 'محفظة ون، كاش، جوال...',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'يرجى إدخال اسم الجهة' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _accountHolderController,
            label: 'اسم صاحب الحساب كما هو مقيد رسمياً *',
            icon: Icons.person_pin_outlined,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'يرجى إدخال اسم صاحب الحساب'
                : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _accountNumberController,
            label: _paymentType == 'bank'
                ? 'رقم الحساب البنكي *'
                : 'رقم المحفظة (الهاتف) *',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.text,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'يرجى إدخال رقم الحساب' : null,
          ),
          const SizedBox(height: 12),
          if (_paymentType == 'bank')
            _buildTextField(
              controller: _ibanController,
              label: 'رقم الآيبان الدولي (IBAN) (اختياري)',
              icon: Icons.credit_card_outlined,
            ),
          const SizedBox(height: 12),
          _buildDropdown(
            label: 'عملة الحساب *',
            value: _paymentCurrency,
            items: const ['YER', 'SAR'],
            onChanged: (v) => setState(() => _paymentCurrency = v!),
          ),
        ],
      ),
    );
  }

  // STEP 7: Emergency Contact
  Widget _buildStep7Emergency() {
    return Form(
      key: _formKeys[6],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF0B1F3A),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'بيانات الطوارئ سرية تماماً ولن يتم مشاركتها مع الركاب نهائياً. تستخدم فقط في الحالات الحرجة.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildTextField(
            controller: _emergencyNameController,
            label: 'اسم جهة اتصال الطوارئ *',
            icon: Icons.person_outline,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'يرجى إدخال الاسم' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _emergencyRelationController,
            label: 'صلة القرابة (مثل: أب، أخ، زوجة، صديق) *',
            icon: Icons.family_restroom_outlined,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'يرجى تحديد صلة القرابة' : null,
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: _buildTextField(
              controller: _emergencyPhoneController,
              label: 'رقم هاتف الطوارئ *',
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'يرجى إدخال رقم الهاتف'
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 8: Review & Terms
  Widget _buildStep8Review() {
    final docsCount = _countUploadedDocuments();

    return Form(
      key: _formKeys[7],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Documents completeness banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: docsCount == 11
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: docsCount == 11
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFFEF4444).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  docsCount == 11
                      ? Icons.check_circle_rounded
                      : Icons.warning_rounded,
                  color: docsCount == 11
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docsCount == 11
                            ? 'جميع المستندات مكتملة (11 / 11)'
                            : 'مستندات غير مكتملة ($docsCount / 11)',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: docsCount == 11
                              ? const Color(0xFF065F46)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                      Text(
                        docsCount == 11
                            ? 'جاهز لرفع المستندات المشفرة ومراجعة الحساب.'
                            : 'يرجى الرجوع لمراحل المستندات واستكمال الرفع.',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'ملخص البيانات المسجلة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 10),

          // Summary Cards
          _buildSummaryCard(
            title: 'المعلومات الشخصية',
            items: [
              'الاسم: ${_nameController.text}',
              'الهاتف: ${_primaryPhoneController.text}',
              'الدولة والمحافظة: $_country - ${_selectedGovernorate ?? ""}',
            ],
            onEdit: () => setState(() => _currentStep = 0),
          ),
          const SizedBox(height: 10),
          _buildSummaryCard(
            title: 'الهوية والجواز',
            items: [
              'الرقم: ${_passportNumberController.text}',
              'الانتهاء: ${_passportExpiryController.text}',
            ],
            onEdit: () => setState(() => _currentStep = 1),
          ),
          const SizedBox(height: 10),
          _buildSummaryCard(
            title: 'رخصة القيادة',
            items: [
              'الرقم: ${_licenseNumberController.text}',
              'الفئة: $_licenseType',
              'الانتهاء: ${_licenseExpiryController.text}',
            ],
            onEdit: () => setState(() => _currentStep = 2),
          ),
          const SizedBox(height: 10),
          _buildSummaryCard(
            title: 'المركبة',
            items: [
              '${_manufacturerController.text} ${_modelController.text} (${_yearController.text})',
              'اللوحة: ${_plateNumberController.text} - المقاعد: ${_seatsController.text}',
            ],
            onEdit: () => setState(() => _currentStep = 3),
          ),
          const SizedBox(height: 10),
          _buildSummaryCard(
            title: 'طريقة الدفع',
            items: [
              'الجهة: ${_paymentProviderController.text}',
              'صاحب الحساب: ${_accountHolderController.text}',
              'الحساب: ${_accountNumberController.text}',
            ],
            onEdit: () => setState(() => _currentStep = 5),
          ),
          const SizedBox(height: 18),

          // Terms Checkboxes
          CheckboxListTile(
            value: _confirmData,
            activeColor: const Color(0xFFF5A623),
            checkColor: const Color(0xFF0B1F3A),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'أقر بأن جميع البيانات والمستندات المرفقة صحيحة ودقيقة.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
            onChanged: (v) => setState(() => _confirmData = v ?? false),
          ),
          CheckboxListTile(
            value: _acceptTerms,
            activeColor: const Color(0xFFF5A623),
            checkColor: const Color(0xFF0B1F3A),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'أوافق على الشروط والأحكام العامة لكباتن رحال.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
            onChanged: (v) => setState(() => _acceptTerms = v ?? false),
          ),
          CheckboxListTile(
            value: _acceptPrivacy,
            activeColor: const Color(0xFFF5A623),
            checkColor: const Color(0xFF0B1F3A),
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'أوافق على سياسة الخصوصية واستخدام البيانات لمنصة رحال.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
            ),
            onChanged: (v) => setState(() => _acceptPrivacy = v ?? false),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPERS
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        color: Color(0xFF0B1F3A),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: Color(0xFF9CA3AF),
        ),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF0B1F3A), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    DateTime? initialDate,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        color: Color(0xFF0B1F3A),
      ),
      onTap: () => _selectDate(
        context: context,
        controller: controller,
        initialDate: initialDate,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF0B1F3A), size: 20),
        suffixIcon: const Icon(Icons.calendar_month_rounded,
            color: Color(0xFF6B7280), size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? 'يرجى اختيار التاريخ' : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final validValue = items.contains(value) ? value : items.first;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontFamily: 'Cairo')),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required XFile? file,
    required bool isRequired,
    required VoidCallback onPick,
  }) {
    final isUploaded = file != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded
              ? const Color(0xFF10B981)
              : const Color(0xFFE5E7EB),
          width: isUploaded ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail / Status Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUploaded
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUploaded
                  ? Icons.check_circle_rounded
                  : Icons.cloud_upload_outlined,
              color: isUploaded
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6B7280),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1F3A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isUploaded
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : (isRequired
                                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                                : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isUploaded
                            ? 'تم الرفع'
                            : (isRequired ? 'مطلوب' : 'اختياري'),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isUploaded
                              ? const Color(0xFF10B981)
                              : (isRequired
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF6B7280)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isUploaded ? file.name : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: isUploaded
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action button
          TextButton(
            onPressed: onPick,
            style: TextButton.styleFrom(
              foregroundColor: isUploaded
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF0B1F3A),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: Text(
              isUploaded ? 'استبدال' : 'اختيار',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChip({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onToggle,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0B1F3A).withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF5A623)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              color: isSelected
                  ? const Color(0xFFF5A623)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0B1F3A)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0B1F3A)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFFF5A623) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required List<String> items,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F3A),
                ),
              ),
              InkWell(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 14, color: Color(0xFFF5A623)),
                    SizedBox(width: 4),
                    Text(
                      'تعديل',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Color(0xFFF5A623),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text(
                it,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
