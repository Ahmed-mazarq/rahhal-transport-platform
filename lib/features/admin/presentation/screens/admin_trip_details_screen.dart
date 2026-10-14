import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/rtl_format.dart';
import '../../../trips/domain/models/trip.dart';

class AdminTripDetailsScreen extends ConsumerWidget {
  final Trip trip;

  const AdminTripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل الرحلة',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'معلومات المسار والوقت',
              children: [
                _buildInfoRow('من', trip.departureCity),
                _buildInfoRow('إلى', trip.arrivalCity),
                _buildInfoRow(
                  'تاريخ ووقت المغادرة',
                  '${RtlFormat.formatDate(trip.departureTime)} - ${RtlFormat.formatTime(trip.departureTime)}',
                ),
                _buildInfoRow(
                  'تاريخ ووقت الوصول',
                  '${RtlFormat.formatDate(trip.arrivalTime)} - ${RtlFormat.formatTime(trip.arrivalTime)}',
                ),
                _buildInfoRow(
                  'المحطات الإضافية',
                  trip.stops.map((e) => e.name).join(', '),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'تفاصيل الرحلة',
              children: [
                _buildInfoRow('السعر', RtlFormat.formatPrice(trip.price)),
                _buildInfoRow('المقاعد الكلية', trip.totalSeats.toString()),
                _buildInfoRow(
                  'المقاعد المتبقية',
                  trip.remainingSeats.toString(),
                ),
                _buildInfoRow('حالة الرحلة', trip.status),
                _buildInfoRow('المميزات', _buildAmenitiesList(trip)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'السائق والمركبة',
              children: [
                _buildInfoRow('السائق (معرف)', trip.driverId),
                if (trip.isCompany) _buildInfoRow('الشركة', trip.name),
                _buildInfoRow('المركبة (معرف)', trip.vehicleId),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'معلومات النظام',
              children: [
                _buildInfoRow('معرف الرحلة', trip.id),
                _buildInfoRow(
                  'تاريخ الإنشاء',
                  '${RtlFormat.formatDate(trip.createdAt)} - ${RtlFormat.formatTime(trip.createdAt)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildAmenitiesList(Trip trip) {
    final List<String> features = [];
    if (trip.hasAc) features.add('المكيف');
    if (trip.hasWifi) features.add('Wi-Fi');
    if (trip.hasLuggageSpace) features.add('مساحة للأمتعة');
    if (trip.isWomenOnly) features.add('رحلة نسائية');
    if (trip.isFamilyOnly) features.add('رحلة عائلية');
    if (trip.isVip) features.add('VIP');
    if (trip.allowPets) features.add('يسمح بالحيوانات');
    if (trip.allowSmoking) features.add('يسمح بالتدخين');
    if (trip.requiresApproval) features.add('تتطلب موافقة');

    if (features.isEmpty) return 'لا توجد مميزات إضافية';
    return features.join(', ');
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1F3A),
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
