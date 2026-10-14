import 'package:flutter/material.dart';
import 'package:rahal/features/auth/presentation/widgets/auth_theme_wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/storage/supabase_storage_service.dart';
import '../providers/auth_provider.dart';
import '../../../common/models/company_model.dart';
import '../../../common/models/verification_document.dart';
import '../../../common/providers/common_providers.dart';

class CompanySignUpScreen extends ConsumerStatefulWidget {
  const CompanySignUpScreen({super.key});

  @override
  ConsumerState<CompanySignUpScreen> createState() =>
      _CompanySignUpScreenState();
}

class _CompanySignUpScreenState extends ConsumerState<CompanySignUpScreen> {
  int _currentStep = 0;
  final List<GlobalKey<FormState>> _formKeys = List.generate(
    6,
    (_) => GlobalKey<FormState>(),
  );
  bool _isLoading = false;

  // Controllers for Section 1
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controllers for Section 2
  final _managerNameController = TextEditingController();
  final _managerPhoneController = TextEditingController();
  final _managerPositionController = TextEditingController();
  final _managerNationalityController = TextEditingController();
  final _managerPassportNumberController = TextEditingController();
  XFile? _managerIdImage;

  // Controllers for Section 3
  final _countryController = TextEditingController(text: 'اليمن');
  final _govController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _yearController = TextEditingController();
  String _businessType = 'نقل أفراد';
  final _branchesController = TextEditingController();
  final _vehiclesController = TextEditingController();
  final _driversController = TextEditingController();
  final _descController = TextEditingController();

  // Controllers for Section 4
  final _crNumberController = TextEditingController();
  final _crExpiryController = TextEditingController();
  XFile? _crImage;

  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  XFile? _licenseImage;

  final _taxController = TextEditingController();
  XFile? _logoImage;
  XFile? _officeFrontImage;
  XFile? _officeInteriorImage;

  // Controllers for Section 5
  final _bankController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _walletTypeController = TextEditingController();
  final _walletNumberController = TextEditingController();

