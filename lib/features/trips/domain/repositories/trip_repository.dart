import '../models/trip.dart';
import '../models/trip_request.dart';
import '../models/booking.dart';
import '../models/stop.dart';
import '../models/seat.dart';

abstract class TripRepository {
  Future<void> createTripRequest(TripRequest request);
  Stream<TripRequest?> watchTripRequest(String requestId);
  Future<void> createTrip(Trip trip);
  Future<Trip?> getTrip(String tripId);
  Future<void> updateTripStatus(String tripId, String status);
  Future<void> createBooking(Booking booking);
  Future<List<Booking>> getPassengerBookings(String passengerId);
  Future<List<Booking>> getDriverBookings(String driverId);
  Stream<List<Booking>> watchDriverBookings(String driverId);
  Future<List<Trip>> getDriverTrips(String driverId);
  Future<List<Map<String, dynamic>>> getPassengerRecentBookingInteractions(
    String passengerId,
  );
  Future<List<Map<String, dynamic>>> getDriverRecentBookingInteractions(
    String driverId,
  );
  Future<List<Map<String, dynamic>>> getCompanyRecentBookingInteractions(
    String companyId,
  );
  Future<void> updateBookingAttendance(String bookingId, String attendance);
  Future<void> updateTripStops(String tripId, List<Stop> stops);
  Future<void> updateTripSeats(String tripId, List<Seat> seats);
  Future<void> updateBookingStatus(String bookingId, String status);

  // New features for advanced search and passenger module
  Stream<List<Trip>> watchTrips();
  Future<List<Trip>> searchTrips({
    required String departureCountryId,
    required String departureProvinceId,
    required String departureCityId,
    required String arrivalCountryId,
    required String arrivalProvinceId,
    required String arrivalCityId,
    int passengerCount = 1,
    String? tripType,
    DateTime? travelDate,
  });
  Future<List<Trip>> getNearbyTrips();
  Future<List<Trip>> getSuggestedTrips();
  Stream<Booking?> watchBooking(String bookingId);
  Future<void> cancelBooking(String bookingId);
  Future<void> addTripReview({
    required String tripId,
    required String driverId,
    required String passengerId,
    required double rating,
    required String comment,
    required Map<String, dynamic> reviewCategories,
    String? bookingId,
  });

  // Booking and Deposit Workflow
  Future<void> createBookingRequest(Booking booking);
  Future<void> submitPaymentProof(
    String bookingId,
    String proofUrl,
    String transactionReference,
    String senderName,
    double amount,
    String? paymentMethodId,
  );
  Future<void> confirmBookingDeposit(String bookingId, String driverId);
  Future<void> rejectPaymentVerification(
    String bookingId,
    String driverId,
    String reason,
  );
  Future<void> expireBooking(String bookingId);
  Future<Booking?> getBooking(String bookingId);
  Future<void> createManualDriverBooking(Booking booking);
  Future<void> releaseManualDriverBooking(String bookingId);
}
