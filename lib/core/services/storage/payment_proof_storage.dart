import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'supabase_storage_service.dart';

/// Abstraction for storing payment proof images.
abstract class PaymentProofStorage {
  Future<String> uploadPaymentProof(String bookingId, dynamic file);
}

/// Development mode implementation that bypasses Storage.
class LocalPaymentProofStorage implements PaymentProofStorage {
  @override
  Future<String> uploadPaymentProof(String bookingId, dynamic file) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'LOCAL_DEVELOPMENT_IMAGE';
  }
}

/// Production implementation using Supabase Storage.
class SupabasePaymentProofStorage implements PaymentProofStorage {
  final SupabaseStorageService _storageService = SupabaseStorageService();

  @override
  Future<String> uploadPaymentProof(String bookingId, dynamic file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Convert to XFile
    XFile xfile;
    if (file is XFile) {
      xfile = file;
    } else {
      throw Exception('Invalid file type for upload');
    }

    return await _storageService.uploadPaymentProof(user.uid, bookingId, xfile);
  }
}
