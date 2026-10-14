import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../domain/models/wallet.dart';
import '../../domain/models/transaction.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../../../core/services/notification_service.dart';

class WalletRepositoryImpl implements WalletRepository {
  final FirebaseFirestore _firestore;

  WalletRepositoryImpl(this._firestore);

  @override
  Future<Wallet?> getWallet(String userId) async {
    final query = await _firestore
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      return Wallet.fromJson(query.docs.first.data());
    }
    return null;
  }

  @override
  Future<void> createWallet(Wallet wallet) async {
    await _firestore.collection('wallets').doc(wallet.id).set(wallet.toJson());
  }

  @override
  Future<void> updateBalance(String userId, double amount) async {
    final query = await _firestore
        .collection('wallets')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final docId = query.docs.first.id;
      final currentBalance =
          (query.docs.first.data()['balance'] as num?)?.toDouble() ?? 0.0;
      await _firestore.collection('wallets').doc(docId).update({
        'balance': currentBalance + amount,
      });

      await SystemNotificationService.sendNotification(
        title: 'تحديث المحفظة',
        body: amount > 0
            ? 'تمت إضافة $amount ر.س إلى محفظتك.'
            : 'تم خصم ${amount.abs()} ر.س من محفظتك.',
        targetUserId: userId,
        category: 'wallet',
        targetRole: 'all',
      );
    }
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toJson());

    // Retrieve wallet to get userId for notification
    final doc = await _firestore
        .collection('wallets')
        .doc(transaction.walletId)
        .get();
    if (doc.exists && doc.data() != null) {
      final userId = doc.data()!['userId'];
      await SystemNotificationService.sendNotification(
        title: 'معاملة جديدة',
        body: 'تمت إضافة معاملة مالية جديدة بقيمة ${transaction.amount} ر.س',
        targetUserId: userId,
        category: 'payment',
        targetRole: 'all',
      );
    }
  }

  @override
  Future<List<Transaction>> getTransactions(String walletId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('walletId', isEqualTo: walletId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Transaction.fromJson(doc.data()))
        .toList();
  }
}
