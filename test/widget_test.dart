import 'package:flutter_test/flutter_test.dart';
import 'package:rahal/features/common/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('UserModel serialization and deserialization', () {
      final now = DateTime.now();
      final user = UserModel(
        id: '123',
        name: 'احمد علي حسن',
        phone: '777777777',
        email: '777777777@rahal.app',
        role: 'passenger',
        status: 'active',
        walletBalance: 0.0,
        createdAt: now,
        updatedAt: now,
        lastLogin: now,
      );

      final json = user.toFirestore();
      final decoded = UserModel.fromFirestore(json, '123');

      expect(decoded.id, '123');
      expect(decoded.uid, '123');
      expect(decoded.name, 'احمد علي حسن');
      expect(decoded.fullName, 'احمد علي حسن');
      expect(decoded.phone, '777777777');
      expect(decoded.role, 'passenger');
    });
  });
}
