import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

abstract class ReportService {
  Future<List<ReportModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<ReportModel?> fetchById(String id);
  Future<void> save(ReportModel item);
  Future<void> update(ReportModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<ReportModel>> streamAll();
  Stream<ReportModel?> streamById(String id);
  Future<void> batchWrite(List<ReportModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
