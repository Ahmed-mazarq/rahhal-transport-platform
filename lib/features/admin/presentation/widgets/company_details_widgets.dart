import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/admin/presentation/providers/admin_company_details_provider.dart';
import 'package:rahal/features/admin/utils/booking_status_mapper.dart';

import 'package:rahal/core/widgets/secure_document_image.dart';
import 'package:rahal/features/admin/presentation/screens/admin_booking_details_screen.dart';
import 'package:rahal/features/admin/presentation/screens/admin_trip_details_screen.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';

class CompanyPersonalInfoTab extends ConsumerWidget {
  final String userId;

  const CompanyPersonalInfoTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyDetailsProvider(userId));
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
                  .read(companyDetailsProvider(userId).notifier)
                  .fetchData(userId),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final company = state.company;
    if (company == null)
      return const Center(
        child: Text(
          'بيانات الشركة غير متوفرة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('بيانات الشركة'),
          _buildCard([
            _buildRow('اسم الشركة', company.name),
            _buildRow('السجل التجاري', company.commercialRegister),
            _buildRow('حالة الشركة', company.status),
            _buildRow('رقم الهاتف', company.companyPhone),
            _buildRow('الهاتف البديل', company.alternativePhone),
            _buildRow('الدولة', company.country),
            _buildRow('المحافظة', company.governorate),
            _buildRow('المدينة الرئيسية', company.mainCity),
            _buildRow('العنوان', company.detailedAddress),
            _buildRow('وصف الشركة', company.companyDescription),
            _buildRow('نوع النشاط', company.businessType),
            _buildRow('سنة التأسيس', company.establishmentYear),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('بيانات المدير'),
          _buildCard([
            _buildRow('اسم المدير', company.managerName),
            _buildRow('هاتف المدير', company.managerPhone),
            _buildRow('منصب المدير', company.managerPosition),
            _buildRow('جنسية المدير', company.managerNationality),
            _buildRow('رقم جواز المدير', company.managerPassportNumber),
            _buildRow('انتهاء جواز المدير', company.managerPassportExpiry),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('التسجيل والتراخيص'),
          _buildCard([
            _buildRow('انتهاء التسجيل', company.registrationExpiry),
            _buildRow('الترخيص التشغيلي', company.operatingLicense),
            _buildRow('انتهاء الترخيص', company.licenseExpiry),
            _buildRow('الرقم الضريبي', company.taxNumber),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('الإحصائيات'),
          _buildCard([
            _buildRow('عدد الفروع', company.branchCount.toString()),
            _buildRow('حجم الأسطول', company.fleetSize.toString()),
            _buildRow('عدد السائقين', company.driverCount.toString()),
            _buildRow('الرصيد', company.walletBalance.toString()),
            _buildRow('عدد الرحلات', state.trips.length.toString()),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('معلومات الدفع'),
          _buildCard([
            _buildRow('البنك', company.bankName),
            _buildRow('صاحب الحساب', company.accountHolder),
            _buildRow('رقم الحساب', company.accountNumber),
            _buildRow('IBAN', company.iban),
            _buildRow('المحفظة الإلكترونية', company.ewalletName),
            _buildRow('رقم المحفظة', company.ewalletNumber),
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

class CompanyTripsBookingsTab extends ConsumerWidget {
  final String userId;
  const CompanyTripsBookingsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyDetailsProvider(userId));
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: TextButton(
          onPressed: () => ref
              .read(companyDetailsProvider(userId).notifier)
              .fetchData(userId),
          child: const Text('إعادة المحاولة'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(companyDetailsProvider(userId).notifier)
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

class CompanyDocumentsTab extends ConsumerWidget {
  final String userId;
  const CompanyDocumentsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyDetailsProvider(userId));
    if (state.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (state.error != null) {
      return Center(
        child: TextButton(
          onPressed: () => ref
              .read(companyDetailsProvider(userId).notifier)
              .fetchData(userId),
          child: const Text('إعادة المحاولة'),
        ),
      );
    }

    final docs = state.company?.documents.values.toList() ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(companyDetailsProvider(userId).notifier)
            .fetchData(userId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'مستندات الشركة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لا توجد مستندات للشركة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ...docs.map((doc) => _buildDocCard(doc)),
        ],
      ),
    );
  }

  Widget _buildDocCard(dynamic doc) {
    final url = doc.url;
    final type = doc.documentType;
    final status = doc.status;

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
