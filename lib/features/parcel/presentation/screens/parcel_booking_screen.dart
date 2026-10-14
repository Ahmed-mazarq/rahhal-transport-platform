import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import 'package:rahal/core/widgets/premium_trip_card.dart';
import 'package:rahal/core/providers/repository_providers.dart';

import 'package:rahal/features/geo/presentation/providers/geo_providers.dart';
import 'package:rahal/features/geo/domain/models/country.dart';
import 'package:rahal/features/geo/domain/models/governorate.dart';
import 'package:rahal/features/geo/domain/models/city.dart';

import '../providers/parcel_provider.dart';
import '../../domain/models/parcel_delivery.dart';
import '../../domain/models/parcel_trip_match.dart';

class ParcelBookingScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const ParcelBookingScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<ParcelBookingScreen> createState() =>
      _ParcelBookingScreenState();
}

class _ParcelBookingScreenState extends ConsumerState<ParcelBookingScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Route Info
  Country? _originCountry;
  Governorate? _originProvince;
  City? _originCity;

  Country? _destinationCountry;
  Governorate? _destinationProvince;
  City? _destinationCity;

  // Receiver Info
  final _receiverNameCtrl = TextEditingController();
  final _receiverPhoneCtrl = TextEditingController();
  final _receiverAddressCtrl = TextEditingController();

  // Parcel Info
  String _parcelCategory = 'أوراق ومستندات';
  final _weightCtrl = TextEditingController(text: '1.0');
  String _size = 'small'; // small, medium, large
  int _pieceCount = 1;
  bool _isFragile = false;
  final _declaredValueCtrl = TextEditingController(text: '0');
  final _specialInstructionsCtrl = TextEditingController();
  bool _agreedToProhibited = false;

  // Pickup/Delivery Methods
  String _pickupMethod = 'drop_off';
  String _deliveryMethod = 'meeting_point';

  // Matching Trips
  bool _isSearching = false;
  List<ParcelTripMatch>? _matchingTrips;

  @override
  void dispose() {
    _receiverNameCtrl.dispose();
    _receiverPhoneCtrl.dispose();
    _receiverAddressCtrl.dispose();
    _weightCtrl.dispose();
    _declaredValueCtrl.dispose();
    _specialInstructionsCtrl.dispose();
    super.dispose();
  }

  void _searchDrivers() async {
    if (!_formKey.currentState!.validate()) return;

    if (_originCountry == null ||
        _originProvince == null ||
        _destinationCountry == null ||
        _destinationProvince == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار بيانات الدولة والمحافظة على الأقل'),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _matchingTrips = null;
    });

    try {
      final repo = ref.read(parcelRepositoryProvider);
      final trips = await repo.searchEligibleTripsForParcel(
        originCountryId: _originCountry!.id,
        originProvinceId: _originProvince?.id,
        originCityId: _originCity?.id,
        destinationCountryId: _destinationCountry!.id,
        destinationProvinceId: _destinationProvince?.id,
        destinationCityId: _destinationCity?.id,
        weight: double.tryParse(_weightCtrl.text) ?? 1.0,
        size: _size,
      );

      setState(() {
        _matchingTrips = trips;
        _currentStep = 5; // Move to trips step
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _bookParcel(ParcelTripMatch match) async {
    final trip = match.trip;
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;
    final user = authState.user;

    final trackingCode =
        'RH-PKG-${const Uuid().v4().substring(0, 6).toUpperCase()}';
    final pickupPin = (1000 + Random().nextInt(9000)).toString();
    final deliveryPin = (1000 + Random().nextInt(9000)).toString();

    final parcel = ParcelDelivery(
      id: '',
      trackingNumber: trackingCode,
      qrCodeValue: trackingCode,
      senderId: user.id,
      senderName: user.fullName,
      senderPhone: user.phone,
      receiverName: _receiverNameCtrl.text,
      receiverPhone: _receiverPhoneCtrl.text,
      receiverCountry: _destinationCountry!.nameAr,
      receiverProvince: _destinationProvince?.nameAr,
      receiverCity: _destinationCity?.nameAr ?? '',
      receiverAddress: _receiverAddressCtrl.text,
      originCountryId: _originCountry!.id,
      originCountry: _originCountry!.nameAr,
      originProvinceId: _originProvince?.id ?? '',
      originProvince: _originProvince?.nameAr ?? '',
      originCityId: _originCity?.id ?? '',
      originCity: _originCity!.nameAr,
      destinationCountryId: _destinationCountry!.id,
      destinationCountry: _destinationCountry!.nameAr,
      destinationProvinceId: _destinationProvince?.id ?? '',
      destinationProvince: _destinationProvince?.nameAr ?? '',
      destinationCityId: _destinationCity?.id ?? '',
      destinationCity: _destinationCity?.nameAr ?? '',
      tripId: trip.id,
      carrierType: trip.companyId != null ? 'company' : 'driver',
      driverId: trip.driverId,
      companyId: trip.companyId,
      vehicleId: trip.vehicleId,
      category: _parcelCategory,
      declaredValue: double.tryParse(_declaredValueCtrl.text) ?? 0.0,
      weight: double.tryParse(_weightCtrl.text) ?? 1.0,
      size: _size,
      pieceCount: _pieceCount,
      isFragile: _isFragile,
      specialInstructions: _specialInstructionsCtrl.text,
      pickupMethod: _pickupMethod,
      deliveryMethod: _deliveryMethod,
      price:
          trip.parcelPrice ??
          0.0, // Assuming Trip model has parcelPrice or we use 0.0 for negotiation
      currency: 'SAR',
      status: 'pending_carrier_acceptance',
      pickupVerificationCode: pickupPin,
      deliveryVerificationCode: deliveryPin,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final resultId = await ref
        .read(parcelActionProvider.notifier)
        .createParcel(parcel);

    if (resultId != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال الطلب بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      context.push('/parcel-details/$resultId');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إنشاء الطرد',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }
  }

  void _submitToMarketplace() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;
    final user = authState.user;

    final trackingCode =
        'RH-PKG-${const Uuid().v4().substring(0, 6).toUpperCase()}';
    final pickupPin = (1000 + Random().nextInt(9000)).toString();
    final deliveryPin = (1000 + Random().nextInt(9000)).toString();

    final parcel = ParcelDelivery(
      id: '',
      trackingNumber: trackingCode,
      qrCodeValue: trackingCode,
      senderId: user.id,
      senderName: user.fullName,
      senderPhone: user.phone,
      receiverName: _receiverNameCtrl.text,
      receiverPhone: _receiverPhoneCtrl.text,
      receiverCountry: _destinationCountry!.nameAr,
      receiverProvince: _destinationProvince?.nameAr,
      receiverCity: _destinationCity?.nameAr ?? '',
      receiverAddress: _receiverAddressCtrl.text,
      originCountryId: _originCountry!.id,
      originCountry: _originCountry!.nameAr,
      originProvinceId: _originProvince?.id ?? '',
      originProvince: _originProvince?.nameAr ?? '',
      originCityId: _originCity?.id ?? '',
      originCity: _originCity?.nameAr ?? '',
      destinationCountryId: _destinationCountry!.id,
      destinationCountry: _destinationCountry!.nameAr,
      destinationProvinceId: _destinationProvince?.id ?? '',
      destinationProvince: _destinationProvince?.nameAr ?? '',
      destinationCityId: _destinationCity?.id ?? '',
      destinationCity: _destinationCity?.nameAr ?? '',
      category: _parcelCategory,
      declaredValue: double.tryParse(_declaredValueCtrl.text) ?? 0.0,
      weight: double.tryParse(_weightCtrl.text) ?? 1.0,
      size: _size,
      pieceCount: _pieceCount,
      isFragile: _isFragile,
      specialInstructions: _specialInstructionsCtrl.text,
      pickupMethod: _pickupMethod,
      deliveryMethod: _deliveryMethod,
      price: 0.0,
      currency: 'SAR',
      status: 'searching_for_carrier',
      pickupVerificationCode: pickupPin,
      deliveryVerificationCode: deliveryPin,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final resultId = await ref
        .read(parcelActionProvider.notifier)
        .createParcel(parcel);

    if (resultId != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال الطلب لسوق السائقين بنجاح',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      context.push('/parcel-details/$resultId');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء إنشاء الطرد',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text(
                'إرسال طرد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
            ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 3 && !_agreedToProhibited) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('يجب الموافقة على شروط الطرود الممنوعة'),
                ),
              );
              return;
            }
            if (_currentStep == 4) {
              _searchDrivers();
            } else if (_currentStep < 5) {
              setState(() => _currentStep += 1);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep -= 1);
            }
          },
          controlsBuilder: (context, details) {
            if (_currentStep == 5) {
              return const SizedBox.shrink(); // Hide default controls on trips step
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1F3A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: details.onStepContinue,
                      child: Text(
                        _currentStep == 4 ? 'البحث عن رحلات' : 'متابعة',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: details.onStepCancel,
                        child: const Text(
                          'رجوع',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text(
                'المسار',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _buildRouteStep(isDark),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text(
                'المستلم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _buildReceiverStep(isDark),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text(
                'تفاصيل الطرد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _buildParcelDetailsStep(isDark),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text(
                'الممنوعات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _buildProhibitedStep(isDark),
              isActive: _currentStep >= 3,
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text(
                'التسليم والاستلام',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _buildMethodStep(isDark),
              isActive: _currentStep >= 4,
              state: _currentStep > 4 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text(
                'اختيار الرحلة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: _buildTripsStep(isDark),
              isActive: _currentStep >= 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStep(bool isDark) {
    return Column(
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
        ref
            .watch(countriesProvider)
            .when(
              data: (countries) {
                if (countries.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لا توجد الدول متاحة حاليًا',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(countriesProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  );
                }
                final selected = countries
                    .where((c) => c.id == _originCountry?.id)
                    .firstOrNull;
                return DropdownButtonFormField<Country>(
                  initialValue: selected,
                  decoration: InputDecoration(
                    labelText: 'دولة الانطلاق',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                  onChanged: (val) => setState(() {
                    _originCountry = val;
                    _originProvince = null;
                    _originCity = null;
                  }),
                  validator: (val) => val == null ? 'مطلوب' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('خطأ في تحميل الدول'),
            ),
        const SizedBox(height: 12),
        if (_originCountry != null)
          ref
              .watch(provincesProvider(_originCountry!.id))
              .when(
                data: (provinces) {
                  if (provinces.isEmpty) {
                    return const Text(
                      'لا توجد محافظات متاحة',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    );
                  }
                  final selected = provinces
                      .where((p) => p.id == _originProvince?.id)
                      .firstOrNull;
                  return DropdownButtonFormField<Governorate>(
                    initialValue: selected,
                    decoration: InputDecoration(
                      labelText: 'محافظة الانطلاق',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                    onChanged: (val) => setState(() {
                      _originProvince = val;
                      _originCity = null;
                    }),
                    validator: (val) => val == null ? 'مطلوب' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('خطأ في تحميل المناطق'),
              ),
        const SizedBox(height: 12),
        if (_originProvince != null)
          ref
              .watch(citiesProvider(_originProvince!.id))
              .when(
                data: (cities) {
                  if (cities.isEmpty) {
                    return const Text(
                      'لا توجد مدن متاحة',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    );
                  }
                  final selected = cities
                      .where((c) => c.id == _originCity?.id)
                      .firstOrNull;
                  return DropdownButtonFormField<City>(
                    initialValue: selected,
                    decoration: InputDecoration(
                      labelText: 'مدينة الانطلاق (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                    onChanged: (val) => setState(() => _originCity = val),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('خطأ في تحميل المدن'),
              ),

        const Divider(height: 32),

        const Text(
          'موقع الوصول',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5A623),
          ),
        ),
        const SizedBox(height: 8),
        ref
            .watch(countriesProvider)
            .when(
              data: (countries) {
                if (countries.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'لا توجد الدول متاحة حاليًا',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(countriesProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  );
                }
                final selected = countries
                    .where((c) => c.id == _destinationCountry?.id)
                    .firstOrNull;
                return DropdownButtonFormField<Country>(
                  initialValue: selected,
                  decoration: InputDecoration(
                    labelText: 'دولة الوصول',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                  onChanged: (val) => setState(() {
                    _destinationCountry = val;
                    _destinationProvince = null;
                    _destinationCity = null;
                  }),
                  validator: (val) => val == null ? 'مطلوب' : null,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => const Text('خطأ في تحميل الدول'),
            ),
        const SizedBox(height: 12),
        if (_destinationCountry != null)
          ref
              .watch(provincesProvider(_destinationCountry!.id))
              .when(
                data: (provinces) {
                  if (provinces.isEmpty) {
                    return const Text(
                      'لا توجد محافظات متاحة',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    );
                  }
                  final selected = provinces
                      .where((p) => p.id == _destinationProvince?.id)
                      .firstOrNull;
                  return DropdownButtonFormField<Governorate>(
                    initialValue: selected,
                    decoration: InputDecoration(
                      labelText: 'محافظة الوصول',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                    onChanged: (val) => setState(() {
                      _destinationProvince = val;
                      _destinationCity = null;
                    }),
                    validator: (val) => val == null ? 'مطلوب' : null,
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('خطأ في تحميل المناطق'),
              ),
        const SizedBox(height: 12),
        if (_destinationProvince != null)
          ref
              .watch(citiesProvider(_destinationProvince!.id))
              .when(
                data: (cities) {
                  if (cities.isEmpty) {
                    return const Text(
                      'لا توجد مدن متاحة',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                    );
                  }
                  final selected = cities
                      .where((c) => c.id == _destinationCity?.id)
                      .firstOrNull;
                  return DropdownButtonFormField<City>(
                    initialValue: selected,
                    decoration: InputDecoration(
                      labelText: 'مدينة الوصول (اختياري)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                    onChanged: (val) => setState(() => _destinationCity = val),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('خطأ في تحميل المدن'),
              ),
      ],
    );
  }

  Widget _buildReceiverStep(bool isDark) {
    return Column(
      children: [
        _buildTextField(
          isDark,
          'اسم المستلم الثلاثي',
          Icons.person,
          _receiverNameCtrl,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          isDark,
          'رقم هاتف المستلم',
          Icons.phone,
          _receiverPhoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          isDark,
          'العنوان التفصيلي (اختياري)',
          Icons.location_on,
          _receiverAddressCtrl,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildParcelDetailsStep(bool isDark) {
    return Column(
      children: [
        _buildDropdown(
          isDark,
          'نوع الطرد',
          _parcelCategory,
          [
            'أوراق ومستندات',
            'ملابس',
            'هدايا',
            'أغراض شخصية',
            'أجهزة إلكترونية',
            'قطع غيار',
            'أخرى',
          ],
          (val) => setState(() => _parcelCategory = val!),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                isDark,
                'الوزن (كجم)',
                Icons.monitor_weight_outlined,
                _weightCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(isDark, 'الحجم', _size, [
                'small',
                'medium',
                'large',
                'extra_large',
              ], (val) => setState(() => _size = val!)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                isDark,
                'عدد القطع',
                _pieceCount.toString(),
                ['1', '2', '3', '4', '5+'],
                (val) {
                  setState(
                    () => _pieceCount =
                        int.tryParse(val!.replaceAll('+', '')) ?? 1,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                isDark,
                'القيمة المصرح بها',
                Icons.attach_money,
                _declaredValueCtrl,
                keyboardType: TextInputType.number,
                isRequired: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text(
            'قابل للكسر (يستدعي عناية خاصة)',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          value: _isFragile,
          activeTrackColor: Theme.of(context).primaryColor,
          onChanged: (v) => setState(() => _isFragile = v),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          isDark,
          'ملاحظات للسائق',
          Icons.note,
          _specialInstructionsCtrl,
          isRequired: false,
        ),
      ],
    );
  }

  Widget _buildProhibitedStep(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'تحذير المواد الممنوعة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'يُمنع إرسال: المخدرات، الأسلحة، الذخائر، المتفجرات، المواد الخطرة، المواد القابلة للاشتعال، وأي سلع غير قانونية وفقاً للأنظمة.',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              title: const Text(
                'أوافق على أن طردي لا يحتوي على أي من المواد الممنوعة المذكورة أعلاه',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
              value: _agreedToProhibited,
              activeTrackColor: Colors.red,
              onChanged: (v) => setState(() => _agreedToProhibited = v),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodStep(bool isDark) {
    return Column(
      children: [
        _buildDropdown(
          isDark,
          'طريقة تسليم الطرد للسائق',
          _pickupMethod,
          ['drop_off', 'pickup_from_sender'],
          (val) => setState(() => _pickupMethod = val!),
          displayNames: {
            'drop_off': 'تسليم في نقطة التجمع',
            'pickup_from_sender': 'استلام من موقع المرسل',
          },
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          isDark,
          'طريقة استلام الطرد',
          _deliveryMethod,
          ['meeting_point', 'home_delivery', 'branch_pickup'],
          (val) => setState(() => _deliveryMethod = val!),
          displayNames: {
            'meeting_point': 'استلام من نقطة التجمع',
            'home_delivery': 'توصيل لعنوان المستلم',
            'branch_pickup': 'استلام من فرع الشركة',
          },
        ),
      ],
    );
  }

  Widget _buildTripsStep(bool isDark) {
    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_matchingTrips == null) return const SizedBox.shrink();

    if (_matchingTrips!.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد رحلة مناسبة لنقل هذا الطرد حالياً',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'يرجى المحاولة لاحقاً أو تغيير تفاصيل المسار، أو رفع الطلب للسائقين مباشرة.',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text(
                  'تغيير المسار',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _submitToMarketplace(),
                icon: const Icon(Icons.send),
                label: const Text(
                  'إرسال للسوق',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final exactCityMatches = _matchingTrips!
        .where((m) => m.matchType == 'exact_city')
        .toList();
    final provinceMatches = _matchingTrips!
        .where((m) => m.matchType == 'exact_province')
        .toList();
    final stopMatches = _matchingTrips!
        .where((m) => m.matchType == 'stop_fallback')
        .toList();
    final countryMatches = _matchingTrips!
        .where((m) => m.matchType == 'country_fallback')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (exactCityMatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'رحلات مطابقة لمسارك',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
          for (final match in exactCityMatches) _buildMatchCard(match),
        ],

        if (exactCityMatches.isEmpty && provinceMatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'لا توجد رحلة مطابقة لنفس المدينة أو المديرية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'توجد رحلات من نفس المحافظتين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange,
              ),
            ),
          ),
          for (final match in provinceMatches) _buildMatchCard(match),
        ] else if (provinceMatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'رحلات من نفس المحافظتين',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange,
              ),
            ),
          ),
          for (final match in provinceMatches) _buildMatchCard(match),
        ],

        if (stopMatches.isNotEmpty) ...[
          if (exactCityMatches.isNotEmpty || provinceMatches.isNotEmpty)
            const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'رحلات قريبة من المسار (يمر عبر)',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.orange,
              ),
            ),
          ),
          for (final match in stopMatches) _buildMatchCard(match),
        ],

        if (exactCityMatches.isEmpty &&
            provinceMatches.isEmpty &&
            stopMatches.isEmpty &&
            countryMatches.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'لا توجد رحلة مطابقة لمسارك حاليًا',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'رحلات أخرى ضمن نفس الاتجاه',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          for (final match in countryMatches) _buildMatchCard(match),
        ] else if (countryMatches.isNotEmpty) ...[
          if (exactCityMatches.isNotEmpty ||
              provinceMatches.isNotEmpty ||
              stopMatches.isNotEmpty)
            const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'رحلات أخرى ضمن نفس الاتجاه',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          for (final match in countryMatches) _buildMatchCard(match),
        ],

        const Divider(height: 32),
        const Text(
          'لم تجد رحلة مناسبة؟',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _submitToMarketplace(),
            icon: const Icon(Icons.public),
            label: const Text(
              'إرسال طلب للسائقين',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFF5A623),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchCard(ParcelTripMatch match) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: match.score >= 100
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.orange.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: BoxDecoration(
                color: match.score >= 100
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    match.score >= 100 ? Icons.check_circle : Icons.alt_route,
                    size: 16,
                    color: match.score >= 100 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    match.matchReason,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: match.score >= 100 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            PremiumTripCard(
              trip: match.trip,
              onTap: () {},
              customActionLabel: 'اختيار هذه الرحلة',
              onBookNow: () => _bookParcel(match),
              onFavorite: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    bool isDark,
    String label,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    Map<String, String>? displayNames,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (i) => DropdownMenuItem(
              value: i,
              child: Text(
                displayNames?[i] ?? i,
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
    );
  }

  Widget _buildTextField(
    bool isDark,
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: isRequired
          ? (value) => value == null || value.isEmpty ? 'مطلوب' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
