import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/supabase_config.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _publicBucket = 'rahhal-public';
  static const String _privateBucket = 'rahhal-private';

  Future<Uint8List> _compressImage(Uint8List bytes, String extension) async {
    try {
      if (extension != '.jpg' &&
          extension != '.jpeg' &&
          extension != '.png' &&
          extension != '.webp') {
        return bytes;
      }

      var format = CompressFormat.jpeg;
      if (extension == '.png') {
        format = CompressFormat.png;
      } else if (extension == '.webp') {
        format = CompressFormat.webp;
      }

      final compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 80,
        minWidth: 1920,
        minHeight: 1920,
        format: format,
      );

      return compressedBytes;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return bytes;
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Master upload method that handles both public and private uploads natively
  Future<String> _uploadFile(
    XFile file,
    String storagePath, {
    required bool isPrivate,
    bool upsert = true,
  }) async {
    final bucket = isPrivate ? _privateBucket : _publicBucket;
    try {
      final bytes = await file.readAsBytes();
      final extension = p.extension(file.name).toLowerCase();
      final mimeType = _getMimeType(extension);

      final compressedBytes = await _compressImage(bytes, extension);

      final fbUser = FirebaseAuth.instance.currentUser;

      String? jwtSub;
      String? jwtRole;
      if (fbUser != null) {
        try {
          final token = await fbUser.getIdToken(false);
          if (token != null) {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = utf8.decode(
                base64Url.decode(base64Url.normalize(parts[1])),
              );
              final data = json.decode(payload);
              jwtSub = data['sub'];
              jwtRole = data['role'];
            }
          }
        } catch (_) {}
      }

      debugPrint('[STORAGE_UPLOAD] bucket: $bucket');
      debugPrint('[STORAGE_UPLOAD] storagePath: $storagePath');
      debugPrint('[STORAGE_UPLOAD] fileSize: ${compressedBytes.length}');
      debugPrint('[STORAGE_UPLOAD] mimeType: $mimeType');
      debugPrint('[STORAGE_UPLOAD] upsert value: $upsert');
      debugPrint('[STORAGE_UPLOAD] Firebase UID: ${fbUser?.uid}');
      debugPrint('[STORAGE_UPLOAD] JWT sub: $jwtSub');
      debugPrint('[STORAGE_UPLOAD] JWT role: $jwtRole');

      await _client.storage
          .from(bucket)
          .uploadBinary(
            storagePath,
            compressedBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: upsert,
              contentType: mimeType,
            ),
          );

      debugPrint('uploadSucceeded: true');

      if (isPrivate) {
        return 'private://$storagePath';
      } else {
        return _client.storage.from(bucket).getPublicUrl(storagePath);
      }
    } on StorageException catch (e) {
      debugPrint(
        '[STORAGE_UPLOAD_ERROR] StorageException message: ${e.message}',
      );
      debugPrint(
        '[STORAGE_UPLOAD_ERROR] StorageException statusCode: ${e.statusCode}',
      );

      String errorContext = 'فشل الرفع.';
      if (e.statusCode == '403') {
        errorContext = 'غير مصرح لك برفع هذا الملف (403).';
      } else if (e.statusCode == '401') {
        errorContext = 'غير مصرح لك (401).';
      } else if (e.statusCode == '404') {
        errorContext = 'المسار غير موجود (404).';
      } else if (e.statusCode == '409') {
        errorContext = 'الملف موجود مسبقاً (409).';
      } else if (e.statusCode == '413') {
        errorContext = 'حجم الملف كبير جداً (413).';
      } else if (e.statusCode == '500') {
        errorContext = 'خطأ في الخادم (500).';
      }
      throw Exception('$errorContext (${e.message})');
    } catch (e) {
      debugPrint('[SUPPORT_ATTACHMENT] storageError: $e');
      debugPrint('Unexpected Upload Error: $e');
      throw Exception('حدث خطأ غير متوقع أثناء الرفع.');
    }
  }

  /// Get Signed URL for a private file
  Future<String> getSignedUrl(String privateUrl) async {
    if (!privateUrl.startsWith('private://')) return privateUrl;
    final path = privateUrl.replaceFirst('private://', '');
    try {
      return await _client.storage
          .from(_privateBucket)
          .createSignedUrl(path, 60 * 60 * 24);
    } catch (e) {
      debugPrint('Error generating signed URL: $e');
      return '';
    }
  }

  /// Get Signed URL via Edge Function for Driver to securely view payment proof
  Future<String> getPaymentProofSignedUrl(
    String bookingId,
    String privateUrl,
  ) async {
    if (!privateUrl.startsWith('private://')) return privateUrl;
    final path = privateUrl.replaceFirst('private://', '');
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) return '';
      final token = await fbUser.getIdToken();

      final url = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/payment-proof-signed-url',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'bookingId': bookingId, 'path': path}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['signedUrl'] ?? '';
      }
      debugPrint(
        'Failed to fetch signed URL from edge function, status: ${response.statusCode}',
      );
      return '';
    } catch (e) {
      debugPrint('Error calling signed URL edge function: $e');
      return '';
    }
  }

  /// Get Signed URL via Edge Function for Booking Chat Attachments
  Future<String> getBookingChatAttachmentSignedUrl(
    String bookingId,
    String privateUrl,
  ) async {
    if (!privateUrl.startsWith('private://')) return privateUrl;
    final path = privateUrl.replaceFirst('private://', '');
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) return '';
      final token = await fbUser.getIdToken();

      final url = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/booking-chat-signed-url',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'bookingId': bookingId, 'path': path}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['signedUrl'] ?? '';
      }
      debugPrint(
        'Failed to fetch booking chat signed URL from edge function, status: ${response.statusCode}',
      );
      return '';
    } catch (e) {
      debugPrint('Error calling booking chat signed URL edge function: $e');
      return '';
    }
  }

  /// Upload Driver Profile Image (Public avatar for passenger viewing)
  Future<String> uploadProfileImage(String userId, XFile file) async {
    final path = 'profiles/$userId/avatar.jpg';
    return _uploadFile(file, path, isPrivate: false);
  }

  /// Upload Driver Personal Photo (Private for verification only)
  Future<String> uploadDriverVerificationPhoto(
    String driverId,
    XFile file,
  ) async {
    final path = 'drivers/$driverId/documents/personal_verification_photo.jpg';
    return _uploadFile(file, path, isPrivate: true);
  }

  /// Uploads a generic file to the specified path (Public)
  Future<String> uploadGenericFile(String path, XFile file) async {
    return _uploadFile(file, path, isPrivate: false);
  }

  /// Upload Driver Document (Identity, License) (Private)
  Future<String> uploadDriverDocument(
    String driverId,
    String documentType,
    XFile file,
  ) async {
    final path = 'drivers/$driverId/documents/$documentType.jpg';
    return _uploadFile(file, path, isPrivate: true);
  }

  /// Upload Vehicle Primary or Additional Photo (supports public or private)
  Future<String> uploadVehiclePhoto(
    String driverId,
    String vehicleId,
    String photoType,
    XFile file, {
    bool isPrivate = false,
  }) async {
    final path = 'drivers/$driverId/vehicles/$vehicleId/$photoType.jpg';
    return _uploadFile(file, path, isPrivate: isPrivate);
  }

  /// Uploads an attachment for the support system (Chat / Tickets / Reports)
  Future<String> uploadSupportAttachment(
    String userType,
    String uploaderId,
    String conversationId,
    XFile file,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = p
        .basename(file.name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    // Using the public bucket according to Auth Insert policy:
    // (storage.foldername(name))[2] = (auth.jwt()->>'sub') -> support/{uploaderId}/...
    final path = 'support/$uploaderId/$conversationId/${timestamp}_$safeName';
    return _uploadFile(file, path, isPrivate: false);
  }

  /// Uploads a payment proof for a booking (Private)
  Future<String> uploadPaymentProof(
    String passengerId,
    String bookingId,
    XFile file,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = p
        .basename(file.name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    // Using private bucket according to Passenger Insert policy:
    // (storage.foldername(name))[1] = 'passengers' AND (storage.foldername(name))[2] = (auth.jwt()->>'sub')
    final path =
        'passengers/$passengerId/payment_proofs/$bookingId/${timestamp}_$safeName';
    return _uploadFile(file, path, isPrivate: true, upsert: false);
  }

  /// Uploads an attachment for the booking chat (Private)
  Future<String> uploadBookingChatAttachment(
    String role,
    String userId,
    String bookingId,
    XFile file,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = p
        .basename(file.name)
        .replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');

    // Role must be 'passenger' or 'driver'
    final folderPrefix = role == 'passenger' ? 'passengers' : 'drivers';
    final path =
        '$folderPrefix/$userId/booking_chat/$bookingId/${timestamp}_$safeName';

    // Use upsert: false for strict INSERT policy
    return _uploadFile(file, path, isPrivate: true, upsert: false);
  }

  /// Resolves an attachment URL correctly, handling private://, public URLs, and raw paths
  Future<String?> resolveAttachmentUrl(String? url, {String? bookingId}) async {
    if (url == null || url.isEmpty) return null;

    // If it's already an HTTP URL (public), return directly
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // If it's a private:// URL, use the Edge Function for passenger/driver access
    if (url.startsWith('private://')) {
      if (bookingId != null) {
        if (url.contains('payment_proofs')) {
          return await getPaymentProofSignedUrl(bookingId, url);
        } else if (url.contains('booking_chat')) {
          return await getBookingChatAttachmentSignedUrl(bookingId, url);
        }
      }
      // Otherwise fallback to general signed URL (requires Admin / RLS SELECT access)
      return await getSignedUrl(url);
    }

    // If it's a raw path in the public bucket (legacy support path), get public URL
    return _client.storage.from(_publicBucket).getPublicUrl(url);
  }
}
