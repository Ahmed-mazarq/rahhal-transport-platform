import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

abstract class ReportRepository {
  Future<List<ReportModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<ReportModel?> getById(String id);
  Future<void> create(ReportModel item);
  Future<void> update(ReportModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<ReportModel>> watchAll();
  Stream<ReportModel?> watchById(String id);
  Future<void> batchWrite(List<ReportModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
