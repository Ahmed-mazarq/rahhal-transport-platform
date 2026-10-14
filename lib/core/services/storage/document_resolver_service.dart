import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/supabase_config.dart';

class ResolvedDocument {
  final String resolvedUrl;
  final bool isPrivate;
  final String storagePath;
  final String referenceType;

  ResolvedDocument({
    required this.resolvedUrl,
    required this.isPrivate,
    required this.storagePath,
    required this.referenceType,
  });
}

class _SignedUrlCacheEntry {
  final String url;
  final DateTime expiresAt;
  _SignedUrlCacheEntry({required this.url, required this.expiresAt});
}

class DocumentResolverService {
  static final Map<String, _SignedUrlCacheEntry> _cache = {};

  String _extractPathFromLegacyUrl(String url, String bucket) {
    if (url.contains('/object/sign/$bucket/')) {
      final parts = url.split('/object/sign/$bucket/');
      if (parts.length > 1) {
        return parts[1].split('?')[0];
      }
    }
    if (url.contains('/object/authenticated/$bucket/')) {
      final parts = url.split('/object/authenticated/$bucket/');
      if (parts.length > 1) {
        return parts[1].split('?')[0];
      }
    }
    if (url.contains('/object/public/$bucket/')) {
      final parts = url.split('/object/public/$bucket/');
      if (parts.length > 1) {
        return parts[1].split('?')[0];
      }
    }
    return '';
  }

  Future<ResolvedDocument> resolve(String storedReference) async {
    if (storedReference.isEmpty ||
        storedReference.contains('mock.rahal.local') ||
        storedReference.contains('placehold.co')) {
      throw Exception('الصورة غير متوفرة');
    }

    String path = '';
    bool isPrivate = false;

    // 1. Current private reference
    if (storedReference.startsWith('private://')) {
      path = storedReference.replaceFirst('private://', '');
      isPrivate = true;
    }
    // 2. Current public Supabase URL
    else if (storedReference.contains('/object/public/rahhal-public/')) {
      return ResolvedDocument(
        resolvedUrl: storedReference,
        isPrivate: false,
        storagePath: _extractPathFromLegacyUrl(
          storedReference,
          'rahhal-public',
        ),
        referenceType: 'public_url',
      );
    }
    // 3 & 4. Legacy private signed URL & authenticated private URL
    else if (storedReference.contains('/object/sign/rahhal-private/') ||
        storedReference.contains('/object/authenticated/rahhal-private/')) {
      path = _extractPathFromLegacyUrl(storedReference, 'rahhal-private');
      isPrivate = true;
    }
    // 5. Raw private bucket reference
    else if (storedReference.startsWith('rahhal-private/')) {
      path = storedReference.replaceFirst('rahhal-private/', '');
      isPrivate = true;
    }
    // 6. Raw public bucket reference
    else if (storedReference.startsWith('rahhal-public/')) {
      path = storedReference.replaceFirst('rahhal-public/', '');
      return ResolvedDocument(
        resolvedUrl:
            '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/rahhal-public/$path',
        isPrivate: false,
        storagePath: path,
        referenceType: 'raw_public',
      );
    }
    // 7. Legacy raw path: drivers/{uid}/documents/...
    else if (storedReference.startsWith('drivers/') &&
        storedReference.contains('/documents/')) {
      path = storedReference;
      isPrivate = true;
    }
    // 8. Legacy raw profile path: profiles/{uid}/...
    else if (storedReference.startsWith('profiles/')) {
      path = storedReference;
      return ResolvedDocument(
        resolvedUrl:
            '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/rahhal-public/$path',
        isPrivate: false,
        storagePath: path,
        referenceType: 'legacy_profile',
      );
    }
    // 9. Vehicle paths
    else if (storedReference.startsWith('drivers/') &&
        storedReference.contains('/vehicles/')) {
      path = storedReference;
      if (storedReference.contains('vehiclePlate')) {
        isPrivate = true;
      } else {
        return ResolvedDocument(
          resolvedUrl:
              '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/rahhal-public/$path',
          isPrivate: false,
          storagePath: path,
          referenceType: 'vehicle_public',
        );
      }
    }
    // Fallback
    else {
      path = storedReference;
      isPrivate = true; // Safe default for unknown
    }

    if (!isPrivate) {
      return ResolvedDocument(
        resolvedUrl:
            '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/rahhal-public/$path',
        isPrivate: false,
        storagePath: path,
        referenceType: 'inferred_public',
      );
    }

    // Resolve Private URL
    if (_cache.containsKey(path)) {
      final entry = _cache[path]!;
      if (DateTime.now().isBefore(entry.expiresAt)) {
        return ResolvedDocument(
          resolvedUrl: entry.url,
          isPrivate: true,
          storagePath: path,
          referenceType: 'cached_signed',
        );
      } else {
        _cache.remove(path);
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('انتهت جلسة المصادقة، يرجى إعادة تسجيل الدخول.');
    }

    bool isRetry = false;
    String? token = await user.getIdToken();

    while (true) {
      if (token == null) {
        throw Exception('فشل في جلب رمز المصادقة');
      }

      final url = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/admin-signed-url',
      );
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'apikey': SupabaseConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'path': path}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['signedUrl'] != null) {
          final signedUrl = data['signedUrl'] as String;
          _cache[path] = _SignedUrlCacheEntry(
            url: signedUrl,
            expiresAt: DateTime.now().add(const Duration(seconds: 800)),
          );
          return ResolvedDocument(
            resolvedUrl: signedUrl,
            isPrivate: true,
            storagePath: path,
            referenceType: 'resolved_signed',
          );
        }
      }

      if (response.statusCode == 403)
        throw Exception('ليس لديك صلاحية لعرض هذا المستند.');
      if (response.statusCode == 404) throw Exception('المستند غير موجود.');

      if (response.statusCode == 401 && !isRetry) {
        isRetry = true;
        token = await user.getIdToken(true);
        continue;
      }
      if (response.statusCode == 401)
        throw Exception('فشل مصادقة المسؤول في الخادم. تأكد من إعدادات حسابك.');
      if (response.statusCode >= 500)
        throw Exception('خطأ في الخادم أثناء جلب المستند.');

      throw Exception('تعذر تحميل المستند.');
    }
  }

  // To not break existing code before it's updated, provide backward compatible method
  Future<String> resolveDocumentUrl(String storedReference) async {
    final doc = await resolve(storedReference);
    return doc.resolvedUrl;
  }
}
