import '../models/wallet.dart';
import '../models/transaction.dart';

abstract class WalletRepository {
  Future<Wallet?> getWallet(String userId);
  Future<void> createWallet(Wallet wallet);
  Future<void> updateBalance(String userId, double amount);
  Future<void> addTransaction(Transaction transaction);
  Future<List<Transaction>> getTransactions(String walletId);
}
