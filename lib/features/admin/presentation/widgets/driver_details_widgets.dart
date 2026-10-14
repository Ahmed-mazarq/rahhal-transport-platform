import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rahal/features/admin/presentation/providers/admin_driver_details_provider.dart';
import 'package:rahal/features/admin/utils/booking_status_mapper.dart';

import 'package:rahal/core/widgets/secure_document_image.dart';
import 'package:rahal/features/admin/presentation/screens/admin_booking_details_screen.dart';
import 'package:rahal/features/admin/presentation/screens/admin_trip_details_screen.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';

class DriverPersonalInfoTab extends ConsumerWidget {
  final String userId;

  const DriverPersonalInfoTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverDetailsProvider(userId));
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'تعذر تحميل البيانات',
              style: TextStyle(fontFamily: 'Cairo'),
            ),
            TextButton(
              onPressed: () => ref
                  .read(driverDetailsProvider(userId).notifier)
                  .fetchData(userId),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final driver = state.driver;
    if (driver == null)
      return const Center(
        child: Text(
          'بيانات السائق غير متوفرة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('معلومات الحساب'),
          _buildCard([
            _buildRow('الاسم الكامل', driver.fullName),
            _buildRow('رقم الهاتف', driver.phone),
            _buildRow('البريد الإلكتروني', driver.email),
            _buildRow('الرقم الإضافي', driver.secondaryPhone),
            _buildRow('الجنسية', driver.nationality),
            _buildRow('الجنس', driver.gender),
            _buildRow('الدولة', driver.country),
            _buildRow('المحافظة', driver.governorate),
            _buildRow('المدينة', driver.city),
            _buildRow('الحي', driver.district),
            _buildRow('حالة التحقق', driver.isVerified ? 'موثق' : 'غير موثق'),
            _buildRow('التقييم', driver.rating.toString()),
            _buildRow('الرحلات المكتملة', driver.totalTrips.toString()),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('معلومات الهوية'),
          _buildCard([
            _buildRow('رقم الجواز / الهوية', driver.passportNumber),
            _buildRow('الدولة', driver.passportCountry),
            _buildRow('تاريخ الإصدار', driver.passportIssueDate),
            _buildRow('تاريخ الانتهاء', driver.passportExpiry),
            _buildRow(
              'حالة التحقق',
              driver.passportVerified ? 'موثق' : 'غير موثق',
            ),
            _buildRow('ملاحظات', driver.passportNotes),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('رخصة القيادة'),
          _buildCard([
            _buildRow('رقم الرخصة', driver.licenseNumber),
            _buildRow('نوع الرخصة', driver.licenseType),
            _buildRow('دولة الإصدار', driver.licenseCountry),
            _buildRow('تاريخ الإصدار', driver.licenseIssueDate),
            _buildRow('تاريخ الانتهاء', driver.licenseExpiryDate),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('معلومات المركبة'),
          _buildCard([
            _buildRow('المركبة', driver.vehicleId),
            _buildRow('النوع', driver.vehicleType),
            _buildRow('الفئة', driver.vehicleCategory),
            _buildRow('الشركة المصنعة', driver.vehicleManufacturer),
            _buildRow('الموديل', driver.vehicleModel),
            _buildRow('السنة', driver.vehicleYear),
            _buildRow('اللون', driver.vehicleColor),
            _buildRow('الوقود', driver.fuelType),
            _buildRow('ناقل الحركة', driver.transmission),
            _buildRow('رقم اللوحة', driver.plateNumber),
            _buildRow('دولة اللوحة', driver.plateCountry),
            _buildRow('VIN', driver.vin),
            _buildRow('رقم التسجيل', driver.registrationNumber),
            _buildRow('انتهاء التسجيل', driver.registrationExpiry),
            _buildRow('شركة التأمين', driver.insuranceCompany),
            _buildRow('رقم التأمين', driver.insuranceNumber),
            _buildRow('رقم الوثيقة', driver.policyNumber),
            _buildRow('انتهاء التأمين', driver.insuranceExpiry),
            _buildRow('التغطية', driver.coverage),
          ]),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          _buildSectionTitle('حسابات الدفع'),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('driver_payment_methods')
                .where('driverId', isEqualTo: driver.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return _buildCard([
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'لا توجد حسابات دفع مسجلة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                ]);
              }

              final accounts = snapshot.data!.docs;
              return Column(
                children: accounts.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type'] == 'bank' ? 'حساب بنكي' : 'محفظة';
                  final providerName = data['providerName'] ?? 'غير محدد';
                  final accountNumber = data['accountNumber'] ?? 'غير متوفر';
                  final iban = data['iban'] ?? '';
                  final isActive = data['isActive'] == true;
                  final createdAt = data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp)
                            .toDate()
                            .toString()
                            .substring(0, 10)
                      : 'غير متوفر';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildCard([
                      _buildRow('نوع الحساب', type),
                      _buildRow('مزود الخدمة / البنك', providerName),
                      _buildRow(
                        type == 'حساب بنكي' ? 'رقم الحساب' : 'رقم المحفظة',
                        accountNumber,
                      ),
                      if (iban.isNotEmpty) _buildRow('IBAN', iban),
                      _buildRow('الحالة', isActive ? 'نشط' : 'غير نشط'),
                      _buildRow('تاريخ الإضافة', createdAt),
                    ]),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('جهة الاتصال للطوارئ'),
          _buildCard([
            _buildRow('الاسم', driver.emergencyContactName),
            _buildRow('صلة القرابة', driver.emergencyContactRelation),
            _buildRow('الهاتف', driver.emergencyContactPhone),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    final displayValue = (value.isEmpty || value == 'null')
        ? 'غير متوفر'
        : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontFamily: 'Cairo',
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              displayValue,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class DriverTripsBookingsTab extends ConsumerWidget {
  final String userId;
  const DriverTripsBookingsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverDetailsProvider(userId));
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: TextButton(
          onPressed: () => ref
              .read(driverDetailsProvider(userId).notifier)
              .fetchData(userId),
          child: const Text('إعادة المحاولة'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(driverDetailsProvider(userId).notifier)
            .fetchData(userId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExpansionTile(
            title: Text(
              'الرحلات (${state.trips.length})',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            initiallyExpanded: true,
            children: state.trips.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لا توجد رحلات',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ]
                : state.trips.map((t) => _buildTripCard(t, context)).toList(),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text(
              'الحجوزات (${state.bookings.length})',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
            initiallyExpanded: true,
            children: state.bookings.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لا توجد حجوزات',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ]
                : state.bookings
                      .map((b) => _buildBookingCard(b, context))
                      .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Trip trip, BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          '${trip.startLocationName.isNotEmpty ? trip.startLocationName : trip.departureCity} → ${trip.endLocationName.isNotEmpty ? trip.endLocationName : trip.arrivalCity}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'الموعد: ${trip.departureTime.toString().substring(0, 16)}',
        ),
        trailing: Chip(
          label: Text(
            TripStatusMapper.getLabel(trip.status),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          backgroundColor: TripStatusMapper.getColor(trip.status),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminTripDetailsScreen(trip: trip),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          'الحجز #${booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.id.substring(0, 8)}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('الراكب: ${booking.passengerId}'),
        trailing: Chip(
          label: Text(
            BookingStatusMapper.getLabel(booking.status),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          backgroundColor: BookingStatusMapper.getColor(booking.status),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminBookingDetailsScreen(booking: booking),
            ),
          );
        },
      ),
    );
  }
}

class DriverDocumentsTab extends ConsumerWidget {
  final String userId;
  const DriverDocumentsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverDetailsProvider(userId));
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: TextButton(
          onPressed: () => ref
              .read(driverDetailsProvider(userId).notifier)
              .fetchData(userId),
          child: const Text('إعادة المحاولة'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(driverDetailsProvider(userId).notifier)
            .fetchData(userId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'المستندات الشخصية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (state.driverDocuments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد مستندات شخصية',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ...state.driverDocuments.map((doc) => _buildDocCard(doc)),
          const SizedBox(height: 24),
          const Text(
            'مستندات المركبة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (state.vehicleDocuments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد مستندات للمركبة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ...state.vehicleDocuments.map((doc) => _buildDocCard(doc)),
        ],
      ),
    );
  }

  Widget _buildDocCard(Map<String, dynamic> doc) {
    final url = doc['fileUrl'] ?? doc['url'] ?? '';
    final type = doc['type'] ?? doc['documentType'] ?? 'مستند';
    final status = doc['status'] ?? 'unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          type,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "الحالة: $status",
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doc['documentNumber'] != null)
                  Text('رقم المستند: ${doc['documentNumber']}'),
                if (doc['issueDate'] != null)
                  Text('تاريخ الإصدار: ${doc['issueDate']}'),
                if (doc['expiryDate'] != null)
                  Text('تاريخ الانتهاء: ${doc['expiryDate']}'),
                if (url.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: SecureDocumentImage(
                      storedReference: url,
                      fit: BoxFit.contain,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'لا توجد صورة للمستند',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
