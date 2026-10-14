import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:rahal/core/utils/rtl_format.dart';
import '../providers/parcel_provider.dart';
import '../../domain/models/parcel_delivery.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import 'package:rahal/features/parcel/presentation/screens/parcel_chat_screen.dart';

class ParcelDetailsScreen extends ConsumerWidget {
  final String parcelId;
  const ParcelDetailsScreen({super.key, required this.parcelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcelAsync = ref.watch(parcelDetailsProvider(parcelId));
    final eventsAsync = ref.watch(parcelEventsProvider(parcelId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final userId = authState is Authenticated ? authState.user.id : '';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تفاصيل الطرد',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      floatingActionButton: parcelAsync.whenData((parcel) {
        if (parcel != null &&
            parcel.status != 'searching_for_carrier' &&
            parcel.status != 'pending_carrier_acceptance' &&
            parcel.status != 'rejected' &&
            (parcel.senderId == userId ||
                parcel.driverId == userId ||
                parcel.companyId == userId)) {
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParcelChatScreen(parcel: parcel),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: const Text('محادثة', style: TextStyle(fontFamily: 'Cairo')),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          );
        }
        return null;
      }).value,
      body: parcelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')),
        ),
        data: (parcel) {
          if (parcel == null) {
            return const Center(
              child: Text(
                'الطرد غير موجود',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrackingHeader(context, parcel, isDark),
                const SizedBox(height: 16),
                _buildParcelInfoCard(context, parcel, isDark),
                const SizedBox(height: 16),
                if (parcel.driverId != null &&
                    parcel.status != 'searching_for_carrier' &&
                    parcel.status != 'rejected') ...[
                  _buildDriverInfoCard(context, parcel, isDark),
                  const SizedBox(height: 16),
                ],

                const Text(
                  'سجل التتبع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                eventsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text(
                    'خطأ في تحميل السجل: $e',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  data: (events) {
                    if (events.isEmpty) {
                      return const Text(
                        'لا يوجد سجل بعد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      );
                    }
                    return Column(
                      children: events.map((event) {
                        return ListTile(
                          leading: const Icon(
                            Icons.circle,
                            size: 12,
                            color: Color(0xFFF5A623),
                          ),
                          title: Text(
                            event.description,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${RtlFormat.formatDate(event.timestamp)} ${RtlFormat.formatTime(event.timestamp)}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackingHeader(
    BuildContext context,
    ParcelDelivery parcel,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          QrImageView(
            data: parcel.qrCodeValue ?? parcel.trackingNumber,
            version: QrVersions.auto,
            size: 100.0,
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parcel.trackingNumber,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0B1F3A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(parcel.status),
                const SizedBox(height: 8),
                Text(
                  'تاريخ الإنشاء:\n${RtlFormat.formatDate(parcel.createdAt)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'آخر تحديث:\n${RtlFormat.formatDate(parcel.updatedAt)} — ${RtlFormat.formatTime(parcel.updatedAt)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (parcel.pickupVerificationCode != null &&
                    !['delivered', 'completed'].contains(parcel.status)) ...[
                  const SizedBox(height: 8),
                  Text(
                    'رمز الاستلام: ${parcel.pickupVerificationCode}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (parcel.deliveryVerificationCode != null &&
                    !['delivered', 'completed'].contains(parcel.status)) ...[
                  const SizedBox(height: 4),
                  Text(
                    'رمز التسليم: ${parcel.deliveryVerificationCode}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelInfoCard(
    BuildContext context,
    ParcelDelivery parcel,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مسار الطرد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'من',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      parcel.originCountry,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      parcel.originProvince,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    if (parcel.originCity.isNotEmpty)
                      Text(
                        parcel.originCity,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                      ),
                    if (parcel.originDistrict != null &&
                        parcel.originDistrict!.isNotEmpty)
                      Text(
                        parcel.originDistrict!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (parcel.originAddress != null &&
                        parcel.originAddress!.isNotEmpty)
                      Text(
                        parcel.originAddress!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إلى',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      parcel.destinationCountry,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      parcel.destinationProvince,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    if (parcel.destinationCity.isNotEmpty)
                      Text(
                        parcel.destinationCity,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                        ),
                      ),
                    if (parcel.destinationDistrict != null &&
                        parcel.destinationDistrict!.isNotEmpty)
                      Text(
                        parcel.destinationDistrict!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (parcel.destinationAddress != null &&
                        parcel.destinationAddress!.isNotEmpty)
                      Text(
                        parcel.destinationAddress!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'معلومات المستلم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          _buildInfoRow('اسم المستلم', parcel.receiverName),
          _buildInfoRow('رقم الهاتف', parcel.receiverPhone),
          _buildInfoRow('العنوان', parcel.receiverAddress),
          if (parcel.receiverProvince != null)
            _buildInfoRow('المحافظة', parcel.receiverProvince!),
          if (parcel.receiverCity.isNotEmpty)
            _buildInfoRow('المدينة', parcel.receiverCity),
          if (parcel.receiverDistrict != null &&
              parcel.receiverDistrict!.isNotEmpty)
            _buildInfoRow('المديرية', parcel.receiverDistrict!),

          const SizedBox(height: 24),
          const Text(
            'تفاصيل الطرد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          _buildInfoRow('الفئة', parcel.category),
          if (parcel.description.isNotEmpty)
            _buildInfoRow('الوصف', parcel.description),
          _buildInfoRow('الوزن', '${parcel.weight} كجم'),
          _buildInfoRow('الحجم', _translateSize(parcel.size)),
          _buildInfoRow('عدد القطع', '${parcel.pieceCount}'),
          _buildInfoRow(
            'قابل للكسر',
            parcel.isFragile ? 'نعم' : 'لا',
            color: parcel.isFragile ? Colors.red : null,
          ),
          _buildInfoRow(
            'القيمة المصرح بها',
            '${parcel.declaredValue} ${parcel.currency}',
          ),
          if (parcel.specialInstructions.isNotEmpty)
            _buildInfoRow('ملاحظات خاصة', parcel.specialInstructions),

          const SizedBox(height: 24),
          const Text(
            'الاستلام والتسليم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          _buildInfoRow(
            'طريقة الاستلام',
            _translateMethod(parcel.pickupMethod),
          ),
          _buildInfoRow(
            'طريقة التسليم',
            _translateMethod(parcel.deliveryMethod),
          ),

          const SizedBox(height: 24),
          const Text(
            'السعر',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          if (parcel.price > 0)
            _buildInfoRow('التكلفة', '${parcel.price} ${parcel.currency}')
          else
            _buildInfoRow('التكلفة', 'سيتم تحديد السعر لاحقاً'),
        ],
      ),
    );
  }

  String _translateSize(String size) {
    switch (size) {
      case 'small':
        return 'صغير';
      case 'medium':
        return 'متوسط';
      case 'large':
        return 'كبير';
      default:
        return size;
    }
  }

  String _translateMethod(String method) {
    switch (method) {
      case 'door_to_door':
        return 'من الباب للباب';
      case 'drop_off':
        return 'تسليم في نقطة';
      case 'meeting_point':
        return 'نقطة التقاء';
      default:
        return method;
    }
  }

  Widget _buildDriverInfoCard(
    BuildContext context,
    ParcelDelivery parcel,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'السائق المسؤول عن طردك',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          if (parcel.carrierName != null)
            _buildInfoRow('الاسم', parcel.carrierName!),
          if (parcel.carrierRating != null)
            _buildInfoRow(
              'التقييم',
              '⭐ ${parcel.carrierRating!.toStringAsFixed(1)}',
            ),
          if (parcel.carrierTripsCount != null)
            _buildInfoRow('الرحلات', '${parcel.carrierTripsCount} مكتملة'),
          if (parcel.vehicleType != null)
            _buildInfoRow(
              'المركبة',
              '${parcel.vehicleType} - ${parcel.vehicleModel ?? ""}',
            ),
          if (parcel.vehicleColor != null)
            _buildInfoRow('لون المركبة', parcel.vehicleColor!),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.verified, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text(
                'سائق موثق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'searching_for_carrier':
        color = Colors.orange;
        text = 'جاري البحث عن ناقل';
        break;
      case 'pending_carrier_acceptance':
        color = Colors.orange;
        text = 'بانتظار قبول الناقل';
        break;
      case 'accepted':
        color = Colors.blue;
        text = 'تم قبول الطرد';
        break;
      case 'awaiting_pickup':
        color = Colors.purple;
        text = 'بانتظار الاستلام';
        break;
      case 'picked_up':
        color = Colors.deepPurple;
        text = 'تم استلام الطرد';
        break;
      case 'in_transit':
        color = Colors.indigo;
        text = 'الطرد في الطريق';
        break;
      case 'arrived':
        color = Colors.teal;
        text = 'وصل إلى الوجهة';
        break;
      case 'ready_for_delivery':
        color = Colors.teal;
        text = 'جاهز للتسليم';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'تم التسليم';
        break;
      case 'completed':
        color = Colors.green;
        text = 'مكتمل';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'ملغى';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'تم رفض الطلب';
        break;
      case 'delivery_failed':
        color = Colors.redAccent;
        text = 'فشل التسليم';
        break;
      case 'disputed':
        color = Colors.amber;
        text = 'متنازع عليه';
        break;
      case 'lost':
        color = Colors.black;
        text = 'مفقود';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Cairo',
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
