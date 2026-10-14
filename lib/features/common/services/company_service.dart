import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company_model.dart';

abstract class CompanyService {
  Future<List<CompanyModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<CompanyModel?> fetchById(String id);
  Future<void> save(CompanyModel item);
  Future<void> update(CompanyModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<CompanyModel>> streamAll();
  Stream<CompanyModel?> streamById(String id);
  Future<void> batchWrite(List<CompanyModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
