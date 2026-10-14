import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trips/domain/models/trip.dart';
import '../../../trips/domain/models/stop.dart';
import '../../../trips/domain/models/seat.dart';
import '../../../trips/domain/services/seat_layout_generator.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../geo/presentation/providers/geo_providers.dart';
import '../../../geo/domain/models/country.dart';
import '../../../geo/domain/models/governorate.dart';
import '../../../geo/domain/models/city.dart';
import '../providers/driver_providers.dart';
import '../utils/driver_tokens.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  final Trip? initialTrip;

  const CreateTripScreen({super.key, this.initialTrip});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Route
  String _tripType = 'inside_yemen';
  Country? _departureCountry;
  Governorate? _departureProvince;
  City? _departureCity;
  Country? _arrivalCountry;
  Governorate? _arrivalProvince;
  City? _arrivalCity;

  // Date & Time
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;

  // Vehicle
  Vehicle? _selectedVehicle;
  List<Vehicle> _driverVehicles = [];

  // Stops
  List<Stop> _stops = [];

  // Custom Seats
  List<Seat>? _customSeats;

  // Features
  bool _hasAc = true;
  bool _hasWifi = false;
  bool _hasLuggageSpace = true;
  bool _allowSmoking = false;
  late TextEditingController _notesCtrl;

  // Parcels
  bool _acceptsParcels = true;
  double _parcelCapacityKg = 50.0;
  final _parcelPriceCtrl = TextEditingController(text: '50.0');

  // Price & Currency
  String _selectedCurrency = 'YER';
  final _priceCtrl = TextEditingController(text: '');

  // Payment Accounts
  List<String> _selectedPaymentMethodIds = [];

  @override
  void initState() {
    super.initState();
    final trip = widget.initialTrip;

    _notesCtrl = TextEditingController(text: trip?.notes ?? '');
    if (trip != null) {
      _priceCtrl.text = trip.price.toString();
      _selectedCurrency = trip.currency.isNotEmpty ? trip.currency : 'YER';
      _customSeats = List.from(trip.seatLayout);
    }

    _loadVehicles();

    if (trip != null) {
      _departureDate = trip.departureTime;
      _departureTime = TimeOfDay.fromDateTime(trip.departureTime);
      _arrivalDate = trip.arrivalTime;
      _arrivalTime = TimeOfDay.fromDateTime(trip.arrivalTime);
      _tripType = trip.tripType;

      _hasAc = trip.hasAc;
      _hasWifi = trip.hasWifi;
      _hasLuggageSpace = trip.hasLuggageSpace;
      _allowSmoking = trip.allowSmoking;

      _acceptsParcels = trip.parcelCountLimit > 0;
      _parcelCapacityKg = trip.parcelCapacityKg;
      _parcelPriceCtrl.text = trip.parcelPrice?.toString() ?? '50.0';

      _stops = List.from(trip.stops);
      _selectedPaymentMethodIds = List.from(trip.paymentMethodIds);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _parcelPriceCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) return;
    try {
      final repo = ref.read(fleetRepositoryProvider);
      final driverRepo = ref.read(driverRepositoryProvider);
      final vehicles = await repo.getDriverVehicles(authState.user.uid);
      final profile = await driverRepo.getDriverProfile(authState.user.uid);

      if (mounted) {
        setState(() {
          _driverVehicles = vehicles;
          if (vehicles.isNotEmpty) {
            final primaryId = profile?.primaryVehicleId;
            _selectedVehicle = vehicles.firstWhere(
              (v) => v.id == primaryId,
              orElse: () => vehicles.firstWhere(
                (v) => v.isDefault,
                orElse: () => vehicles.first,
              ),
            );
            if (widget.initialTrip != null) {
              try {
                _selectedVehicle = vehicles.firstWhere(
                  (v) => v.id == widget.initialTrip!.vehicleId,
                );
              } catch (_) {}
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    }
  }

  void _nextStep() {
    bool isValid = false;
    if (_currentStep == 0) {
      isValid =
          _departureCountry != null &&
          _departureProvince != null &&
          _departureCity != null &&
          _arrivalCountry != null &&
          _arrivalProvince != null &&
          _arrivalCity != null;
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تعبئة جميع بيانات الموقع')),
        );
      }
    } else if (_currentStep == 1) {
      isValid = _departureDate != null && _departureTime != null;
      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تحديد وقت الانطلاق')),
        );
      }
    } else if (_currentStep == 2) {
      isValid = _selectedVehicle != null;
      if (!isValid) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('الرجاء تحديد مركبة')));
      }
    } else if (_currentStep == 3) {
      isValid = true; // Seats
    } else if (_currentStep == 4) {
      isValid = true; // Stops
    } else if (_currentStep == 5) {
      isValid = true; // Features
    } else if (_currentStep == 6) {
      isValid = true; // Parcels
    } else if (_currentStep == 7) {
      if (_priceCtrl.text.isEmpty ||
          double.tryParse(_priceCtrl.text) == null ||
          double.parse(_priceCtrl.text) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال سعر صحيح للمقعد')),
        );
        isValid = false;
      } else {
        isValid = true;
      }
    } else if (_currentStep == 8) {
      isValid = true; // Payments
    }

    if (isValid && _currentStep < 9) {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _saveTrip() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      if (authState is! Authenticated) throw Exception('غير مسجل الدخول');

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('غير مسجل الدخول');
      }
      final authenticatedDriverId = firebaseUser.uid;

      // Defensive Validation: Ensure selected payment methods are actually approved and active against Firestore
      bool hasInvalidMethod = false;
      final firestore = FirebaseFirestore.instance;
      for (final id in _selectedPaymentMethodIds) {
        final doc = await firestore
            .collection('driver_payment_methods')
            .doc(id)
            .get();
        if (!doc.exists) {
          hasInvalidMethod = true;
          break;
        }
        final data = doc.data()!;
        if (data['driverId'] != authenticatedDriverId ||
            data['isActive'] != true) {
          hasInvalidMethod = true;
          break;
        }
      }

      if (hasInvalidMethod) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'يجب اختيار حساب دفع مفعل خاص بك.',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              backgroundColor: DriverTokens.semanticError,
            ),
          );
        }
        return;
      }

      final depTime = DateTime(
        _departureDate!.year,
        _departureDate!.month,
        _departureDate!.day,
        _departureTime!.hour,
        _departureTime!.minute,
      );

      final arrTime = _arrivalDate != null && _arrivalTime != null
          ? DateTime(
              _arrivalDate!.year,
              _arrivalDate!.month,
              _arrivalDate!.day,
              _arrivalTime!.hour,
              _arrivalTime!.minute,
            )
          : depTime.add(const Duration(hours: 4));

      final tripId =
          widget.initialTrip?.id ??
          'tr_${DateTime.now().millisecondsSinceEpoch}';

      final totalPassengerSeats = _selectedVehicle?.seatsCount ?? 4;

      // Preserve custom seats or generate new ones
      List<Seat> finalSeats = [];
      List<List<int>> finalLayout = [];
      int finalRemaining = totalPassengerSeats;

      if (_customSeats != null && _customSeats!.isNotEmpty) {
        finalSeats = _customSeats!;
        finalRemaining = _customSeats!
            .where((s) => s.status == 'available')
            .length;
      } else if (widget.initialTrip != null &&
          widget.initialTrip!.totalSeats == totalPassengerSeats) {
        finalSeats = widget.initialTrip!.seatLayout;
        finalRemaining = widget.initialTrip!.remainingSeats;
      } else {
        finalLayout = SeatLayoutGenerator.generateLayout(totalPassengerSeats);
        for (int rowIdx = 0; rowIdx < finalLayout.length; rowIdx++) {
          for (int colIdx = 0; colIdx < finalLayout[rowIdx].length; colIdx++) {
            final seatNum = finalLayout[rowIdx][colIdx];
            finalSeats.add(
              Seat(
                id: 's_$seatNum',
                number: seatNum.toString(),
                status: seatNum == 0 ? 'driver' : 'available',
                row: rowIdx,
                column: colIdx,
              ),
            );
          }
        }
      }

      final driverRepo = ref.read(driverRepositoryProvider);
      final driverProfile = await driverRepo.getDriverProfile(
        authenticatedDriverId,
      );
      final currentProfileImage =
          driverProfile?.profileImage ?? authState.user.profileImage;

      final priceVal = double.tryParse(_priceCtrl.text) ?? 0.0;
      final parcelPriceVal = double.tryParse(_parcelPriceCtrl.text) ?? 50.0;

      final trip = Trip(
        id: tripId,
        passengerId: '',
        driverId: authenticatedDriverId,
        startLocationName: _departureCity!.nameAr,
        endLocationName: _arrivalCity!.nameAr,
        startLatitude: 0.0,
        startLongitude: 0.0,
        endLatitude: 0.0,
        endLongitude: 0.0,
        currency: _selectedCurrency,
        driverName: authState.user.fullName,
        driverAvatar: currentProfileImage,
        vehicleId: _selectedVehicle!.id,
        vehiclePlate: _selectedVehicle!.plateNumber,
        vehicleBrand: _selectedVehicle!.make,
        vehicleModel: _selectedVehicle!.model,
        vehicleYear: _selectedVehicle!.year,
        vehicleColor: _selectedVehicle!.color,
        vehicleFuelType: _selectedVehicle!.fuelType,
        vehiclePhotoUrl: _selectedVehicle!.photoUrl,
        vehiclePhotoUrls: _selectedVehicle!.additionalPhotos,
        departureCity: _departureCity!.nameAr,
        departureCityId: _departureCity!.id,
        arrivalCity: _arrivalCity!.nameAr,
        arrivalCityId: _arrivalCity!.id,
        departureCountryId: _departureCountry!.id,
        departureCountry: _departureCountry!.nameAr,
        arrivalCountryId: _arrivalCountry!.id,
        arrivalCountry: _arrivalCountry!.nameAr,
        departureProvince: _departureProvince!.nameAr,
        departureProvinceId: _departureProvince!.id,
        arrivalProvince: _arrivalProvince!.nameAr,
        arrivalProvinceId: _arrivalProvince!.id,
        departureTime: depTime,
        arrivalTime: arrTime,
        price: priceVal,
        totalSeats: totalPassengerSeats,
        remainingSeats: finalRemaining,
        seatLayout: finalSeats,
        stops: _stops,
        tripType: _tripType,
        isWomenOnly: false,
        hasAc: _hasAc,
        hasWifi: _hasWifi,
        hasLuggageSpace: _hasLuggageSpace,
        allowSmoking: _allowSmoking,
        allowPets: false,
        isVip: false,
        requiresApproval: false,
        paymentMethodIds: _selectedPaymentMethodIds,
        parcelCountLimit: _acceptsParcels ? 5 : 0,
        parcelCapacityKg: _acceptsParcels ? _parcelCapacityKg : 0.0,
        parcelPrice: parcelPriceVal,
        status: widget.initialTrip?.status ?? 'published',
        createdAt: widget.initialTrip?.createdAt ?? DateTime.now(),
        notes: _notesCtrl.text.trim(),
      );

      final repo = ref.read(tripRepositoryProvider);
      await repo.createTrip(trip); // This upserts

      if (mounted) {
        setState(() => _isLoading = false);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialTrip != null
                  ? 'تم تعديل الرحلة بنجاح'
                  : 'تم إنشاء ونشر الرحلة بنجاح',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تعذر حفظ الرحلة. الرجاء التحقق من البيانات والاتصال بالإنترنت.',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: DriverTokens.semanticError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: AppTheme.lightTheme,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.initialTrip != null ? 'تعديل الرحلة' : 'إنشاء رحلة جديدة',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
          body: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: _nextStep,
            onStepCancel: _previousStep,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    if (_currentStep < 9)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B1F3A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'التالي',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    if (_currentStep == 9)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'حفظ ونشر الرحلة',
                                style: TextStyle(fontFamily: 'Cairo'),
                              ),
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(
                        _currentStep == 0 ? 'إلغاء' : 'السابق',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              _buildRouteStep(),
              _buildDateStep(),
              _buildVehicleStep(),
              _buildSeatsStep(),
              _buildStopsStep(),
              _buildFeaturesStep(),
              _buildParcelStep(),
              _buildPriceStep(),
              _buildPaymentStep(),
              _buildReviewStep(),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildRouteStep() {
    return Step(
      title: const Text(
        'مسار الرحلة',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 0,
      content: Column(
        children: [
          _buildLocationPicker(
            title: 'منطقة الانطلاق',
            country: _departureCountry,
            province: _departureProvince,
            city: _departureCity,
            onChanged: (country, prov, city) {
              setState(() {
                _departureCountry = country;
                _departureProvince = prov;
                _departureCity = city;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildLocationPicker(
            title: 'وجهة الوصول',
            country: _arrivalCountry,
            province: _arrivalProvince,
            city: _arrivalCity,
            onChanged: (country, prov, city) {
              setState(() {
                _arrivalCountry = country;
                _arrivalProvince = prov;
                _arrivalCity = city;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPicker({
    required String title,
    Country? country,
    Governorate? province,
    City? city,
    required Function(Country?, Governorate?, City?) onChanged,
  }) {
    // A simplified dropdown for locations. In real implementation, this would use your GeoProviders.
    final countries = ref.watch(countriesProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          countries.when(
            data: (cList) => DropdownButtonFormField<Country>(
              value: country,
              hint: const Text('اختر الدولة'),
              items: cList
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.nameAr)))
                  .toList(),
              onChanged: (val) => onChanged(val, null, null),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading countries'),
          ),
          if (country != null) ...[
            Consumer(
              builder: (context, ref, child) {
                final provs = ref.watch(provincesProvider(country.id));
                return provs.when(
                  data: (pList) => DropdownButtonFormField<Governorate>(
                    value: province,
                    hint: const Text('اختر المحافظة/المنطقة'),
                    items: pList
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.nameAr)),
                        )
                        .toList(),
                    onChanged: (val) => onChanged(country, val, null),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                );
              },
            ),
          ],
          if (province != null) ...[
            Consumer(
              builder: (context, ref, child) {
                final cities = ref.watch(citiesProvider(province.id));
                return cities.when(
                  data: (cList) => DropdownButtonFormField<City>(
                    value: city,
                    hint: const Text('اختر المدينة'),
                    items: cList
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.nameAr)),
                        )
                        .toList(),
                    onChanged: (val) => onChanged(country, province, val),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Step _buildDateStep() {
    return Step(
      title: const Text(
        'الموعد والتاريخ',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 1,
      content: Column(
        children: [
          ListTile(
            title: const Text('وقت الانطلاق'),
            subtitle: Text(
              _departureDate == null
                  ? 'لم يتم التحديد'
                  : '${DateFormat('yyyy-MM-dd').format(_departureDate!)} ${_departureTime?.format(context) ?? ''}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _departureDate = date;
                    _departureTime = time;
                  });
                }
              }
            },
          ),
          ListTile(
            title: const Text('وقت الوصول (اختياري)'),
            subtitle: Text(
              _arrivalDate == null
                  ? 'لم يتم التحديد'
                  : '${DateFormat('yyyy-MM-dd').format(_arrivalDate!)} ${_arrivalTime?.format(context) ?? ''}',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _departureDate ?? DateTime.now(),
                firstDate: _departureDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _arrivalDate = date;
                    _arrivalTime = time;
                  });
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Step _buildVehicleStep() {
    return Step(
      title: const Text(
        'المركبة',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 2,
      content: _driverVehicles.isEmpty
          ? const Text('لا توجد مركبات مسجلة. يرجى إضافة مركبة من حسابك.')
          : Column(
              children: _driverVehicles
                  .map(
                    (v) => RadioListTile<Vehicle>(
                      title: Text('${v.make} ${v.model} (${v.year})'),
                      subtitle: Text('عدد المقاعد: ${v.seatsCount}'),
                      value: v,
                      groupValue: _selectedVehicle,
                      onChanged: (val) =>
                          setState(() => _selectedVehicle = val),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Step _buildSeatsStep() {
    final int totalSeats = _selectedVehicle?.seatsCount ?? 4;

    return Step(
      title: const Text(
        'المقاعد',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 3,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'سعة المركبة: $totalSeats مقاعد.',
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          ),
          if (_customSeats != null && _customSeats!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DriverTokens.primaryNavy.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
              ),
              child: Text(
                'تم تخصيص المقاعد: ${_customSeats!.where((s) => s.status == 'available').length} متاح، ${_customSeats!.where((s) => s.status == 'blocked').length} محجوب، ${_customSeats!.where((s) => s.isWomenOnly).length} مخصص للنساء، ${_customSeats!.where((s) => s.isVip).length} VIP',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DriverTokens.primaryNavy,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: DriverTokens.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () async {
              final result = await context.push<List<Seat>>(
                '/manage-trip-seats',
                extra: {'seats': _customSeats, 'seatsCount': totalSeats},
              );
              if (result != null) {
                setState(() {
                  _customSeats = result;
                });
              }
            },
            icon: const Icon(Icons.event_seat),
            label: const Text(
              'تخصيص وتوزيع المقاعد (حجب / نسائي / VIP)',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStopsStep() {
    return Step(
      title: const Text(
        'محطات التوقف',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 4,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_stops.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'لم يتم إضافة أي محطات توقف.',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ..._stops.asMap().entries.map((entry) {
            final idx = entry.key;
            final stop = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  '${idx + 1}. ${stop.name}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Wrap(
                  spacing: 8,
                  children: [
                    if (stop.pickupAllowed)
                      const Chip(
                        label: Text(
                          'صعود مسموح',
                          style: TextStyle(fontSize: 10, fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Colors.greenAccent,
                      ),
                    if (stop.dropoffAllowed)
                      const Chip(
                        label: Text(
                          'نزول مسموح',
                          style: TextStyle(fontSize: 10, fontFamily: 'Cairo'),
                        ),
                        backgroundColor: Colors.lightBlueAccent,
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (idx > 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        onPressed: () {
                          setState(() {
                            final item = _stops.removeAt(idx);
                            _stops.insert(idx - 1, item);
                          });
                        },
                      ),
                    if (idx < _stops.length - 1)
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        onPressed: () {
                          setState(() {
                            final item = _stops.removeAt(idx);
                            _stops.insert(idx + 1, item);
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 18,
                      ),
                      onPressed: () => _showStopDialog(stop: stop, index: idx),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _stops.removeAt(idx);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showStopDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'إضافة محطة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTokens.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await context.push<List<Stop>>(
                      '/manage-trip-stops',
                      extra: _stops,
                    );
                    if (result != null) {
                      setState(() {
                        _stops = result;
                      });
                    }
                  },
                  icon: const Icon(Icons.alt_route),
                  label: const Text(
                    'إدارة وترتيب',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStopDialog({Stop? stop, int? index}) {
    final nameCtrl = TextEditingController(text: stop?.name ?? '');
    final notesCtrl = TextEditingController(text: stop?.locationNotes ?? '');
    bool pickup = stop?.pickupAllowed ?? true;
    bool dropoff = stop?.dropoffAllowed ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                stop == null ? 'إضافة محطة جديدة' : 'تعديل المحطة',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'اسم المحطة',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text(
                        'يسمح بصعود الركاب',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: pickup,
                      onChanged: (val) => setStateDialog(() => pickup = val),
                    ),
                    SwitchListTile(
                      title: const Text(
                        'يسمح بنزول الركاب',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                      value: dropoff,
                      onChanged: (val) => setStateDialog(() => dropoff = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات المحطة',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final newStop = Stop(
                      id:
                          stop?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      pickupAllowed: pickup,
                      dropoffAllowed: dropoff,
                      orderIndex: index ?? _stops.length,
                      locationNotes: notesCtrl.text.trim(),
                    );
                    setState(() {
                      if (index != null) {
                        _stops[index] = newStop;
                      } else {
                        _stops.add(newStop);
                      }
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Step _buildFeaturesStep() {
    return Step(
      title: const Text(
        'ميزات الرحلة',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 5,
      content: Column(
        children: [
          SwitchListTile(
            title: const Text('يوجد تكييف'),
            value: _hasAc,
            onChanged: (v) => setState(() => _hasAc = v),
          ),
          SwitchListTile(
            title: const Text('واي فاي'),
            value: _hasWifi,
            onChanged: (v) => setState(() => _hasWifi = v),
          ),
          SwitchListTile(
            title: const Text('مساحة للأمتعة'),
            value: _hasLuggageSpace,
            onChanged: (v) => setState(() => _hasLuggageSpace = v),
          ),
          SwitchListTile(
            title: const Text('يسمح بالتدخين'),
            value: _allowSmoking,
            onChanged: (v) => setState(() => _allowSmoking = v),
          ),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'ملاحظات إضافية',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Step _buildParcelStep() {
    final currencyLabel = _selectedCurrency == 'YER'
        ? 'ريال يمني'
        : 'ريال سعودي';
    return Step(
      title: const Text(
        'خدمة الطرود',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 6,
      content: Column(
        children: [
          SwitchListTile(
            title: const Text('استقبال الطرود مع الرحلة'),
            value: _acceptsParcels,
            activeColor: DriverTokens.primaryNavy,
            onChanged: (v) => setState(() => _acceptsParcels = v),
          ),
          if (_acceptsParcels) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _parcelPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    'سعر الطرد الأساسي ($currencyLabel - $_selectedCurrency)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Step _buildPriceStep() {
    return Step(
      title: const Text(
        'العملة والسعر',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 7,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'عملة تسعير الرحلة:',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Text(
                      'ريال يمني (YER)',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  selected: _selectedCurrency == 'YER',
                  selectedColor: DriverTokens.primaryNavy.withValues(
                    alpha: 0.15,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCurrency = 'YER');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: Text(
                      'ريال سعودي (SAR)',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                  selected: _selectedCurrency == 'SAR',
                  selectedColor: DriverTokens.primaryNavy.withValues(
                    alpha: 0.15,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCurrency = 'SAR');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'سعر المقعد للراكب ($_selectedCurrency)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildPaymentStep() {
    return Step(
      title: const Text(
        'حسابات الدفع المعتمدة',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 8,
      content: Consumer(
        builder: (context, ref, child) {
          final methodsAsync = ref.watch(driverPaymentMethodsProvider);
          return methodsAsync.when(
            data: (methods) {
              final activeMethods = methods
                  .where((m) => m.isActive)
                  .toList();

              if (activeMethods.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DriverTokens.semanticWarning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      DriverTokens.radiusSmall,
                    ),
                    border: Border.all(
                      color: DriverTokens.semanticWarning.withValues(
                        alpha: 0.3,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: DriverTokens.semanticWarning,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'لا توجد طريقة دفع مفعلة حالياً.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'يشترط وجود طريقة دفع مفعلة واحدة على الأقل لاستقبال حجوزات الركاب.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverTokens.primaryNavy,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => context.push('/payment-methods'),
                        icon: const Icon(Icons.account_balance_wallet),
                        label: const Text(
                          'إدارة طرق الدفع',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر طرق الدفع التي ترغب في ربطها بهذه الرحلة:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...activeMethods.map((m) {
                    return CheckboxListTile(
                      title: Text(
                        '${m.providerName} - ${m.accountNumber}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        m.type == 'bank' ? 'حساب بنكي' : 'محفظة إلكترونية',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                      ),
                      value: _selectedPaymentMethodIds.contains(m.id),
                      activeColor: DriverTokens.primaryNavy,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedPaymentMethodIds.add(m.id);
                          } else {
                            _selectedPaymentMethodIds.remove(m.id);
                          }
                        });
                      },
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => const Text(
              'حدث خطأ في جلب طرق الدفع',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
          );
        },
      ),
    );
  }

  Step _buildReviewStep() {
    final hasRoute = _departureCity != null && _arrivalCity != null;
    final hasDate = _departureDate != null && _departureTime != null;
    final hasVehicle = _selectedVehicle != null;
    final hasPrice = (double.tryParse(_priceCtrl.text) ?? 0) > 0;
    final hasPayment = _selectedPaymentMethodIds.isNotEmpty;
    final isReadyToPublish = hasRoute && hasDate && hasVehicle && hasPrice;

    return Step(
      title: const Text(
        'المراجعة وجاهزية النشر',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
      ),
      isActive: _currentStep >= 9,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isReadyToPublish
                  ? DriverTokens.semanticSuccess.withValues(alpha: 0.08)
                  : DriverTokens.semanticError.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DriverTokens.radiusSmall),
              border: Border.all(
                color: isReadyToPublish
                    ? DriverTokens.semanticSuccess.withValues(alpha: 0.3)
                    : DriverTokens.semanticError.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isReadyToPublish ? Icons.check_circle : Icons.error_outline,
                  color: isReadyToPublish
                      ? DriverTokens.semanticSuccess
                      : DriverTokens.semanticError,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isReadyToPublish
                        ? 'الرحلة مكتملة البيانات وجاهزة للنشر فوراً.'
                        : 'يرجى استكمال البيانات الناقصة قبل النشر.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: isReadyToPublish
                          ? DriverTokens.semanticSuccess
                          : DriverTokens.semanticError,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildChecklistItem(
            'المسار',
            hasRoute,
            '${_departureCity?.nameAr ?? "غير محدد"} ← ${_arrivalCity?.nameAr ?? "غير محدد"}',
          ),
          _buildChecklistItem(
            'الموعد',
            hasDate,
            hasDate
                ? '${DateFormat("yyyy-MM-dd").format(_departureDate!)} ${_departureTime?.format(context) ?? ""}'
                : 'غير محدد',
          ),
          _buildChecklistItem(
            'المركبة',
            hasVehicle,
            hasVehicle
                ? '${_selectedVehicle!.make} ${_selectedVehicle!.model} (${_selectedVehicle!.plateNumber})'
                : 'غير محددة',
          ),
          _buildChecklistItem(
            'السعر والعملة',
            hasPrice,
            hasPrice
                ? '${_priceCtrl.text} $_selectedCurrency'
                : 'لم يتم تحديد سعر صحيح',
          ),
          _buildChecklistItem(
            'طرق الدفع',
            hasPayment,
            hasPayment
                ? '${_selectedPaymentMethodIds.length} طرق دفع محددة'
                : 'لا توجد طريقة دفع مختارة (تحذير)',
            isWarning: !hasPayment,
          ),
          const SizedBox(height: 16),
          if (_acceptsParcels)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '• خدمة الطرود: مفعلة بسعر ${_parcelPriceCtrl.text} $_selectedCurrency',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
          if (_stops.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                '• محطات التوقف: ${_stops.length} محطة إضافية',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    String label,
    bool isOk,
    String value, {
    bool isWarning = false,
  }) {
    final iconColor = isOk
        ? DriverTokens.semanticSuccess
        : (isWarning
              ? DriverTokens.semanticWarning
              : DriverTokens.semanticError);
    final icon = isOk
        ? Icons.check_circle
        : (isWarning ? Icons.warning_amber : Icons.cancel);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: isOk
                    ? Colors.black87
                    : (isWarning
                          ? DriverTokens.semanticWarning
                          : DriverTokens.semanticError),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
