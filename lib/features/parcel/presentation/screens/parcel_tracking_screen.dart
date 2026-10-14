import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rahal/features/auth/presentation/providers/auth_provider.dart';
import '../providers/parcel_provider.dart';

class ParcelTrackingScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSendNewParcel;
  const ParcelTrackingScreen({super.key, this.onSendNewParcel});

  @override
  ConsumerState<ParcelTrackingScreen> createState() =>
      _ParcelTrackingScreenState();
}

class _ParcelTrackingScreenState extends ConsumerState<ParcelTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = TabBarView(
      controller: _tabController,
      children: [
        _buildParcelsList([
          'searching_for_carrier',
          'pending_carrier_acceptance',
          'accepted',
          'awaiting_pickup',
          'picked_up',
          'in_transit',
          'arrived',
          'ready_for_delivery',
        ]),
        _buildParcelsList(['delivered', 'completed', 'cancelled', 'rejected']),
        _buildParcelsList(['delivery_failed', 'disputed', 'lost']),
      ],
    );

    if (widget.onSendNewParcel != null) {
      return Column(
        children: [
          TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
            labelColor: const Color(0xFFF5A623),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFF5A623),
            tabs: const [
              Tab(text: 'الحالية'),
              Tab(text: 'السابقة'),
              Tab(text: 'المشاكل'),
            ],
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'طرودي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          labelColor: const Color(0xFFF5A623),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFF5A623),
          tabs: const [
            Tab(text: 'الحالية'),
            Tab(text: 'السابقة'),
            Tab(text: 'المشاكل'),
          ],
        ),
      ),
      body: body,
    );
  }

  Widget _buildParcelsList(List<String> statuses) {
    final authState = ref.watch(authProvider);
    if (authState is! Authenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    final parcelsAsyncValue = ref.watch(
      passengerParcelsProvider(authState.user.id),
    );

    return parcelsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) {
        String errorMsg =
            'تعذر تحميل طرودك. حدث خطأ مؤقت أثناء تحميل البيانات.';
        final errorStr = e.toString();
        if (errorStr.contains('failed-precondition')) {
          errorMsg = 'يحتاج النظام إلى تحديث بسيط. حاول مرة أخرى.';
        } else if (errorStr.contains('permission-denied')) {
          errorMsg = 'ليس لديك صلاحية للوصول إلى هذه البيانات.';
        } else if (errorStr.contains('unavailable')) {
          errorMsg = 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت.';
        } else if (errorStr.contains('not-found')) {
          errorMsg = 'لم يعد هذا الطرد متاحًا.';
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'تعذر تحميل طرودك',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(passengerParcelsProvider(authState.user.id)),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A623),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      data: (allParcels) {
        final docs = allParcels
            .where((p) => statuses.contains(p.status))
            .toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_rounded,
                  size: 60,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'لم ترسل أي طرد بعد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أرسل طردك بسهولة وتابع حالته حتى التسليم.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.onSendNewParcel != null)
                  ElevatedButton(
                    onPressed: widget.onSendNewParcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A623),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إرسال أول طرد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final parcel = docs[index];
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return InkWell(
              onTap: () async {
                await context.push('/parcel-details/${parcel.id}');
                ref.invalidate(passengerParcelsProvider(authState.user.id));
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          parcel.trackingNumber,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        _buildStatusBadge(parcel.status),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.flight_takeoff,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          parcel.originProvince,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const Icon(
                          Icons.flight_land,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          parcel.destinationProvince,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (parcel.originCity.isNotEmpty &&
                        parcel.destinationCity.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_city,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            parcel.originCity,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            parcel.destinationCity,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.category,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          parcel.category,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (parcel.driverId != null &&
                        parcel.carrierName != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'الناقل: ${parcel.carrierName}',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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
        text = 'تم القبول';
        break;
      case 'awaiting_pickup':
        color = Colors.purple;
        text = 'بانتظار الاستلام';
        break;
      case 'picked_up':
        color = Colors.deepPurple;
        text = 'تم الاستلام';
        break;
      case 'in_transit':
        color = Colors.indigo;
        text = 'في الطريق';
        break;
      case 'arrived':
        color = Colors.teal;
        text = 'وصل';
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
        text = 'مرفوض';
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
