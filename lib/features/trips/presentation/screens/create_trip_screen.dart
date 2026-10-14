import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/trip.dart';
import 'package:rahal/features/geo/presentation/providers/geo_providers.dart';
import 'package:rahal/features/geo/domain/models/country.dart';
import 'package:rahal/features/geo/domain/models/governorate.dart';
import 'package:rahal/features/geo/domain/models/city.dart';
import '../../../driver/presentation/providers/driver_providers.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 10;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // Step 1: Route
  Country? _departureCountry;
  Governorate? _departureProvince;
  City? _departureCity;

  Country? _arrivalCountry;
  Governorate? _arrivalProvince;
  City? _arrivalCity;

  // Step 2: DateTime
  DateTime _departureDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _arrivalDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 16, minute: 0);

  // Step 3: Vehicle/Seats
  final _vehicleTypeController = TextEditingController(text: 'صالون اقتصادية');
  int _totalSeats = 4;

  // Step 4: Seat Configuration
  bool _isWomenOnly = false;
  bool _isFamilyOnly = false;
  bool _isVip = false;

  // Step 5: Features
  bool _hasAc = true;
  bool _hasWifi = false;
  bool _hasLuggage = true;
  bool _allowSmoking = false;

  // Step 6: Parcel Availability
  final _parcelCapacityController = TextEditingController(text: '50');
  final _parcelCountLimitController = TextEditingController(text: '10');

  // Step 7: Parcel Pricing
  final _parcelPriceController = TextEditingController();

  // Step 8: Pricing
  final _priceController = TextEditingController();

  // Step 9: Payment Accounts
  final List<String> _selectedPaymentMethodIds = [];

  @override
  void dispose() {
    _pageController.dispose();
    _vehicleTypeController.dispose();
    _parcelPriceController.dispose();
    _parcelCapacityController.dispose();
    _parcelCountLimitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && (_departureCity == null || _arrivalCity == null))
      return;
    if (_currentStep == 2 && _vehicleTypeController.text.trim().isEmpty) return;
    if (_currentStep == 7 && _priceController.text.trim().isEmpty) return;

    if (_currentStep == 9) {
      _publishTrip();
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  bool _isNextEnabled() {
    if (_currentStep == 0 && (_departureCity == null || _arrivalCity == null))
      return false;
    if (_currentStep == 2 && _vehicleTypeController.text.trim().isEmpty)
      return false;
    if (_currentStep == 7 && _priceController.text.trim().isEmpty) return false;
    return true;
  }

  void _publishTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departureCity == null || _arrivalCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء اختيار مدن الانطلاق والوصول',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      context.go('/login');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tripId = 'tr_${DateTime.now().millisecondsSinceEpoch}';

      final depDateTime = DateTime(
        _departureDate.year,
        _departureDate.month,
        _departureDate.day,
        _departureTime.hour,
        _departureTime.minute,
      );

      final arrDateTime = DateTime(
        _arrivalDate.year,
        _arrivalDate.month,
        _arrivalDate.day,
        _arrivalTime.hour,
        _arrivalTime.minute,
      );

      final parcelPrice = double.tryParse(_parcelPriceController.text);

      final trip = Trip(
        id: tripId,
        driverId: authState.user.uid,
        driverName: authState.user.fullName,
        driverRating: 5.0,
        startLocationName: _departureCity?.nameAr ?? '',
        endLocationName: _arrivalCity?.nameAr ?? '',
        departureCountryId: _departureCountry?.id ?? '',
        departureCountry: _departureCountry?.nameAr ?? '',
        departureProvinceId: _departureProvince?.id ?? '',
        departureProvince: _departureProvince?.nameAr ?? '',
        departureCityId: _departureCity?.id ?? '',
        departureCity: _departureCity?.nameAr ?? '',
        arrivalCountryId: _arrivalCountry?.id ?? '',
        arrivalCountry: _arrivalCountry?.nameAr ?? '',
        arrivalProvinceId: _arrivalProvince?.id ?? '',
        arrivalProvince: _arrivalProvince?.nameAr ?? '',
        arrivalCityId: _arrivalCity?.id ?? '',
        arrivalCity: _arrivalCity?.nameAr ?? '',
        price: double.tryParse(_priceController.text) ?? 0.0,
        status: 'published',
        createdAt: DateTime.now(),
        departureTime: depDateTime,
        arrivalTime: arrDateTime,
        totalSeats: _totalSeats,
        remainingSeats: _totalSeats,
        vehicleType: _vehicleTypeController.text.trim(),
        isCompany: authState.user.role == 'company',
        name: authState.user.role == 'company' ? authState.user.fullName : '',
        isWomenOnly: _isWomenOnly,
        isFamilyOnly: _isFamilyOnly,
        hasAc: _hasAc,
        hasWifi: _hasWifi,
        hasLuggageSpace: _hasLuggage,
        allowSmoking: _allowSmoking,
        isVip: _isVip,
        parcelPrice: parcelPrice,
        parcelCapacityKg:
            double.tryParse(_parcelCapacityController.text) ?? 50.0,
        parcelCountLimit: int.tryParse(_parcelCountLimitController.text) ?? 10,
        paymentMethodIds: _selectedPaymentMethodIds,
      );

      final tripRepo = ref.read(tripRepositoryProvider);
      await tripRepo.createTrip(trip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم نشر الرحلة بنجاح!',
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
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'نشر رحلة جديدة',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF0B1F3A),
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStep1(),
                            _buildStep2(),
                            _buildStep3(),
                            _buildStep4(),
                            _buildStep5(),
                            _buildStep6(),
                            _buildStep7(),
                            _buildStep8(),
                            _buildStep9(),
                            _buildStep10(),
                          ],
                        ),
                      ),
                      _buildBottomControls(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStep1() {
    return _WizardPage(
      title: 'المسار والاتجاه',
      subtitle: 'حدد من أين ستنطلق وإلى أين ستتجه',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'موقع الانطلاق',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5A623),
            ),
          ),
          const SizedBox(height: 8),
          _buildGeoDropdowns(
            isDeparture: true,
            country: _departureCountry,
            province: _departureProvince,
            city: _departureCity,
            onCountryChanged: (c) => setState(() {
              _departureCountry = c;
              _departureProvince = null;
              _departureCity = null;
            }),
            onProvinceChanged: (p) => setState(() {
              _departureProvince = p;
              _departureCity = null;
            }),
            onCityChanged: (c) => setState(() => _departureCity = c),
          ),
          const SizedBox(height: 16),
          const Text(
            'موقع الوصول',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5A623),
            ),
          ),
          const SizedBox(height: 8),
          _buildGeoDropdowns(
            isDeparture: false,
            country: _arrivalCountry,
            province: _arrivalProvince,
            city: _arrivalCity,
            onCountryChanged: (c) => setState(() {
              _arrivalCountry = c;
              _arrivalProvince = null;
              _arrivalCity = null;
            }),
            onProvinceChanged: (p) => setState(() {
              _arrivalProvince = p;
              _arrivalCity = null;
            }),
            onCityChanged: (c) => setState(() => _arrivalCity = c),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _WizardPage(
      title: 'التواريخ والمواعيد',
      subtitle: 'متى ستبدأ وتنتهي هذه الرحلة؟',
      content: Column(
        children: [
          _buildDateTimePicker(
            'وقت الانطلاق',
            _departureDate,
            _departureTime,
            (d) => setState(() => _departureDate = d),
            (t) => setState(() => _departureTime = t),
          ),
          const SizedBox(height: 24),
          _buildDateTimePicker(
            'وقت الوصول المتوقع',
            _arrivalDate,
            _arrivalTime,
            (d) => setState(() => _arrivalDate = d),
            (t) => setState(() => _arrivalTime = t),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _WizardPage(
      title: 'السيارة والمقاعد',
      subtitle: 'ما نوع سيارتك وكم عدد المقاعد المتاحة للركاب؟',
      content: Column(
        children: [
          TextFormField(
            controller: _vehicleTypeController,
            decoration: const InputDecoration(
              labelText: 'نوع السيارة (مثال: تويوتا كامري 2020)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_car),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.airline_seat_recline_normal,
                  color: Color(0xFF0B1F3A),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'عدد المقاعد المتاحة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () => setState(
                    () => _totalSeats = _totalSeats > 1 ? _totalSeats - 1 : 1,
                  ),
                ),
                Text(
                  '$_totalSeats',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: () => setState(() => _totalSeats++),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return _WizardPage(
      title: 'تكوين المقاعد',
      subtitle: 'هل هناك شروط خاصة لهذه الرحلة؟',
      content: Column(
        children: [
          _buildSwitchTile(
            'رحلة عائلية فقط',
            _isFamilyOnly,
            (v) => setState(() => _isFamilyOnly = v),
            Icons.family_restroom,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'للنساء فقط',
            _isWomenOnly,
            (v) => setState(() => _isWomenOnly = v),
            Icons.pregnant_woman,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'مقاعد VIP',
            _isVip,
            (v) => setState(() => _isVip = v),
            Icons.star,
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return _WizardPage(
      title: 'المميزات الإضافية',
      subtitle: 'حدد الخدمات المتاحة للركاب في سيارتك',
      content: Column(
        children: [
          _buildSwitchTile(
            'تكييف متوفر',
            _hasAc,
            (v) => setState(() => _hasAc = v),
            Icons.ac_unit,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'مساحة للأمتعة',
            _hasLuggage,
            (v) => setState(() => _hasLuggage = v),
            Icons.luggage,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'إنترنت Wi-Fi',
            _hasWifi,
            (v) => setState(() => _hasWifi = v),
            Icons.wifi,
          ),
          const SizedBox(height: 12),
          _buildSwitchTile(
            'يسمح بالتدخين',
            _allowSmoking,
            (v) => setState(() => _allowSmoking = v),
            Icons.smoking_rooms,
          ),
        ],
      ),
    );
  }

  Widget _buildStep6() {
    return _WizardPage(
      title: 'سوق الطرود',
      subtitle: 'حدد سعة الطرود التي يمكنك توصيلها خلال هذه الرحلة',
      content: Column(
        children: [
          TextFormField(
            controller: _parcelCapacityController,
            decoration: const InputDecoration(
              labelText: 'السعة القصوى للطرود بالوزن (اختياري)',
              border: OutlineInputBorder(),
              suffixText: 'كجم',
              prefixIcon: Icon(Icons.fitness_center),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _parcelCountLimitController,
            decoration: const InputDecoration(
              labelText: 'الحد الأقصى لعدد الطرود (اختياري)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory_2),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildStep7() {
    return _WizardPage(
      title: 'تسعيرة الطرود',
      subtitle: 'أدخل تسعيرة توصيل الطرود إذا كنت تقبلها',
      content: Column(
        children: [
          TextFormField(
            controller: _parcelPriceController,
            decoration: const InputDecoration(
              labelText: 'سعر الكيلو للطرود (اختياري)',
              border: OutlineInputBorder(),
              suffixText: 'ريال',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          const Text(
            'يمكنك ترك هذا الحقل فارغاً إذا كنت لا ترغب في تحديد سعر ثابت للطرود وسيعتمد الأمر على التفاوض أو سعر الطرد الأصلي.',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep8() {
    return _WizardPage(
      title: 'تسعيرة الركاب',
      subtitle: 'ما هو سعر المقعد الواحد في هذه الرحلة؟',
      content: Column(
        children: [
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'سعر المقعد الواحد',
              border: OutlineInputBorder(),
              suffixText: 'ريال',
              prefixIcon: Icon(Icons.monetization_on),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildStep9() {
    return _WizardPage(
      title: 'حسابات الدفع',
      subtitle: 'حدد حسابات الدفع التي تقبل التحويل عليها',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final methodsAsync = ref.watch(driverPaymentMethodsProvider);
              return methodsAsync.when(
                data: (methods) {
                  final approvedMethods = methods
                      .where(
                        (m) => m.isActive,
                      )
                      .toList();
                  if (approvedMethods.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'لا توجد حسابات دفع معتمدة. يرجى إضافتها من قائمة "حساباتي" أولاً.',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: approvedMethods.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final method = approvedMethods[index];
                      final isSelected = _selectedPaymentMethodIds.contains(
                        method.id,
                      );
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedPaymentMethodIds.remove(method.id);
                            } else {
                              _selectedPaymentMethodIds.add(method.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0B1F3A)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? const Color(
                                    0xFF0B1F3A,
                                  ).withValues(alpha: 0.05)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                method.type == 'bank'
                                    ? Icons.account_balance
                                    : Icons.account_balance_wallet,
                                color: isSelected
                                    ? const Color(0xFF0B1F3A)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.providerName,
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      method.accountNumber,
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF0B1F3A),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedPaymentMethodIds.add(method.id);
                                    } else {
                                      _selectedPaymentMethodIds.remove(
                                        method.id,
                                      );
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text(
                  'حدث خطأ في جلب الحسابات',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep10() {
    return _WizardPage(
      title: 'مراجعة ونشر',
      subtitle: 'تأكد من صحة جميع البيانات قبل نشر الرحلة',
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _reviewRow('من', _departureCity?.nameAr ?? ''),
            _reviewRow('إلى', _arrivalCity?.nameAr ?? ''),
            _reviewRow('المقاعد', '$_totalSeats'),
            _reviewRow('السعر', '${_priceController.text} ريال'),
            if (_selectedPaymentMethodIds.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تحذير: لم تحدد أي حساب دفع',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.orange,
                        ),
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

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'رجوع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isNextEnabled() ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 50),
                backgroundColor: _currentStep == 9
                    ? Colors.green
                    : const Color(0xFF0B1F3A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == 9 ? 'نشر الرحلة' : 'التالي',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(
    String label,
    DateTime date,
    TimeOfDay time,
    Function(DateTime) onDate,
    Function(TimeOfDay) onTime,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B1F3A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (d != null) onDate(d);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0B1F3A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${date.year}-${date.month}-${date.day}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (t != null) onTime(t);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Color(0xFF0B1F3A),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time.format(context),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: value
            ? const Color(0xFF0B1F3A).withValues(alpha: 0.05)
            : Colors.transparent,
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        secondary: Icon(
          icon,
          color: value ? const Color(0xFF0B1F3A) : Colors.grey,
        ),
        value: value,
        activeColor: const Color(0xFF0B1F3A),
        onChanged: onChanged,
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeoDropdowns({
    required bool isDeparture,
    Country? country,
    Governorate? province,
    City? city,
    required Function(Country?) onCountryChanged,
    required Function(Governorate?) onProvinceChanged,
    required Function(City?) onCityChanged,
  }) {
    return Column(
      children: [
        ref
            .watch(countriesProvider)
            .when(
              data: (countries) => DropdownButtonFormField<Country>(
                value: country,
                decoration: const InputDecoration(
                  labelText: 'الدولة',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: countries
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c.nameAr,
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onCountryChanged,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('خطأ'),
            ),
        const SizedBox(height: 12),
        if (country != null)
          ref
              .watch(provincesProvider(country.id))
              .when(
                data: (provinces) => DropdownButtonFormField<Governorate>(
                  value: province,
                  decoration: const InputDecoration(
                    labelText: 'المحافظة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  items: provinces
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.nameAr,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onProvinceChanged,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ'),
              ),
        const SizedBox(height: 12),
        if (province != null)
          ref
              .watch(citiesProvider(province.id))
              .when(
                data: (cities) => DropdownButtonFormField<City>(
                  value: city,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: cities
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c.nameAr,
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    onCityChanged(val);
                    setState(() {});
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('خطأ'),
              ),
      ],
    );
  }
}

class _WizardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget content;

  const _WizardPage({
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(child: SingleChildScrollView(child: content)),
        ],
      ),
    );
  }
}
