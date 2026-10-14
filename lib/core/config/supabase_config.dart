import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupabaseConfig {
  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  // Public portfolio note: runtime endpoints are injected with --dart-define.
  // Production authorization must still be enforced by Supabase RLS and server-side checks.

  static Future<void> initialize() async {
    try {
      if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
        throw StateError(
          'Missing SUPABASE_URL or SUPABASE_PUBLISHABLE_KEY. '
          'Provide them with --dart-define for local development.',
        );
      }
      await Supabase.initialize(
        url: _supabaseUrl,
        publishableKey: _supabaseAnonKey,
        accessToken: () async {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser == null) return null;

          // Pass false to getIdToken so we don't force refresh unnecessarily.
          String? fbToken = await fbUser.getIdToken(false);
          if (fbToken == null) return null;

          // Supabase Third-Party Firebase Auth directly accepts the Firebase ID token.
          // However, the token MUST have the custom claim: role = "authenticated".
          try {
            Map<String, dynamic>? data = _decodeToken(fbToken);
            if (data == null) return null;

            debugPrint('SupabaseConfig: Checking token... UID: ${fbUser.uid}');
            debugPrint('SupabaseConfig: Token SUB: ${data['sub']}');
            debugPrint('SupabaseConfig: Token ROLE: ${data['role']}');
            debugPrint('SupabaseConfig: Token EXP: ${data['exp']}');

            if (data['role'] != 'authenticated') {
              debugPrint(
                'SupabaseConfig: Token missing "role: authenticated". Calling claim bridge...',
              );
              final url = Uri.parse(
                '$_supabaseUrl/functions/v1/firebase-claim-bridge',
              );
              final response = await http.post(
                url,
                headers: {
                  'Authorization': 'Bearer $fbToken',
                  'Content-Type': 'application/json',
                },
              );

              debugPrint(
                'SupabaseConfig: Claim bridge HTTP status: ${response.statusCode}',
              );

              if (response.statusCode == 200) {
                // Force refresh the token to retrieve the newly added claim.
                fbToken = await fbUser.getIdToken(true);
                debugPrint('SupabaseConfig: Token refreshed successfully.');

                // Re-decode and verify the new token
                data = _decodeToken(fbToken);
                debugPrint('SupabaseConfig: Final Token SUB: ${data?['sub']}');
                debugPrint(
                  'SupabaseConfig: Final Token ROLE: ${data?['role']}',
                );
              } else {
                debugPrint(
                  'SupabaseConfig: Claim bridge response body: ${response.body}',
                );
                throw Exception(
                  'Auth bridge failed with status ${response.statusCode}',
                );
              }
            }

            if (data == null || data['role'] != 'authenticated') {
              debugPrint(
                'SupabaseConfig: CRITICAL ERROR - Final token still lacks role=authenticated.',
              );
              throw Exception(
                'Final Firebase token lacks role=authenticated. Check claim bridge.',
              );
            }

            if (data['sub'] != fbUser.uid) {
              debugPrint(
                'SupabaseConfig: CRITICAL ERROR - Final token sub does not match UID.',
              );
              throw Exception('Firebase token sub does not match UID.');
            }
          } catch (e) {
            debugPrint('SupabaseConfig: Error checking token claims: $e');
            rethrow; // Don't silently continue with invalid token!
          }

          return fbToken;
        },
        debug: kDebugMode,
      );
      debugPrint('===== SUPABASE STORAGE READY =====');
    } catch (e) {
      debugPrint('Supabase Initialization Error: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;

  static Map<String, dynamic>? _decodeToken(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return json.decode(payload);
  }
}
