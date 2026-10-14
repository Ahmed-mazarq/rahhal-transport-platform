import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DriverProfileImageState {
  final String url;
  final int? updatedAt;

  const DriverProfileImageState({required this.url, this.updatedAt});
}

final driverProfileImageProvider =
    StreamProvider.autoDispose<DriverProfileImageState>((ref) {
      final authState = ref.watch(authProvider);
      if (authState is! Authenticated) {
        return Stream.value(const DriverProfileImageState(url: ''));
      }

      final uid = authState.user.id;
      final firestore = FirebaseFirestore.instance;

      final driverStream = firestore.collection('drivers').doc(uid).snapshots();

      return driverStream.asyncMap((driverDoc) async {
        final dData = driverDoc.data();
        final dUrl = dData?['profileImage']?.toString() ?? '';
        final dTime = (dData?['profileImageUpdatedAt'] as num?)?.toInt();

        if (dUrl.isNotEmpty) {
          return DriverProfileImageState(url: dUrl, updatedAt: dTime);
        }

        // Fallback to user document
        final userDoc = await firestore.collection('users').doc(uid).get();
        final uData = userDoc.data();
        final uUrl = uData?['profileImage']?.toString() ?? '';
        final uTime = (uData?['profileImageUpdatedAt'] as num?)?.toInt();

        return DriverProfileImageState(url: uUrl, updatedAt: uTime);
      });
    });
