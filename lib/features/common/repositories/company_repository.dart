import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';

abstract class CompanyRepository {
  Future<List<CompanyModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<CompanyModel?> getById(String id);
  Future<void> create(CompanyModel item);
  Future<void> update(CompanyModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<CompanyModel>> watchAll();
  Stream<CompanyModel?> watchById(String id);
  Future<void> batchWrite(List<CompanyModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