  // Controllers for Section 6
  bool _confirmData = false;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(Function(XFile?) onPicked) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        onPicked(image);
      });
    }
  }

  Future<String> _uploadImage(XFile file, String path) async {
    final storageService = SupabaseStorageService();
    return await storageService.uploadGenericFile(path, file);
  }

  Future<void> _submit() async {
    debugPrint('=== SIGNUP STEP 1: VALIDATE FORM FIELDS ===');
    if (!_formKeys[5].currentState!.validate()) return;
    if (!_confirmData || !_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى الموافقة على جميع الشروط')),
      );
      return;
    }
    debugPrint('=== SIGNUP STEP 1: SUCCESS VALIDATION ===');

    setState(() => _isLoading = true);
    try {
      debugPrint(
        '=== SIGNUP STEP 2: CALL registerCompany() in authNotifier ===',
      );
      final authNotifier = ref.read(authProvider.notifier);
      final user = await authNotifier.registerCompany(
        name: _nameController.text.trim(),
        email: "${_phoneController.text.trim()}@rahal.com",
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
      );
      debugPrint('=== SIGNUP STEP 2: registerCompany() COMPLETED ===');

      if (!mounted) {
        debugPrint(
          '=== SIGNUP ERROR: Widget unmounted after registerCompany ===',
        );
        return;
      }

      if (user != null) {
        final uid = user.id;
        debugPrint('=== AUTHENTICATED WITH UID: $uid ===');

        Map<String, VerificationDocument> docs = {};

        final company = CompanyModel(
          id: uid,
          name: _nameController.text,
          ownerId: uid,
          status: 'pending_review',
          walletBalance: 0.0,
          companyPhone: _phoneController.text,
          alternativePhone: _altPhoneController.text,
          managerName: _managerNameController.text,
          managerPhone: _managerPhoneController.text,
          managerPosition: _managerPositionController.text,
          managerNationality: _managerNationalityController.text,
          managerPassportNumber: _managerPassportNumberController.text,
          managerPassportExpiry: "",

          country: _countryController.text,
          governorate: _govController.text,
          mainCity: _cityController.text,
          detailedAddress: _addressController.text,
          establishmentYear: _yearController.text,
          businessType: _businessType,
          branchCount: int.tryParse(_branchesController.text) ?? 0,
          fleetSize: int.tryParse(_vehiclesController.text) ?? 0,
          driverCount: int.tryParse(_driversController.text) ?? 0,
          companyDescription: _descController.text,
          commercialRegister: _crNumberController.text,

          registrationExpiry: _crExpiryController.text,
          operatingLicense: _licenseNumberController.text,
          licenseExpiry: _licenseExpiryController.text,
          taxNumber: _taxController.text,
          bankName: _bankController.text,
          accountHolder: _accountHolderController.text,
          accountNumber: _accountNumberController.text,
          iban: _ibanController.text,
          ewalletName: _walletTypeController.text,
          ewalletNumber: _walletNumberController.text,
          documents: docs,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        debugPrint(
          '=== SIGNUP STEP 7b: OVERWRITE COMPANY DOCUMENT IN FIRESTORE ===',
        );
        await ref.read(companyRepositoryProvider).create(company);
        debugPrint('=== SIGNUP STEP 7b: SUCCESS ===');

        debugPrint('=== SIGNUP STEP 8: START IMAGE UPLOADS ===');
        Future<void> uploadDoc(String key, XFile? file) async {
          if (file != null) {
            try {
              final url = await _uploadImage(
                file,
                "verification_company/$uid/$key.jpg",
              );
              docs[key] = VerificationDocument(
                url: url,
                status: 'uploaded',
                updatedAt: DateTime.now(),
              );
            } catch (e) {
              debugPrint('Image upload failed for $key: $e');
              throw Exception('فشل رفع $key: $e');
            }
          }
        }

        await uploadDoc('managerId', _managerIdImage);
        await uploadDoc('commercialRegistration', _crImage);
        await uploadDoc('operatingLicense', _licenseImage);
        await uploadDoc('companyLogo', _logoImage);
        await uploadDoc('officeFront', _officeFrontImage);
        debugPrint('=== SIGNUP STEP 8: COMPLETED IMAGE UPLOADS ===');

        // 3. UPDATE FIRESTORE WITH SUCCESSFUL IMAGES
        try {
          debugPrint('=== SIGNUP STEP 9: UPDATE FIRESTORE WITH DOC URLS ===');
          final updatedCompany = company.copyWith(documents: docs);
          await ref.read(companyRepositoryProvider).update(updatedCompany);
          debugPrint('=== SIGNUP STEP 9: SUCCESS ===');
        } catch (e, stack) {
          debugPrint('Failed to update documents map in Firestore: $e\n$stack');
        }

        // 4. UPDATE USER STATUS TO pending_review
        try {
          debugPrint(
            '=== SIGNUP STEP 10: UPDATE USER STATUS TO pending_review ===',
          );
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'status': 'pending_review',
          });
          debugPrint('=== SIGNUP STEP 10: SUCCESS ===');
        } catch (e, stack) {
          debugPrint(
            'Failed to update user status to pending_review: $e\n$stack',
          );
        }

        if (!mounted) return;
        debugPrint('=== SIGNUP SUCCESS: REDIRECTING ===');
        context.go('/pending-approval');
      } else {
        debugPrint('=== SIGNUP FAILED: User is null ===');
      }
    } catch (e, stack) {
      debugPrint('=== SIGNUP ERROR CAUGHT IN UI: $e ===\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = true,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: isRequired ? (v) => v!.isEmpty ? 'مطلوب' : null : null,
      ),
    );
  }

  Widget _buildImagePicker(
    String label,
    XFile? file,
    Function(XFile?) onPicked,
  ) {
    return ListTile(
      title: Text(label),
      subtitle: Text(file != null ? 'تم الاختيار' : 'لم يتم الاختيار'),
      trailing: const Icon(Icons.camera_alt),
      onTap: () => _pickImage(onPicked),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthThemeWrapper(
      child: Scaffold(
        appBar: AppBar(title: Text('تسجيل شركة جديدة')),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Stepper(
                type: StepperType.vertical,
                physics: ClampingScrollPhysics(),
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_formKeys[_currentStep].currentState!.validate()) {
                    if (_currentStep < 5) {
                      setState(() => _currentStep++);
                    } else {
                      _submit();
                    }
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    context.pop();
                  }
                },
                steps: [
                  Step(
                    title: Text('معلومات الحساب'),
                    content: Form(
                      key: _formKeys[0],
                      child: Column(
                        children: [
                          _buildTextField(_nameController, 'اسم الشركة'),
                          _buildTextField(
                            _phoneController,
                            'رقم الهاتف',
                            type: TextInputType.phone,
                          ),
                          _buildTextField(
                            _altPhoneController,
                            'رقم بديل',
                            isRequired: false,
                            type: TextInputType.phone,
                          ),
                          _buildTextField(
                            _passwordController,
                            'كلمة المرور',
                            isPassword: true,
                          ),
                          _buildTextField(
                            _confirmPasswordController,
                            'تأكيد كلمة المرور',
                            isPassword: true,
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: Text('المسؤول'),
                    content: Form(
                      key: _formKeys[1],
                      child: Column(
                        children: [
                          _buildTextField(_managerNameController, 'اسم المدير'),
                          _buildTextField(
                            _managerPhoneController,
                            'رقم هاتف المدير',
                            type: TextInputType.phone,
                          ),
                          _buildTextField(_managerPositionController, 'المنصب'),
                          _buildTextField(
                            _managerNationalityController,
                            'الجنسية',
                          ),
                          _buildTextField(
                            _managerPassportNumberController,
                            'رقم الهوية',
                          ),
                          _buildImagePicker(
                            'صورة الهوية',
                            _managerIdImage,
                            (f) => _managerIdImage = f,
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 1,
                  ),
                  Step(
                    title: Text('معلومات الشركة'),
                    content: Form(
                      key: _formKeys[2],
                      child: Column(
                        children: [
                          _buildTextField(_countryController, 'الدولة'),
                          _buildTextField(_govController, 'المحافظة'),
                          _buildTextField(_cityController, 'المدينة'),
                          _buildTextField(
                            _addressController,
                            'العنوان التفصيلي',
                          ),
                          _buildTextField(
                            _yearController,
                            'سنة التأسيس',
                            type: TextInputType.number,
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _businessType,
                            items:
                                [
                                      'نقل أفراد',
                                      'نقل جماعي',
                                      'نقل دولي',
                                      'نقل داخلي',
                                      'شحن',
                                    ]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) =>
                                setState(() => _businessType = v!),
                            decoration: InputDecoration(
                              labelText: 'نوع النشاط',
                            ),
                          ),
                          _buildTextField(
                            _branchesController,
                            'عدد الفروع',
                            type: TextInputType.number,
                          ),
                          _buildTextField(
                            _vehiclesController,
                            'عدد المركبات',
                            type: TextInputType.number,
                          ),
                          _buildTextField(
                            _driversController,
                            'عدد السائقين',
                            type: TextInputType.number,
                          ),
                          _buildTextField(
                            _descController,
                            'وصف الشركة',
                            isRequired: false,
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 2,
                  ),
                  Step(
                    title: Text('الوثائق الرسمية'),
                    content: Form(
                      key: _formKeys[3],
                      child: Column(
                        children: [
                          _buildTextField(
                            _crNumberController,
                            'رقم السجل التجاري',
                          ),
                          _buildTextField(
                            _crExpiryController,
                            'تاريخ انتهاء السجل',
                          ),
                          _buildImagePicker(
                            'صورة السجل',
                            _crImage,
                            (f) => _crImage = f,
                          ),
                          _buildTextField(
                            _licenseNumberController,
                            'رقم ترخيص المزاولة',
                          ),
                          _buildTextField(
                            _licenseExpiryController,
                            'تاريخ انتهاء الترخيص',
                          ),
                          _buildImagePicker(
                            'صورة الترخيص',
                            _licenseImage,
                            (f) => _licenseImage = f,
                          ),
                          _buildTextField(
                            _taxController,
                            'الرقم الضريبي',
                            isRequired: false,
                          ),
                          _buildImagePicker(
                            'شعار الشركة',
                            _logoImage,
                            (f) => _logoImage = f,
                          ),
                          _buildImagePicker(
                            'صورة المكتب (أمام)',
                            _officeFrontImage,
                            (f) => _officeFrontImage = f,
                          ),
                          _buildImagePicker(
                            'صورة المكتب (داخل)',
                            _officeInteriorImage,
                            (f) => _officeInteriorImage = f,
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 3,
                  ),
                  Step(
                    title: Text('طرق الدفع'),
                    content: Form(
                      key: _formKeys[4],
                      child: Column(
                        children: [
                          _buildTextField(
                            _bankController,
                            'اسم البنك',
                            isRequired: false,
                          ),
                          _buildTextField(
                            _accountHolderController,
                            'اسم مالك الحساب',
                            isRequired: false,
                          ),
                          _buildTextField(
                            _accountNumberController,
                            'رقم الحساب',
                            isRequired: false,
                          ),
                          _buildTextField(
                            _ibanController,
                            'IBAN',
                            isRequired: false,
                          ),
                          _buildTextField(
                            _walletTypeController,
                            'المحفظة',
                            isRequired: false,
                          ),
                          _buildTextField(
                            _walletNumberController,
                            'رقم المحفظة',
                            isRequired: false,
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 4,
                  ),
                  Step(
                    title: Text('الإقرار'),
                    content: Form(
                      key: _formKeys[5],
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text('أقر بصحة البيانات'),
                            value: _confirmData,
                            onChanged: (v) => setState(() => _confirmData = v!),
                          ),
                          CheckboxListTile(
                            title: Text('أوافق على الشروط'),
                            value: _acceptTerms,
                            onChanged: (v) => setState(() => _acceptTerms = v!),
                          ),
                          CheckboxListTile(
                            title: Text('أوافق على الخصوصية'),
                            value: _acceptPrivacy,
                            onChanged: (v) =>
                                setState(() => _acceptPrivacy = v!),
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 5,
                  ),
                ],
              ),
      ),
    );
  }
}
