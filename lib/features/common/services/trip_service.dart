import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

abstract class TripService {
  Future<List<TripModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<TripModel?> fetchById(String id);
  Future<void> save(TripModel item);
  Future<void> update(TripModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<TripModel>> streamAll();
  Stream<TripModel?> streamById(String id);
  Future<void> batchWrite(List<TripModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
  Future<List<TripModel>> searchTrips({
    required String origin,
    required String destination,
    required DateTime travelDate,
    int passengerCount = 1,
  });
}
