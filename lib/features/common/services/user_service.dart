import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class UserService {
  Future<List<UserModel>> fetchAll({
    int? limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<UserModel?> fetchById(String id);
  Future<void> save(UserModel item);
  Future<void> update(UserModel item);
  Future<void> remove(String id, {bool softDelete = true});
  Stream<List<UserModel>> streamAll();
  Stream<UserModel?> streamById(String id);
  Future<void> batchWrite(List<UserModel> items);
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction transaction) action,
  );
}
