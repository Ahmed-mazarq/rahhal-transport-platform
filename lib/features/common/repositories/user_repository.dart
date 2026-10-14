import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<List<UserModel>> getAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<UserModel?> getById(String id);
  Future<void> create(UserModel item);
  Future<void> update(UserModel item);
  Future<void> delete(String id, {bool softDelete = true});
  Stream<List<UserModel>> watchAll();
  Stream<UserModel?> watchById(String id);
  Future<void> batchWrite(List<UserModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
