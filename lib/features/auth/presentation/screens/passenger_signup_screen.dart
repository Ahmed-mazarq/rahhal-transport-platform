import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_theme_wrapper.dart';

class PassengerSignUpScreen extends ConsumerStatefulWidget {
  const PassengerSignUpScreen({super.key});

  @override
  ConsumerState<PassengerSignUpScreen> createState() =>
      _PassengerSignUpScreenState();
}

class _PassengerSignUpScreenState extends ConsumerState<PassengerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedNationality = 'يمني';
  String _selectedCountry = 'اليمن';
  String? _selectedGovernorate;

  List<String> _governorates = [];
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoadingGovs = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadGovernorates();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

      if (!mounted) return;

      final countryCode =
          _selectedCountry == 'اليمن' ? 'yemen' : 'saudi_arabia';
      final countryMatches =
          countries.where((element) => element.id == countryCode).toList();
      if (countryMatches.isEmpty) {
        throw Exception('البلد غير متوفر');
      }
      final country = countryMatches.first;

      final govs = await geoRepo.getGovernorates(country.id);

      if (!mounted) return;
      setState(() {
        _governorates = govs.map((e) => e.nameAr).toList();
        if (_governorates.isNotEmpty) {
          _selectedGovernorate = _governorates.first;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_selectedCountry == 'اليمن') {
            _governorates = [
              'أمانة العاصمة',
              'صنعاء',
              'عدن',
              'تعز',
              'إب',
              'حضرموت',
              'الحديدة',
              'مأرب',
            ];
          } else {
            _governorates = [
              'الرياض',
              'مكة المكرمة',
              'المدينة المنورة',
              'المنطقة الشرقية',
              'عسير',
              'تبوك',
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

  void _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى الموافقة على الشروط وسياسة الخصوصية للمتابعة.',
            textAlign: TextAlign.right,
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> roleFields = {
        'nationality': _selectedNationality,
        'currentCountry': _selectedCountry,
        'governorate': _selectedGovernorate,
      };

      final authNotifier = ref.read(authProvider.notifier);

      await authNotifier.register(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: 'passenger',
        roleFields: roleFields,
      );

      if (!mounted) return;

      final state = ref.read(authProvider);
      if (state is AuthError) {
        String friendlyError = state.message;
        if (friendlyError.contains('already-in-use') ||
            friendlyError.contains('already in use')) {
          friendlyError = 'رقم الهاتف مستخدم بالفعل في حساب آخر.';
        } else if (friendlyError.contains('network') ||
            friendlyError.contains('connection')) {
          friendlyError = 'تعذر الاتصال بالخادم، تحقق من اتصال الإنترنت.';
        } else if (friendlyError.contains('weak-password')) {
          friendlyError = 'كلمة المرور ضعيفة، يرجى اختيار كلمة مرور أقوى.';
        } else {
          friendlyError = 'تعذر إنشاء الحساب، يرجى المحاولة مرة أخرى.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyError,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      } else if (state is Authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء الحساب بنجاح! مرحباً بك في رحال.',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.go('/dashboard');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر إكمال عملية التسجيل، يرجى المحاولة لاحقاً.',
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'إنشاء حساب راكب',
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  // Header Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0B1F3A), Color(0xFF162D4A)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B1F3A).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Color(0xFFF5A623),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'انضم إلى مجتمع رحال',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'احجز رحلاتك بين المدن بكل أمان وسهولة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Form Container Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المعلومات الشخصية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1F3A),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Full Name
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Color(0xFF0B1F3A),
                            ),
                            decoration: InputDecoration(
                              labelText: 'الاسم الكامل الثلاثي *',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFF0B1F3A),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'يرجى إدخال الاسم الكامل';
                              }
                              final words = val.trim().split(RegExp(r'\s+'));
                              if (words.length < 3) {
                                return 'الاسم الكامل يجب أن يكون ثلاثياً على الأقل';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Phone Number
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: Color(0xFF0B1F3A),
                              ),
                              decoration: InputDecoration(
                                labelText: 'رقم الهاتف *',
                                alignLabelWithHint: true,
                                labelStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_android_rounded,
                                  color: Color(0xFF0B1F3A),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB)),
                                ),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'يرجى إدخال رقم الهاتف'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Color(0xFF0B1F3A),
                            ),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور *',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF0B1F3A),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: const Color(0xFF6B7280),
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'يرجى إدخال كلمة المرور';
                              }
                              if (val.length < 8) {
                                return 'يجب أن تكون كلمة المرور ٨ خانات على الأقل';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              color: Color(0xFF0B1F3A),
                            ),
                            decoration: InputDecoration(
                              labelText: 'تأكيد كلمة المرور *',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF0B1F3A),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: const Color(0xFF6B7280),
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'يرجى تأكيد كلمة المرور';
                              }
                              if (val != _passwordController.text) {
                                return 'كلمات المرور غير متطابقة';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          const Text(
                            'الموقع والإقامة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1F3A),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Nationality Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedNationality,
                            decoration: InputDecoration(
                              labelText: 'الجنسية *',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'يمني',
                                child: Text('🇾🇪 يمني',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ),
                              DropdownMenuItem(
                                value: 'سعودي',
                                child: Text('🇸🇦 سعودي',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ),
                              DropdownMenuItem(
                                value: 'أخرى',
                                child: Text('🌍 أخرى',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ),
                            ],
                            onChanged: (val) => setState(
                              () => _selectedNationality =
                                  val ?? _selectedNationality,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Current Country Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCountry,
                            decoration: InputDecoration(
                              labelText: 'الدولة الحالية *',
                              labelStyle: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'اليمن',
                                child: Text('اليمن',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ),
                              DropdownMenuItem(
                                value: 'السعودية',
                                child: Text('السعودية',
                                    style: TextStyle(fontFamily: 'Cairo')),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCountry = val);
                                _loadGovernorates();
                              }
                            },
                          ),
                          const SizedBox(height: 14),

                          // Governorate Dropdown
                          if (_isLoadingGovs)
                            const Center(
                              child: LinearProgressIndicator(
                                color: Color(0xFFF5A623),
                              ),
                            )
                          else if (_governorates.isNotEmpty)
                            DropdownButtonFormField<String>(
                              initialValue: _selectedGovernorate,
                              decoration: InputDecoration(
                                labelText: 'المحافظة *',
                                labelStyle: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB)),
                                ),
                              ),
                              items: _governorates
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(
                                            fontFamily: 'Cairo'),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedGovernorate = val),
                            ),
                          const SizedBox(height: 18),

                          // Checkbox Terms
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                activeColor: const Color(0xFFF5A623),
                                checkColor: const Color(0xFF0B1F3A),
                                onChanged: (val) =>
                                    setState(() => _acceptTerms = val ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'أوافق على الشروط والأحكام الخاصة بمنصة رحال.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptPrivacy,
                                activeColor: const Color(0xFFF5A623),
                                checkColor: const Color(0xFF0B1F3A),
                                onChanged: (val) => setState(
                                    () => _acceptPrivacy = val ?? false),
                              ),
                              const Expanded(
                                child: Text(
                                  'أوافق على سياسة الاستخدام والخصوصية للراكب.',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Action Button
                          if (_isSubmitting)
                            const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF5A623),
                                ),
                              ),
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B1F3A),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(54),
                                elevation: 2,
                                shadowColor: const Color(0xFF0B1F3A)
                                    .withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _submit,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'إنشاء حساب راكب',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline_rounded,
                                      size: 20),
                                ],
                              ),
                            ),
                        ],
                      ),
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
}

