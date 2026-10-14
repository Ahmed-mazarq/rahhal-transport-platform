import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rahal/features/common/utils/date_parser.dart';
import '../../../trips/domain/models/trip.dart';
import '../providers/admin_operations_provider.dart';

class AdminTripsScreen extends ConsumerStatefulWidget {
  const AdminTripsScreen({super.key});

  @override
  ConsumerState<AdminTripsScreen> createState() => _AdminTripsScreenState();
}

class _AdminTripsScreenState extends ConsumerState<AdminTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'إدارة الرحلات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo'),
          labelColor: const Color(0xFF0B1F3A),
          indicatorColor: const Color(0xFF0B1F3A),
          tabs: const [
            Tab(text: 'جارية الآن'),
            Tab(text: 'مجدولة'),
            Tab(text: 'مكتملة'),
            Tab(text: 'ملغاة'),
            Tab(text: 'مسودة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _TripsTabView(status: ['running', 'active', 'started']),
          _TripsTabView(
            status: [
              'scheduled',
              'published',
              'open_for_booking',
              'almost_full',
            ],
          ),
          _TripsTabView(status: ['completed', 'finished']),
          _TripsTabView(status: 'cancelled'),
          _TripsTabView(status: 'draft'),
        ],
      ),
    );
  }
}

class _TripsTabView extends ConsumerWidget {
  final dynamic status;
  const _TripsTabView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String orderBy = 'createdAt';
    bool descending = true;

    if (status is List) {
      if ((status as List).contains('scheduled') ||
          (status as List).contains('published') ||
          (status as List).contains('open_for_booking') ||
          (status as List).contains('almost_full')) {
        orderBy = 'departureTime';
        descending = false;
      } else if ((status as List).contains('running') ||
          (status as List).contains('active') ||
          (status as List).contains('started')) {
        orderBy = 'departureTime';
        descending = true;
      } else if ((status as List).contains('completed')) {
        orderBy = 'departureTime';
        descending = true;
      }
    } else {
      if (status == 'cancelled') {
        orderBy = 'updatedAt';
        descending = true;
      } else if (status == 'draft') {
        orderBy = 'createdAt';
        descending = true;
      }
    }

    final streamAsync = ref.watch(
      opsStreamProvider(
        OpsCollectionParams(
          'trips',
          defaultStatus: status,
          orderBy: orderBy,
          descending: descending,
          sortLocally: false,
        ),
      ),
    );

    return streamAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return const Center(
            child: Text(
              'لا توجد رحلات بهذا التصنيف',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return _buildDataTable(context, ref, trips);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) =>
                  _buildTripCard(context, trips[index]),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildDataTable(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> trips,
  ) {
    final isRunning = status is List
        ? (status as List).contains('running') ||
              (status as List).contains('active')
        : status == 'running' || status == 'active';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(
              label: Text(
                'الرقم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'المسار',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'تاريخ المغادرة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'السائق',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'السعر',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'المقاعد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'إجراءات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          rows: trips.map((trip) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    trip['id']?.toString().substring(0, 6) ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    '${trip['departureCity'] ?? 'غير محدد'} ➔ ${trip['arrivalCity'] ?? 'غير محدد'}',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    trip['departureTime'] != null
                        ? DateParser.formatDateTime(
                            DateParser.parse(trip['departureTime']),
                          )
                        : '-',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    trip['driverName'] ?? '-',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Text(
                    '${trip['price'] ?? 0} ر.س',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${trip['bookedSeats'] ?? 0} / ${trip['totalSeats'] ?? 0}',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      if (isRunning)
                        IconButton(
                          icon: const Icon(
                            Icons.gps_fixed,
                            color: Colors.green,
                          ),
                          tooltip: 'تتبع حي',
                          onPressed: () {
                            try {
                              context.push(
                                '/admin/operations/live-monitor',
                                extra: trip,
                              );
                            } catch (e) {
                              debugPrint('Navigation Error: $e');
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'عرض',
                        onPressed: () {
                          try {
                            final tripObj = Trip.fromJson(trip);
                            context.push(
                              '/admin/operations/trips/details/${trip['id']}',
                              extra: tripObj,
                            );
                          } catch (e) {
                            debugPrint('Navigation Error: $e');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'تعديل',
                        onPressed: () {
                          try {
                            final tripObj = Trip.fromJson(trip);
                            context.push('/create-trip', extra: tripObj);
                          } catch (e) {
                            debugPrint('Navigation Error: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Map<String, dynamic> trip) {
    final isRunning = status is List
        ? (status as List).contains('running') ||
              (status as List).contains('active')
        : status == 'running' || status == 'active';
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'رحلة #${trip['id']?.toString().substring(0, 6) ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${trip['price'] ?? 0} ر.س',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${trip['departureCity'] ?? 'غير محدد'} ➔ ${trip['arrivalCity'] ?? 'غير محدد'}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  trip['departureTime'] != null
                      ? DateParser.formatDateTime(
                          DateParser.parse(trip['departureTime']),
                        )
                      : '-',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_seat, color: Colors.grey, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${trip['bookedSeats'] ?? 0} / ${trip['totalSeats'] ?? 0} مقعد',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (isRunning)
                  ElevatedButton.icon(
                    onPressed: () {
                      try {
                        context.push(
                          '/admin/operations/live-monitor',
                          extra: trip,
                        );
                      } catch (e) {
                        debugPrint('Navigation Error: ');
                      }
                    },
                    icon: const Icon(Icons.gps_fixed, size: 16),
                    label: const Text(
                      'تتبع',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: 'عرض',
                  onPressed: () {
                    try {
                      final tripObj = Trip.fromJson(trip);
                      context.push(
                        '/admin/operations/trips/details/${trip['id']}',
                        extra: tripObj,
                      );
                    } catch (e) {
                      debugPrint('Navigation Error: ');
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  tooltip: 'تعديل',
                  onPressed: () {
                    try {
                      final tripObj = Trip.fromJson(trip);
                      context.push('/create-trip', extra: tripObj);
                    } catch (e) {
                      debugPrint('Navigation Error: ');
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
