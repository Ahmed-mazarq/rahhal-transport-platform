import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rahal/features/admin/presentation/providers/admin_passenger_details_provider.dart';
import 'package:rahal/features/admin/utils/booking_status_mapper.dart';
import 'package:rahal/features/trips/domain/models/booking.dart';
import 'package:rahal/features/trips/domain/models/trip.dart';
import 'package:rahal/features/trips/domain/models/trip_request.dart';
import 'package:rahal/features/admin/presentation/screens/admin_booking_details_screen.dart';
import 'package:rahal/features/admin/presentation/screens/admin_trip_details_screen.dart';

class PassengerDetailsTab extends ConsumerWidget {
  final String userId;

  const PassengerDetailsTab({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(passengerDetailsProvider(userId));

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'تعذر تحميل البيانات',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref
                  .read(passengerDetailsProvider(userId).notifier)
                  .fetchData(userId),
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(passengerDetailsProvider(userId).notifier)
            .fetchData(userId);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummarySection(state.counts),
          const SizedBox(height: 16),
          _buildBookingsSection(
            title: 'طلبات الحجز',
            bookings: state.bookings
                .where(
                  (b) => [
                    'pending',
                    'awaiting_payment',
                    'pending_payment',
                    'payment_verification',
                    'awaiting_driver_verification',
                    'support_review',
                  ].contains(b.status),
                )
                .toList(),
            tripCache: state.tripCache,
            emptyMessage: 'لا توجد طلبات حجز قيد الانتظار',
            context: context,
          ),
          const SizedBox(height: 16),
          _buildBookingsSection(
            title: 'الحجوزات',
            bookings: state.bookings
                .where((b) => ['confirmed', 'accepted'].contains(b.status))
                .toList(),
            tripCache: state.tripCache,
            emptyMessage: 'لا توجد حجوزات مؤكدة',
            context: context,
          ),
          const SizedBox(height: 16),
          _buildTripsSection(
            title: 'الرحلات القادمة',
            trips: _getTripsByStatus(
              state.bookings,
              state.tripCache,
              'upcoming',
            ),
            emptyMessage: 'لا توجد رحلات قادمة',
            context: context,
          ),
          const SizedBox(height: 16),
          _buildTripsSection(
            title: 'الرحلات الجارية',
            trips: _getTripsByStatus(
              state.bookings,
              state.tripCache,
              'current',
            ),
            emptyMessage: 'لا توجد رحلات جارية حالياً',
            context: context,
          ),
          const SizedBox(height: 16),
          _buildTripsSection(
            title: 'الرحلات المكتملة',
            trips: _getTripsByStatus(
              state.bookings,
              state.tripCache,
              'completed',
            ),
            emptyMessage: 'لا توجد رحلات مكتملة',
            context: context,
          ),
          const SizedBox(height: 16),
          _buildTripsSection(
            title: 'الرحلات الملغاة',
            trips: _getTripsByStatus(
              state.bookings,
              state.tripCache,
              'cancelled',
            ), // Includes cancelled bookings' trips if applicable or just cancelled trips.
            emptyMessage: 'لا توجد رحلات ملغاة',
            context: context,
          ),
          const SizedBox(height: 16),
          _buildTripRequestsSection(state.tripRequests),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummarySection(PassengerCounts counts) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملخص',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildSummaryItem(
                  'إجمالي الحجوزات',
                  counts.totalBookings.toString(),
                  Colors.blueGrey,
                ),
                _buildSummaryItem(
                  'طلبات الحجز',
                  counts.pendingBookings.toString(),
                  Colors.orange,
                ),
                _buildSummaryItem(
                  'مؤكدة',
                  counts.currentBookings.toString(),
                  Colors.blue,
                ),
                _buildSummaryItem(
                  'مكتملة',
                  counts.completedBookings.toString(),
                  Colors.green,
                ),
                _buildSummaryItem(
                  'ملغاة',
                  counts.cancelledBookings.toString(),
                  Colors.red,
                ),
                _buildSummaryItem(
                  'الرحلات القادمة',
                  counts.upcomingTrips.toString(),
                  Colors.indigo,
                ),
                _buildSummaryItem(
                  'الرحلات الجارية',
                  counts.currentTrips.toString(),
                  Colors.teal,
                ),
                _buildSummaryItem(
                  'الرحلات المكتملة',
                  counts.completedTrips.toString(),
                  Colors.green[800]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<Trip> _getTripsByStatus(
    List<Booking> bookings,
    Map<String, Trip> tripCache,
    String classification,
  ) {
    final Set<String> processed = {};
    final List<Trip> result = [];
    final now = DateTime.now();

    for (var b in bookings) {
      if (b.tripId.isNotEmpty &&
          tripCache.containsKey(b.tripId) &&
          !processed.contains(b.tripId)) {
        final trip = tripCache[b.tripId]!;
        processed.add(trip.id);

        if (classification == 'completed' &&
            ['completed', 'finished'].contains(trip.status)) {
          result.add(trip);
        } else if (classification == 'current' &&
            ['active', 'running', 'started'].contains(trip.status)) {
          result.add(trip);
        } else if (classification == 'current' &&
            ['published', 'scheduled'].contains(trip.status) &&
            now.isAfter(trip.departureTime) &&
            now.isBefore(trip.arrivalTime)) {
          result.add(trip);
        } else if (classification == 'upcoming' &&
            ['published', 'scheduled'].contains(trip.status) &&
            now.isBefore(trip.departureTime)) {
          result.add(trip);
        } else if (classification == 'cancelled' &&
            ['cancelled'].contains(trip.status)) {
          result.add(trip);
        }
      }
    }
    return result;
  }

  Widget _buildBookingsSection({
    required String title,
    required List<Booking> bookings,
    required Map<String, Trip> tripCache,
    required String emptyMessage,
    required BuildContext context,
  }) {
    return ExpansionTile(
      title: Text(
        '$title (${bookings.length})',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      initiallyExpanded: bookings.isNotEmpty,
      children: bookings.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
              ),
            ]
          : bookings
                .map((b) => _buildBookingCard(b, tripCache[b.tripId], context))
                .toList(),
    );
  }

  Widget _buildBookingCard(Booking booking, Trip? trip, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الحجز #${booking.bookingNumber.isNotEmpty ? booking.bookingNumber : booking.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    BookingStatusMapper.getLabel(booking.status),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: BookingStatusMapper.getColor(booking.status),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const Divider(),
            if (trip != null) ...[
              Text(
                'الرحلة: ${trip.startLocationName.isNotEmpty ? trip.startLocationName : trip.departureCity} → ${trip.endLocationName.isNotEmpty ? trip.endLocationName : trip.arrivalCity}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
              Text(
                'موعد الرحلة: ${trip.departureTime.toString().substring(0, 16)}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
              Text(
                'السائق: ${trip.driverName}',
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              ),
            ] else ...[
              const Text(
                'بيانات الرحلة غير متاحة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
              ),
            ],
            Text(
              'المقاعد: ${booking.seatCount.toInt()}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),
            Text(
              'السعر: ${booking.price} ${trip?.currency ?? "ريال"}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminBookingDetailsScreen(booking: booking),
                      ),
                    );
                  },
                  child: const Text(
                    'عرض تفاصيل الحجز',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                if (trip != null)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminTripDetailsScreen(trip: trip),
                        ),
                      );
                    },
                    child: const Text(
                      'عرض تفاصيل الرحلة',
                      style: TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsSection({
    required String title,
    required List<Trip> trips,
    required String emptyMessage,
    required BuildContext context,
  }) {
    return ExpansionTile(
      title: Text(
        '$title (${trips.length})',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      initiallyExpanded: trips.isNotEmpty,
      children: trips.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.grey,
                  ),
                ),
              ),
            ]
          : trips.map((t) => _buildTripCard(t, context)).toList(),
    );
  }

  Widget _buildTripCard(Trip trip, BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          '${trip.startLocationName.isNotEmpty ? trip.startLocationName : trip.departureCity} → ${trip.endLocationName.isNotEmpty ? trip.endLocationName : trip.arrivalCity}',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'الموعد: ${trip.departureTime.toString().substring(0, 16)}\nالسائق: ${trip.driverName}',
        ),
        trailing: Chip(
          label: Text(
            TripStatusMapper.getLabel(trip.status),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          backgroundColor: TripStatusMapper.getColor(trip.status),
        ),
        isThreeLine: true,
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

  Widget _buildTripRequestsSection(List<TripRequest> requests) {
    return ExpansionTile(
      title: Text(
        'طلبات الرحلات (${requests.length})',
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      children: requests.isEmpty
          ? [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'لا توجد طلبات رحلات',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                ),
              ),
            ]
          : requests
                .map(
                  (r) => Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      title: Text(
                        '${r.startLocationName} → ${r.endLocationName}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('السعر المقدر: ${r.estimatedPrice}'),
                      trailing: Chip(
                        label: Text(
                          r.status,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
    );
  }
}
