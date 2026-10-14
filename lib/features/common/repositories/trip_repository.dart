import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

abstract class TripRepository {
  Future<List<TripModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<TripModel?> getById(String id);
  Future<void> create(TripModel item);
  Future<void> update(TripModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<TripModel>> watchAll();
  Stream<TripModel?> watchById(String id);
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
