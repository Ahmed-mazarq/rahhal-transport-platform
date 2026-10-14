import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported() || await _auth.canCheckBiometrics;
  }

  Future<bool> authenticate(String localizedReason) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
      );
      return authenticated;
    } catch (e) {
      return false;
    }
  }
}
